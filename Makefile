JOBS=$(shell grep -c '^processor' /proc/cpuinfo)

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-

.PHONY:
setup:
	@echo "Updating submodules"
	@git submodule update --init --recursive

.PHONY:
setup-dev:
	@echo "Creating venv"
	@python3 -m venv env
	@echo "Installing r3build"
	@. ./env/bin/activate; \
	pip install wheel; \
	pip install r3build

.PHONY:
watch:
	@echo "Watching changes in linux-brain and u-boot-brain"
	@. ./env/bin/activate; \
	@python3 -m r3build

.PHONY:
udefconfig:
	make -C ./u-boot-brain pwsh1_defconfig

.PHONY:
udefconfig-%:
	make -C ./u-boot-brain pw$*_defconfig

.PHONY:
usavedefconfig:
	make -C ./u-boot-brain savedefconfig

.PHONY:
umenuconfig:
	make -C ./u-boot-brain menuconfig

.PHONY:
uclean:
	make -C ./u-boot-brain distclean

.PHONY:
ubuild:
	make -j$(JOBS) -C ./u-boot-brain u-boot.sb

.PHONY:
ldefconfig:
	make -C ./linux-brain brain_defconfig

.PHONY:
lmenuconfig:
	make -C ./linux-brain menuconfig

.PHONY:
lsavedefconfig:
	make -C ./linux-brain savedefconfig
	mv ./linux-brain/defconfig ./linux-brain/arch/arm/configs/brain_defconfig

.PHONY:
lclean:
	make -C ./linux-brain distclean

.PHONY:
lbuild:
	make -j$(JOBS) -C ./linux-brain

.PHONY:
uuu:
	sudo uuu ./u-boot-brain/u-boot.sb

.PHONY:
nkbin-maker:
	make -C ./nkbin_maker

.PHONY:
nk.bin:
	./nkbin_maker/bsd-ce ./u-boot-brain/u-boot.bin

debian:
	@if [ "$(shell uname)" != "Linux" ]; then \
		echo "Debootstrap is only available in Linux!"; \
		exit 1; \
	fi
	mkdir -p debian
	@if [ "$(CI)" == "true" ]; then \
		echo "I'm in CI and debootstrap without cache."
		sudo debootstrap --arch=armel --foreign buster debian/; \
	else; \
		sudo debootstrap --arch=armel --foreign buster debian/ http://localhost:65432/debian/; \
	fi
	sudo cp /usr/bin/qemu-arm-static debian/usr/bin/
	sudo cp ./tools/setup_debian.sh debian/
	sudo -E chroot debian /setup_debian.sh

image/sd.img: clean_work
	./image/build_image.sh

.PHONY:
clean_work:
	sudo rm -rf image/work

.PHONY:
aptcache:
	./tools/aptcache_linux_amd64 \
		-rule 'local=localhost:65432, remote=ftp.jaist.ac.jp' \
		-rule 'local=localhost:65433, remote=security.debian.org'
