#!/bin/bash

# This script is executed at the Linux VM boot, it will be called by /etc/rc.local

# NOTES:
# * This script will always be executed as root, you should not preface the commands with "sudo".
# * If you edit this script on Windows, make sure your text editor saves it with \n (LF, Linux) and not \r\n (CRLF, Windows)

# Reasons to run these commands on a separate script (this file) instead of appending them to /etc/rc.local:
#    1) /etc/rc.local first line says "#!/bin/sh -e". This means:
#            a) It uses /bin/sh (Bourne Shell) instead of /bin/bash (Bash). Bash is more powerful than Bourne Shell.
#            b) The "-e" flag will interrupt rc.local execution if any command generates
#               an error. In contrast, this Bash script will run until EOF regardless of errors.
#            c) Makes testing easier. We don't need to execute rc.local every time we want to test these commands
#            d) It's simpler and faster to manage this Bash script than to have the Vagrantfile insert commands into rc.local

# Get Vagrant shared folder mount path
VM_SHARED_FOLDER=`mount -l -t vboxsf | tail -1 | cut -d " " -f 3`

# Log this script's execution
echo "`date "+%Y-%m-%d %H:%M:%S"` - Machine booted. ${BASH_SOURCE[0]} script executed." >> /var/log/vagrant_boot.log

# Checks if the VirtualBox shared folder is mounted.
if [ ! -f ${VM_SHARED_FOLDER}/Vagrantfile ]; then
	printf "\033[1;31mCRITICAL ERROR: seems like the Vagrant shared folder (${VM_SHARED_FOLDER}) is empty (not mounted).
			Fix it and re-run \"vagrant provision\".\033[0m\n"
	exit 1  # Exit with error exit code
fi

# Start PostgreSQL
sudo service postgresql start
