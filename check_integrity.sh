#!/bin/bash
# check_integrity.sh - Checks for Evil Maid attack indicators
# Run this script on every boot, ideally as a systemd service

BASELINE_DIR="/var/lib/evil_maid_protection"
LOG_FILE="/var/log/evil_maid_check.log"
ALERT_FLAG=0

echo "[+] Checking Bootloader & Kernel Integrity..."
sha256sum -c "$BASELINE_DIR/boot_hashes.txt" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[!] WARNING: Bootloader or Kernel files have changed!" | tee -a "$LOG_FILE"
    ALERT_FLAG=1
fi

echo "[+] Checking Secure Boot & Firmware Info..."
mokutil --list-enrolled | diff - "$BASELINE_DIR/secure_boot_keys.txt" > /dev/null
if [ $? -ne 0 ]; then
    echo "[!] WARNING: Secure Boot keys have changed!" | tee -a "$LOG_FILE"
    ALERT_FLAG=1
fi

fwupdmgr get-devices | diff - "$BASELINE_DIR/firmware_info.txt" > /dev/null
if [ $? -ne 0 ]; then
    echo "[!] WARNING: Firmware information has changed!" | tee -a "$LOG_FILE"
    ALERT_FLAG=1
fi

echo "[+] Checking LUKS Header Integrity..."
cryptsetup luksDump /dev/sda2 | diff - "$BASELINE_DIR/luks_header.txt" > /dev/null
if [ $? -ne 0 ]; then
    echo "[!] WARNING: LUKS header has changed!" | tee -a "$LOG_FILE"
    ALERT_FLAG=1
fi

echo "[+] Checking Partition Table..."
fdisk -l | diff - "$BASELINE_DIR/partition_info.txt" > /dev/null
if [ $? -ne 0 ]; then
    echo "[!] WARNING: Partition layout has changed!" | tee -a "$LOG_FILE"
    ALERT_FLAG=1
fi

echo "[+] Checking TPM Measurements (If Available)..."
tpm2_pcrread | diff - "$BASELINE_DIR/tpm_pcr_values.txt" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[!] WARNING: TPM PCR values have changed!" | tee -a "$LOG_FILE"
    ALERT_FLAG=1
fi

if [ $ALERT_FLAG -ne 0 ]; then
    echo "[!!!] ALERT: Possible Evil Maid Attack detected! Check logs at $LOG_FILE"
else
    echo "[✔] No modifications detected."
fi

