#!/bin/bash

# To run at startup and enable the old network interfaces: 
# - download check.desktop, edit with your username and and copy into ~/.config/autostart  
# - sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&net.ifnames=0 biosdevname=0 /' /etc/default/grub  && sudo update-grub                                                                                           

#------------------------------------------Pre-steps---------------------------------------------------------------#

# Enable leds, I need it on my keyboard... uncomment the next line if you need it too
# xset led 3
 
# Ask for sudo privileges
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

# Run apt update
if ping -c1 www.google.com > /dev/null 2>&1; then
    echo "updating"
    sudo apt update > /dev/null 2>&1
fi

# Check requirements
sudo dpkg -l | grep -qw figlet || sudo apt-get install figlet -y
sudo dpkg -l | grep -qw dmidecode || sudo apt-get install dmidecode -y
sudo dpkg -l | grep -qw lshw || sudo apt-get install lshw -y
sudo dpkg -l | grep -qw fwupd || sudo apt-get install fwupd -y
sudo dpkg -l | grep -qw nvme-cli || sudo apt install nvme-cli -y

#tpm=$(sudo dpkg -l | grep -E  tpmtool)
#{
#if [[ -z "$tpm" ]]; then
#    wget https://github.com/9elements/tpmtool/releases/download/v3/tpmtool_3_linux_amd64.deb
#    sudo dpkg -i tpmtool_3_linux_amd64.deb
#    sudo apt-get install -f -y
#    sudo rm tpmtool_3_linux_amd64.deb
#fi
#}
#------------------------------------------Variables declaration---------------------------------------------------------------#
echo "////////////////////////////////////////////////////////////////////////////"

# nvme
nvme=/dev/nvme0n1 

# Network interfaces variables, change like you need
ethernet=eth0
wireless=wlan0

#------------------------------------------Check for previous txt---------------------------------------------------------------#
echo "Checking folders and files"

# Check if the working directory exist otherwise it will create one
mkdir -p "/sec"

# Check if the original list of sha512sums of the /boot and /efi partitions is present otherwise it will create one
if [ -f /sec/sha512sum_list_boot_orig.txt ]  
then
     echo "sha512sum_list_orig exist"
else
    echo "List sha512sum of /boot and /efi partition"
    sudo find /boot -type f -exec sha512sum "{}" + | sudo tee /sec/sha512sum_list_boot_orig.txt > /dev/null 2>&1
fi

# Check if the orginal file containing the bios infos is present otherwise it will create one
if [ -f /sec/bios_info_orig.txt ]  
then
     echo "bios_info_orig exist"
else
   echo "Extract bios infos"
   sudo dmidecode --type bios | sudo tee /sec/bios_info_orig.txt > /dev/null 2>&1
   sudo tail -n +2 '/sec/bios_info_orig.txt' | sudo tee temp.tmp > /dev/null 2>&1 && sudo mv temp.tmp '/sec/bios_info_orig.txt' > /dev/null 2>&1
fi

# Check if the orginal file containing the ssd infos is present otherwise it will create one
if [ -f /sec/ssd_orig.txt ]  
then
     echo "ssd_orig exist"
else
   echo "Extract ssd infos"
   sudo nvme id-ctrl $nvme| grep -A 2 'sn' | sudo tee /sec/ssd_orig.txt > /dev/null 2>&1
fi

# Check if the orginal file containing the tpm_pcr_0 hashes is present otherwise it will create one
#if [ -f /sec/tpm.bootguard_orig.txt ]  
#then
#     echo "tpm.bootguard_orig exist"
#else
#   echo "Extract tpm infos"
#   sudo tpmtool eventlog dump | grep -A 3 'PCR: 0' | sudo tee /sec/tpm.bootguard_orig.txt > /dev/null 2>&1
#fi
# # Check if the orginal file containing the tpm_pcr_8 hashes is present otherwise it will create one
#if [ -f /sec/tpm.kernel_orig.txt ]  
#then
#     echo "tpm.kernel_orig exist"
#else
#   echo "Extract tpm infos"
#   sudo tpmtool eventlog dump | grep -E -A 1 -B 2 "initrd /" | sudo tee /sec/tpm.kernel_orig.txt > /dev/null 2>&1
#fi
#------------------------------------------Compare old to new---------------------------------------------------------------#
echo "////////////////////////////////////////////////////////////////////////////"
# Calculate sha512sum of the /boot and /efi partitions files and compare the new txt with the old one
echo "Checking for / boot and /efi partition changes"
sudo find /boot -type f -exec sha512sum "{}" + | sudo tee /sec/sha512sum_list_boot_new.txt > /dev/null 2>&1
if diff -s /sec/sha512sum_list_boot_orig.txt /sec/sha512sum_list_boot_new.txt
then
    figlet "/BOOT & /EFI MATCH"
    sudo rm -rf /sec/sha512sum_list_boot_new.txt
else
    echo "If you have booted windows is totally normal that it's entries are different"
    while [ -z $prompt ];
    do read -p "DATA WAS TAMPERED! Continue (y/n)?" choice;
    case "$choice" in
        y|Y ) echo "skipping...";sudo rm -rf /sec/bios_info_new.txt;break;;
        n|N ) exit 0;;
    esac;
    done;
