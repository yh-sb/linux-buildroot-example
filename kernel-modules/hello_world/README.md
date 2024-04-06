# hello_world
Exmaple of custom kernel module

## How to build
```bash
make ARCH=arm CROSS_COMPILE=arm-buildroot-linux-uclibcgnueabihf- KERNELDIR=../../linux BUILD_TYPE=Debug
# Install
cp hello_world.ko ../../buildroot/output/target/usr/lib/modules
```
