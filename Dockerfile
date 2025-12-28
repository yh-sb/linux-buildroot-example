FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    binutils bc cpio file g++ git cmake ninja-build rsync bzip2 unzip wget python3 \
    autoconf bison flex kmod gdb libcurl4-openssl-dev libssl-dev uuid-dev xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
