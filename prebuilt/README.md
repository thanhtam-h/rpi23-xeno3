# prebuilt kernel and xenomai for rpi23 include 3b+
built 4.9.80 ipipe patched kernel + prebuilt xenomai user-space libraries and tool. Pull down and deploy

Deployment
------------
Download and transfer all files in this directory to rpi23. From rpi:

     sudo dpkg -i linux-image*
     sudo dpkg -i linux-headers*
     sudo tar -xjvf linux-dts-4.9.y-xeno3+.tar.bz2
     cd dts
     sudo cp -rf * /boot/
     sudo mv /boot/vmlinuz-4.9.80-v7-xeno3+ /boot/kernel7.img
     sudo tar -xjvf rpi23-xeno3-deploy.tar.bz2 -C /
     sudo cp xenomai.conf /etc/ld.so.conf.d/
     sudo ldconfig
     sudo reboot
     
Test xenomai on rpi:
------------   
In order to test whether your kernel is really patched with xenomai, run the latency test from xenomai tool:

      sudo /usr/xenomai/bin/latency
If latency tool get start and show some result, you are now have realtime kernel for your rpi
