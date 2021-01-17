#!/bin/bash

sudo /etc/init.d/ufw stop

cd ~/gtp5g
sudo make && sudo make install

sudo iptables -t nat -F
sudo iptables -t nat -X

sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
