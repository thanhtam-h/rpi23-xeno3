# rpi01-4.9.80-xeno3-scripts
Set of scripts and guide to build realtime kernel 4.9.80 with xenomai 3 for raspberry pi 0, 0-W, 1. 

References
------------
Xenomai 3: https://xenomai.org/installing-xenomai-3-x/
Raspberry pi linux: https://github.com/raspberrypi/linux

Here I make this guide and scripts for rpi 1, zero and zero-W only:
- Add support rpi zero-W to kernel 4.9.80
- Add post-patch


Preparation on host PC
------------
      sudo apt-get install gcc-arm-linux-gnueabihf
      sudo apt-get install --no-install-recommends ncurses-dev bc

* Download xenomai-3: 

      wget https://git.xenomai.org/xenomai-3.git/snapshot/xenomai-3-3.0.5.tar.bz2
      tar -xjvf xenomai-3-3.0.5.tar.bz2
      ln -s xenomai-3-3.0.5 xenomai
MODIFY 'xenomai/scripts/prepare-kernel.sh' file
Replace 'ln -sf' by 'cp'  so that it will copy all neccessary xenomai files to linux source

* Download rpi-linux-4.9.y:

	  git clone -b rpi-4.9.y --depth 1 git://github.com/raspberrypi/linux.git linux-rpi-4.9.y-xeno3
	  ln -s linux-rpi-4.9.y-xeno3 linux
    
* Download patches set:

	  git clone git://github.com/thanhtam-h/rpi01-4.9.80-xeno3-scripts.git xeno3-patches
            
	
Patching
------------
	 cd linux
    
1. Add support rpi zero-W:

	  	patch -p1 <../xeno3-patches/1-rpi-4.9.y-add-pi0W.patch
       
2. Ipipe patch and kernel prepraration:

	  	../xenomai/scripts/prepare-kernel.sh --linux=./  --arch=arm  --ipipe=../xeno3-patches/2-ipipe-core-4.1.18-arm-10-for-4.9.80.patch
      
3. Apply post patch:

	  	patch -p1 <../xeno3-patches/3-ipipe-core-4.9.80-raspberry-post.patch
      
4. Replace *pinctrl-bcm2835.c* by the one from ipipe git:

	  	cp ../xeno3-patches/pinctrl-bcm2835.c 	drivers/pinctrl/bcm/
           
Building kernel
------------
	  
    make -j4 O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
    make O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 menuconfig

Select options as following:
	
  General setup  --->
	│ │                            (-xeno3) Local version - append to kernel release
	│ │                                Stack Protector buffer overflow detection (None)  --->
	 
	Kernel Features  --->
	│ │                                Preemption Model (Preemptible Kernel (Low-Latency Desktop))  --->                              
	│ │                                Timer frequency (1000 Hz)  --->   
	│ │                            [ ] Allow for memory compaction
	│ │                            [ ] Contiguous Memory Allocator

	CPU Power Management  --->
	│ │                                CPU Frequency scaling  --->
                                        [ ] CPU Frequency scaling
									
	Kernel hacking  --->
	│ │                            [ ] KGDB: kernel debugger  ---							
							
	
Build image, modules and device overlay

    make O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 bzImage modules dtbs
Install module

    make O=build ARCH=arm INSTALL_MOD_PATH=dist -j4 modules_install
  
Build package

    make O=build ARCH=arm KBUILD_DEBARCH=armhf  CROSS_COMPILE=arm-linux-gnueabihf- -j4 deb-pkg   
           
Deployment
------------
After building, we have:
- Kernel modules in 'buid/dist' directory
- Kernel image and device overlay in 'buid/arch/arm/boot' directory
- Kernel image, modules, headers in debian packages in 'linux' directory

For kernel image, modules and headers, we are going to use debian pakage file. For device overlay use output directory 'buid/arch/arm/boot/dts' 

* Compress dts files:

      cd build/arch/arm/boot
      tar -cjvf linux-dts-4.9.80-xeno3+.tar.bz2 dts
      cd ..
      cd ..
      cd ..
      cd ..
      cp build/arch/arm/boot/linux-dts-4.9.80-xeno3+.tar.bz2 ./ 


* COPY linux-headers, linux-image and linux-dts to rpi

* In rpi, deploy and ignore any error:

      sudo dpkg -i linux-image*
      sudo dpkg -i linux-headers*
      sudo tar -xjvf 4.9.80-dts.tar.bz2
      cd dts
      sudo cp -rf * /boot/
      sudo mv /boot/vmlinuz-4.9.80-xeno3+ /boot/kernel.img
      sudo reboot

* Fix linux headers:
 Linux header install in previous step is needed to fixed before you can use to build module natively on rpi in future:
    
      cd /usr/src/linux-headers-4.9.80-xeno3+/
      sudo make -i modules_prepare
      
This may take some times and just ignore errors if happened 

Build xenomai user-space libraries and tools (Host PC):
------------
Go to xenomai source directory:

      cd xenomai
      ./scripts/bootstrap
      ./configure --host=arm-linux-gnueabihf --disable-smp --with-core=cobalt
      make
      sudo make install
After installation, the built xenomai for raspberry will be located at */usr/xenomai* directory on host PC, compress it and transfer to rpi:

      tar -cjvf rpi01-xeno3-deploy.tar.bz2 /usr/xenomai
Transfer this file (xenomai-3.0.5-cobalt-rpi01-deploy.tar.bz2) to rpi and extract it:

      sudo tar -xjvf rpi01-xeno3-deploy.tar.bz2 -C /
Make a configuration file and link to xenomai directory
    
      sudo nano /etc/ld.so.conf.d/xenomai.conf
Add to this file:
  
      #xenomai lib path
      /usr/local/lib
      /usr/xenomai/lib
Save it and run ldconfig command:

      sudo ldconfig
      
      
Test xenomai on rpi:
------------      
In order to test whether your kernel is really patched with xenomai, run the latency test from xenomai tool:

      sudo /usr/xenomai/bin/latency
If latency tool get start and show some result, you are now have realtime kernel for your rpi

      

