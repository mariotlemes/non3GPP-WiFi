<div align="center">

<a href="https://github.com/LABORA-INF-UFG/my5Gcore"><img width="20%" src="docs/figs/my5g-logo.png" alt="free5GC"/></a>

</div> 

# Non-3GPP-IoT-WiFi
Non-3GPP-IoT-Wifi aims to demonstrate the untrusted non-3GPP access to the my5Gcore using a IEEE 802.11 wireless network.

<p align="center">
    <img src="docs/figs/proposta.png" height="500"/> 
</p>

## Interface Y1 

On your host, install the necessary packages.

```bash
sudo apt-get update && sudo apt-get install hostapd dnsmasq -y
```

Create wlan0 and wlan1 wireless cards.
```bash
sudo modprobe mac80211_hwsim radios=2
```

Apply the settings for wlan0:
```bash
sudo ifconfig wlan0 up
sudo ip addr add 192.168.1.10/24 dev wlan0
```

Create the hostapd.conf file:
```bash
sudo touch $HOME/hostapd.conf && sudo chmod 666 $HOME/hostapd.conf
echo -e "interface=wlan0\ndriver=nl80211\nssid=my5gcore\nchannel=0\nhw_mode=b\nwpa=3\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nwpa_passphrase=my5gcore\nauth_algs=3\nbeacon_int=100" > ~/Desktop/hostapd.conf
```

Initializing hostapd.conf for wlan0:
```bash
cd ~
sudo hostapd hostapd.conf
```





