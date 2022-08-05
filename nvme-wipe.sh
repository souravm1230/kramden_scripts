#!/bin/bash

scriptLoc=$(readlink -f "$0")
clear 

# Grab all nvme devices
grabDevices() { sudo nvme -list | grep /dev/ | while read line ; do echo "$line " | cut -c1-18 | tr " " "\n" | tr -s "\n" "\n"; done;}

# Prompts user to select drives and allows for re-freshing of drive list
refreshPrompt() {
	
	response="" 
	
	while [ -z "$response" ]; do 
	
		deviceList=`grabDevices`
		
		nvme1=""; nvme2=""; nvme3=""; nvme4=""; 
		
		if grep -q "/nvme0n1" <<< "$deviceList"; then nvme1="/dev/nvme0n1"; fi; 
		if grep -q "/nvme1n1" <<< "$deviceList"; then nvme2="/dev/nvme1n1"; fi; 
		if grep -q "/nvme2n1" <<< "$deviceList"; then nvme3="/dev/nvme2n1"; fi; 
		if grep -q "/nvme3n1" <<< "$deviceList"; then nvme4="/dev/nvme3n1"; fi; 
		
		response=$(zenity --height=250 --list --checklist --title='Drive Selection' --text="Sourav's NVME Secure Erase" --column=Boxes --column=Selections --cancel-label="Exit" --ok-label="Erase" --extra-button="Refresh List" FALSE $nvme1 FALSE $nvme2 FALSE $nvme3 FALSE $nvme4;)
		ret=$? 
		
		if [ $ret -eq 1 ]; 
		then 
			if grep -q "Refresh" <<< $response; 
			then 
				response=""; 
			else
				exit 1; 
			fi; 
		fi; 
		
		# Make sure that if erase is selected, a drive is also selected so it doesn't auto-refresh by default. 
		if [ "$ret" = "0" ] && [ -z "$response" ]; then zenity --info --text="Please select a drive!"; response=""; fi; 
		
		
	done;
	
	echo "$response" 

} 


# Erasing funtion. First parameter is 1 or 0 (whether to erase or not). Second parameter is the drive number (1-4). Third parameter is verify size, and fourth is random location. 
eraseDrives() {

randomHexLocation=/home/owner/Desktop/disk-wipe/Random_Hex_Bytes
errorLog=/home/owner/Desktop/nvme-wipe/Logs/errorLog
echo -n "" > "$errorLog"
erase=$1 
driveName="" 
verifySize=$3
randomLocation=$4

if [ $erase -eq 0 ]; then exit; else

if [ $2 -eq 1 ]; then driveName=/dev/nvme0n1; fi; 
if [ $2 -eq 2 ]; then driveName=/dev/nvme1n1; fi; 
if [ $2 -eq 3 ]; then driveName=/dev/nvme2n1; fi; 
if [ $2 -eq 4 ]; then driveName=/dev/nvme3n1; fi; 

# Write verification at the specified location with the specified size...
sudo dd if=$randomHexLocation of=$driveName bs=512 count=$verifySize seek=$randomLocation 
sudo 2>"$errorLog" nvme format -f -s1 $driveName
verification=$(sudo dd if=$driveName bs=512 count=$verifySize skip=$randomLocation) 
if [ -z $verification ]; then zenity --info --text="Secure Erase Successful: $driveName"; 
else zenity --info --text="Secure Erase Failed: $driveName"; fi;  

# End else statement from above...
fi; 

} 

export -f eraseDrives

random=$(( $RANDOM % 1000 + 1000))

selection=$(refreshPrompt) 
 
if grep -q "EXIT" <<< "$selection"; then exit 1; fi; 

n1e=0; n2e=0; n3e=0; n4e=0; 

if grep -q "/nvme0n1" <<< "$selection"; then n1e=1; fi; 
if grep -q "/nvme1n1" <<< "$selection"; then n2e=1; fi; 
if grep -q "/nvme2n1" <<< "$selection"; then n3e=1; fi; 
if grep -q "/nvme3n1" <<< "$selection"; then n4e=1; fi; 

&>/home/owner/Desktop/nvme-wipe/Logs/outputLog parallel --link -j4 ::: eraseDrives ::: $n1e $n2e $n3e $n4e ::: 1 2 3 4 ::: $random ::: 2000000

zenity --question --text="Return to Drive List?" 
if [ $? -eq 1 ]; then exit 1; fi; 
exec "$scriptLoc" 

