#!/bin/bash

cd /targets

cat >cloud.cfg <<EOF
#cloud-config

# allow root login
disable_root: False

# setup root ssh
runcmd:
  - mkdir -m0700 /root/.ssh
write_files:
  - path: /root/.ssh/authorized_keys
    content: |
      $(cat /root/.ssh/id_rsa.pub)

# install stuff
packages:
  - ca-certificates
  - openssl
  - wget
  - curl
  - screen
  - apt-transport-https
  - make
  - git

# install docker-ce
runcmd:
  - echo "deb [arch=\$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu xenial edge" >/etc/apt/sources.list.d/docker.list
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -qq - >/dev/null
  - apt-get update
  - apt-get -y install docker-ce
EOF

echo "#cloud-config" >nonjob.cfg

cloud-localds cloud.img cloud.cfg
cloud-localds nonjob.img nonjob.cfg

