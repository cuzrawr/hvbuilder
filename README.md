
----

### no root initrd+rootfs+kernel builder scripts
Created for own needs. 
Project status: working PoC

### Project description:
The aim of this project is to automate the process of creating & customizing VM images **without root perms** for my personal needs. 

### Details:

Makefile produce `*.erofs` image at the end, ensuring they are deletion-proofed. 
This means that even if a user accidentally runs `rm -rf` inside VM, everything will still be in read-only mode thanks to overlayfs. 
In the worst-case scenario, the user may lose only the overlay files, but not the operating system.

Currently, project supports only `debian 12 bookworm` and `cloud-hypervisor`, but easily extend this support in the future. 

The rootfs packed into *,erofs along with the initrd. 
Customizing of the rootfs done by `virt-customize` tool.

Current Proof of Concept (PoC) creates a custom initrd with badly scripted overlayfs (*rewritethis :-) ).
The `overlayfs` is mounted within the generated rootfs (**.erofs*) filesystem which is read-only by design and `tmpfs` ontop.
While the PoC doesn't currently implement storing persistent user data, this feature can be added in the future.


----
### Below are some usage instructions
Ensure the following dependencies are installed:
- `virt-make-fs`
- `virt-customize`
- `guestfish`
- `mkfs.erofs`
- `curl`
- `xz`

### Usage
- Run `make` or `make all` to clean, download the clean rootfs, build, and test.
- After building, run `make runhv` to run the image ( require `cloud-hypervisor` ).
- Use `make clean` to remove generated files.
- Use `make ultraclean` to reset project to initial state
- 
- Customize everything by editing the appropriate sections in the Makefile.

----

### Note
- Here notes that I fogot.

----

### TODO

- automate kernel build process, similar to initrd build
