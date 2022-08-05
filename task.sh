#!/bin/bash

clear 
scriptLoc=$(readlink -f "$0")

# Function to erase drives. First parameter is whether or not to wipe the drive, second parameter is the drive number (/dev/sdb = 1, ../sdc = 2, etc...) 
# To write: sudo dd if=/home/owner/Desktop/Random_Hex_Bytes of=/dev/sdb bs=512 count=1 seek=1000
# To read: sudo dd if=/dev/sdb bs=512 count=1 skip=1000

randomLocation=$(( $RANDOM % 1000 + 100000))

derase() {

# Variables to support up to 1 GB of verification pass
hexBytesLocation=/home/owner/Desktop/disk-wipe/Random_Hex_Bytes
errorLogFolder=/home/owner/Desktop/disk-wipe/errors
randomLocation=$3
verifyBlockNum=$4
errorCatch="" 
driveName="" 

if [ $1 -eq 0 ]; then exit; else

if [ $2 -eq 1 ]; then driveName=/dev/sdb; errorCatch=$errorLogFolder/errorSDB; fi; 
if [ $2 -eq 2 ]; then driveName=/dev/sdc; errorCatch=$errorLogFolder/errorSDC; fi; 
if [ $2 -eq 3 ]; then driveName=/dev/sdd; errorCatch=$errorLogFolder/errorSDD; fi; 
if [ $2 -eq 4 ]; then driveName=/dev/sde; errorCatch=$errorLogFolder/errorSDE; fi; 
if [ $2 -eq 5 ]; then driveName=/dev/sdf; errorCatch=$errorLogFolder/errorSDF; fi; 
if [ $2 -eq 6 ]; then driveName=/dev/sdg; errorCatch=$errorLogFolder/errorSDG; fi; 
if [ $2 -eq 7 ]; then driveName=/dev/sdh; errorCatch=$errorLogFolder/errorSDH; fi; 
if [ $2 -eq 8 ]; then driveName=/dev/sdi; errorCatch=$errorLogFolder/errorSDI; fi; 

# Clear Error Log before New Wipe
echo -n "" > "$errorCatch"
estimatedMinutes=$(sudo hdparm -I /dev/sdb | grep "SECURITY ERASE" | cut -c1-6 | tr -dc '0-9')

&>"$errorCatch" sudo hdparm --user-master u --security-unlock p $driveName
&>"$errorCatch" sudo hdparm --user-master u --security-disable p $driveName

&>"$errorCatch" sudo hdparm --user-master u --security-unlock password $driveName
&>"$errorCatch" sudo hdparm --user-master u --security-disable password $driveName

# Write verification sequence to the random location passed in through third parameter
# block size for all dd operations is 512 bytes, so multiply the num of blocks to verify by 512 to get total bytes
2>"$errorCatch" sudo dd if=$hexBytesLocation of=$driveName bs=512 count=verifyBlockNum seek=$randomLocation
sudo -u $USER --preserve-env=DISPLAY,XDG_RUNTIME_DIR \
  zenity --timeout 1 --notification --text="Verification Block Written to $driveName" &

# Set secure erase password to Kramden, initialize secure erase, catch errors in the designated errorCatch file location, and display an estimated timer 
2>"$errorCatch" sudo hdparm --user-master u --security-set-pass p $driveName

now=$(date)

countdown $estimatedMinutes | zenity --progress --title="Sourav's Secure Erase" --text="Erase Progress: $driveName" --time-remaining --auto-close --auto-kill & 2>"$errorCatch" sudo hdparm --user-master u --security-erase p $driveName & wait -n 
pkill -P $$

# Read verification block and write to verificationFile, defined at top of function... 
verification=$(2>"$errorCatch" dd if=$driveName bs=512 count=$verifyBlockNum skip=$randomLocation) 

# Verify the erase by ensuring that the data at the random location is zeroed, and that there were no errors caught while issuing secure erase. 
# Error-based failure is still buggy right now, working on a patch for it... 
if [ -z "$verification" ]; 
then

# Notify user that data was removed but that secure erase errors were logged...
if grep "SG_IO" <<< $errorCatch; 
then
zenity --error --text="$driveName SG_IO Error!" 
fi; 

if grep "dd:" <<< $errorCatch; 
then
zenity --error --text="$driveName DD Error! Check Logs!" 
else
zenity --info --text="$driveName Successfully Erased."
fi; 

# If the erase failed, prompt to start a block wipe.
else
if zenity --question --text="Erase Failed for $driveName (check error log). Block wipe?"; 
then
sudo nwipe --exclude=/dev/sda --autonuke --nogui --method=quick $driveName | pv -f "$driveName" 2>&1 | zenity --progress --auto-kill --title="$driveName nwipe" --text="Progress: " --time-remaining 
fi; 

fi; 

fi; 

}

