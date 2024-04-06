# linux-buildroot-example
Example how to build and use embedded linux with Buildroot

By default, image for Raspberry Pi Zero 2 W is built. See board configs in [./buildroot-external/configs](./buildroot-external/configs) directory.

## Requirements
```bash
sudo apt update
sudo apt install autoconf bc bzip2 bison cmake flex g++ gdb make ninja-build unzip uuid-dev libssl-dev
```

## How to build
```sh
git clone --recursive https://github.com/yh-sb/linux-buildroot-example.git
cd linux-buildroot-example
make
```
Find image here: `buildroot/output/images/sdcard.img`
***Note:** if you need to update only userspace app, use: `make update`. It will update app via ssh over USB*

The userspace `app` binary is located in `/usr/bin` on the Raspberry Pi filesystem. It starts automatically on boot. Read logs: `journalctl -xef -u app` or `make log` if you connected to the board via USB.

## Automatic connection to Wi-Fi
Set your WiFi credentials directly to `rootfs_overlay/etc/wpa_supplicant.conf`:
```conf
ap_scan=1

network={
    ssid="EDIT_THIS"
    psk="EDIT_THIS"
}
```

## SSH access to the board
SSH is opened via USB (network adapter is configured automatically on Raspberry Pi side) or Wi-Fi network. In case of using USB connection board will have IP address 10.1.1.1. In case of using Wi-Fi network - find Raspberry Pi IP address on the Wi-Fi router web interface or in Raspberry Pi console.
Quick access when connected on USB:
* `make ssh` to easily connect to the device shell
* `make log` to view user app (azure-sdk-app) log.

## Firmware upgrade
Can be done in two alternative ways:

### Upgrade using SD card and sdcard.img
1. Insert SD card to the PC
2. Write `buildroot/output/images/sdcard.img` to the sd card (for example use [Balena Etcher](https://github.com/balena-io/etcher/releases) or from Linux `sudo dd bs=4M if=buildroot/output/images/sdcard.img of=/dev/sdX conv=fdatasync status=progress`) _where `/dev/sdX` is your sd card device_

### Upgrade over USB or Wi-Fi using image.swu
1. Go to the http://10.1.1.1:8080 (or use Raspberry Pi IP address in case of Wi-Fi)
2. Upload .swu file and wait for restart
