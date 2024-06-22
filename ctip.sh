#!/bin/bash

#copies target machine ip address (can be especially useful when writing a reverse shell)

#check if xclip is installed. If not, install it.
if ! command -v xclip &> /dev/null; then
	sudo apt-get install -y xclip > /dev/null 2>&1
fi

echo -e "Target machine name: " && read targetMachineName

targetMachineLocation=""

if [[ -d ~/HackTheBox/$targetMachineName ]]; then
	cat ~/HackTheBox/$targetMachineName/ip_address.txt | tr -d '\n' | xclip -selection clipboard
elif [[ -d ~/HTB_academy/$targetMachineName ]]; then
	cat ~/HTB_academy/$targetMachineName/ip_address.txt | tr -d '\n' | xclip -selection clipboard	
fi
