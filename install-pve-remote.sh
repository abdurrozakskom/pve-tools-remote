#!/bin/bash

# Installer untuk Proxmox VE Remote Tools

PVE_TOOLS_SCRIPT="pve-tools-remote.sh"
INSTALL_DIR="/usr/local/bin"

echo "🔧 Installing Proxmox VE Remote Tools..."
echo "══════════════════════════════════════════════════════════"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Script ini harus dijalankan sebagai root" 
   echo "Gunakan: sudo $0"
   exit 1
fi

# Check if main script exists
if [[ ! -f "$PVE_TOOLS_SCRIPT" ]]; then
    echo "❌ File $PVE_TOOLS_SCRIPT tidak ditemukan!"
    echo "Pastikan file berada di directory yang sama"
    exit 1
fi

# Check for SSH client
if ! command -v ssh &> /dev/null; then
    echo "📦 Installing SSH client..."
    apt-get update && apt-get install -y openssh-client
fi

# Copy main script
echo "📁 Copying main script ke $INSTALL_DIR..."
cp "$PVE_TOOLS_SCRIPT" "$INSTALL_DIR/pve-remote"
chmod +x "$INSTALL_DIR/pve-remote"

# Create bash completion
echo "⌨️  Creating bash completion..."
cat > "/etc/bash_completion.d/pve-remote" << 'EOF'
_pve_remote() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --version --setup --list --resources --start --stop --restart --details --logs --status"
    
    case "${prev}" in
        --start|--stop|--restart|--details)
            COMPREPLY=( $(compgen -W "" -- ${cur}) )
            ;;
        *)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            ;;
    esac
}
complete -F _pve_remote pve-remote
EOF

echo "✅ Installation completed successfully!"
echo ""
echo "📖 Usage:"
echo "  pve-remote                    # Interactive mode"
echo "  pve-remote --setup           # Setup connection"
echo "  pve-remote --list            # List all containers/VMs"
echo "  pve-remote --resources       # Show resource usage"
echo "  pve-remote --status          # Show connection status"
echo "  pve-remote --help            # Show help"
echo ""
echo "🚀 First time setup:"
echo "  1. Run: pve-remote --setup"
echo "  2. Enter Proxmox VE host details"
echo "  3. Setup SSH key authentication"
echo ""
echo "🔑 SSH Key Setup:"
echo "  Script akan otomatis generate dan copy SSH key"
echo "  Jika gagal, ikuti petunjuk manual yang diberikan"
echo ""
echo "🎉 You can now run 'pve-remote' from anywhere in the system!"