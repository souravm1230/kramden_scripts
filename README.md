# kramden_scripts
Python eBay and Sourav Secure Erase Packages

This is a software package developed by Sourav Mahanty, designed to secure erase disk, ssd, and nvme storage devices. The nvme wipe program is entirely graphical, with no need for command line access. The disk-wipe utility requires a terminal to run, but still has zenity GUI elements embedded, so progress, verification, and end results are displayed in dialog boxes. 

- In order to run nvme-wipe, make sure that you completely power off the machine first and attach all nvme drives. Since most nvme memory is not hot-swappable, you will need to power cycle the machine whenever you change drives.
    - After attaching drives and booting into ubuntu, open up a new terminal window, and run the nvme-wipe executable file (./nvme-wipe.sh) with sudo privileges (** THIS IS VERY IMPORTANT!! If you don't run as sudo it will not detect any drives becuase of permission erros). Using a standard loaded ubuntu drive with Sourav's Secure Erase, the default location is /home/owner/Desktop/nvme-wipe/nvme-wipe.sh. 
    - Next, you will be prompted with a graphical list that displays all the drives connected to the machine, with a checkbox option on the left side. There are three buttons: exit, erase, and refresh list. They all do exactly what their names imply. Select which drives to erase and click erase to start the erase process. Click refresh list to refresh the drive list in case one of your nvmes is not showing up. When clicking exit, you will have to select "no" when it prompts to return you to the drive menu in order to terminate the program. 
    - After pressing erase, wait for a dialog window to pop up for EACH drive. Currently there is no progres bar (as nvme wipes are almost instant). The program will display a dialog indicating that the erase for a specific drive either succesfully completed or failed. 

- Disk wipe is another utility included with the SSE package, and this allows you to erase ATA drives (ssds and mechanical drives). 
    - Disk wipe requires a terminal environment. Open a terminal, and with sudo privileges execute the task.sh file in the disk-wipe folder. The default location for the ubuntu drive is /home/owner/Desktop/disk-wipe/task.sh. Ensure that the folder with task.sh contains a subdirectory with error txt files for each drive, as well as a file called "Random_Hex_Bytes.txt" which should contain about 1 GB of random hex data. 
    - After launching disk wipe, you will see that the terminal displays all currently connected drives (disk-wipe supports up to 8 simultaneous drives). The first prompt asks if you want a system suspend. This option will allow you to possibly un-freeze connected drives through a suspend and re-wake, but if your drives say not frozen, skip this step. After the prompt for suspend, click no again for refresh drive list unless you don't see a connected drive. 
    - After clicking no to refresh drive list, disk-wipe will give you a short transition screen displaying which drives will be wiped. You can press ctrl + c at this step to cancel the wipe for any reason. After these 2 seconds pass, the program will list all drive names and serial numbers, and then begin the wipe process. 
    - You will see dialogs for successful verification block writes, as well as an estimated time progress bar during the erase. At the end, all errors are logged to the drives respective error file, and the program displays a dialog for either a successful or failed erase. If your secure erase fails, you can immediately begin a block wipe by selecting yes to the prompt, or exit the wipe stage of the program and return to the drive list or exit. 

*** IMPORTANT DISCLAIMERS *** 
- This program does not do a full verification pass, instead opting for a user-defined verification block size. This speeds up the erase process, but theoretically a drive might not have all its data erased. Please keep this in mind when using this program. 
- 

