#!/bin/bash

clear 
scriptLoc=$(readlink -f "$0")

# Function to erase drives. First parameter is whether or not to wipe the drive, second parameter is the drive number (/dev/sdb = 1, ../sdc = 2, etc...) 
# To write: sudo dd if=/home/owner/Desktop/Random_Hex_Bytes of=/dev/sdb bs=512 count=1 seek=1000
# To read: sudo dd if=/dev/sdb bs=512 count=1 skip=1000

randomLocation=$(( $RANDOM % 1000 + 1000))

derase() {

# Variables to support up to 1 GB of verification pass
hexBytesLocation=/home/owner/Desktop/disk-wipe/Random_Hex_Bytes
verificationFile=/home/owner/Desktop/disk-wipe/verification
randomLocation=$3
verifyBlockNum=$4
errorCatch="" 
driveName="" 

if [ $1 -eq 0 ]; then exit; else

if [ $2 -eq 1 ]; then driveName=/dev/sdb; errorCatch=/home/owner/Desktop/disk-wipe/errors/errorSDB; fi; 
if [ $2 -eq 2 ]; then driveName=/dev/sdc; errorCatch=/home/owner/Desktop/disk-wipe/errors/errorSDC; fi; 
if [ $2 -eq 3 ]; then driveName=/dev/sdd; errorCatch=/home/owner/Desktop/disk-wipe/errors/errorSDD; fi; 
if [ $2 -eq 4 ]; then driveName=/dev/sde; errorCatch=/home/owner/Desktop/disk-wipe/errors/errorSDE; fi; 

# Clear Error Log before New Wipe
echo -n "" > "$errorCatch"

# Write verification sequence to the random location passed in through third parameter
dd if=$hexBytesLocation of=$driveName bs=512 count=$verifyBlockNum seek=$randomLocation 
echo "verify sequence written: $driveName" 

# Set secure erase password to Kramden, initialize secure erase, catch errors in the designated errorCatch file location
2>"$errorCatch" sudo hdparm --user-master u --security-set-pass p $driveName
2>"$errorCatch" sudo hdparm --user-master u --security-erase p $driveName

# Read verification block and write to verificationFile, defined at top of function... 
dd if=$driveName of=$verificationFile bs=512 count=$verifyBlockNum skip=$randomLocation

# Verify the erase by ensuring that the data at the random location is zeroed, and that there were no errors caught while issuing secure erase. 
if [ -s "$verificationFile" ] && [ -s "$errorCatch" ]; 
then
zenity --info --text="$driveName Successfully Erased."
else 

# If the erase fails, ask the user if they want to start a block wipe.
if zenity --question --text="Erase Failed for $driveName. Block wipe?"; 
then
sudo nwipe --exclude=/dev/sda --autonuke --nogui --method=quick $driveName | pv -f "$driveName" 2>&1 | zenity --progress --title="$driveName nwipe" --text="Progress: " --time-remaining --auto-kill
fi; 
fi; 
fi; 
}

# Export function for parallel processing implementation
export -f derase 

dinfo() {
echo -e "______________________________________________________________________________ \n"
drive1state=`2>/dev/null hdparm -I /dev/sdb | grep frozen`
drive1SMART=`smartctl -a /dev/sdb | grep -A 4 "SMART support"`
if [ -z "$drive1state" ]; then echo -e "\n/dev/sdb: NOT FOUND \n______________________________________________________________________________"; else 
echo -e "/dev/sdb: $drive1state \n "`2>/dev/null hdparm -i /dev/sdb | grep Model`" \n $drive1SMART \n______________________________________________________________________________"; fi; 

drive2state=`2>/dev/null hdparm -I /dev/sdc | grep frozen`
drive2SMART=`smartctl -a /dev/sdc | grep -A 4 "SMART support"`
if [ -z "$drive2state" ]; then echo -e "\n/dev/sdc: NOT FOUND \n______________________________________________________________________________"; else
echo -e "/dev/sdc: $drive2state \n "`2>/dev/null hdparm -i /dev/sdc | grep Model`" \n $drive2SMART \n______________________________________________________________________________"; fi; 

drive3state=`2>/dev/null hdparm -I /dev/sdd | grep frozen`
drive3SMART=`smartctl -a /dev/sdd | grep -A 4 "SMART support"`
if [ -z "$drive3state" ]; then echo -e "\n/dev/sdd: NOT FOUND \n______________________________________________________________________________"; else
echo -e "/dev/sdd: $drive3state \n "`2>/dev/null hdparm -i /dev/sdd | grep Model`" \n $drive3SMART \n______________________________________________________________________________"; fi; 

drive4state=`2>/dev/null hdparm -I /dev/sde | grep frozen`
drive4SMART=`smartctl -a /dev/sde | grep -A 4 "SMART support"`
if [ -z "$drive4state" ]; then echo -e "\n/dev/sde: NOT FOUND \n______________________________________________________________________________"; else
echo -e "/dev/sde: $drive4state \n "`2>/dev/null hdparm -i /dev/sde | grep Model`" \n $drive4SMART \n______________________________________________________________________________ \n"; fi; 
}

clear

dinfo 

if zenity --question --text "Try un-freeze with system suspend?" --no-wrap --ok-label "Yes" --cancel-label "No"; 
then
sudo rtcwake -m mem -s 5
clear 
fi

clear 
dinfo 

inWhile=0

while [ $inWhile -eq 0 ]
do
	if zenity --question --text "Refresh Drive List?" --no-wrap --ok-label "Yes" --cancel-label "No"; 
	then 
	clear
	dinfo
	else
	inWhile=1
	fi
done

d1e=0
d2e=0
d3e=0
d4e=0

clear 

if grep -q "not" <<< "$drive1state"; then echo "/dev/sdb OK..."; d1e=1; else echo "/dev/sdb not working..."; fi; 
if grep -q "not" <<< "$drive2state"; then echo "/dev/sdc OK..."; d2e=1; else echo "/dev/sdc not working..."; fi; 
if grep -q "not" <<< "$drive3state"; then echo "/dev/sdd OK..."; d3e=1; else echo "/dev/sdd not working..."; fi; 
if grep -q "not" <<< "$drive4state"; then echo "/dev/sde OK..."; d4e=1; else echo "/dev/sde not working..."; fi; 

echo -e "continuing with erase for OK drives (press Ctrl + C to abort)..."
sleep 2

clear 
dinfo

echo -e "SETTING PASSWORDS ON DRIVES AND ISSUING SECURE ERASE COMMANDS (Sector location: $randomLocation)" 
echo -e "______________________________________________________________________________ \n"

# Simultaneously wipe ALL drives, based on whether or not they are frozen. 
parallel --link -j4 ::: derase ::: $d1e $d2e $d3e $d4e ::: 1 2 3 4 ::: $randomLocation ::: 2000000
read -p "Press enter to return to drive list..."
exec "$scriptLoc" 
