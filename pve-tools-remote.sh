#!/bin/bash

# Proxmox VE Tools - Remote CLI Helper
# Author: System Administrator
# Version: 2.0
# Description: Remote tools untuk management CT/VM di Proxmox VE dari komputer lain

PVE_TOOLS_VERSION="2.0"
CONFIG_FILE="$HOME/.pve-remote.conf"
LOG_FILE="/tmp/pve-remote.log"
SSH_KEY="$HOME/.ssh/id_rsa"
SSH_OPTIONS="-o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no"

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

# Variabel global
CURRENT_PVE_HOST=""
CURRENT_PVE_USER=""
CURRENT_SSH_PORT=""

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
        log "Configuration loaded from $CONFIG_FILE"
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
    log "Configuration saved to $CONFIG_FILE"
}

# Fungsi untuk cek SSH key
check_ssh_key() {
    if [[ -f "$SSH_KEY" ]]; then
        echo -e "${GREEN}✅ SSH key ditemukan: $SSH_KEY${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  SSH key tidak ditemukan: $SSH_KEY${NC}"
        echo -e "${YELLOW}Menggunakan password authentication...${NC}"
        return 1
    fi
}

# Fungsi untuk mendapatkan parameter SSH
get_ssh_params() {
    local ssh_key_param=""
    if [[ -f "$SSH_KEY" ]]; then
        ssh_key_param="-i $SSH_KEY"
    fi
    echo "$ssh_key_param"
}

# Fungsi untuk test koneksi SSH
test_ssh_connection() {
    if [[ -z "$CURRENT_PVE_HOST" ]]; then
        echo -e "${RED}❌ Host belum di-set!${NC}"
        return 1
    fi
    
    local ssh_params=$(get_ssh_params)
    
    echo -e "${BLUE}Testing koneksi ke $CURRENT_PVE_HOST...${NC}"
    ssh $ssh_params $SSH_OPTIONS -p "$CURRENT_SSH_PORT" "$CURRENT_PVE_USER@$CURRENT_PVE_HOST" "echo 'connected'" &>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Koneksi berhasil!${NC}"
        return 0
    else
        echo -e "${RED}❌ Koneksi gagal!${NC}"
        return 1
    fi
}

# Fungsi untuk execute command remote
execute_remote() {
    local command="$1"
    local ssh_params=$(get_ssh_params)
    
    ssh $ssh_params $SSH_OPTIONS -p "$CURRENT_SSH_PORT" "$CURRENT_PVE_USER@$CURRENT_PVE_HOST" "$command"
}

