<div align="center">
    <a href="https://github.com/LABORA-INF-UFG/my5Gcore"><img width="20%" src="figs/my5g-logo.png" alt="free5GC"/></a>
</div> 

# Non-3GPP-IoT-WiFi
Non-3GPP-IoT-WiFi aims to demonstrate the untrusted non-3GPP access to the my5Gcore using a IEEE 802.11 network as illustrated by the following image.

<p align="center">
    <img src="figs/general-architecture.png" height="300"/> 
</p>


# Expected result
This experiment aims to demonstrate a non-3GPP access based on  N3IWF with integrated with a 
IEEE 802.11 network implemented mac_80211_hwsim and using the hostapd and 
wpa\_supplicant tools. We also use an open-source implementation of the 
SBA-based 5G core software ([my5gcore](https://github.com/my5G/my5G-core)), and 
an open-source implementation to provide untrusted non-3GPP access do 5G core network
([UE-IoT-non3GPP](https://github.com/my5G/UE-IoT-non3GPP)).

<p align="center">
    <img src="figs/proposal.png" height="500"/> 
</p>

## Interface Y1 - Conection beetween UE and Access Point

On your host, install the necessary packages:

```bash
sudo apt-get update && sudo apt-get install hostapd dnsmasq -y
```

To create wlan0 and wlan1 wireless cards with mac80211_hwsim:
```bash
sudo modprobe mac80211_hwsim radios=2
```

Apply the settings for wlan0:
```bash
sudo ifconfig wlan0 up
sudo ip addr add 192.168.1.10/24 dev wlan0
```

To create the hostapd.conf file:
```bash
sudo touch $HOME/hostapd.conf && sudo chmod 666 $HOME/hostapd.conf
echo -e "interface=wlan0\ndriver=nl80211\nssid=my5gcore\nchannel=0\nhw_mode=b\nwpa=3\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nwpa_passphrase=my5gcore\nauth_algs=3\nbeacon_int=100" > $HOME/hostapd.conf
```

Initializing hostapd.conf to wlan0:
```bash
cd ~
sudo hostapd hostapd.conf -B
```

To create the wpa_supplicant.conf file:
```bash
  sudo touch $HOME/wpa_supplicant.conf && sudo chmod 666 $HOME/wpa_supplicant.conf
  echo -e 'network={\nssid="'$SSID'"\nkey_mgmt=WPA-PSK\npsk="'$WPA_PASSPHRASE'"\n}' > $HOME/wpa_supplicant.conf
```

Apply the settings for wlan1 and initialize wpa_supplicant for wlan1:
```bash
sudo ifconfig wlan1 192.168.1.2
sudo wpa_supplicant -i wlan1 -c $HOME/wpa_supplicant.conf && sleep 2
```
Done! At this point, the virtual interface wlan1 is connected to wlan0 which acts as a wifi access point.
If success, the output will look like below:

<p align="center">
    <img src="docs/figs/success-interface-y1.png" height="200"/> 
</p>

You can also use the interface-y1.sh file to automate the previous steps.

```bash
sudo interface-y1.sh up
```
To stop the script and clean-up environment type CRTL+c or run the command:

```bash
sudo interface-y1.sh down
```
