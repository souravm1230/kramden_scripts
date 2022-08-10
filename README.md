# kramden_scripts
Python eBay and Sourav Secure Erase Packages

This is the first version of the GUI package for Sourav's Secure Erase. 

This GUI program will allow you to easily erase all the drives attached to the installed ubuntu disk, without ever wiping the installed OS disk. 

The script is designed to run on startup, which can easily be done by creating a file in /bin that executes a "sudo (pathnamehere)" command to start the program. With this file in the bin, you can run the gui from anywhere by typing the name of your saved file in /bin into a terminal. After you are able to do this, open gnome startup applications (you can run "sudo apt-get install gnome-startup-applications" to install if it is not already). Add a startup profile, and name it whatever you please. In the command line, enter the name of the file you put in /bin. That's it. Now the GUI for SSE will open automatically after login every time you boot the PC. 

The application has several features that you may or may not need to use. To refresh the drive list, click refresh list. To try un-freezing drives, you can click to sleep button to sleep and re-wake the computer for 5 seconds as an attempt to un-freeze drives. Lastly, you can click exit to break the program loop and terminate the processes. 

The main button, erase ALL, will execute a secure erase operation for all drives listed. DO NOT press this button until you are 100% positive that ALL drives listed should be erased. You CANNOT select drives with this application, it simply wipes all non-OS drives attached to the system. Because of this, make sure to double-check, as there is no going back. 

After clicking erase ALL, you should notice that several progress windows will pop up with estimated progress and time remaining. During the wipe process, errors are discreetly caught and thrown into a subdirectory on the desktop, /disk-wipe/errors, which contains files names errorSDX, where X is the drive letter for the corresponding drive. These files reset after each program loop. 

After all drives successfully or unsuccessfully have secure erase commands issued, verification takes place. There might be a period of time where nothing is on the screen, but REST ASSURED that the program is still running. You will need to give it a bit of time to write the verification sequences and corresponding secure erase results to tmp files. The program will auto-detect errors with erases, including dd, SG_IO, and incomplete data wiping. 

At the end of the erase sequence, you will see a text dialog window that contains the erase results. Each drive's serial number is printed, as well as the erase results or error that was caught. REMEMBER TO CHECK ANY LOG FILES BEFORE CLIKING OK!! After you click OK on the dialog window, all tmp and error logs are erased, and the program prepares to wipe new drives. 
