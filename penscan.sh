#!/bin/bash

# Automates pentest scan process.


#TO DO:
#1. Set up sublist3r, theHarvester or similar tools for subdomain enumeration
#2. Add wbscan
#3. Add SSLScan
#4. Add WhatWeb 
#5. Fix the way arguments are handled. Currently only able to use --skip-nmap, but it is not possible to add multiple arguments
#6. Write separate script to copy target ip address



#argument - skip nmap - Doesn't entirely skip nmap, but it runs a basic quick scan instead. May need fixes
skip_nmap=false
if [[ "$1" == "--skip-nmap" ]]; then
    skip_nmap=true
fi

#colours
RESETCOLOUR="\e[0m"
RED="\e[31m"
BLUE="\e[34m"

#install tools
check_packages_install() {
    echo -e "${BLUE}[i]${RESETCOLOUR} Running apt-update...\n---------------\n"
    sudo apt-get update > /dev/null 2>&1
    
    packagesNeeded=("dirsearch" "gobuster" "sublist3r")

    echo -e "${BLUE}[i]${RESETCOLOUR} Checking for missing packages..."
    
    for packageNeeded in ${packagesNeeded[@]}; do
        if ! command -v $packageNeeded &> /dev/null; then
            echo -e "${BLUE} |_${RESETCOLOUR} Installing $packageNeeded...\n"
            sudo apt-get install -y $packageNeeded > /dev/null 2>&1
        fi
    done
    for packageNeeded in ${packagesNeeded[@]}; do
        if ! command -v $packageNeeded &> /dev/null; then
            echo -e "\n---------------\n${RED}[!]${RESETCOLOUR} It was not possible to install package $packageNeeded. Please install manually."
        fi
    done
}

check_packages_install

#Input Machine Name and IP Address
echo -e "____________________________________________________\nMachine name:"
read machineName

echo -e "Machine IP Address:"
read machineIPAddress

#create machine directory and sub-directories
mkdir -p $machineName/scans

#write target ip address to file
echo $machineIPAddress > $machineName/ip_address.txt

#run nmap detailed scan, or skip it to only get port list
if [[ "$skip_nmap" == false ]]; then

    sudo nmap -sV -sC -vvv -p- $machineIPAddress -oN $machineName/scans/nmap.txt 
    
    targetPorts=$(grep -E '([0-9]+)/(tcp|udp)' $machineName/scans/nmap.txt | cut -d '/' -f 1 | awk '{print $1}' | tr '\n' ' ')
    targetWebPorts=$(grep -E '([0-9]+)/(tcp|udp).*http' $machineName/scans/nmap.txt | cut -d '/' -f 1 | tr '\n' ' ')
    
    	#check for OS
	targetOS=$(grep "Service Info" $machineName/scans/nmap.txt | awk '{print $6}' | cut -d ";" -f 1)

	#run enum4linux if windows is detected
	if [[ $targetOS == "Windows" ]]; then
   		enum4linux -a $machineIPAddress | tee $machineName/scans/enum4linux.txt
	fi
else
    echo -e "\n---------------\n${BLUE}[i]${RESETCOLOUR} Skipping detailed nmap scan...\n---------------\n"
    #nmap port sweep
    echo -e "${BLUE}[i]${RESETCOLOUR} Open ports:\n"
    nmap $machineIPAddress -oN $machineName/scans/nmap_ports.txt
    targetPorts=$(grep -E '([0-9]+)/(tcp|udp)' $machineName/scans/nmap_ports.txt | cut -d '/' -f 1 | awk '{print $1}' | awk 'NF' | tr '\n' ' ')
    targetWebPorts=$(grep -E '([0-9]+)/(tcp|udp).*http' 10.129.226.210/scans/nmap_ports.txt | cut -d '/' -f 1)
fi 

#run the following for every port found - TEMPORARILY DISABLED, TAKES TOO LONG.
#for targetPort in $targetPorts; do
    #sudo nmap --script vuln -p$targetPort $machineIPAddress >> $machineName/scans/nmap_vulns.txt
#done

#run the following for every web port found
for targetWebPort in $targetWebPorts; do
    # Directory bruteforcing
    dirsearch -u http://$machineIPAddress:$targetWebPort -o $machineName/scans/dirsearch.txt
    gobuster dir -u http://$machineIPAddress:$targetWebPort -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -o $machineName/scans/gobuster.txt
    nikto -host $machineIPAddress -port $targetWebPort -output $machineName/scans/nikto.txt
done
