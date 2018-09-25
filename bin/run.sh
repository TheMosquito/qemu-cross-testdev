#!/bin/bash

ARCH=$1
IMAGE=$2
CLOUDIMAGE=$3
PAYLOAD=$4

export PATH=/usr/local/bin:$PATH

cd /targets/$ARCH

# start emu
case "$ARCH" in
	arm)
		qemu-system-arm -smp 4 -m 2048 -M virt -nographic \
		-kernel vmlinuz \
 		-initrd initrd.img \
 		-append "root=/dev/vda1 rootfstype=ext4" \
 		-device virtio-blk-device,drive=image \
 		-drive if=none,id=image,file=$IMAGE,cache=writeback \
 		-netdev user,id=user0,hostfwd=tcp::2222-:22 -device virtio-net-device,netdev=user0 \
 		-no-reboot \
 		-cdrom $CLOUDIMAGE \
 		-monitor telnet:127.0.0.1:12222,server,nowait \
 		-serial telnet:127.0.0.1:22222,server,nowait &
		;;
	aarch64)
		qemu-system-aarch64 -smp 4 -m 2048 -M virt -nographic \
		-kernel vmlinuz \
		-initrd initrd.img \
		-append "root=/dev/vda1 rootfstype=ext4" \
		-device virtio-blk-device,drive=image \
		-drive if=none,id=image,file=$IMAGE,cache=writeback \
		-netdev user,id=user0,hostfwd=tcp::2222-:22 -device virtio-net-device,netdev=user0 \
		-cpu cortex-a57 \
		-no-reboot \
		-monitor telnet:127.0.0.1:12222,server,nowait \
		-serial telnet:127.0.0.1:22222,server,nowait \
		-cdrom $CLOUDIMAGE &
		;;
	ppc64le)
		qemu-system-ppc64 -smp 4 -m 2048 \
		-M usb=off -M type=pseries \
		-cpu POWER8E \
		-display none \
		-no-reboot \
		-nographic \
		-vga none \
		-device spapr-vscsi -device scsi-hd,drive=drive0 \
		-drive id=drive0,if=none,file=$IMAGE,cache=writeback \
		-netdev user,id=net0,hostfwd=tcp::2222-:22 -device spapr-vlan,netdev=net0 \
		-no-reboot \
		-cdrom $CLOUDIMAGE \
		-monitor telnet:127.0.0.1:12222,server,nowait \
		-serial telnet:127.0.0.1:22222,server,nowait &
		;;
	x86_64|x86)
		KVM=$(lscpu | grep VT-x >/dev/null && echo "-enable-kvm" || echo)
		qemu-system-x86_64 $KVM -smp 4 -m 2048 -nographic \
		-device e1000,netdev=user0 \
		-netdev user,id=user0,hostfwd=tcp::2222-:22 \
		-drive file=$IMAGE,if=virtio,cache=writeback,index=0 \
		-no-reboot \
		-monitor telnet:127.0.0.1:12222,server,nowait \
		-serial telnet:127.0.0.1:22222,server,nowait \
		-cdrom $CLOUDIMAGE &
		;;
esac

# wait for emu to start can dump out console
while ! nc -z localhost 22222; do sleep 0.1; done

# dump out console
nc localhost 22222 &

# wait until I can ssh in
ssh-keygen -f "/root/.ssh/known_hosts" -R "[localhost]:2222"
while ! ssh -o StrictHostKeyChecking=no -p 2222 localhost 'egrep "Cloud-init v. .* finished" /var/log/cloud-init-output.log'; do sleep 10; done

# run payload, payload needs to end with reboot
bash -x $PAYLOAD

# just in case you nonjob'd it
# ssh -o StrictHostKeyChecking=no -p 2222 localhost reboot

# for all process to exit
wait