fi

echo "////////////////////////////////////////////////////////////////////////////"
# Extract the bios infos and compare them to the old txt
echo "Extract bios infos"
sudo dmidecode --type bios | sudo tee /sec/bios_info_new.txt > /dev/null 2>&1
sudo tail -n +2 '/sec/bios_info_new.txt' | sudo tee temp.tmp > /dev/null 2>&1 && sudo mv temp.tmp '/sec/bios_info_new.txt' > /dev/null 2>&1
if diff -s /sec/bios_info_orig.txt /sec/bios_info_new.txt
then
    figlet BIOS MATCH
    sudo rm -rf /sec/bios_info_new.txt
else
    while [ -z $prompt ];
    do read -p "DATA WAS TAMPERED! Continue (y/n)?" choice;
    case "$choice" in
        y|Y ) echo "skipping...";sudo rm -rf /sec/bios_info_new.txt;break;;
        n|N ) exit 0;;
    esac;
    done;
fi

echo "////////////////////////////////////////////////////////////////////////////"
# Extract the ssd infos and compare them to the old txt
echo "Extract ssd infos"
sudo nvme id-ctrl $nvme| grep -A 2 'sn' | sudo tee /sec/ssd_new.txt > /dev/null 2>&1
if diff -s /sec/ssd_orig.txt /sec/ssd_new.txt
then
    figlet SSD MATCH
    sudo rm -rf /sec/ssd_new.txt
else
    while [ -z $prompt ];
    do read -p "DATA WAS TAMPERED! Continue (y/n)?" choice;
    case "$choice" in
        y|Y ) echo "skipping...";sudo rm -rf /sec/bios_info_new.txt;break;;
        n|N ) exit 0;;
    esac;
    done;
fi

echo "////////////////////////////////////////////////////////////////////////////"
# Extract the tpm_pcr_0 hashes and compare them to the old txt
echo "Extract tpm infos"
sudo tpmtool eventlog dump | grep -A 3 'PCR: 0' | sudo tee /sec/tpm.bootguard_new.txt  > /dev/null 2>&1

if diff -s /sec/tpm.bootguard_orig.txt /sec/tpm.bootguard_new.txt 
then
    figlet PCR 0 MATCH
    sudo rm -rf /sec/tpm.bootguard_new.txt 
else
    while [ -z $prompt ];
    do read -p "DATA WAS TAMPERED! Continue (y/n)?" choice;
    case "$choice" in
        y|Y ) echo "skipping...";sudo rm -rf /sec/bios_info_new.txt;break;;
        n|N ) exit 0;;
    esac;
    done;
fi

echo "////////////////////////////////////////////////////////////////////////////"
# Extract the tpm_pcr_8 hashes and compare them to the old txt
echo "Extract tpm infos"
sudo tpmtool eventlog dump | grep -E -A 1 -B 2 "initrd /" | sudo tee /sec/tpm.kernel_new.txt > /dev/null 2>&1

if diff -s /sec/tpm.kernel_orig.txt /sec/tpm.kernel_new.txt 
then
    figlet PCR 8 MATCH
    sudo rm -rf /sec/tpm.kernel_new.txt 
else 
    echo "*Attention*: If you have upgraded the kernel, this check will fail on first reboot, because the TPM-based hash will have changed. This check will pass again after an additional reboot."
    while [ -z $prompt ];
    do read -p "DATA WAS TAMPERED! Continue (y/n)?" choice;
    case "$choice" in
        y|Y ) echo "skipping...";sudo rm -rf /sec/bios_info_new.txt;break;;
        n|N ) exit 0;;
    esac;
    done;
fi 

#------------------------------------------Recalculate hashes and store on txt---------------------------------------------------------------#
echo "////////////////////////////////////////////////////////////////////////////"
# Generate the new sha512 list because some updates can change some values
echo "Create sha512sum of the /boot partition"
sudo find /boot -type f -exec sha512sum "{}" + | sudo tee /sec/sha512sum_list_boot_orig.txt > /dev/null 2>&1

# Generate the new sha512sum because some updates can change some values
echo "Extract bios infos"
sudo rm /sec/bios_info_orig.txt
sudo dmidecode --type bios | sudo tee /sec/bios_info_orig.txt > /dev/null 2>&1
sudo tail -n +2 '/sec/bios_info_orig.txt' | sudo tee temp.tmp > /dev/null 2>&1 && sudo mv temp.tmp '/sec/bios_info_orig.txt' > /dev/null 2>&1

#Generate the new sha512sum because some updates can change some values
echo "Extract ssd infos"
sudo rm /sec/ssd_orig.txt
sudo nvme id-ctrl $nvme| grep -A 2 'sn' | sudo tee /sec/ssd_orig.txt > /dev/null 2>&1

#Generate the new tpm_pcr_0 because some updates can change some values
echo "Extract tpm infos"
sudo tpmtool eventlog dump | grep -A 3 'PCR: 0' | sudo tee /sec/tpm.bootguard_orig.txt > /dev/null 2>&1
sudo tpmtool eventlog dump | grep -E -A 1 -B 2 "initrd /" | sudo tee /sec/tpm.kernel_orig.txt > /dev/null 2>&1

echo "////////////////////////////////////////////////////////////////////////////"
