<div align="center">
    <a href="https://github.com/LABORA-INF-UFG/my5Gcore"><img width="20%" src="figs/my5g-logo.png" alt="free5GC"/></a>
</div> 

# Non-3GPP-IoT-WiFi
Non-3GPP-IoT-WiFi aims to demonstrate the untrusted non-3GPP access to the my5Gcore using a IEEE 802.11 network (WiFi) as illustrated by the following image.

<p align="center">
    <img src="figs/general-architecture.png" height="250"/> 
</p>


## Expected result

This experiment aims to demonstrate a non-3GPP access based on N3IWF (Non-3GPP Interworking Function) with integrated a 
IEEE 802.11 network implemented mac80211_hwsim and using hostapd and 
wpa\_supplicant tools. We also use an open-source implementation of the 
SBA-based 5G core software ([my5gcore](https://github.com/my5G/my5G-core)), and 
an open-source implementation to provide untrusted non-3GPP access do 5G core network
([UE-IoT-non3GPP](https://github.com/my5G/UE-IoT-non3GPP)). Y1 interface is responsible for the connection
between User Equipment (UE) and Access Point (AP) and Y2 establishes connection between AP and N3IWF.

<p align="center">
    <img src="figs/proposal.png" height="500" width="100%"/> 
</p>

## Interface Y1 - Conection beetween UE and AP

On your host, install the necessary packages:

```bash
sudo apt-get update && sudo apt-get install hostapd wget -y
```

To create wlan0 and wlan1 wireless cards with mac80211_hwsim:

```bash
sudo modprobe mac80211_hwsim radios=2
```
The argument radios=2 defines how many virtual interfaces will be created and 
defaults to two devices. After successfully loading the kernel module, wlan0 and wlan1 
are showing up, as shown in figure below (execute iwconfig). 
The third interface that pops up is hwsim0 that is a virtual interface for 
debugging purposes, where you could listen to all radio frames on all channels. 
We won’t need it for this guide.

<p align="center">
    <img src="figs/iwconfig.png" height="200"/> 
</p>

We are going to create a network namespace called **APns** for the wlan0 interface 
and run a separate shell in that namespace. With that we end up having two shells: One for 
the WiFi hotspot (**APns**) and one for the WiFi client.

To create a network namespace:

```bash
sudo ip netns add APns
```

In other terminal, type:
```bash
# Run this in a separate shell.
sudo ip netns exec APns bash
echo $BASHPID
```
The resulted expected is like below. 
In this tutorial, the bash pid is 3065 (in your case, it will be another number)

<p align="center">
    <img src="figs/bashpid.png"/> 
</p>

At the first terminal, type:

```bash
# Run this command with your bash pid instead of 3065
sudo iw phy phy0 set netns 3065 # you must have to change the bash pid
```

at this point, the first terminal will look like the isolated wlan1 interface 
as in the figure below: 

<p align="center">
    <img src="figs/first-terminal.png" height="200"/> 
</p>

The second terminal will be the wifi access point. Note in the figure that wlan0 is isolated

<p align="center">
    <img src="figs/second-terminal.png" height="200"/> 
</p>

Apply the settings for wlan0 (in the second terminal):

```bash
sudo ip addr add 192.168.1.10/24 dev wlan0
```

To create the hostapd.conf file:

```bash
sudo touch $HOME/hostapd.conf && sudo chmod 666 $HOME/hostapd.conf
echo -e "interface=wlan0\ndriver=nl80211\nssid=my5gcore\nchannel=0\nhw_mode=b\nwpa=3\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nwpa_passphrase=my5gcore\nauth_algs=3\nbeacon_int=100" > $HOME/hostapd.conf
```
<br>

Or download the hostapd file:

```bash
cd ~
wget -q https://raw.githubusercontent.com/mariotlemes/non-3gpp-iot-wifi/hostapd.conf
```

Initializing hostapd.conf to wlan0:

```bash
cd ~
sudo hostapd hostapd.conf -B
```
The expected result is like below:

<p align="center">
    <img src="figs/hostapd-background.png" height="200"/> 
</p>

In the first terminal, type to create the wpa_supplicant.conf file:

```bash
  cd ~
  sudo touch wpa_supplicant.conf && sudo chmod 666 wpa_supplicant.conf
  echo -e 'network={\nssid="my5gcore"\nkey_mgmt=WPA-PSK\npsk="my5gcore"\n}' > wpa_supplicant.conf
```
<br>
Or download the wpa_supplicant file:
```bash
cd ~
wget -q https://raw.githubusercontent.com/mariotlemes/non-3gpp-iot-wifi/wpa_supplicant.conf
```

Apply the settings for wlan1 and initialize wpa_supplicant for wlan1:

```bash
cd ~
sudo killall wpa_supplicant
sudo wpa_supplicant -i wlan1 -c wpa_supplicant.conf -B
sudo ip addr add 192.168.1.1/24 dev wlan1
#sudo route add default gw 192.168.1.10 wlan1
```
Done! At this point, the virtual interface wlan1 (ip address 192.168.1.1/24) is connected to wlan0 (ip address 192.168.1.10/24) 
which acts as a wifi access point. If success, the output of the command iwconfig will be like
below:

<p align="center">
    <img src="figs/success-interface-y1.png" height="200"/> 
</p>


You can also use the interface-y1.sh file to automate the previous steps.

```bash
sudo interface-y1.sh up
```
To stop the script and clean-up environment type CRTL+c or run the command:

```bash
sudo interface-y1.sh down
```

## Interface Y2 - Conection beetween AP and N3IWF

The connection between AP and N3IWF will be made by a router that knows the UE 
network and the N3IWF network, being able to route messages between the two components. 
Virtual interfaces will be established between AP and Router and Router and N3IWF and 
routes will be created to exchange messages.


