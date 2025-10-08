#!/bin/bash

# Proxmox VE Tools - Remote CLI Helper
# Author: System Administrator
# Version: 1.0
# Description: Remote tools untuk management CT/VM di Proxmox VE dari komputer lain

PVE_TOOLS_VERSION="1.0"
CONFIG_FILE="$HOME/.pve-remote.conf"
LOG_FILE="/tmp/pve-remote.log"

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Konfigurasi default
DEFAULT_PVE_HOST=""
DEFAULT_PVE_USER="root"
DEFAULT_SSH_PORT="22"

# Fungsi logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Fungsi untuk menampilkan header
show_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           PROXMOX VE REMOTE TOOLS v$PVE_TOOLS_VERSION           ║"
    echo "║             CLI Helper Remote untuk CT/VM               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [[ -n "$CURRENT_PVE_HOST" ]]; then
        echo -e "${CYAN}📡 Terhubung ke: ${GREEN}$CURRENT_PVE_HOST${NC} sebagai ${GREEN}$CURRENT_PVE_USER${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    fi
}

# Fungsi untuk load konfigurasi
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        CURRENT_PVE_HOST="$PVE_HOST"
        CURRENT_PVE_USER="$PVE_USER"
        CURRENT_SSH_PORT="$SSH_PORT"
    else
        CURRENT_PVE_HOST=""
        CURRENT_PVE_USER="$DEFAULT_PVE_USER"
        CURRENT_SSH_PORT="$DEFAULT_SSH_PORT"
    fi
}

# Fungsi untuk save konfigurasi
save_config() {
    cat > "$CONFIG_FILE" << EOF
PVE_HOST="$CURRENT_PVE_HOST"
PVE_USER="$CURRENT_PVE_USER"
SSH_PORT="$CURRENT_SSH_PORT"
EOF
    chmod 600 "$CONFIG_FILE"
}

# Fungsi untuk test koneksi SSH
test_ssh_connection() {
    if [[ -z "$CURRENT_PVE_HOST" ]]; then
        return 1
    fi
    
    ssh -o ConnectTimeout=5 -p "$CURRENT_SSH_PORT" "$CURRENT_PVE_USER@$CURRENT_PVE_HOST" "echo 'connected'" &>/dev/null
    return $?
}

# Fungsi untuk execute command remote
execute_remote() {
    local command="$1"
    ssh -p "$CURRENT_SSH_PORT" "$CURRENT_PVE_USER@$CURRENT_PVE_HOST" "$command"
}

