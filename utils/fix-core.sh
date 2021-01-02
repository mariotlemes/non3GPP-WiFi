#!/bin/bash

cd ~/gtp5g
make && sudo make install

sudo service ufw stop

sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
