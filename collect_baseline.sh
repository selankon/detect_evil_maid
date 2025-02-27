#!/bin/bash
# collect_baseline.sh - Collects system integrity data for Evil Maid detection
# Run this script once on a trusted system

BASELINE_DIR="evil_maid_protection"
mkdir -p "$BASELINE_DIR"

echo "[+] Collecting Bootloader & Kernel Hashes..."
sha256sum /boot/* > "$BASELINE_DIR/boot_hashes.txt"

echo "[+] Collecting Secure Boot & Firmware Info..."
mokutil --list-enrolled > "$BASELINE_DIR/secure_boot_keys.txt"
fwupdmgr get-devices > "$BASELINE_DIR/firmware_info.txt"

echo "[+] Dumping LUKS Header Info..."
cryptsetup luksDump /dev/sda2 > "$BASELINE_DIR/luks_header.txt"

echo "[+] Collecting Partition Layout..."
fdisk -l > "$BASELINE_DIR/partition_info.txt"

echo "[+] Collecting TPM Measurements (If Available)..."
tpm2_pcrread > "$BASELINE_DIR/tpm_pcr_values.txt" 2>/dev/null || echo "No TPM found" > "$BASELINE_DIR/tpm_pcr_values.txt"

echo "[+] Baseline collection complete. Store this directory securely!"