# Fungsi untuk setup koneksi
setup_connection() {
    show_header
    echo -e "${YELLOW}🔧 SETUP KONEKSI PROXMOX VE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    # Cek SSH key
    check_ssh_key
    
    echo ""
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
    
    if [[ -z "$CURRENT_PVE_HOST" ]]; then
        echo -e "${RED}❌ Host tidak boleh kosong!${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    save_config
    
    # Test koneksi
    if test_ssh_connection; then
        log "Connected to $CURRENT_PVE_HOST as $CURRENT_PVE_USER"
    else
        echo -e "${YELLOW}⚠️  Koneksi gagal. Lanjutkan setup SSH key? [y/N]: ${NC}" 
        read -r setup_ssh
        if [[ "$setup_ssh" =~ ^[Yy]$ ]]; then
            setup_ssh_key
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk setup SSH key
setup_ssh_key() {
    show_header
    echo -e "${YELLOW}🔑 SETUP SSH KEY AUTHENTICATION${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    # Generate SSH key jika belum ada
    if [[ ! -f "$SSH_KEY" ]]; then
        echo -e "${BLUE}Generating SSH key...${NC}"
        ssh-keygen -t rsa -b 4096 -C "pve-remote@$(hostname)" -f "$SSH_KEY" -N ""
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ SSH key generated: $SSH_KEY${NC}"
        else
            echo -e "${RED}❌ Gagal generate SSH key!${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ SSH key sudah ada: $SSH_KEY${NC}"
    fi
    
    # Tampilkan public key
    echo -e "\n${YELLOW}📋 Public Key Anda:${NC}"
    echo "══════════════════════════════════════════════════════════"
    cat "${SSH_KEY}.pub"
    echo "══════════════════════════════════════════════════════════"
    
    # Copy key ke server
    echo -e "\n${BLUE}📤 Copying SSH key ke server...${NC}"
    ssh-copy-id -p "$CURRENT_SSH_PORT" "$CURRENT_PVE_USER@$CURRENT_PVE_HOST"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSH key berhasil di-copy ke $CURRENT_PVE_HOST${NC}"
        log "SSH key setup completed for $CURRENT_PVE_HOST"
    else
        echo -e "${YELLOW}⚠️  Gagal copy SSH key secara otomatis.${NC}"
        echo -e "${YELLOW}Manual setup required.${NC}"
        echo -e "\n${BLUE}📝 Manual Steps:${NC}"
        echo "1. Login ke $CURRENT_PVE_HOST"
        echo "2. Run: mkdir -p ~/.ssh && chmod 700 ~/.ssh"
        echo "3. Edit: nano ~/.ssh/authorized_keys"
        echo "4. Paste public key di atas"
        echo "5. Run: chmod 600 ~/.ssh/authorized_keys"
    fi
    
    # Test koneksi lagi
    echo -e "\n${BLUE}🔍 Testing koneksi dengan SSH key...${NC}"
    if test_ssh_connection; then
        echo -e "${GREEN}🎉 SSH key authentication berhasil!${NC}"
    else
        echo -e "${YELLOW}⚠️  Masih memerlukan password authentication.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan daftar VM/CT remote
list_containers_remote() {
    show_header
    echo -e "${YELLOW}📋 DAFTAR CONTAINER (LXC) - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    local container_list=$(execute_remote "pct list 2>/dev/null")
    if [ $? -eq 0 ] && [ -n "$container_list" ]; then
        echo "$container_list" | awk '
        BEGIN { printf "%-8s %-20s %-12s %-15s %-10s\n", "ID", "Nama", "Status", "IP", "Memori" }
        NR>1 { printf "%-8s %-20s %-12s %-15s %-10s\n", $1, $2, $3, $4, $5 }
        '
    else
        echo -e "${YELLOW}Tidak ada container atau gagal mengambil data${NC}"
    fi
    
    echo -e "\n${YELLOW}🖥️  DAFTAR VIRTUAL MACHINE (QEMU) - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    local vm_list=$(execute_remote "qm list 2>/dev/null")
    if [ $? -eq 0 ] && [ -n "$vm_list" ]; then
        echo "$vm_list" | awk '
        BEGIN { printf "%-8s %-20s %-12s %-8s %-12s %-10s\n", "ID", "Nama", "Status", "CPU", "Memori", "Disk" }
        NR>1 { printf "%-8s %-20s %-12s %-8s %-12s %-10s\n", $1, $2, $3, $4, $5, $6 }
        '
    else
        echo -e "${YELLOW}Tidak ada VM atau gagal mengambil data${NC}"
    fi
}

# Fungsi untuk menampilkan resource usage remote
show_resources_remote() {
    show_header
    echo -e "${YELLOW}📊 STATUS RESOURCE NODE - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    # CPU Usage
    local cpu_usage=$(execute_remote "mpstat 1 1 2>/dev/null | awk '\$12 ~ /[0-9.]+/ { print 100 - \$12 }' | tail -1")
    if [ -n "$cpu_usage" ]; then
        echo -e "CPU Usage: ${GREEN}$cpu_usage%${NC}"
    else
        echo -e "CPU Usage: ${YELLOW}Tidak tersedia${NC}"
    fi
    
    # Memory Usage
    local mem_info=$(execute_remote "free -h 2>/dev/null | awk '/Mem:/ {print \$2, \$3, \$3/\$2*100}'")
    if [ -n "$mem_info" ]; then
        local mem_total=$(echo "$mem_info" | awk '{print $1}')
        local mem_used=$(echo "$mem_info" | awk '{print $2}')
        local mem_percent=$(echo "$mem_info" | awk '{printf "%.1f", $3}')
        echo -e "Memory: ${GREEN}$mem_used${NC} / $mem_total ($mem_percent%)"
    else
        echo -e "Memory: ${YELLOW}Tidak tersedia${NC}"
    fi
    
    # Disk Usage
    local disk_usage=$(execute_remote "df -h / 2>/dev/null | awk 'NR==2 {print \$5 \" used (\" \$3 \" / \" \$2 \")\"}'")
    if [ -n "$disk_usage" ]; then
        echo -e "Disk: ${GREEN}$disk_usage${NC}"
    else
        echo -e "Disk: ${YELLOW}Tidak tersedia${NC}"
    fi
    
    echo -e "\n${YELLOW}🏃 CONTAINER/VM YANG SEDANG BERJALAN - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    # Running containers
    local running_ct=$(execute_remote "pct list 2>/dev/null | grep running | wc -l")
    local total_ct=$(execute_remote "pct list 2>/dev/null | tail -n +2 | wc -l")
    echo -e "Container: ${GREEN}$running_ct${NC} / $total_ct berjalan"
    
    # Running VMs
    local running_vm=$(execute_remote "qm list 2>/dev/null | grep running | wc -l")
    local total_vm=$(execute_remote "qm list 2>/dev/null | tail -n +2 | wc -l")
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
        echo -e "${RED}❌ ID tidak boleh kosong!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    local is_container=$(execute_remote "pct list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    local is_vm=$(execute_remote "qm list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    
    if [ "$is_container" -eq 0 ]; then
        echo -e "${BLUE}Starting Container $target_id...${NC}"
        execute_remote "pct start $target_id"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Container $target_id started successfully${NC}"
            log "Started container $target_id on $CURRENT_PVE_HOST"
        else
            echo -e "${RED}❌ Gagal start container $target_id${NC}"
        fi
    elif [ "$is_vm" -eq 0 ]; then
        echo -e "${BLUE}Starting VM $target_id...${NC}"
        execute_remote "qm start $target_id"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ VM $target_id started successfully${NC}"
            log "Started VM $target_id on $CURRENT_PVE_HOST"
        else
            echo -e "${RED}❌ Gagal start VM $target_id${NC}"
        fi
    else
        echo -e "${RED}❌ ID $target_id tidak ditemukan!${NC}"
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
        echo -e "${RED}❌ ID tidak boleh kosong!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    local is_container=$(execute_remote "pct list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    local is_vm=$(execute_remote "qm list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    
    if [ "$is_container" -eq 0 ]; then
        echo -e "${BLUE}Stopping Container $target_id...${NC}"
        execute_remote "pct stop $target_id"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Container $target_id stopped successfully${NC}"
            log "Stopped container $target_id on $CURRENT_PVE_HOST"
        else
            echo -e "${RED}❌ Gagal stop container $target_id${NC}"
        fi
    elif [ "$is_vm" -eq 0 ]; then
        echo -e "${BLUE}Stopping VM $target_id...${NC}"
        execute_remote "qm stop $target_id"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ VM $target_id stopped successfully${NC}"
            log "Stopped VM $target_id on $CURRENT_PVE_HOST"
        else
            echo -e "${RED}❌ Gagal stop VM $target_id${NC}"
        fi
    else
        echo -e "${RED}❌ ID $target_id tidak ditemukan!${NC}"
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
        echo -e "${RED}❌ ID tidak boleh kosong!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    local is_container=$(execute_remote "pct list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    local is_vm=$(execute_remote "qm list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    
    if [ "$is_container" -eq 0 ]; then
        echo -e "${BLUE}Restarting Container $target_id...${NC}"
        execute_remote "pct restart $target_id"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Container $target_id restarted successfully${NC}"
            log "Restarted container $target_id on $CURRENT_PVE_HOST"
        else
            echo -e "${RED}❌ Gagal restart container $target_id${NC}"
        fi
    elif [ "$is_vm" -eq 0 ]; then
        echo -e "${BLUE}Restarting VM $target_id...${NC}"
        execute_remote "qm reset $target_id"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ VM $target_id restarted successfully${NC}"
            log "Restarted VM $target_id on $CURRENT_PVE_HOST"
        else
            echo -e "${RED}❌ Gagal restart VM $target_id${NC}"
        fi
    else
        echo -e "${RED}❌ ID $target_id tidak ditemukan!${NC}"
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
        echo -e "${RED}❌ ID tidak boleh kosong!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Cek apakah ID termasuk container atau VM
    local is_container=$(execute_remote "pct list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    local is_vm=$(execute_remote "qm list 2>/dev/null | awk '{print \$1}' | grep -q \"^$target_id$\"; echo \$?")
    
    if [ "$is_container" -eq 0 ]; then
        echo -e "\n${GREEN}📦 Detail Container $target_id:${NC}"
        echo "──────────────────────────────────────────────────"
        execute_remote "pct config $target_id 2>/dev/null" | head -20
    elif [ "$is_vm" -eq 0 ]; then
        echo -e "\n${GREEN}🖥️  Detail VM $target_id:${NC}"
        echo "──────────────────────────────────────────────────"
        execute_remote "qm config $target_id 2>/dev/null" | head -20
    else
        echo -e "${RED}❌ ID $target_id tidak ditemukan!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk melihat logs remote
view_logs_remote() {
    show_header
    echo -e "${YELLOW}📋 LOGS SISTEM - REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    echo -e "${CYAN}Pilih log yang ingin dilihat:${NC}"
    echo "1. System Log (journalctl - last 50 lines)"
    echo "2. PVE Task Log"
    echo "3. Auth Log"
    echo "4. Syslog"
    echo "5. Container/VM Logs"
    echo "6. Kembali ke menu utama"
    
    read -p "Pilih option [1-6]: " log_option
    
    case $log_option in
        1)
            echo -e "\n${GREEN}📄 System Log (50 lines terakhir):${NC}"
            echo "──────────────────────────────────────────────────"
            execute_remote "journalctl -n 50 --no-pager 2>/dev/null"
            ;;
        2)
            echo -e "\n${GREEN}📊 PVE Task Log:${NC}"
            echo "──────────────────────────────────────────────────"
            execute_remote "tail -50 /var/log/pve/tasks/index 2>/dev/null || echo 'Log tidak tersedia'"
            ;;
        3)
            echo -e "\n${GREEN}🔐 Auth Log:${NC}"
            echo "──────────────────────────────────────────────────"
            execute_remote "tail -50 /var/log/auth.log 2>/dev/null || echo 'Log tidak tersedia'"
            ;;
        4)
            echo -e "\n${GREEN}📝 Syslog:${NC}"
            echo "──────────────────────────────────────────────────"
            execute_remote "tail -50 /var/log/syslog 2>/dev/null || echo 'Log tidak tersedia'"
            ;;
        5)
            echo -e "\n${GREEN}🐳 Container/VM Logs:${NC}"
            echo "──────────────────────────────────────────────────"
            read -p "Masukkan ID Container/VM: " log_id
            if [[ -n "$log_id" ]]; then
                execute_remote "pct logs $log_id 2>/dev/null || qm config $log_id 2>/dev/null | head -10"
            fi
            ;;
        6)
            return
            ;;
        *)
            echo -e "${RED}❌ Pilihan tidak valid!${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan status koneksi
