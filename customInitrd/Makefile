.PHONY: all clean initrd test fetchbuild info

all: clean initrd test

initrd: initrd_dirs initrd_populate initrd_cpio

initrd_dirs:
	mkdir -p TMP_BUILD
	mkdir -p TMP_BUILD/bin
	mkdir -p TMP_BUILD/dev
	mkdir -p TMP_BUILD/etc
	mkdir -p TMP_BUILD/proc

initrd_populate:
	cp initrd_sources/busybox TMP_BUILD/bin/busybox
	for t in $$(TMP_BUILD/bin/busybox --list); do ln -s busybox TMP_BUILD/bin/$$t; done
	cp initrd_sources/init.new.sh TMP_BUILD/init

initrd_cpio:
	cd TMP_BUILD/ && find . | cpio -o -H newc | gzip > ../initrd.cpio.gz && cd -
	@echo "COMPLETE your file is..."
	ls -l initrd.cpio.gz

test:
	@echo "Running tests..."
	@if [ -d initrd_sources ]; then \
		echo -e "\033[32mTest 1 passed: initrd_sources directory exists."; \
		else \
		echo -e "\033[31minitrd_sources directory does not exist. YOU MISSING SOURCES DIR. redownload full project again!"; \
		exit 1; \
	fi
	@if [ -f initrd.cpio.gz ]; then \
		if gunzip -c initrd.cpio.gz | cpio -t --quiet | grep -qo '^bin/busybox$$' && gunzip -c initrd.cpio.gz | cpio -t --quiet | grep -qo '^init$$'; then \
			echo -e "\033[32mTest 2 passed: bin/busybox and init are present in build directory\033[0m"; \
		else \
			echo -e "\033[31mW A R N I N G !!! Test failed: bin/busybox or init or both is missing in build directory\033[0m"; \
			exit 1; \
		fi; \
	else \
		echo -e "\033[31mW A R N I N G !!! Test failed: initrd.cpio.gz does not exist! run make in this directory to create it.\033[0m"; \
		exit 1; \
	fi

clean:
	rm -f initrd.cpio.gz
	rm -f busybox-snapshot.tar.bz2
	rm -rf TMP_BUILD
	rm -rf TMP_BUSYBOX_BUILD

# download:
# 	wget -c "https://www.busybox.net/downloads/busybox-snapshot.tar.bz2" -O busybox-snapshot.tar.bz2
# 	mkdir -p TMP_BUSYBOX_BUILD
# 	tar xjf busybox-snapshot.tar.bz2 --strip-components=1 -C TMP_BUSYBOX_BUILD
# 	cd TMP_BUSYBOX_BUILD && cp busybox_working.config .config
# 	make -j$(nproc)
# 	cd -

fetchbuild:
	@echo "Downloading busybox..."
	wget -c "https://www.busybox.net/downloads/busybox-snapshot.tar.bz2" -O busybox-snapshot.tar.bz2 \
	&& echo "Building busybox..." \
	&& mkdir -p TMP_BUSYBOX_BUILD \
	&& tar xjf busybox-snapshot.tar.bz2 --strip-components=1 -C TMP_BUSYBOX_BUILD \
	&& rm -f busybox-snapshot.tar.bz2 \
	&& cp initrd_sources/busybox_working.config TMP_BUSYBOX_BUILD/.config && cd TMP_BUSYBOX_BUILD && make -j$(nproc) && cd -
	@echo "Build complete"
	file TMP_BUSYBOX_BUILD/busybox
	@echo "Moving busybox binary to initrd_sources/busybox..."
	cp TMP_BUSYBOX_BUILD/busybox initrd_sources/busybox
	@echo "DONE: ready to make initrd..."

info:
	@echo "info about all files inside produces initrd:"
	@echo " "
	file initrd.cpio.gz
	@echo " "
	gunzip -c initrd.cpio.gz | cpio -t --quiet | column
	@echo " "
	@echo "end of list."
	@echo " "
