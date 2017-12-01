
ARCH=$(shell uname -m)
HOST_ARCH=$(shell uname -m)
TAG=1.0.0
QEMUV=v2.10.1
PACKAGE=qemu
IMAGE=$(PACKAGE)
#CACHE_FLAG=--no-cache
CACHE_FLAG=

# restore flag if flag missing, but image in docker
$(shell tools/flag.sh $(IMAGE) $(TAG))

# define package arch
ifeq ($(ARCH),arm)
	PACKAGE_ARCH=armhf
endif
ifeq ($(ARCH),aarch64)
	PACKAGE_ARCH=arm64
endif
ifeq ($(ARCH),ppc64le)
	PACKAGE_ARCH=ppc64el
endif
ifeq ($(ARCH),x86_64)
	PACKAGE_ARCH=amd64
endif
ifeq ($(ARCH),x86)
	PACKAGE_ARCH=i386
endif

default: targets/$(ARCH)/osimage.img

qemu: $(IMAGE)-$(TAG).flag

pullqemu:
	docker pull datajerk/qemu:$(TAG)
	# tag it

$(IMAGE)-$(TAG).flag: Dockerfile
	docker build --build-arg QEMUV=$(QEMUV) $(CACHE_FLAG) -t $(IMAGE):$(TAG) -f $< .
	docker tag $(IMAGE):$(TAG) $(IMAGE):latest
	touch $@

targets/$(ARCH)/xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img: $(IMAGE)-$(TAG).flag
	mkdir -p targets/$(ARCH)
	test -s $@ && touch $@ || \
	docker run --rm -it -v $$PWD/targets:/targets qemu:$(TAG) /bin/bash -c '\
		cd /targets/$(ARCH); \
		curl -sLO https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img \
		'
	touch $@

baseimage: targets/$(ARCH)/xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img

targets/$(ARCH)/vmlinuz: targets/$(ARCH)/xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img
	docker run --rm -it -v $$PWD/targets:/targets \
		--privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules \
		qemu:$(TAG) /bin/bash -c '\
		cd /targets/$(ARCH); \
		modprobe nbd max_part=16; \
		qemu-nbd -c /dev/nbd0 xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img; \
		partprobe /dev/nbd0; \
		mount -r /dev/nbd0p1 /mnt; \
		cp -f /mnt/boot/vmlinuz* vmlinuz; \
		cp -f /mnt/boot/vmlinuz vmlinuz; \
		umount /mnt; \
		qemu-nbd -d /dev/nbd0 \
		'
	touch $@

targets/$(ARCH)/initrd.img: targets/$(ARCH)/xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img
	docker run --rm -it -v $$PWD/targets:/targets \
		--privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules \
		qemu:$(TAG) /bin/bash -c '\
		cd /targets/$(ARCH); \
		modprobe nbd max_part=16; \
		qemu-nbd -c /dev/nbd0 xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img; \
		partprobe /dev/nbd0; \
		mount -r /dev/nbd0p1 /mnt; \
		cp -f /mnt/boot/initrd.img* initrd.img; \
		cp -f /mnt/boot/initrd.img initrd.img; \
		umount /mnt; \
		qemu-nbd -d /dev/nbd0 \
		'
	touch $@

vmlinuz: targets/$(ARCH)/vmlinuz

initrd.img: targets/$(ARCH)/initrd.img

targets/$(ARCH)/osimage.img: targets/$(ARCH)/xenial-server-cloudimg-$(PACKAGE_ARCH)-disk1.img bin/run.sh bin/reboot.sh bin/cloudconfig.sh targets/$(ARCH)/vmlinuz targets/$(ARCH)/initrd.img
	docker run --rm -it -v $$PWD/targets:/targets \
		qemu:$(TAG) /bin/bash -c '\
		rm -f /$@; \
		/usr/local/bin/qemu-img create -f qcow2 -b /$< /$@; \
		/usr/local/bin/qemu-img resize /$@ 8G; \
		'
	docker run --rm -it -v $$PWD/targets:/targets -v $$PWD/bin:/rbin \
		--privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules \
		qemu:$(TAG) /bin/bash -c '\
		/rbin/cloudconfig.sh; \
		/rbin/run.sh $(ARCH) osimage.img ../cloud.img /rbin/reboot.sh \
		'

osimage.img: targets/$(ARCH)/osimage.img

targets/$(ARCH)/testimage.img: targets/$(ARCH)/osimage.img targets/$(ARCH)/vmlinuz targets/$(ARCH)/initrd.img
	docker run --rm -it -v $$PWD/targets:/targets \
		qemu:$(TAG) /bin/bash -c '\
		rm -f /$@; \
		/usr/local/bin/qemu-img create -f qcow2 -b /$< /$@; \
		/usr/local/bin/qemu-img resize /$@ 8G; \
		'

testimage.img: targets/$(ARCH)/testimage.img

testdev: testimage.img bin/prep.sh bin/run.sh
	docker rm -f testdev || true
	docker run -d --name testdev -p 0.0.0.0:2222:2222 -v $$PWD/targets:/targets -v $$PWD/bin:/rbin \
		--privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules \
		qemu:$(TAG) /bin/bash -c '\
		/rbin/cloudconfig.sh; \
		/rbin/run.sh $(ARCH) testimage.img ../nonjob.img /rbin/prep.sh \
		'

stopdev:
	docker rm -f testdev || true

clean:
	rm -rf *.flag

imageclean:
	rm -rf targets

dockerclean:
	docker rmi $(IMAGE):latest $(IMAGE):$(TAG) || true

realclean: dockerclean imageclean clean
	docker images -f dangling=true -q | xargs docker rmi || true

