# pve-tools-remote
remote Proxmox VE Tools dari komputer lain

# Cara Penggunaan:
## Donwload script:
```bash
git clone https://github.com/abdurrozakskom/pve-tools-remote.git
cd pve-tools-remote
chmod +x *.sh
chmod +x pve-tools-remote.sh install-pve-remote.sh setup-pve-remote.sh
```

## Install tools:
```bash
./setup-pve-remote.sh
# atau
pve-remote --setup
```

## Jalankan tools:
```bash
pve-remote
```

# Fitur Remote Version:
```bash
✅ SSH Key Authentication - Otomatis generate dan setup SSH key
✅ Error Handling - Handle koneksi gagal dengan lebih baik
✅ Connection Testing - Test koneksi sebelum eksekusi command
✅ Better Logging - Logging yang lebih informatif
✅ User Friendly - Pesan error dan success yang jelas
✅ Auto-retry - Option untuk setup SSH key jika koneksi gagal
✅ Configuration Management - Simpan dan load config
✅ Status Monitoring - Cek status koneksi
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



