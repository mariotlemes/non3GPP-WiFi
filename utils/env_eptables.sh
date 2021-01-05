 #!/bin/bash

 INIF="wlan0"

 function add_ebtables () {
   COMPIP=$1
   COMPMAC=$2

   ebtables -t nat -A PREROUTING -i $INIF -p IPv4 --ip-dst $COMPIP -j \
   dnat --to-dst $COMPMAC --dnat-target ACCEPT
   ebtables -t nat -A PREROUTING -i $INIF -p ARP --arp-ip-dst $COMPIP \
   -j dnat --to-dst $COMPMAC --dnat-target ACCEPT

 }

 if [[ $# -ne 2 ]]; then
   echo "Usage: $0 ip mac"
 elif [[ $(whoami) != "root" ]]; then
   echo "Error: must be root"
 else
   add_ebtables $1 $2
 fi
