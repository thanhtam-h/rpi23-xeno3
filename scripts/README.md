# rpi01-4.9.80-xeno3-scripts
Set of scripts and guide to build realtime kernel 4.9.80 with xenomai 3 for raspberry pi 2, 3 (include 3b+). 

References
------------
Xenomai 3: https://xenomai.org/installing-xenomai-3-x/
Raspberry pi linux: https://github.com/raspberrypi/linux

Here what I did:
- Modify ipipe patch (4.9.51) to adapt rpi kernel version of 4.9.80

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
    
* Download patches set from:

	  mkdir xeno3-patches
Download all files in this directory and save them to *xeno3-patches* directory

	  https://github.com/thanhtam-h/rpi23-4.9.80-xeno3/tree/master/scripts

	
Patching
------------
	 cd linux
    
1. Ipipe patch and kernel prepraration:

	  	../xenomai/scripts/prepare-kernel.sh --linux=./  --arch=arm  --ipipe=../xeno3-patches/ipipe-core-4.9.51-arm-4-for-4.9.80.patch
      
2. Replace *pinctrl-bcm2835.c* by the one from ipipe git:

	  	cp ../xeno3-patches/pinctrl-bcm2835.c 	drivers/pinctrl/bcm/
           
Building kernel
------------
	  
    make -j4 O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
    make O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 menuconfig

Select options as following:
	
  General setup  --->
	│ │                            (-v7-xeno3) Local version - append to kernel release
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
      tar -cjvf linux-dts-4.9.y-xeno3+.tar.bz2 dts
      cd ..
      cd ..
      cd ..
      cd ..
      cp build/arch/arm/boot/linux-dts-4.9.y-xeno3+.tar.bz2 ./ 


* COPY linux-headers, linux-image and linux-dts to rpi

* In rpi, deploy and ignore any error:

      sudo dpkg -i linux-image*
      sudo dpkg -i linux-headers*
      sudo tar -xjvf 4.9.y-dts.tar.bz2
      cd dts
      sudo cp -rf * /boot/
      sudo mv /boot/vmlinuz-4.9.80-xeno3+ /boot/kernel.img
      sudo reboot

* Fix linux headers:
 Linux header install in previous step is needed to fixed before you can use to build module natively on rpi in future:
    
      cd /usr/src/linux-headers-4.9.80-v7-xeno3+/
      sudo make -i modules_prepare
      
This may take some times and just ignore errors if happened 

Build xenomai user-space libraries and tools (Host PC):
------------
Go to xenomai source directory:

      cd xenomai
      ./scripts/bootstrap
      ./configure --host=arm-linux-gnueabihf --enable-smp --with-core=cobalt
      make
      sudo make install
After installation, the built xenomai for raspberry will be located at */usr/xenomai* directory on host PC, compress it and transfer to rpi:

      tar -cjvf rpi23-xeno3-deploy.tar.bz2 /usr/xenomai
Transfer this file (rpi23-xeno3-deploy.tar.bz2) to rpi and extract it:

      sudo tar -xjvf rpi23-xeno3-deploy.tar.bz2 -C /
Make a configuration file and link to xenomai directory
    
      sudo nano /etc/ld.so.conf.d/xenomai.conf
Add to this file:
  
      #xenomai lib path
      /usr/local/lib
      /usr/xenomai/lib
Save it and run ldconfig command:

      sudo ldconfig
      
CPU affinity
------------  
At least, there are 2 reasons that we should do CPU affinity for rpi23:

- First, since rpi2,3 machines has 4 CPU cores, it can be better if we separate 2 CPU cores for normal Xenomai and 2 for normal Linux. This works may reduce realtime task latency. 
- Second, it is found that current 4.9.80 xenomai kernel will be stopped after few hours running latency test (or any realtime task) on raspberri pi 3b+. Curerent work-around solution is CPU affinity.

In order to do that CPU affinity for rpi23, edit */boot/cmdline.txt* file:

	sudo nano /boot/cmdline.txt
Add below texts to the end of single-line in */boot/cmdline.txt* file

	 isolcpus=0,1 xenomai.supported_cpus=0x3
Here we isolate 2 first COU cores from Linux (**isolcpus=0,1**) and use them for xenomai realtime tasks (**xenomai.supported_cpus=0x3**)

Test xenomai on rpi
------------      
In order to test whether your kernel is really patched with xenomai, run the latency test from xenomai tool:

      sudo /usr/xenomai/bin/latency
If latency tool get start and show some result, you are now have realtime kernel for your rpi

      