show_connection_status() {
    show_header
    echo -e "${YELLOW}🔗 STATUS KONEKSI${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    if [[ -n "$CURRENT_PVE_HOST" ]]; then
        echo -e "Host: ${GREEN}$CURRENT_PVE_HOST${NC}"
        echo -e "User: ${GREEN}$CURRENT_PVE_USER${NC}"
        echo -e "Port: ${GREEN}$CURRENT_SSH_PORT${NC}"
        echo -e "SSH Key: ${GREEN}$SSH_KEY${NC}"
        
        # Test koneksi
        echo -e "\n${BLUE}Testing koneksi...${NC}"
        if test_ssh_connection; then
            echo -e "${GREEN}✅ Koneksi aktif dan berfungsi${NC}"
        else
            echo -e "${RED}❌ Koneksi gagal${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Tidak ada koneksi yang aktif${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan menu utama
show_menu() {
    echo -e "\n${GREEN}📝 MENU UTAMA REMOTE${NC}"
    echo "══════════════════════════════════════════════════════════"
    
    if [[ -z "$CURRENT_PVE_HOST" ]] || ! test_ssh_connection; then
        echo -e "${RED}❌ Tidak terhubung ke Proxmox VE${NC}"
        echo -e "${BLUE}1.${NC} 🔧 Setup Koneksi Proxmox VE"
        echo -e "${BLUE}2.${NC} 🔑 Setup SSH Key"
    else
        echo -e "${GREEN}✅ Terhubung ke: $CURRENT_PVE_HOST${NC}"
        echo -e "${BLUE}1.${NC} 🔧 Ganti/Setup Koneksi"
        echo -e "${BLUE}2.${NC} 🔑 Setup SSH Key"
        echo -e "${BLUE}3.${NC} 📋 List semua Container/VM"
        echo -e "${BLUE}4.${NC} 📊 Status Resource Node"
        echo -e "${BLUE}5.${NC} 🚀 Start Container/VM"
        echo -e "${BLUE}6.${NC} 🛑 Stop Container/VM"
        echo -e "${BLUE}7.${NC} 🔄 Restart Container/VM"
        echo -e "${BLUE}8.${NC} 📄 Detail Container/VM"
        echo -e "${BLUE}9.${NC} 📋 View System Logs"
        echo -e "${BLUE}10.${NC} 🔗 Status Koneksi"
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
            read -p "Pilih menu [0-2]: " choice
        else
            read -p "Pilih menu [0-10]: " choice
        fi
        
        case $choice in
            1)
                setup_connection
                ;;
            2)
                if [[ -n "$CURRENT_PVE_HOST" ]]; then
                    setup_ssh_key
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    list_containers_remote
                    read -p "Press Enter to continue..."
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    show_resources_remote
                    read -p "Press Enter to continue..."
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            5)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    start_container_remote
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            6)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    stop_container_remote
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            7)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    restart_container_remote
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            8)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    show_details_remote
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            9)
                if [[ -n "$CURRENT_PVE_HOST" ]] && test_ssh_connection; then
                    view_logs_remote
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            10)
                if [[ -n "$CURRENT_PVE_HOST" ]]; then
                    show_connection_status
                else
                    echo -e "${RED}❌ Silakan setup koneksi terlebih dahulu!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0)
                echo -e "${GREEN}👋 Terima kasih telah menggunakan Proxmox VE Remote Tools!${NC}"
                log "Proxmox VE Remote Tools stopped"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Pilihan tidak valid! Silakan coba lagi.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Trap untuk handle Ctrl+C
trap 'echo -e "\n${RED}❌ Script diinterupsi. Keluar...${NC}"; log "Script interrupted by user"; exit 1' INT

# Check dependencies
if ! command -v ssh &> /dev/null; then
    echo -e "${RED}❌ SSH client tidak ditemukan!${NC}"
    echo "Install dengan: sudo apt-get install openssh-client"
    exit 1
fi

# Jalankan main function
main "$@"