# Returns the percentage of time that has passed sinced called (pass in parameter $1 - minutes to set the number of minutes for the timer) 
countdown() {
# Only parameter is number of minutes
seconds=$(( $1 * 60 )) 
count=1

while ! [ $seconds -eq 0 ]; 
do 
percentage=$(( ( $count * 100 ) / $seconds ))
echo $percentage
count=$(( $count + 1 )) 
sleep 1
done; 
}

dinfo() {

echo -e "______________________________________________________________________________"
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

drive5state=`2>/dev/null hdparm -I /dev/sdf | grep frozen`
drive5SMART=`smartctl -a /dev/sdf | grep -A 4 "SMART support"`
if [ -z "$drive5state" ]; then echo -e "\n/dev/sdf: NOT FOUND \n______________________________________________________________________________"; else
echo -e "/dev/sdf: $drive5state \n "`2>/dev/null hdparm -i /dev/sdf | grep Model`" \n $drive5SMART \n______________________________________________________________________________ \n"; fi; 

drive6state=`2>/dev/null hdparm -I /dev/sdg | grep frozen`
drive6SMART=`smartctl -a /dev/sdg | grep -A 4 "SMART support"`
if [ -z "$drive6state" ]; then echo -e "\n/dev/sdg: NOT FOUND \n______________________________________________________________________________"; else
echo -e "/dev/sdg: $drive6state \n "`2>/dev/null hdparm -i /dev/sdg | grep Model`" \n $drive6SMART \n______________________________________________________________________________ \n"; fi; 

drive7state=`2>/dev/null hdparm -I /dev/sdh | grep frozen`
drive7SMART=`smartctl -a /dev/sdh | grep -A 4 "SMART support"`
if [ -z "$drive7state" ]; then echo -e "\n/dev/sdg: NOT FOUND \n______________________________________________________________________________"; else
echo -e "/dev/sdh: $drive7state \n "`2>/dev/null hdparm -i /dev/sdh | grep Model`" \n $drive7SMART \n______________________________________________________________________________ \n"; fi; 

drive8state=`2>/dev/null hdparm -I /dev/sdi | grep frozen`
drive8SMART=`smartctl -a /dev/sdi | grep -A 4 "SMART support"`
if [ -z "$drive4state" ]; then echo -e "\n/dev/sdi: NOT FOUND \n______________________________________________________________________________"; else
echo -e "/dev/sdi: $drive8state \n "`2>/dev/null hdparm -i /dev/sdi | grep Model`" \n $drive8SMART \n______________________________________________________________________________ \n"; fi; 
}

# Export functions for parallel processing implementation
export -f derase 
export -f countdown
export -f zenity 


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
d5e=0
d6e=0
d7e=0
d8e=0

clear 

if grep -q "not" <<< "$drive1state"; then echo "/dev/sdb OK..."; d1e=1; else echo "/dev/sdb not working..."; fi; 
if grep -q "not" <<< "$drive2state"; then echo "/dev/sdc OK..."; d2e=1; else echo "/dev/sdc not working..."; fi; 
if grep -q "not" <<< "$drive3state"; then echo "/dev/sdd OK..."; d3e=1; else echo "/dev/sdd not working..."; fi; 
if grep -q "not" <<< "$drive4state"; then echo "/dev/sde OK..."; d4e=1; else echo "/dev/sde not working..."; fi; 
if grep -q "not" <<< "$drive5state"; then echo "/dev/sdf OK..."; d4e=1; else echo "/dev/sdf not working..."; fi; 
if grep -q "not" <<< "$drive6state"; then echo "/dev/sdg OK..."; d4e=1; else echo "/dev/sdg not working..."; fi; 
if grep -q "not" <<< "$drive7state"; then echo "/dev/sdh OK..."; d4e=1; else echo "/dev/sdh not working..."; fi; 
if grep -q "not" <<< "$drive8state"; then echo "/dev/sdi OK..."; d4e=1; else echo "/dev/sdi not working..."; fi; 

echo -e "continuing with erase for OK drives (press Ctrl + C to abort)..."
sleep 2

clear 
dinfo

echo -e "SETTING PASSWORDS ON DRIVES AND ISSUING SECURE ERASE COMMANDS \n (Sector location: $randomLocation)" 
echo -e "______________________________________________________________________________ \n"

# Simultaneously wipe ALL drives, based on whether or not they are frozen. 
parallel --link --lb -j8 ::: derase ::: $d1e $d2e $d3e $d4e $d5e $d6e $d7e $d8e ::: 1 2 3 4 5 6 7 8 ::: $randomLocation ::: 1000000
if zenity --question --text="Return to Drive List?"; 
then 
exec "$scriptLoc"
else
exit
fi
