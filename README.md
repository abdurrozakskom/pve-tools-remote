# pve-tools-remote
remote Proxmox VE Tools dari komputer lain

# Cara Penggunaan:
## Donwload script:
```bash
git clone https://github.com/abdurrozakskom/pve-tools-remote.git
cd pve-tools-remote
chmod +x *.sh
```

## Install tools:
```bash
sudo ./install-pve-remote.sh
```

## Setup SSH keys (jika belum):
```bash
./setup-ssh-keys.sh
```

## Jalankan tools:
```bash
pve-remote
```

# Fitur Remote Version:
```bash
✅ Koneksi SSH ke multiple Proxmox VE hosts
✅ Konfigurasi persistensi - simpan setting koneksi
✅ Test koneksi sebelum eksekusi command
✅ Semua fitur local tersedia secara remote
✅ Logging aktivitas remote
✅ Security dengan SSH key authentication
✅ Flexible - bisa ganti host kapan saja
✅ View system logs remote
✅ Error handling untuk koneksi gagal
```

# Contoh Tampilan Remote:
```bash
╔══════════════════════════════════════════════════════════╗
║           PROXMOX VE REMOTE TOOLS v1.0           ║
║             CLI Helper Remote untuk CT/VM               ║
╚══════════════════════════════════════════════════════════╝

📡 Terhubung ke: 192.168.1.100 sebagai root
══════════════════════════════════════════════════════════

📝 MENU UTAMA REMOTE
══════════════════════════════════════════════════════════
✅ Terhubung ke: 192.168.1.100
1. 🔧 Ganti/Setup Koneksi
2. 📋 List semua Container/VM
3. 📊 Status Resource Node
4. 🚀 Start Container/VM
5. 🛑 Stop Container/VM
6. 🔄 Restart Container/VM
7. 📄 Detail Container/VM
8. 💾 Backup Container/VM
9. 📋 View System Logs
0. 🚪 Exit
══════════════════════════════════════════════════════════
Pilih menu [0-9]:
╔══════════════════════════════════════════════════════════╗
║           PROXMOX VE REMOTE TOOLS v1.0           ║
║             CLI Helper Remote untuk CT/VM               ║
╚══════════════════════════════════════════════════════════╝

📡 Terhubung ke: 192.168.1.100 sebagai root
══════════════════════════════════════════════════════════

📝 MENU UTAMA REMOTE
══════════════════════════════════════════════════════════
✅ Terhubung ke: 192.168.1.100
1. 🔧 Ganti/Setup Koneksi
2. 📋 List semua Container/VM
3. 📊 Status Resource Node
4. 🚀 Start Container/VM
5. 🛑 Stop Container/VM
6. 🔄 Restart Container/VM
7. 📄 Detail Container/VM
8. 💾 Backup Container/VM
9. 📋 View System Logs
0. 🚪 Exit
══════════════════════════════════════════════════════════
Pilih menu [0-9]:
```



