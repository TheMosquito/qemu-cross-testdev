FROM ubuntu:18.04

ARG QEMUV

RUN apt-get update && apt-get -y install qemu qemu-utils qemu-kvm cloud-utils wget xterm pkg-config zlib1g-dev libglib2.0-dev libpixman-1-dev git bison flex make curl kmod parted netcat udev python

RUN mkdir -p /root
WORKDIR /root
RUN git clone https://github.com/qemu/qemu
WORKDIR qemu
RUN git checkout $QEMUV
RUN git submodule update --init dtc
RUN ./configure --target-list=arm-softmmu,aarch64-softmmu,ppc64-softmmu,x86_64-softmmu
RUN make -j2
RUN make install
WORKDIR /root

RUN mkdir -p -m0700 /root/.ssh
RUN ssh-keygen -f /root/.ssh/id_rsa -P ""

