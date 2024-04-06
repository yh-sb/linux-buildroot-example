# app
Userspace example application

## Requirements
* For Linux:
    ```bash
    sudo apt install cmake g++ ninja-build libfuse2
    # Install linuxdeploy
    mkdir -p ~/bin && cd $_
    curl -L https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -o ~/bin/linuxdeploy.AppImage
    chmod +x linuxdeploy.AppImage
    export PATH=~/bin:$PATH
    ```
* [MinGW-w64](https://winlibs.com) or [MSVC](https://visualstudio.microsoft.com/free-developer-offers) or Linux GCC
* [CMake](https://cmake.org/download)
* [Ninja](https://ninja-build.org)

## How to build and launch
```bash
make

./build/app

# Deploy .AppImage
make install
```
