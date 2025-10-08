#!/bin/bash

# Setup Helper untuk Proxmox VE Remote Tools

echo "🚀 PROXMOX VE REMOTE TOOLS SETUP HELPER"
echo "══════════════════════════════════════════════════════════"

# Check if pve-remote is installed
if ! command -v pve-remote &> /dev/null; then
    echo "❌ pve-remote tidak terinstall!"
    echo "Jalankan: sudo ./install-pve-remote.sh"
    exit 1
fi

echo "✅ pve-remote sudah terinstall"

# Run initial setup
echo ""
echo "🔧 Menjalankan initial setup..."
pve-remote --setup

echo ""
echo "🎉 Setup selesai!"
echo "Anda sekarang bisa menggunakan: pve-remote"
echo "Untuk bantuan: pve-remote --help"