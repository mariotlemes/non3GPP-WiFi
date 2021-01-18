#!/bin/bash

# enable forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# stoppig ufw service
sudo /etc/init.d/ufw stop

# compiling gtp5g module
cd ~/gtp5g
sudo make && sudo make install

# adding rule in iptables
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
