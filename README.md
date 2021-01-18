
<div align="center">
    <a href="https://github.com/LABORA-INF-UFG/my5Gcore"><img width="20%" src="figs/my5g-logo.png" alt="free5GC"/></a>
</div> 

# Non-3GPP-WiFi use-case
Non-3GPP-WiFi use-case aims to demonstrate the untrusted non-3GPP access to the my5G-core using a IEEE 802.11 network (WiFi) as illustrated by the following image.

<p align="center">
    <img src="figs/general-architecture.png" height="250"/> 
</p>


## Expected result

This experiment aims to demonstrate a non-3GPP access based on N3IWF (Non-3GPP Interworking Function) with integrated a IEEE 802.11 network implemented by mac80211_hwsim and using hostapd and 
wpa\_supplicant tools. We also use an open-source implementation of the 
SBA-based 5G core software ([my5G-core](https://github.com/my5G/my5G-core)), and 
an open-source implementation to provide untrusted non-3GPP access do 5G core network
([UE-non3GPP](https://github.com/my5G/UE-IoT-non3GPP)). Y1 interface is responsible for the connection
between User Equipment (UE-non3GPP) and Access Point (AP) and Y2 establishes connection between AP and N3IWF.

<p align="center">
    <img src="figs/proposal.png" width="100%"/> 
</p>

## Interface Y1 - Conection beetween UE-non3GPP and AP

On your host, install the necessary packages:

```bash
sudo apt-get update && sudo apt-get install dnsmasq hostapd wget -y
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

We are going to create network namespaces: i) **APns** for interface wlan0 and ii) **UEns** for  interface wlan1.

To create a network namespace for UEns and APns:

```bash
sudo ip netns add APns
sudo ip netns add UEns
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

At this point, wlan0 interface is in APns namespace and wlan1 at UEns namespace. Note in the figure that wlan0 is isolated.

<p align="center">
    <img src="figs/second-terminal.png"/> 
</p>

Apply the settings for wlan0. In this tutorial, the ip address at access point (wlan0) will be 192.168.1.10/24

```bash
sudo ip addr add 192.168.1.10/24 dev wlan0
```

To create the dnsmasq.conf file:
```bash
sudo killall dnsmasq
sudo touch $HOME/dnsmasq.conf && sudo chmod 666 $HOME/dnsmasq.conf
echo -e "interface=wlan0\ndhcp-range=192.168.1.2,192.168.1.254,255.255.255.0,12h\nserver=8.8.8.8\nlog-queries\nlog-dhcp\nlisten-address=127.0.0.1\ndhcp-host=02:00:00:00:01:00,192.168.1.1" > $HOME/dnsmasq.conf

```
<br>

Or download the dnsmasq.conf file from the repository:

```bash
cd ~
wget -O dnsmasq.conf https://raw.githubusercontent.com/mariotlemes/non-3gpp-iot-wifi/master/conf/dnsmasq.conf?token=ACYGK3XWNRZ7RVIOKYKCJKTAAWIIC
```
<br>

Initializing dnsmasq.conf:

```bash
cd ~
sudo ip netns exec APns dnsmasq -C $HOME/dnsmasq.conf -D
```

To create the hostapd.conf file:

```bash
sudo killall wpa_supplicant
sudo touch $HOME/hostapd.conf && sudo chmod 666 $HOME/hostapd.conf
echo -e "interface=wlan0\ndriver=nl80211\nssid=my5gcore\nchannel=0\nhw_mode=b\nwpa=3\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nwpa_passphrase=my5gcore\nauth_algs=3\nbeacon_int=100" > $HOME/hostapd.conf
```
<br>

Or download the hostapd.conf file from the repository:

```bash
cd ~
wget -O hostapd.conf https://raw.githubusercontent.com/mariotlemes/non-3gpp-iot-wifi/master/conf/hostapd.conf?token=ACYGK3S5HDFSL3RPIKC6KLLAAWILC
```
<br>

Initializing hostapd.conf to wlan0. At the end of this process, wlan0 will become an access point:

```bash
cd ~
sudo ip netns exec APns hostapd hostapd.conf -B
```
The expected result is like below:

<p align="center">
    <img src="figs/hostapd-background.png"/> 
</p>

To create the wpa_supplicant.conf file:

```bash
  cd ~
  sudo touch wpa_supplicant.conf && sudo chmod 666 wpa_supplicant.conf
  echo -e 'network={\nssid="my5gcore"\nkey_mgmt=WPA-PSK\npsk="my5gcore"\n}' > wpa_supplicant.conf
```
<br>

Or download the wpa_supplicant.conf file from the repository:

```bash
cd ~
wget -O wpa_supplicant.conf https://raw.githubusercontent.com/mariotlemes/non-3gpp-iot-wifi/master/conf/wpa_supplicant.conf?token=ACYGK3TSG2SLZVZ3OE334LLAAWIMY
```
<br>

Apply the settings for wlan1 and initialize wpa_supplicant:

```bash
cd ~
sudo killall wpa_supplicant
sudo ip netns exec UEns wpa_supplicant -i wlan1 -c wpa_supplicant.conf -B 
sudo dhclient wlan1
```
Removing the default route from UE. This route will be added later.

```bash
sudo ip netns exec UEns route del -net 0.0.0.0 gw 192.168.1.10 netmask 0.0.0.0 dev wlan1
```

Done! At this point, the virtual interface wlan1 (ip address 192.168.1.1/24) is connected to wlan0 (ip address 192.168.1.10/24) which acts as a WiFi access point. If success, the output of the command iwconfig will be like
below:

<p align="center">
    <img src="figs/success-interface-y1.png"/> 
</p>

## Interface Y2 - Conection beetween AP and N3IWF

The connection between AP and N3IWF will be made by veth (virtual ethernet) and the AP will be able to able to route messages between UE (wlan1 interface) and N3IWF (veth2). The ip addressing for the logical interface Y2 and the virtual interfaces are shown in the figure below:

<p align="center">
    <img src="figs/interface-y2.png"/> 
</p>

### Setting-up environment
```bash
cd ~
git clone https://github.com/mariotlemes/non-3gpp-iot-wifi.git


# fix and install module gtp5g
cd ~/non-3gpp-iot-wifi
sudo ./utils/fix_core.sh
```

```bash
cd ~/my5G-core
 
# backup of the config folder
mv -f config config.orig

# using sample1 folder for configuration
cp -R sample/sample1/ config
```

```bash
# backup of upf config
mv -f src/upf/build/config/upfcfg.yaml src/upf/build/config/upfcfg.yaml.orig

# new configuration for upf
cp src/upf/config/upfcfg.sample1.yaml src/upf/build/config/upfcfg.yaml

# set UE-non3GPP http bind address 
sed -i 's/HttpIPv4Address: .*/HttpIPv4Address: 192.168.1.1/' config/uecfg.conf

# remove database due to previews tests
mongo free5gc --eval "db.dropDatabase()"

# run webconsole
go build -o bin/webconsole -x webconsole/server.go
./bin/webconsole &

# add the UE-non3GPP that will be used in the test
~/my5G-core/sample/sample1/utils/add_test_ue.sh
```

### Set routes and namespaces for the scenario
```bash
cd ~/my5G-core/sample/sample1/utils

#backup env_manager.sh file
mv env_manager.sh env_manager.sh-ori

# copy the env_manager.sh file from the repository
sudo cp ~/non-3gpp-iot-wifi/utils/env_manager.sh ~/my5G-core/sample/sample1/utils/

# setup network interfaces and namespaces
./env_manager.sh up $(ip route | grep default | cut -d' ' -f5)
```

### Starting monitoring tools

```bash
# Wireshark for global namespace
wireshark -kni any --display-filter "isakmp or nas-5gs or ngap or pfcp or gtp or esp or gre" &

# Wireshark for UEns (wlan1)
sudo ip netns exec UEns wireshark -kni wlan1 --display-filter "isakmp or esp" &
```

### Starting UPF
```bash
# Use a new terminal so we can easily see the logs
cd ~/my5G-core/sample/sample1/utils
./run_upf.sh 
```
### Running my5G-core
Run the components of core in this order: 

1) NFR 
2) AMF 
3) SMF 
4) UDR 
5) PCF 
6) UDM 
7) NSSF 
8) AUSF
9) N3IWF

