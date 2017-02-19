Packer BlackArch
===========
[Packer](https://www.packer.io) templates for building [BlackArch](https://blackarch.org/) vagrant images.
[BlackArch](https://blackarch.org/) Linux is an [Arch Linux](https://www.archlinux.org/)-based penetration testing distribution for penetration testers and security researchers.

Building result on Atlas https://atlas.hashicorp.com/ph20/boxes/blackarch-core-x86_64

Usage
-----
```
packer-io build -var='headless=true' -only=virtualbox-iso blackarch-template.json
packer-io build -var='headless=true' -only=qemu blackarch-template.json
```

Resources used to create this
-----------------------------
- https://github.com/elasticdog/packer-arch
- https://github.com/BlackArch/blackarch-installer