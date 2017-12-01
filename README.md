## Horizon cross testdev

### Prereq

Ubuntu 16.04 x86_64 with 8 virtual (4 physical) cores and 4 GB RAM.

```
echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu xenial edge" >/etc/apt/sources.list.d/docker.list
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -qq - >/dev/null
apt-get update
apt-get install -y qemu-kvm docker-ce make git
```

### Run

As `root`:

```
git clone https://github.com/open-horizon/qemu-cross-testdev
cd qemu-cross-testdev
```

32-bit ARM:
```
time make testdev ARCH=arm
```

64-bit ARM:
```
time make testdev ARCH=aarch64
```

PPC64:
```
time make testdev ARCH=ppc64le
```

x86_64:
```
time make testdev ARCH=x86_64
```

The first run will take sometime to download and build the QEMU images.  Any time after that it should be pretty quick.


### Check if ready

`docker logs testdev`, look for `testdev ready to go!!!` message.


### Get a shell (after ready)

> NOTE: if you copy `id_rsa` to your local workstation, this command will work from your local workstation, or CI system, etc...

```
docker cp testdev:/root/.ssh/id_rsa id_rsa
ssh -i id_rsa -o StrictHostKeyChecking=no -p 2222 root@your_local_machine_ip_address
```

### [Clean] shutdown

```
docker cp testdev:/root/.ssh/id_rsa id_rsa
ssh -i id_rsa -o StrictHostKeyChecking=no -p 2222 your_local_machine_ip_address reboot
```

### [Hard] shutdown

```
make stopdev
```
