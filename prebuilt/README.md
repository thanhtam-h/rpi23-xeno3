# prebuilt kernel and xenomai for rpi23 include 3b+
built 4.9.80 ipipe patched kernel + prebuilt xenomai user-space libraries and tool. Pull down and deploy

Download prebuilt kernel
------------
Download and transfer all files in this directory to rpi23:

     sudo apt-get install subversion
     svn checkout https://github.com/thanhtam-h/rpi23-4.9.80-xeno3/trunk/prebuilt
     cd prebuilt
     
Automatically deploy
------------
Run these commands and deploy automatically, your rasperry pi will be updated and rebooted 
	
	 chmod +x deploy.sh
	 ./deploy.sh
	 
Manually deploy (optional)
------------
From prebuilt directory:

	sudo rm /boot/*4.9.80-v7-xeno3+
	sudo dpkg -i linux-image*
	sudo dpkg -i linux-headers*
	tar -xjvf linux-dts-4.9.*.tar.bz2
	cd dts
	sudo cp -rf * /boot/
	sudo mv /boot/vmlinuz-4.9.80-v7-xeno3+ /boot/kernel7.img
	cd ..
	sudo tar -xjvf rpi23-xeno3-deploy.tar.bz2 -C /
	sudo cp xenomai.conf /etc/ld.so.conf.d/
	sudo ldconfig
	sudo reboot
	 
Post processing
------------ 
We need to fix Linux header before we can use it to build module native on rpi in future:

	 cd /usr/src/linux-headers-4.9.80-v7-xeno3+/
	 sudo make -i modules_prepare

CPU affinity
------------ 
Update: If we isolate all 4 cores of rpi23 for xenomai use, the EtherCAT sending/receiving worst time will be significantly reduced
In order to do that CPU affinity for rpi23, edit */boot/cmdline.txt* file:

	sudo nano /boot/cmdline.txt
Add below texts to the end of single-line in */boot/cmdline.txt* file

	 isolcpus=0,1,2,3 xenomai.supported_cpus=0xF
Here we isolate all 4 CPU cores from Linux (**isolcpus=0,1,2,3**) and use them for Xenomai realtime tasks (**xenomai.supported_cpus=0xF**). CPU affinity will be affected after you reboot rpi machine


Test xenomai on rpi
------------   
In order to test whether your kernel is really patched with xenomai, run the latency test from xenomai tool:

      sudo /usr/xenomai/bin/latency
If latency tool get start and show some result, your rpi is now having realtime kernel
