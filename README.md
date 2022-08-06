# kramden_scripts
Python eBay and Sourav Secure Erase Packages

This is a software package developed by Sourav Mahanty, designed to secure erase disk, ssd, and nvme storage devices. The nvme wipe program is entirely graphical, with no need for command line access. The disk-wipe utility requires a terminal to run, but still has zenity GUI elements embedded, so progress, verification, and end results are displayed in dialog boxes. 

- In order to run nvme-wipe, make sure that you completely power off the machine first and attach all nvme drives. Since most nvme memory is not hot-swappable, you will need to power cycle the machine whenever you change drives.
    - After attaching drives and booting into ubuntu, open up a new terminal window, and run the nvme-wipe executable file (./nvme-wipe.sh) with sudo privileges (** THIS IS VERY IMPORTANT!! If you don't run as sudo it will not detect any drives becuase of permission erros). Using a standard loaded ubuntu drive with Sourav's Secure Erase, the default location is /home/owner/Desktop/nvme-wipe/nvme-wipe.sh. 
    - Next, you will be prompted with a graphical list that displays all the drives connected to the machine, with a checkbox option on the left side. There are three buttons: exit, erase, and refresh list. They all do exactly what their names imply. Select which drives to erase and click erase to start the erase process. Click refresh list to refresh the drive list in case one of your nvmes is not showing up. When clicking exit, you will have to select "no" when it prompts to return you to the drive menu in order to terminate the program. 
    - After pressing erase, wait for a dialog window to pop up for EACH drive. Currently there is no progres bar (as nvme wipes are almost instant). The program will display a dialog indicating that the erase for a specific drive either succesfully completed or failed. 


