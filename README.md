
<div align="center">
    <a href="https://github.com/LABORA-INF-UFG/my5Gcore"><img width="20%" src="figs/my5g-logo.png" alt="free5GC"/></a>
</div> 

# Non-3GPP-WiFi-use-case
Non-3GPP-WiFi-use-case aims to demonstrate the untrusted non-3GPP access to the my5Gcore using a IEEE 802.11 network (WiFi) as illustrated by the following image.

<p align="center">
    <img src="figs/general-architecture.png" height="250"/> 
</p>


## Expected result

This experiment aims to demonstrate a non-3GPP access based on N3IWF (Non-3GPP Interworking Function) with integrated a 
IEEE 802.11 network implemented mac80211_hwsim and using hostapd and 
wpa\_supplicant tools. We also use an open-source implementation of the 
SBA-based 5G core software ([my5gcore](https://github.com/my5G/my5G-core)), and 
an open-source implementation to provide untrusted non-3GPP access do 5G core network
([UE-non3GPP](https://github.com/my5G/UE-IoT-non3GPP)). Y1 interface is responsible for the connection
between User Equipment (UE) and Access Point (AP) and Y2 establishes connection between AP and N3IWF.

<p align="center">
    <img src="figs/proposal.png" width="100%"/> 
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

We are going to create network namespaces: i) **APns** for interface wlan0, ii) **UEns** for  interface wlan1 and iii) **N3IWFns** for N3IWF component.

To create a network namespace for UEns, APns and N3IWFns:

```bash
sudo ip netns add APns
sudo ip netns add UEns
sudo ip netns add N3IWFns
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
sudo iw phy phy0 set netns 3065 # you must have to change the bash pid (APns)
```

In other terminal, type:
```bash
# Run this in a separate shell.
sudo ip netns exec UEns bash
echo $BASHPID
```

At the first terminal, type:

```bash
# Run this command with your bash pid instead of 3065
sudo iw phy phy1 set netns 3065 # you must have to change the bash pid (UEns)
```

At this point, wlan0 interface is in APns namespace and wlan1 at UEns namespace.

The second terminal (APns namespace) will be the wifi access point. Note in the figure that wlan0 is isolated.

<p align="center">
    <img src="figs/second-terminal.png"/> 
</p>

Apply the settings for wlan0:

```bash
sudo ip addr add 192.168.1.10/24 dev wlan0
```

To create the hostapd.conf file:

```bash
sudo killall wpa_supplicant
sudo touch $HOME/hostapd.conf && sudo chmod 666 $HOME/hostapd.conf
echo -e "interface=wlan0\ndriver=nl80211\nssid=my5gcore\nchannel=0\nhw_mode=b\nwpa=3\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nwpa_passphrase=my5gcore\nauth_algs=3\nbeacon_int=100" > $HOME/hostapd.conf
```
<br>

Or download the hostapd file:

```bash
cd ~
wget -q XXXXXXXXX
```
<br>

Initializing hostapd.conf to wlan0:

```bash
cd ~
sudo hostapd hostapd.conf -B
```
The expected result is like below:

<p align="center">
    <img src="figs/hostapd-background.png"/> 
</p>

At UEns namespace terminal, type to create the wpa_supplicant.conf file:

```bash
  cd ~
  sudo touch wpa_supplicant.conf && sudo chmod 666 wpa_supplicant.conf
  echo -e 'network={\nssid="my5gcore"\nkey_mgmt=WPA-PSK\npsk="my5gcore"\n}' > wpa_supplicant.conf
```
<br>
Or download the wpa_supplicant file:

```bash
cd ~
wget -q XXXX
```
<br>

Apply the settings for wlan1 and initialize wpa_supplicant:

```bash
cd ~
sudo killall wpa_supplicant
sudo wpa_supplicant -i wlan1 -c wpa_supplicant.conf -B
sudo ip addr add 192.168.1.1/24 dev wlan1

```
Done! At this point, the virtual interface wlan1 (ip address 192.168.1.1/24) is connected to wlan0 (ip address 192.168.1.10/24) 
which acts as a wifi access point. If success, the output of the command iwconfig will be like
below:

<p align="center">
    <img src="figs/success-interface-y1.png"/> 
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

The connection between AP and N3IWF will be made by veth (virtual ethernet) and the AP will be able to able to route messages between UE (wlan1 interface) and N3IWF (veth). The ip addressing for the logical interface Y2 and the virtual interfaces are shown in the figure below:

<p align="center">
    <img src="figs/interface-y2.png"/> 
</p>

### Setting-up environment
```bash
cd ~
git clone https://github.com/mariotlemes/non-3gpp-iot-wifi.git
cd non-3gpp-iot-wifi
sudo rmmod gtp5g
sudo ./utils/fix_core.sh
```

```bash
cd ~/my5G-core
mv -f config config.orig
cp -R sample/sample1/ config
```

```bash
# UP config
mv -f src/upf/build/config/upfcfg.yaml src/upf/build/config/upfcfg.yaml.orig
cp src/upf/config/upfcfg.sample1.yaml src/upf/build/config/upfcfg.yaml

# Remove expiration/retry timers so that we can take our time debugging
sed -i "s/t3502:.*/t3502: 0/" config/amfcfg.conf
sed -i "s/t3512:.*/t3512: 0/" config/amfcfg.conf
sed -i "s/non3gppDeregistrationTimer:.*/non3gppDeregistrationTimer: 0/" config/amfcfg.conf
sed -i 's/TimeT3560 time.Duration = .*/TimeT3560 time.Duration = 2 * time.Hour/' src/amf/context/3gpp_types.go

# set UE http bind address 
sed -i 's/HttpIPv4Address: .*/HttpIPv4Address: 192.168.1.1/' config/uecfg.conf

# remove database due to previews tests
mongo free5gc --eval "db.dropDatabase()"

# run webconsole
cd ~/my5G-core
go build -o bin/webconsole -x webconsole/server.go
./bin/webconsole &

# add the UE that will be used in the test
~/my5G-core/sample/sample1/utils/add_test_ue.sh
```

### Set the routes and namespaces
```bash
cd ~/my5G-core/sample/sample1/utils

#backup env_manager.sh file
mv env_manager.sh env_manager.sh-ori

#wget env_manager.sh #TODO: get github content
sudo cp ~/non-3gpp-iot-wifi/utils/env_manager.sh ~/my5G-core/sample/sample1/utils/

# setup network interfaces and namespaces
./env_manager.sh up $(ip route | grep default | cut -d' ' -f5)
```

###Starting monitoring tools

```bash
wireshark -kni any --display-filter "isakmp or nas-5gs or ngap or pfcp or gtp or esp or gre" &
```

### Starting UPF
```bash
# Use a new terminal so we can easily see the logs
cd ~/my5G-core/sample/sample1/utils
./run_upf.sh 
```

### Starting UE in debug mode
```bash
# Use a new terminal or split
#cd ~/my5G-core
#echo $(which dlv) | sudo xargs -I % sh -c 'ip netns exec UEns % --listen=192.168.1.1:2345 --headless=true --api-version=2 --accept-multiclient #exec ./bin/ue' 
```

### Starting UE.
Run the components of core: NFR -> AMF -> SMF -> UDR -> PCF -> UDM -> NSSF -> AUSF ->  N3IWF -> UE Debugger

### Triggering initial registration procedure
```bash
cd ~/my5G-core/src/ue
./trigger_initial_registration.sh --ue_addr 192.168.1.1 --ue_port 10000 --scheme http
```

### Cleanning-up
```bash
sudo kill -9 $(ps aux | grep "watch -d -n 2 sudo ip netns exec UEns ip xfrm" | awk '{ print $2}')

# wireshark
killall -9 wireshark

# webconsole
killall -9 webconsole

# UE-IoT-non3GPP
sudo ip netns exec UEns killall -9 dlv
sudo ip netns exec UEns killall -9 ./bin/ue

# UPF
sudo ip netns exec UPFns killall -9 free5gc-upfd
```

```bash
# removing network interfaces, namespaces and addresses
~/my5G-core/sample/sample1/utils/env_manager.sh down $(ip route | grep default | cut -d' ' -f5)

# removing DB
mongo free5gc --eval "db.dropDatabase()"

# restoring original configuration
cd ~/my5G-core
rm -rf config
mv config.orig config
rm src/upf/build/config/upfcfg.yaml
mv src/upf/build/config/upfcfg.yaml.orig src/upf/build/config/upfcfg.yaml
rm sample/sample1/utils/env_manager.sh
mv sample/sample1/utils/env_manager.sh-ori sample/sample1/utils/env_manager.sh


# restore T3560 timer
cd src/amf
git checkout -- context/3gpp_types.go
cd ~/my5G-core

```





