#!/bin/bash

# SSH Key Setup Helper untuk Proxmox VE Remote Tools

echo "🔑 SSH Key Setup Helper untuk Proxmox VE Remote"
echo "════════════════════════════════════════════════"

# Cek apakah SSH key sudah ada
if [[ -f "$HOME/.ssh/id_rsa" ]] || [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    echo "✅ SSH key sudah ditemukan"
    ls -la ~/.ssh/id_*
else
    echo "📝 Generating new SSH key..."
    read -p "Masukkan email untuk SSH key: " ssh_email
    ssh-keygen -t rsa -b 4096 -C "$ssh_email" -f ~/.ssh/id_rsa
fi

echo ""
echo "📋 SSH Public Key Anda:"
echo "════════════════════════════════════════════════"
cat ~/.ssh/id_rsa.pub

echo ""
echo "🚀 Petunjuk Copy SSH Key ke Proxmox VE:"
echo "════════════════════════════════════════════════"
echo "1. Login ke Proxmox VE server"
echo "2. Edit file: /root/.ssh/authorized_keys"
echo "3. Paste public key di atas ke file tersebut"
echo "4. Atau jalankan: ssh-copy-id -i ~/.ssh/id_rsa.pub root@proxmox-host"
echo ""
echo "🔒 Pastikan permission file benar:"
echo "   chmod 700 ~/.ssh"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "✅ Setup SSH key selesai!"