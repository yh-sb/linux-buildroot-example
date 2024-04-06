BUILD_TYPE ?= Debug

BUILDROOT_CONFIG = raspberrypizero2w_custom_defconfig
LINUX_CONFIG = bcm2711_defconfig

.PHONY: buildroot linux kernel-modules app image update log ssh clean

# Add Buildroot tools to PATH
$(eval export PATH=$(PWD)/buildroot/output/host/bin:$(PWD)/buildroot/output/host/sbin:$(PATH))

all: buildroot linux kernel-modules app image

buildroot:
	make -C buildroot BR2_EXTERNAL=../buildroot-external $(BUILDROOT_CONFIG)
	make -C buildroot -j $(shell grep -c ^processor /proc/cpuinfo)

linux:
	make -C linux ARCH=arm64 CROSS_COMPILE=aarch64-linux- $(LINUX_CONFIG)
	make -C linux ARCH=arm64 CROSS_COMPILE=aarch64-linux- Image modules dtbs -j $(shell grep -c ^processor /proc/cpuinfo)
	cd linux && ./scripts/clang-tools/gen_compile_commands.py
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
	make -C kernel-modules/hello_world ARCH=arm64 CROSS_COMPILE=aarch64-linux- KERNELDIR=$(PWD)/linux BUILD_TYPE=$(BUILD_TYPE)
	cp kernel-modules/hello_world/hello_world.ko buildroot/output/target/usr/lib/modules/*/

app:
	cmake -S app -Bapp/build -G Ninja -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DCMAKE_TOOLCHAIN_FILE=$(PWD)/buildroot/output/host/usr/share/buildroot/toolchainfile.cmake
	cmake --build app/build -j
	install -D app/build/app buildroot/output/target/usr/bin/app

image:
#	Rebuild buildroot to trigger rootfs overlay update
	$(MAKE) buildroot
	$(eval export BINARIES_DIR=$(PWD)/buildroot/output/images)
	$(eval export BUILD_DIR=$(PWD)/buildroot/output/build)
	./buildroot/board/raspberrypizero2w/post-image.sh
	swugenerator create --sw-description sw-description --no-compress --no-encrypt --artifactory buildroot/output/images --swu-file buildroot/output/images/image.swu --loglevel DEBUG

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

clean:
	make -C buildroot distclean
	make -C linux distclean
	make -C kernel-modules/hello_world clean
	make -C app clean
