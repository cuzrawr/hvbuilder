	wget -c "https://www.busybox.net/downloads/busybox-snapshot.tar.bz2" -O busybox-snapshot.tar.bz2
	mkdir -p busybox_build
	tar xjf busybox-snapshot.tar.bz2 --strip-components=1 -C busybox_build
	cd busybox_build && cp busybox_working.config .config
	make -j$(nproc)
	cd -
