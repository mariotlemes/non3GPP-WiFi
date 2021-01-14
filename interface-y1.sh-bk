#!/bin/bash

#This script creates two virtual interfaces, instantiates the first with hostpad to become an access point and makes the wpa_supplicant call to connect the 2nd network interface to the access point. WiFi credential: default is ssid:my5gcore and pass:my5gcore

SSID=my5gcore
WPA_PASSPHRASE=my5gcore


function trap_ctrlc () {
echo -e "\n-------------------------------------------------------------"
  echo -e "\033[01;32mRemoving process and modules...\033[01;37m"
  echo -e "-------------------------------------------------------------\n"  
  sudo killall dnsmasq hostapd wpa_supplicant
  sudo rm -rf $HOME/hostapd.conf $HOME/wpa_supplicant.conf
  sudo rmmod mac80211_hwsim
  exit 2
}
 
trap "trap_ctrlc" 2

if [[ $# -ne 1 ]] || ([[ $1 != "up" ]] && [[ $1 != "down" ]]); then
  echo "Usage: $0 [up|down]"
  exit 1
fi

if [[ $1 == "up" ]]; then
  echo -e "\n-------------------------------------------------------------"
  echo -e "\033[01;32mInstall necessary packages... \033[01;37m" 
  echo -e "-------------------------------------------------------------\n"
  sudo apt-get update && sudo apt-get install hostapd dnsmasq -y
  #sudo killall dnsmasq hostapd wpa_supplicant
  
  echo -e "\n-------------------------------------------------------------"
  echo -e "\033[01;32mCreating wlan0 and wlan1 wireless cards...\033[01;37m"
  echo -e "-------------------------------------------------------------\n"
  sudo modprobe mac80211_hwsim radios=2 && sleep 2
  sudo ifconfig wlan0 up
  sudo ip addr add 192.168.1.10/24 dev wlan0
  echo -e "Complete!"
  #sudo dnsmasq -i wlan0 -p 5353 --dhcp-range=192.168.1.1,192.168.1.253 &
  sudo touch $HOME/hostapd.conf && sudo chmod 666 $HOME/hostapd.conf
  echo -e "interface=wlan0\ndriver=nl80211\nssid=my5gcore\nchannel=0\nhw_mode=b\nwpa=3\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nwpa_passphrase=my5gcore\nauth_algs=3\nbeacon_int=100" > $HOME/hostapd.conf
  sleep 5
  
  echo -e "\n-------------------------------------------------------------"
  echo -e "\033[01;32mInitializing hostapd.conf...\033[01;37m" 
  echo -e "-------------------------------------------------------------\n"
  cd ~
  sudo hostapd hostapd.conf & sleep 10
  
  echo -e "\n-------------------------------------------------------------"
  echo -e "\033[01;32mInitializing wpa_supplicant for wlan1...\033[01;37m"
  echo -e "-------------------------------------------------------------\n"  
  sudo touch $HOME/wpa_supplicant.conf && sudo chmod 666 $HOME/wpa_supplicant.conf
  echo -e 'network={\nssid="'$SSID'"\nkey_mgmt=WPA-PSK\npsk="'$WPA_PASSPHRASE'"\n}' > $HOME/wpa_supplicant.conf
  sudo ip addr add 192.168.1.1/24 dev wlan1
  sudo wpa_supplicant -i wlan1 -c $HOME/wpa_supplicant.conf -B

 
elif [[ $1 == "down" ]]; then
  echo -e "\n-------------------------------------------------------------"
  echo -e "\033[01;32mRemoving process and modules...\033[01;37m"
  echo -e "-------------------------------------------------------------\n"  
  sudo killall dnsmasq hostapd wpa_supplicant
  sudo rm -rf $HOME/hostapd.conf $HOME/wpa_supplicant.conf
  sudo rmmod mac80211_hwsim
fi
