BUILD_TYPE ?= Debug

BUILDROOT_CONFIG = raspberrypizero2w_custom_defconfig
LINUX_CONFIG = bcm2711_defconfig

.PHONY: buildroot linux kernel-modules app image update log ssh docker clean

# Add Buildroot tools to PATH
$(eval export PATH=$(PWD)/buildroot/output/host/bin:$(PWD)/buildroot/output/host/sbin:$(PATH))

all: buildroot linux kernel-modules app image

buildroot:
	make -C buildroot BR2_EXTERNAL=../buildroot-external $(BUILDROOT_CONFIG)
	make -C buildroot BR2_WGET="wget -nv -nd -t 3 --connect-timeout=10" -j $(shell nproc)

linux:
	make -C linux ARCH=arm64 CROSS_COMPILE?=aarch64-linux- $(LINUX_CONFIG)
	cd linux && ./scripts/clang-tools/gen_compile_commands.py
	make -C linux ARCH=arm64 CROSS_COMPILE?=aarch64-linux- Image modules dtbs -j $(shell nproc)
#	Install kernel
	install linux/arch/arm64/boot/Image buildroot/output/images
#	Install kernel modules
	make -C linux INSTALL_MOD_PATH=$(PWD)/buildroot/output/target/usr modules_install -j
	rm -rf buildroot/output/target/usr/lib/modules/*/build buildroot/output/target/usr/lib/modules/*/source
#	Install device tree
	rm -rf buildroot/output/images/rpi-firmware/*.dtb buildroot/output/images/rpi-firmware/overlays/*.dtbo
	install linux/arch/arm64/boot/dts/broadcom/bcm2710-rpi-zero-2-w.dtb buildroot/output/images
	install linux/arch/arm64/boot/dts/overlays/*.dtbo buildroot/output/images/rpi-firmware/overlays

kernel-modules:
	make -C kernel-modules/hello_world ARCH=arm64 CROSS_COMPILE?=aarch64-linux- KERNELDIR=$(PWD)/linux BUILD_TYPE=$(BUILD_TYPE)
	cp kernel-modules/hello_world/hello_world.ko buildroot/output/target/usr/lib/modules/*/

app:
	$(eval CMAKE_TOOLCHAIN_FILE?=$(PWD)/buildroot/output/host/usr/share/buildroot/toolchainfile.cmake)
	cmake -S app -Bapp/build -G Ninja -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) --toolchain $(CMAKE_TOOLCHAIN_FILE)
	cmake --build app/build -j
	install -D app/build/app buildroot/output/target/usr/bin/app

image:
#	Trigger rootfs overlay update
	make -C buildroot rootfs-ext2
#	Create .img SD-Card image
	genimage --rootpath $(shell mktemp -d) \
		--inputpath ./buildroot/output/images \
		--outputpath ./buildroot/output/images \
		--config ./buildroot-external/configs/genimage.cfg
#	Create .swu image
	swugenerator --sw-description buildroot-external/configs/sw-description \
		--swu-file buildroot/output/images/image.swu \
		--artifactory buildroot/output/images \
		--no-compress --no-encrypt \
		--loglevel DEBUG \
		create

update:
	@chmod 600 rootfs-overlay/root/.ssh/raspberrypi.key
	scp -i rootfs-overlay/root/.ssh/raspberrypi.key app/build/app root@10.1.1.1:/tmp
	ssh -i rootfs-overlay/root/.ssh/raspberrypi.key root@10.1.1.1 "mv /tmp/app /usr/bin && killall app"
#   systemd will autostart app

log:
	@chmod 600 rootfs-overlay/root/.ssh/raspberrypi.key
	ssh -i rootfs-overlay/root/.ssh/raspberrypi.key -t root@10.1.1.1 "journalctl -xef -u app"

ssh:
	@chmod 600 rootfs-overlay/root/.ssh/raspberrypi.key
	ssh -i rootfs-overlay/root/.ssh/raspberrypi.key -t root@10.1.1.1

# Build in Docker
docker:
# For macOS: mount partition with this project in colima: colima start --cpu 12 --memory 18 --mount /Volumes/linux:w
	docker build -t buildroot .
	docker volume create buildroot-output
	docker run --rm -it --init \
		-v $(PWD):/workspace \
		-v buildroot-output:/output \
		-v $(PWD)/buildroot/output/images:/output/images \
		-v $(PWD)/buildroot/output/target:/output/target \
		buildroot bash -c " \
			make buildroot O=/output && \
			make linux CROSS_COMPILE=/output/host/bin/aarch64-linux- && \
			make kernel-modules CROSS_COMPILE=/output/host/bin/aarch64-linux- && \
			make app CMAKE_TOOLCHAIN_FILE=/output/host/usr/share/buildroot/toolchainfile.cmake && \
			make image O=/output PATH=/output/host/bin:/output/host/sbin:\$$PATH"

clean:
	make -C buildroot distclean --no-print-directory
	make -C linux distclean --no-print-directory
	make -C kernel-modules/hello_world clean --no-print-directory
	make -C app clean --no-print-directory
	docker ps -aq --filter ancestor=buildroot | xargs -r docker rm -f
	docker images -q buildroot | xargs -r docker rmi
	docker volume ls -q --filter name=buildroot-output | xargs -r docker volume rm