For example, to run NRF:
```bash
cd ~/my5G-core
./bin/nrf &
```
Repeat the process to AMF, SMF, UDR, PCF, UDM, NSSF and AUSF. 

Finally, to run N3IWF:
```bash
cd ~/my5G-core
sudo ./bin/n3iwf &
```

### Starting UE-non3GPP
```bash
# Use a new terminal or split
cd ~/my5G-core/src/ue

# New ike_bind_addr - ip of wlan1
sed -i 's/ike_bind_addr=.*/ike_bind_addr=${ike_bind_addr:-"192.168.1.1"}/' trigger_initial_registration.sh

# Starting UE-non3GPP
sudo ip netns exec UEns ../../bin/ue
```
<br>

### Triggering initial registration procedure
```bash
cd ~/my5G-core/src/ue
sudo ip netns exec UEns ./trigger_initial_registration.sh --ue_addr 192.168.1.1 --ue_port 10000 --scheme http
```
<br>

### Verify safe association between UE-non3GPP and N3IWF

```bash
# Starting watch XFRM policy
watch -d -n 2 sudo ip netns exec UEns ip xfrm policy 

# Starting watch XFRM state
watch -d -n 2 sudo ip netns exec UEns ip xfrm state 
```

if successful, you will be able to see the safe associations as show in the figures below:

<p align="center">
    <img src="figs/policy.png"/> 
</p>

<p align="center">
    <img src="figs/state.png"/> 
</p>

### Cleanning-up
```bash
sudo kill -9 $(ps aux | grep "watch -d -n 2 sudo ip netns exec UEns ip xfrm" | awk '{ print $2}')

# kill wireshark
killall -9 wireshark

# kill webconsole
killall -9 webconsole

# kill UE-non3GPP
sudo ip netns exec UEns killall -9 ./bin/ue

# kill UPF
sudo ip netns exec UPFns killall -9 free5gc-upfd

# kill hostapd and wpa_supplicant
sudo killall hostapd
sudo killall wpa_supplicant

#Stopping my5G-core
cd ~/my5G-core
sudo ./force_kill.sh

# removing network interfaces, namespaces and addresses
~/my5G-core/sample/sample1/utils/env_manager.sh down $(ip route | grep default | cut -d' ' -f5)

# removing mac80211_hwsim
sudo rmmod mac80211_hwsim

# removing DB
mongo free5gc --eval "db.dropDatabase()"

# restoring original configuration
cd ~/my5G-core
rm -rf config
mv config.orig config
rm src/upf/build/config/upfcfg.yaml
mv src/upf/build/config/upfcfg.yaml.orig src/upf/build/config/upfcfg.yaml
rm -f sample/sample1/utils/env_manager.sh
mv -f sample/sample1/utils/env_manager.sh-ori sample/sample1/utils/env_manager.sh
sed -i 's/ike_bind_addr=.*/ike_bind_addr=${ike_bind_addr:-"192.168.127.2"}/' src/ue/trigger_initial_registration.sh
```






