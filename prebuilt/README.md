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
Linux header install in previous step is needed to fixed before you can use to build module natively on rpi in future:

	 cd /usr/src/linux-headers-4.9.80-v7-xeno3+/
	 sudo make -i modules_prepare

CPU affinity
------------  
At least, there are 2 reasons that we should do CPU affinity for rpi23:

- First, since rpi2,3 machines has 4 CPU cores, it can be better if we separate 2 CPU cores for normal Xenomai and 2 for normal Linux. This works may reduce realtime task latency. 
- Second, it is found that current 4.9.80 xenomai kernel will be stopped after few hours running latency test (or any realtime task) on raspberri pi 3b+. Curerent work-around solution is CPU affinity.

In order to do that CPU affinity for rpi23, edit */boot/cmdline.txt* file:

	sudo nano /boot/cmdline.txt
Add below texts to the end of single-line in */boot/cmdline.txt* file

	 isolcpus=0,1 xenomai.supported_cpus=0x3
Here we isolate 2 first COU cores from Linux (**isolcpus=0,1**) and use them for xenomai realtime tasks (**xenomai.supported_cpus=0x3**). CPU affinity will be affected after you reboot rpi machines


Test xenomai on rpi
------------   
In order to test whether your kernel is really patched with xenomai, run the latency test from xenomai tool:

      sudo /usr/xenomai/bin/latency
If latency tool get start and show some result, you are now have realtime kernel for your rpi
