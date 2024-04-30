# No root hypervisor initrd+rootfs+kernel builder

## project description

The goal is to automate the creation of hypervisor images for my own needs without using root, currently supporting only Debian 12 & Cloud-hypervisor project (Can be easily extended in the future).

The current Proof of Concept (PoC) produces a custom initrd. Initrd has badly:-) scripted overlayfs.
That overlay combinintg tmpfs + rootfs, so you get temporary VM with initial state each time you reboot it.
Instead of using tmpfs it can be adjusted to store persitent userdata. (that not implemented currently) 

Next, it produces, along with initrd, the Debian rootfs which is packed into erofs. 
Currently utilizing LXC project rootfs Debian 12 bookworm.
And for rootfs customization its utilising `virt-customize` utility.

====
*Project status: working PoC*



## Below are some usage instructions:

### Requirements
Ensure the following dependencies are installed:
- `virt-make-fs`
- `virt-customize`
- `guestfish`
- `mkfs.erofs`
- `curl`
- `xz`

### Usage
- Run `make` or `make all` to clean, initialize the image, build, and test.
- After building, run `make runhv` to run the image ( require `cloud-hypervisor` ).
- Customize everything by editing the appropriate sections in the Makefile.
- Use `make clean` to remove generated files.
- Use `make ultraclean` to reset project to initial state

## Network Configuration

Configure network settings:
```bash
ip a add 192.168.249.2/24 dev ens3
echo "nameserver 1.1.1.1" > /etc/resolv.conf
ip link set dev ens3 up
ip route add default via 192.168.249.1
apt install -y iperf3
```

### Note
- Here notes that I fogot.

### TODO

- automate kernel build process, similar to initrd build
