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
