# Makefile for building cloud-hypervisor images (currently only debian12)
# possible requirements (not all included check makefile by urslef):
#       virt-make-fs
#       virt-customize
#       guestfish
#       mkfs.erofs
#       curl
#       xz

# Variables

# TODO: figureout linuxcontainers project pipeline
#       write scraper
#        and get official builds from official mirrors (not directly jenkins)
#         (maybe there util already exist)

ROOTFS_URL := https://jenkins.linuxcontainers.org/job/image-debian/lastStableBuild/architecture=amd64,release=bookworm,variant=cloud/artifact/rootfs.tar.xz
# debug url, run pythom -m http.server with rootfs.tar.xz in same dir
#ROOTFS_URL := http://127.0.0.1:8000/rootfs.tar.xz
#ROOTFS_URL ?=
ROOTFS_TAR := rootfs.tar.xz
RAW_TAR := 1.tar
OUTPUT_QCOW2 := output.qcow2
IMAGEEROFS := debian2.erofs
HYPERVISOR := cloud-hypervisor

# HARDCODED vmlinux 6.2 ( TODO: write build script)
KERNEL_IMAGE := ./linux-cloud-hypervisor/arch/x86/boot/compressed/vmlinux.bin
INITRD_IMAGE := ./customInitrd/initrd.cpio.gz


# Enable debug mode by setting this variable to 1
DEBUG_MODE := 0

# Conditionally include debug options
ifeq ($(DEBUG_MODE),1)
CUSTOMIZATION_ARGS := -v -x
HYPERVISOR_ARGS := "console=hvc0"
endif


# ifeq ($(ROOTFS_URL),)
# $(ROOTFS_TAR):
# 	@echo "ROOTFS_URL is not provided. Assuming $(ROOTFS_TAR) already exists locally."
# else
# $(ROOTFS_TAR):
# 	curl -L -C - -f -o $(ROOTFS_TAR) $(ROOTFS_URL)
# endif


.PHONY: all clean build test initrd ultraclean runhv stophv

all: clean initrd build test

build: $(OUTPUT_QCOW2) $(IMAGEEROFS)
	@echo -e "\033[32m cloud-hypervisor image built \033[0m\033[33m successfull. \033[0m\033[32m \033[0m"
	@echo -e "\033[32m run \033[0m\033[33m make runhv \033[0m\033[32m to test. \033[0m"


$(ROOTFS_TAR):
	curl -L -C - -f -o $(ROOTFS_TAR) $(ROOTFS_URL)

$(RAW_TAR): $(ROOTFS_TAR)
	xz -dv $(ROOTFS_TAR) && mv $(basename $(ROOTFS_TAR)) $(RAW_TAR)



################### WARNING ADDING SIZE IS IMPORTANT
################### IF THERE NO ENOUGH FREE SPACE IN output.qcow2 BUILD WILL CRASH
#### TODO: MAKE size PREDICTION BY SIMPLE FORMULA = sizeof incl. files + PADDING(~10M)
#   | OR SWITCH TO OTHER UTILS


$(OUTPUT_QCOW2): $(RAW_TAR)
	virt-make-fs --format=qcow2 --size=+100M $(RAW_TAR) $(OUTPUT_QCOW2)

	@echo "HERE CUSTOMIZE PART FEEL FREE TO CHANGE"
	virt-customize $(CUSTOMIZATION_ARGS) -a $(OUTPUT_QCOW2) \
		--root-password password:123 \
		--hostname "hostname" \
		--firstboot "deploy_sources/scripts/ntwrk.sh" \
		--firstboot-command "ssh-keygen -A && systemctl enable sshd" \
		--copy-in "deploy_sources/debs/busybox-static_1.35.0-4+b3_amd64.deb:/var/cache/apt/" \
		--install "/var/cache/apt/busybox-static_1.35.0-4+b3_amd64.deb" \
		--firstboot-command "apt-get -y clean"

$(IMAGEEROFS): $(OUTPUT_QCOW2)
	rm -rf rootfs_building
	mkdir -p rootfs_building
	guestfish --ro --format=qcow2 -m /dev/sda -a $(OUTPUT_QCOW2) -i copy-out / rootfs_building
	mkfs.erofs --all-root -T31536000 $(IMAGEEROFS) rootfs_building

clean:
	rm -f $(ROOTFS_TAR) $(RAW_TAR) $(OUTPUT_QCOW2) $(IMAGEEROFS)
	rm -rf rootfs_building
	rm -f ./cloud-hypervisor-test.sock
	rm -f ./ch.vsock

test:
	@if [ ! -f $(KERNEL_IMAGE) ]; then \
		echo "Error: vmlinux.bin does not exist. Build it first or place it in ./linux-cloud-hypervisor/arch/x86/boot/compressed/"; \
		exit 1; \
	fi
	@if [ ! -f "./customInitrd/initrd.cpio.gz" ]; then \
		echo "Error: initrd.cpio.gz does not exist."; \
		echo "Run make initrd to build"; \
		exit 1; \
	fi

initrd:
	@if [ ! -f "./customInitrd/initrd.cpio.gz" ]; then \
		echo "Building initrd based on busybox..."; \
		cd ./customInitrd && make all && cd -; \
	else \
		echo "initrd already exists."; \
	fi

#
# using bogon TEST-NET2 ( check: deploy_sources/scripts/ntwrk.sh )
#
runhv:
	@rm -f ./cloud-hypervisor-test.sock
	@rm -f ./ch.vsock
	@#(sleep 70s && killall -9 cloud-hypervisor && tset) &
	@echo " "
	@echo -e "[ ] \033[32mHello. The hypervisor will commence autostart shortly.\033[0m"
	@echo " "
	@echo -e "[ ] \033[32mTo access  API  socket ( examples ):\033[0m"
	@echo -e "[ ] \033[33mch-remote --api-socket ./cloud-hypervisor-test.sock ping\033[0m"
	@echo -e "[ ] \033[33mch-remote --api-socket ./cloud-hypervisor-test.sock info\033[0m"
	@echo " "
	@echo -e "[ ] \033[32mATTENTION: Prepare for terminal entry...\033[0m"
	@echo " "
	@echo -e "[ ] default \033[33mUSER:\033[0m\033[31m root\033[0m with\033[33m PASSWORD:\033[0m\033[31m 123\033[0m"
	@echo -en "[ ] " && ./deploy_sources/loading_screen.sh &
	@sleep 10s && $(HYPERVISOR) \
		--kernel $(KERNEL_IMAGE) \
		--disk path=$(IMAGEEROFS) \
		--cmdline " $(HYPERVISOR_ARGS) root=/dev/vda1 rw " \
		--cpus boot=2 \
		--memory size=1024M \
		--net "tap=,mac=,ip=198.51.100.1,mask=255.255.255.0" \
		--vsock cid=3,socket=./ch.vsock \
		--api-socket ./cloud-hypervisor-test.sock \
		--initramfs=$(INITRD_IMAGE) && reset

#	timeout --foreground --kill-after=60 --signal=15 50s
stophv:
	-@pgrep -f "cloud-hypervisor" > /dev/null && killall -15 cloud-hypervisor > /dev/null 2>&1 || echo "cloud-hypervisor is not running"


ultraclean:
	@echo "Resetting project state"
	make clean && cd ./customInitrd && make clean && cd -

