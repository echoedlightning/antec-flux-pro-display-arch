#!/bin/bash
# Installation script for Antec Flux Pro Display on Arch Linux

set -e

echo "=================================="
echo "Antec Flux Pro Display Installer"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root. It will ask for sudo when needed."
    exit 1
fi

# Check if running on Arch Linux
if ! [ -f /etc/arch-release ]; then
    echo "Warning: This script is designed for Arch Linux."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install dependencies
echo "Installing dependencies..."
sudo pacman -S --needed rust cargo git base-devel systemd

# Optional: Install lm_sensors for finding CPU temperature path
read -p "Install lm_sensors to help find CPU temperature sensors? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S --needed lm_sensors
    echo "Run 'sensors' to find your CPU temperature device path"
fi

# Optional: Install NVIDIA drivers if GPU is present
if lspci | grep -i nvidia > /dev/null; then
    echo "NVIDIA GPU detected."
    read -p "Install nvidia-utils for GPU temperature monitoring? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed nvidia-utils
    fi
fi

# Clone the repository
echo "Cloning repository..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git clone https://github.com/nishtahir/antec-flux-pro-display.git
cd antec-flux-pro-display

# Build the project
echo "Building af-pro-display..."
cargo build --release

# Install binary
echo "Installing binary..."
sudo install -Dm755 "target/release/af-pro-display" "/usr/bin/af-pro-display"

# Install systemd service
echo "Installing systemd service..."
if [ -f "packaging/af-pro-display.service" ]; then
    sudo install -Dm644 "packaging/af-pro-display.service" "/usr/lib/systemd/system/af-pro-display.service"
else
    # Use our custom service file if the original doesn't exist
    cat << 'EOF' | sudo tee /usr/lib/systemd/system/af-pro-display.service > /dev/null
[Unit]
Description=Antec Flux Pro Display Service
After=network.target systemd-udev-settle.service
Wants=systemd-udev-settle.service

[Service]
Type=simple
ExecStart=/usr/bin/af-pro-display --config /etc/af-pro-display/config.toml
Restart=on-failure
RestartSec=5s
User=root
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/sys/class/hwmon

[Install]
WantedBy=multi-user.target
EOF
fi

# Install udev rules
echo "Installing udev rules..."
if [ -f "packaging/99-af-pro-display.rules" ]; then
    sudo install -Dm644 "packaging/99-af-pro-display.rules" "/usr/lib/udev/rules.d/99-af-pro-display.rules"
else
    cat << 'EOF' | sudo tee /usr/lib/udev/rules.d/99-af-pro-display.rules > /dev/null
SUBSYSTEM=="usb", ATTRS{idVendor}=="2022", ATTRS{idProduct}=="0522", MODE="0660", GROUP="plugdev", TAG+="uaccess"
EOF
fi

# Create config directory and install default config
echo "Installing configuration..."
sudo mkdir -p /etc/af-pro-display

# Find a reasonable default CPU temperature path
CPU_TEMP_PATH=$(find /sys/class/hwmon -name "temp*_input" 2>/dev/null | head -n 1)
if [ -z "$CPU_TEMP_PATH" ]; then
    CPU_TEMP_PATH="/sys/class/hwmon/hwmon0/temp1_input"
    echo "Warning: Could not detect CPU temperature sensor, using default: $CPU_TEMP_PATH"
else
    echo "Detected CPU temperature sensor: $CPU_TEMP_PATH"
fi

# Create config file
cat << EOF | sudo tee /etc/af-pro-display/config.toml > /dev/null
# Antec Flux Pro Display Configuration
# Path to CPU temperature sensor
cpu_device = "$CPU_TEMP_PATH"

# Polling interval in milliseconds
polling_interval = 200
EOF

# Ensure plugdev group exists (might not exist on Arch by default)
if ! getent group plugdev > /dev/null; then
    echo "Creating plugdev group..."
    sudo groupadd -r plugdev
fi

# Add current user to plugdev group
echo "Adding $USER to plugdev group..."
sudo usermod -aG plugdev "$USER"

# Reload udev rules
echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Clean up
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "=================================="
echo "Installation complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Log out and back in for group membership to take effect"
echo "2. Verify your config at: /etc/af-pro-display/config.toml"
echo "3. Start the service: sudo systemctl start af-pro-display"
echo "4. Enable autostart: sudo systemctl enable af-pro-display"
echo "5. Check status: sudo systemctl status af-pro-display"
echo "6. View logs: journalctl -u af-pro-display -f"
echo ""
echo "If you have issues, run 'sensors' to find your CPU temp path"
echo "and update it in /etc/af-pro-display/config.toml"
