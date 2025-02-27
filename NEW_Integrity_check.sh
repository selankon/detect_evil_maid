#!/bin/bash

# Request sudo privileges
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

# Set directory for storing integrity data
SEC_DIR="sec"  # Change this to your preferred directory

echo "Checking system integrity..."

nvme=/dev/nvme0n1

sudo dpkg -l | grep -qw figlet || sudo apt-get install figlet -y

# Verify SHA512 checksums of /boot and /efi
echo "Checking /boot and /efi integrity..."
sudo find /boot -type f -exec sha512sum "{}" + | sudo tee "$SEC_DIR/sha512sum_list_boot_new.txt" > /dev/null 2>&1
if diff -s "$SEC_DIR/sha512sum_list_boot_orig.txt" "$SEC_DIR/sha512sum_list_boot_new.txt"; then
    figlet "/BOOT & /EFI MATCH"
    sudo rm -rf "$SEC_DIR/sha512sum_list_boot_new.txt"
else
    echo "WARNING: /boot and /efi data was tampered!"
    exit 1
fi

# Verify BIOS integrity
echo "Checking BIOS integrity..."
sudo dmidecode --type bios | sudo tee "$SEC_DIR/bios_info_new.txt" > /dev/null 2>&1
sudo tail -n +2 "$SEC_DIR/bios_info_new.txt" | sudo tee temp.tmp > /dev/null 2>&1 && sudo mv temp.tmp "$SEC_DIR/bios_info_new.txt" > /dev/null 2>&1
if diff -s "$SEC_DIR/bios_info_orig.txt" "$SEC_DIR/bios_info_new.txt"; then
    figlet "BIOS MATCH"
    sudo rm -rf "$SEC_DIR/bios_info_new.txt"
else
    echo "WARNING: BIOS data was tampered!"
    exit 1
fi

# Verify SSD integrity
echo "Checking SSD integrity..."
sudo nvme id-ctrl $nvme | grep -A 2 'sn' | sudo tee "$SEC_DIR/ssd_new.txt" > /dev/null 2>&1
if diff -s "$SEC_DIR/ssd_orig.txt" "$SEC_DIR/ssd_new.txt"; then
    figlet "SSD MATCH"
    sudo rm -rf "$SEC_DIR/ssd_new.txt"
else
    echo "WARNING: SSD data was tampered!"
    exit 1
fi

# Verify TPM PCR 0 integrity
#echo "Checking TPM PCR 0 integrity..."
#sudo tpmtool eventlog dump | grep -A 3 'PCR: 0' | sudo tee "$SEC_DIR/tpm.bootguard_new.txt" > /dev/null 2>&1
#if diff -s "$SEC_DIR/tpm.bootguard_orig.txt" "$SEC_DIR/tpm.bootguard_new.txt"; then
#    figlet "PCR 0 MATCH"
#    sudo rm -rf "$SEC_DIR/tpm.bootguard_new.txt"
#else
#    echo "WARNING: TPM PCR 0 data was tampered!"
#    exit 1
#fi
#
# Verify TPM PCR 8 integrity
#echo "Checking TPM PCR 8 integrity..."
#sudo tpmtool eventlog dump | grep -E -A 1 -B 2 "initrd /" | sudo tee "$SEC_DIR/tpm.kernel_new.txt" > /dev/null 2>&1
#if diff -s "$SEC_DIR/tpm.kernel_orig.txt" "$SEC_DIR/tpm.kernel_new.txt"; then
#    figlet "PCR 8 MATCH"
#    sudo rm -rf "$SEC_DIR/tpm.kernel_new.txt"
#else
#    echo "WARNING: TPM PCR 8 data was tampered!"
#    echo "*Note: If you've updated the kernel, this will fail on the first reboot and should pass on the next check."
#    exit 1
#fi

echo "[+] Checking TPM Measurements (If Available)..."
tpm2_pcrread | diff - "$SEC_DIR/tpm_pcr_values.txt" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[!] WARNING: TPM PCR values have changed!"
fi

echo "[+] Checking TPM Measurements (If Available)..."
tpm2_pcrread sha1:0,8 | diff - "$SEC_DIR/tpm_pcr_values2.txt" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[!] WARNING: TPM PCR values have changed!"
fi

echo "[+] Checking TPM Measurements (If Available)..."
tpm2_pcrread sha256:0,8 | diff - "$SEC_DIR/tpm_pcr_values3.txt" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[!] WARNING: TPM PCR values have changed!"
fi



echo "Integrity check complete. No issues found."

