#!/bin/bash

# Request sudo privileges
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

# Set directory for storing integrity data
SEC_DIR="sec"  # Change this to your preferred directory

sudo dpkg -l | grep -qw dmidecode || sudo apt-get install dmidecode -y
sudo dpkg -l | grep -qw nvme-cli || sudo apt install nvme-cli -y
sudo dpkg -l | grep -qw tpm2-tools || sudo apt install tpm2-tools -y

echo "Collecting system data..."

# Create directory if it doesn't exist
mkdir -p "$SEC_DIR"

# Define variables
nvme=/dev/nvme0n1

# Collect and store SHA512 checksums of /boot and /efi
echo "Storing sha512sum of /boot and /efi..."
sudo find /boot -type f -exec sha512sum "{}" + | sudo tee "$SEC_DIR/sha512sum_list_boot_orig.txt" > /dev/null 2>&1

# Collect BIOS info
echo "Storing BIOS info..."
sudo dmidecode --type bios | sudo tee "$SEC_DIR/bios_info_orig.txt" > /dev/null 2>&1
sudo tail -n +2 "$SEC_DIR/bios_info_orig.txt" | sudo tee temp.tmp > /dev/null 2>&1 && sudo mv temp.tmp "$SEC_DIR/bios_info_orig.txt" > /dev/null 2>&1

# Collect SSD info
echo "Storing SSD info..."
sudo nvme id-ctrl $nvme | grep -A 2 'sn' | sudo tee "$SEC_DIR/ssd_orig.txt" > /dev/null 2>&1

# Collect TPM PCR 0 hashes
#echo "Storing TPM PCR 0 info..."
#sudo tpmtool eventlog dump | grep -A 3 'PCR: 0' | sudo tee "$SEC_DIR/tpm.bootguard_orig.txt" > /dev/null 2>&1
#
# Collect TPM PCR 8 hashes
#echo "Storing TPM PCR 8 info..."
#sudo tpmtool eventlog dump | grep -E -A 1 -B 2 "initrd /" | sudo tee "$SEC_DIR/tpm.kernel_orig.txt" > /dev/null 2>&1

sudo tpm2_pcrread > "$SEC_DIR/tpm_pcr_values.txt" 2>/dev/null || echo "No TPM found" > "$SEC_DIR/tpm_pcr_values.txt"

sudo tpm2_pcrread sha1:0,8 > "$SEC_DIR/tpm_pcr_values2.txt" 2>/dev/null || echo "No TPM found" > "$SEC_DIR/tpm_pcr_values2.txt"
sudo tpm2_pcrread sha256:0,8 > "$SEC_DIR/tpm_pcr_values3.txt" 2>/dev/null || echo "No TPM found" > "$SEC_DIR/tpm_pcr_values3.txt"

echo "Data collection complete."

