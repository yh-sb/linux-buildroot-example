
obj-m = hello_world.o

# Build natively by default
ARCH ?= x86_64
KERNELDIR ?= /lib/modules/*/build

ifeq ($(BUILD_TYPE),Debug)
CFLAGS = -O0 -g -DDEBUG
endif

all:
	$(MAKE) -C $(KERNELDIR) modules M=$(CURDIR) ccflags-y="$(CFLAGS)" --no-print-directory

modules_install:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules_install

clean:
	@rm -rf .*.cmd *.ko *.o *.mod *.mod.c Module.symvers modules.order
