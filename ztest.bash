#!/bin/bash
scriptLoc=$(readlink -f "$0")
randomLocation=$(( $RANDOM % 1000 + 100000))
tempResults=$(mktemp /tmp/dwipe-XXXXX) 

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

dprompt() {
tempD=$1 
driveArray=$2
for i in "${driveArray[@]}"; 
do 
driveData=$(2>/dev/null sudo hdparm -I $i | grep frozen)
if grep -q "not" <<< "$driveData"; then driveState="NO"; else driveState="YES"; fi; 

driveSN=$(2>/dev/null sudo hdparm -i $i | grep Model | tr -d " " | cut -d "," -f3)
driveMN=$(2>/dev/null sudo hdparm -i $i | grep Model | tr -d " " | cut -d "," -f1) 
driveSMART=$(sudo smartctl -a $i | grep "overall-health self-assessment" | cut -c51-)
if [ -z "$driveData" ]; 
then echo "$i MISSING? N/A N/A N/A" >> $tempD; 
else 
echo "$i $driveState $driveMN $driveSN $driveSMART" >> $tempD; 
fi; 
done; 
} 

derase() {

# Variables to support up to 1 GB of verification pass
hexBytesLocation=/home/owner/Desktop/disk-wipe/Random_Hex_Bytes
errorLogFolder=/home/owner/Desktop/disk-wipe/errors
tempFile=$5
randomLocation=$3
verifyBlockNum=$4
driveName=$2

if [ $1 -eq 0 ]; then exit; else

if grep -q "/sdb" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDB; fi; 
if grep -q "/sdc" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDC; fi; 
if grep -q "/sdd" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDD; fi; 
if grep -q "/sde" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDE; fi; 
if grep -q "/sdf" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDF; fi; 
if grep -q "/sdg" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDG; fi; 
if grep -q "/sdh" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDH; fi; 
if grep -q "/sdi" <<< "$driveName"; then errorCatch=$errorLogFolder/errorSDI; fi; 

# Clear Error Log before New Wipe
echo -n "" > "$errorCatch"
estimatedMinutes=$(sudo hdparm -I $driveName | grep "SECURITY ERASE" | cut -c1-6 | tr -dc '0-9')

&>"$errorCatch" sudo hdparm --user-master u --security-unlock p $driveName
&>"$errorCatch" sudo hdparm --user-master u --security-disable p $driveName

&>"$errorCatch" sudo hdparm --user-master u --security-unlock password $driveName
&>"$errorCatch" sudo hdparm --user-master u --security-disable password $driveName

# Write verification sequence to the random location passed in through third parameter
# block size for all dd operations is 512 bytes, so multiply the num of blocks to verify by 512 to get total bytes
2>"$errorCatch" sudo dd if=$hexBytesLocation of=$driveName bs=512 count=verifyBlockNum seek=$randomLocation
zenity --notification --text="Verification Block written to $driveName" 

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
echo -e "$driveName SG_IO Error!" >> $tempFile  
fi; 

if grep "dd:" <<< $errorCatch; 
then
echo "$driveName DD Error! Check Logs!" >> $tempFile 
else 
echo -e "$driveName: `2>/dev/null sudo hdparm -i $driveName | grep Model | tr -d " " | cut -d "," -f3` : Successfully Erased. \n" >> $tempFile
fi; 

# If the erase failed, prompt to start a block wipe.
else
if zenity --question --text="Erase Failed for $driveName (check error log). Block wipe?"; 
then
sudo nwipe --exclude=/dev/sda --autonuke --nogui --method=quick $driveName | pv -f "$driveName" 2>&1 | zenity --progress --auto-kill --title="$driveName nwipe" --text="Progress: " --time-remaining 
fi; 
echo -e "$driveName: `2>/dev/null sudo hdparm -i $driveName | grep Model | tr -d " " | cut -d "," -f3` : Erase Failed! \n" >> $tempFile
fi; 

fi; 

}

export -f derase 
export -f countdown

driveArray=( "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde" "/dev/sdf" "/dev/sdg" "/dev/sdh" "/dev/sdi") 
eraseDrives=( 0 0 0 0 0 0 0 0 )
# Variable to stay inside while loop
eraseSelect=0 
while [ $eraseSelect -eq 0 ]; do 
# Create temp file for storing values
tempFile=$(mktemp /tmp/dwipe-XXXXX)

# Write the drive info to the temp file
dprompt $tempFile $driveArray

response=$(zenity --list --width=1000 --height=400 --title="Sourav's Secure Disk Erase" --cancel-label="Exit" --ok-label="Erase ALL" --extra-button="Refresh List" --extra-button="Sleep" --column="Drive Name" --column="Frozen?" --column="Model" --column="Serial #" --column="SMART Self-Assessment"  $(cat $tempFile))
retVal=$? 

# Input based flow control for zenity window
if [ $retVal -eq 0 ]; then eraseSelect=1; exit=0; else 
eraseSelect=1; 
exit=1; 
if grep -q "Refresh" <<< "$response"; then eraseSelect=0; exit=0; fi; 
if grep -q "Sleep" <<< "$response"; then sudo rtcwake -m mem -s 5; eraseSelect=0; exit=0; fi; 
fi;
done; 

if [ $exit -eq 1 ]; then exit 1; fi; 
count=0
for drive in "${driveArray[@]}"; do 
currLine=$(cat $tempFile | grep "$drive") 
frozenState=$(cat $tempFile | grep "$drive" | cut -c9-12)
if grep -q "NO" <<< "$frozenState"; then eraseDrives[$count]=1; fi; 
count=$(( $count + 1 )) 
done; 

echo "${driveArray[@]}" 
echo "${eraseDrives[@]}" 


parallel --link --lb -j8 ::: derase ::: ${eraseDrives[0]} ${eraseDrives[1]} ${eraseDrives[2]} ${eraseDrives[3]} ${eraseDrives[4]} ${eraseDrives[5]} ${eraseDrives[6]} ${eraseDrives[7]} ::: ${driveArray[0]} ${driveArray[1]} ${driveArray[2]} ${driveArray[3]} ${driveArray[4]} ${driveArray[5]} ${driveArray[6]} ${driveArray[7]} ::: $randomLocation ::: 100000 ::: $tempResults
zenity --text-info --width=800 --height=600 --filename=$tempResults --title="SSE Erase Results"

rm -f $tempResults
rm -f $tempFile

exec "$scriptLoc"
