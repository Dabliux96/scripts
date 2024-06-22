#!/bin/bash


#copies local machine ip address (can be especially useful when writing a reverse shell)
#assumes that local machine is connected to HTB openvpn connection 10.0.0.0 on tun0

#check if xclip is installed. If not, install it.
if ! command -v xclip &> /dev/null; then
	sudo apt-get install -y xclip > /dev/null 2>&1
fi

ip a | grep -E '10.([0-9]+).([0-9]+).([0-9])' | awk '{print $2}' | cut -d '/' -f 1 | tr -d '\n' | xclip -selection clipboard
echo -e "[i] Local IP address copied."