# Fungsi untuk setup koneksi
setup_connection() {
    show_header
    echo -e "${YELLOW}🔧 SETUP KONEKSI PROXMOX VE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    read -p "Masukkan alamat Proxmox VE host [${CURRENT_PVE_HOST:-$DEFAULT_PVE_HOST}]: " input_host
    read -p "Masukkan username [${CURRENT_PVE_USER:-$DEFAULT_PVE_USER}]: " input_user
    read -p "Masukkan SSH port [${CURRENT_SSH_PORT:-$DEFAULT_SSH_PORT}]: " input_port
    
    CURRENT_PVE_HOST="${input_host:-$CURRENT_PVE_HOST}"
    CURRENT_PVE_USER="${input_user:-$CURRENT_PVE_USER}"
    CURRENT_SSH_PORT="${input_port:-$CURRENT_SSH_PORT}"
    
    # Set default jika masih kosong
    CURRENT_PVE_HOST="${CURRENT_PVE_HOST:-$DEFAULT_PVE_HOST}"
    CURRENT_PVE_USER="${CURRENT_PVE_USER:-$DEFAULT_PVE_USER}"
    CURRENT_SSH_PORT="${CURRENT_SSH_PORT:-$DEFAULT_SSH_PORT}"
    
    save_config
    
    echo -e "\n${BLUE}Testing koneksi ke $CURRENT_PVE_HOST...${NC}"
    if test_ssh_connection; then
        echo -e "${GREEN}✅ Koneksi berhasil!${NC}"
        log "Connected to $CURRENT_PVE_HOST as $CURRENT_PVE_USER"
    else
        echo -e "${RED}❌ Koneksi gagal! Periksa setting dan koneksi jaringan.${NC}"
        return 1
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan daftar VM/CT remote
list_containers_remote() {
    show_header
    echo -e "${YELLOW}📋 DAFTAR CONTAINER (LXC) - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    execute_remote "pct list" | awk '
    BEGIN { printf "%-8s %-20s %-12s %-15s %-10s\n", "ID", "Nama", "Status", "IP", "Memori" }
    NR>1 { printf "%-8s %-20s %-12s %-15s %-10s\n", $1, $2, $3, $4, $5 }
    '
    
    echo -e "\n${YELLOW}🖥️  DAFTAR VIRTUAL MACHINE (QEMU) - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    execute_remote "qm list" | awk '
    BEGIN { printf "%-8s %-20s %-12s %-8s %-12s %-10s\n", "ID", "Nama", "Status", "CPU", "Memori", "Disk" }
    NR>1 { printf "%-8s %-20s %-12s %-8s %-12s %-10s\n", $1, $2, $3, $4, $5, $6 }
    '
}

# Fungsi untuk menampilkan resource usage remote
show_resources_remote() {
    show_header
    echo -e "${YELLOW}📊 STATUS RESOURCE NODE - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    # CPU Usage
    cpu_usage=$(execute_remote "mpstat 1 1 | awk '\$12 ~ /[0-9.]+/ { print 100 - \$12 }' | tail -1")
    echo -e "CPU Usage: ${GREEN}$cpu_usage%${NC}"
    
    # Memory Usage
    mem_info=$(execute_remote "free -h | awk '/Mem:/ {print \$2, \$3, \$3/\$2*100}'")
    mem_total=$(echo "$mem_info" | awk '{print $1}')
    mem_used=$(echo "$mem_info" | awk '{print $2}')
    mem_percent=$(echo "$mem_info" | awk '{printf \"%.1f\", $3}')
    echo -e "Memory: ${GREEN}$mem_used${NC} / $mem_total ($mem_percent%)"
    
    # Disk Usage
    disk_usage=$(execute_remote "df -h / | awk 'NR==2 {print \$5 \" used (\" \$3 \" / \" \$2 \")\"}'")
    echo -e "Disk: ${GREEN}$disk_usage${NC}"
    
    echo -e "\n${YELLOW}🏃 CONTAINER/VM YANG SEDANG BERJALAN - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    # Running containers
    running_ct=$(execute_remote "pct list | grep running | wc -l")
    total_ct=$(execute_remote "pct list | tail -n +2 | wc -l")
    echo -e "Container: ${GREEN}$running_ct${NC} / $total_ct berjalan"
    
    # Running VMs
    running_vm=$(execute_remote "qm list | grep running | wc -l")
    total_vm=$(execute_remote "qm list | tail -n +2 | wc -l")
    echo -e "VM: ${GREEN}$running_vm${NC} / $total_vm berjalan"
}

# Fungsi untuk start container/VM remote
start_container_remote() {
    show_header
    echo -e "${YELLOW}🚀 START CONTAINER/VM - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    list_containers_remote
    echo
    read -p "Masukkan ID Container/VM yang akan di-start: " target_id
    
    if [[ -z "$target_id" ]]; then
        echo -e "${RED}ID tidak boleh kosong!${NC}"
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    if execute_remote "pct list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Starting Container $target_id...${NC}"
        execute_remote "pct start $target_id"
        log "Started container $target_id on $CURRENT_PVE_HOST"
    elif execute_remote "qm list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Starting VM $target_id...${NC}"
        execute_remote "qm start $target_id"
        log "Started VM $target_id on $CURRENT_PVE_HOST"
    else
        echo -e "${RED}ID $target_id tidak ditemukan!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk stop container/VM remote
stop_container_remote() {
    show_header
    echo -e "${YELLOW}🛑 STOP CONTAINER/VM - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    list_containers_remote
    echo
    read -p "Masukkan ID Container/VM yang akan di-stop: " target_id
    
    if [[ -z "$target_id" ]]; then
        echo -e "${RED}ID tidak boleh kosong!${NC}"
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    if execute_remote "pct list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Stopping Container $target_id...${NC}"
        execute_remote "pct stop $target_id"
        log "Stopped container $target_id on $CURRENT_PVE_HOST"
    elif execute_remote "qm list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Stopping VM $target_id...${NC}"
        execute_remote "qm stop $target_id"
        log "Stopped VM $target_id on $CURRENT_PVE_HOST"
    else
        echo -e "${RED}ID $target_id tidak ditemukan!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk restart container/VM remote
restart_container_remote() {
    show_header
    echo -e "${YELLOW}🔄 RESTART CONTAINER/VM - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    list_containers_remote
    echo
    read -p "Masukkan ID Container/VM yang akan di-restart: " target_id
    
    if [[ -z "$target_id" ]]; then
        echo -e "${RED}ID tidak boleh kosong!${NC}"
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    if execute_remote "pct list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Restarting Container $target_id...${NC}"
        execute_remote "pct restart $target_id"
        log "Restarted container $target_id on $CURRENT_PVE_HOST"
    elif execute_remote "qm list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Restarting VM $target_id...${NC}"
        execute_remote "qm reset $target_id"
        log "Restarted VM $target_id on $CURRENT_PVE_HOST"
    else
        echo -e "${RED}ID $target_id tidak ditemukan!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk melihat detail container/VM remote
show_details_remote() {
    show_header
    echo -e "${YELLOW}📄 DETAIL CONTAINER/VM - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    list_containers_remote
    echo
    read -p "Masukkan ID Container/VM: " target_id
    
    if [[ -z "$target_id" ]]; then
        echo -e "${RED}ID tidak boleh kosong!${NC}"
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    if execute_remote "pct list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "\n${GREEN}Detail Container $target_id:${NC}"
        echo "──────────────────────────────────────────────────"
        execute_remote "pct config $target_id" | grep -E "(hostname|memory|cores|net|rootfs)" | head -10
    elif execute_remote "qm list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "\n${GREEN}Detail VM $target_id:${NC}"
        echo "──────────────────────────────────────────────────"
        execute_remote "qm config $target_id" | grep -E "(name|memory|cores|net|scsi)" | head -10
    else
        echo -e "${RED}ID $target_id tidak ditemukan!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk backup container/VM remote
backup_container_remote() {
    show_header
    echo -e "${YELLOW}💾 BACKUP CONTAINER/VM - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    list_containers_remote
    echo
    read -p "Masukkan ID Container/VM yang akan di-backup: " target_id
    
    if [[ -z "$target_id" ]]; then
        echo -e "${RED}ID tidak boleh kosong!${NC}"
        return
    fi
    
    read -p "Masukkan nama file backup (tanpa ekstensi): " backup_name
    
    if [[ -z "$backup_name" ]]; then
        backup_name="backup_${target_id}_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Cek apakah ID termasuk container atau VM
    if execute_remote "pct list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Creating backup for Container $target_id...${NC}"
        execute_remote "vzdump $target_id --dumpdir /var/lib/vz/dump/ --mode snapshot --compress zstd --storage local"
        log "Backed up container $target_id on $CURRENT_PVE_HOST to $backup_name"
    elif execute_remote "qm list | awk '{print \$1}'" | grep -q "^$target_id$"; then
        echo -e "${BLUE}Creating backup for VM $target_id...${NC}"
        execute_remote "vzdump $target_id --dumpdir /var/lib/vz/dump/ --mode suspend --compress zstd --storage local"
        log "Backed up VM $target_id on $CURRENT_PVE_HOST to $backup_name"
    else
        echo -e "${RED}ID $target_id tidak ditemukan!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk melihat logs remote
view_logs_remote() {
    show_header
    echo -e "${YELLOW}📋 LOGS SISTEM - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    echo -e "${CYAN}Pilih log yang ingin dilihat:${NC}"
    echo "1. System Log (journalctl)"
    echo "2. PVE Task Log"
    echo "3. Auth Log"
    echo "4. Syslog"
    echo "5. Kembali ke menu utama"
    
    read -p "Pilih option [1-5]: " log_option
    
    case $log_option in
        1)
            echo -e "\n${GREEN}System Log (50 lines terakhir):${NC}"
            execute_remote "journalctl -n 50 --no-pager"
            ;;
        2)
            echo -e "\n${GREEN}PVE Task Log:${NC}"
            execute_remote "tail -50 /var/log/pve/tasks/index"
            ;;
        3)
            echo -e "\n${GREEN}Auth Log:${NC}"
            execute_remote "tail -50 /var/log/auth.log"
            ;;
        4)
            echo -e "\n${GREEN}Syslog:${NC}"
            execute_remote "tail -50 /var/log/syslog"
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan menu utama
show_menu() {
    echo -e "\n${GREEN}📝 MENU UTAMA REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    if [[ -z "$CURRENT_PVE_HOST" ]] || ! test_ssh_connection; then
        echo -e "${RED}❌ Tidak terhubung ke Proxmox VE${NC}"
        echo -e "${BLUE}1.${NC} 🔧 Setup Koneksi Proxmox VE"
    else
        echo -e "${GREEN}✅ Terhubung ke: $CURRENT_PVE_HOST${NC}"
        echo -e "${BLUE}1.${NC} 🔧 Ganti/Setup Koneksi"
        echo -e "${BLUE}2.${NC} 📋 List semua Container/VM"
        echo -e "${BLUE}3.${NC} 📊 Status Resource Node"
        echo -e "${BLUE}4.${NC} 🚀 Start Container/VM"
        echo -e "${BLUE}5.${NC} 🛑 Stop Container/VM"
        echo -e "${BLUE}6.${NC} 🔄 Restart Container/VM"
        echo -e "${BLUE}7.${NC} 📄 Detail Container/VM"
        echo -e "${BLUE}8.${NC} 💾 Backup Container/VM"
        echo -e "${BLUE}9.${NC} 📋 View System Logs"
    fi
    echo -e "${BLUE}0.${NC} 🚪 Exit"
    echo "══════════════════════════════════════════════════════════"
}

# Main function
main() {
    # Load konfigurasi
    load_config
    
    # Create log file if not exists
    touch "$LOG_FILE"
    
    # Log startup
    log "Proxmox VE Remote Tools started"
    
    while true; do
        show_header
        show_menu
        
        if [[ -z "$CURRENT_PVE_HOST" ]] || ! test_ssh_connection; then
            read -p "Pilih menu [0-1]: " choice
        else
            read -p "Pilih menu [0-9]: " choice
        fi
        
        case $choice in
            1)
                setup_connection
                ;;
            2)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    list_containers_remote
                    read -p "Press Enter to continue..."
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    show_resources_remote
                    read -p "Press Enter to continue..."
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    start_container_remote
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    stop_container_remote
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    restart_container_remote
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    show_details_remote
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    backup_container_remote
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            9)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    view_logs_remote
                else
                    echo -e "${RED}Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0)
                echo -e "${GREEN}Terima kasih telah menggunakan Proxmox VE Remote Tools!${NC}"
                log "Proxmox VE Remote Tools stopped"
                exit 0
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid! Silakan coba lagi.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Trap untuk handle Ctrl+C
trap 'echo -e "\n${RED}Script diinterupsi. Keluar...${NC}"; log "Script interrupted by user"; exit 1' INT

# Jalankan main function
main "$@"