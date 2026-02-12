#!/usr/bin/env bash
# Installation script for Antec Flux Pro Display on Arch Linux

set -e

printf "==================================\n"
printf "Antec Flux Pro Display Installer\n"
printf "==================================\n"
printf "\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    printf "Please do not run this script as root. It will ask for sudo when needed.\n"
    exit 1
fi

# Check if running on Arch Linux
if ! [ -f /etc/arch-release ]; then
    printf "Warning: This script is designed for Arch Linux.\n"
    if [ -t 0 ]; then
        printf "Continue anyway? (y/N) "
        read -r reply
        if [[ ! $reply =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        printf "Non-interactive mode: skipping confirmation\n"
    fi
fi

# Install dependencies
printf "Installing dependencies...\n"
sudo pacman -S --needed --noconfirm rust cargo git base-devel systemd

# Auto-install lm_sensors in non-interactive mode, prompt in interactive mode
if [ -t 0 ]; then
    printf "Install lm_sensors to help find CPU temperature sensors? (y/N) "
    read -r reply
    if [[ $reply =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed --noconfirm lm_sensors
        printf "Run 'sensors' to find your CPU temperature device path\n"
    fi
else
    printf "Installing lm_sensors (non-interactive mode)...\n"
    sudo pacman -S --needed --noconfirm lm_sensors
fi

# Optional: Install NVIDIA drivers if GPU is present
if lspci 2>/dev/null | grep -i nvidia > /dev/null 2>&1; then
    printf "NVIDIA GPU detected.\n"
    if [ -t 0 ]; then
        printf "Install nvidia-utils for GPU temperature monitoring? (y/N) "
        read -r reply
        if [[ $reply =~ ^[Yy]$ ]]; then
            sudo pacman -S --needed --noconfirm nvidia-utils
        fi
    else
        printf "Installing nvidia-utils (non-interactive mode)...\n"
        sudo pacman -S --needed --noconfirm nvidia-utils
    fi
fi

# Clone the repository
printf "Cloning repository...\n"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git clone https://github.com/nishtahir/antec-flux-pro-display.git
cd antec-flux-pro-display

# Build the project
printf "Building af-pro-display...\n"
cargo build --release

# Install binary
printf "Installing binary...\n"
sudo install -Dm755 "target/release/af-pro-display" "/usr/bin/af-pro-display"

# Install systemd service
printf "Installing systemd service...\n"
# Always use our custom service file with correct paths for Arch
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

# Install udev rules
printf "Installing udev rules...\n"
# Always use our custom udev rules
cat << 'EOF' | sudo tee /usr/lib/udev/rules.d/99-af-pro-display.rules > /dev/null
SUBSYSTEM=="usb", ATTRS{idVendor}=="2022", ATTRS{idProduct}=="0522", MODE="0660", GROUP="plugdev", TAG+="uaccess"
EOF

# Create config directory and install default config
printf "Installing configuration...\n"
sudo mkdir -p /etc/af-pro-display

# Find the best CPU temperature path
CPU_TEMP_PATH=""

# First, try to find k10temp (AMD CPUs) - prioritize Tctl
printf "Detecting CPU temperature sensor...\n"
for sensor in $(find /sys/class/hwmon -name "temp*_input" 2>/dev/null); do
    hwmon_dir=$(dirname "$sensor")
    if [ -f "$hwmon_dir/name" ]; then
        name=$(cat "$hwmon_dir/name" 2>/dev/null)
        if [ "$name" = "k10temp" ]; then
            # Check for Tctl label (preferred for AMD)
            label_file="${sensor%_input}_label"
            if [ -f "$label_file" ]; then
                label=$(cat "$label_file" 2>/dev/null)
                if [ "$label" = "Tctl" ]; then
                    CPU_TEMP_PATH="$sensor"
                    printf "Found AMD CPU sensor (k10temp Tctl): %s\n" "$CPU_TEMP_PATH"
                    break
                fi
            fi
            # Fallback to any k10temp sensor
            if [ -z "$CPU_TEMP_PATH" ]; then
                CPU_TEMP_PATH="$sensor"
                printf "Found AMD CPU sensor (k10temp): %s\n" "$CPU_TEMP_PATH"
                break
            fi
        elif [ "$name" = "coretemp" ] && [ -z "$CPU_TEMP_PATH" ]; then
            # Intel CPU
            CPU_TEMP_PATH="$sensor"
            printf "Found Intel CPU sensor (coretemp): %s\n" "$CPU_TEMP_PATH"
            break
        fi
    fi
done

# Fallback to first available sensor
if [ -z "$CPU_TEMP_PATH" ]; then
    CPU_TEMP_PATH=$(find /sys/class/hwmon -name "temp1_input" 2>/dev/null | head -n 1)
    if [ -n "$CPU_TEMP_PATH" ]; then
        printf "Using first available sensor: %s\n" "$CPU_TEMP_PATH"
    else
        CPU_TEMP_PATH="/sys/class/hwmon/hwmon0/temp1_input"
        printf "Warning: Could not detect CPU temperature sensor, using default: %s\n" "$CPU_TEMP_PATH"
    fi
fi

# Test the sensor
if [ -f "$CPU_TEMP_PATH" ] && [ -r "$CPU_TEMP_PATH" ]; then
    temp_raw=$(cat "$CPU_TEMP_PATH" 2>/dev/null)
    if [ -n "$temp_raw" ]; then
        temp_c=$((temp_raw / 1000))
        printf "Sensor test successful - Current temperature: %d°C\n" "$temp_c"
    fi
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
    printf "Creating plugdev group...\n"
    sudo groupadd -r plugdev
fi

# Add current user to plugdev group
printf "Adding %s to plugdev group...\n" "$USER"
sudo usermod -aG plugdev "$USER"

# Reload udev rules
printf "Reloading udev rules...\n"
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reload systemd daemon
printf "Reloading systemd daemon...\n"
sudo systemctl daemon-reload

# Clean up
cd /
rm -rf "$TEMP_DIR"

printf "\n"
printf "==================================\n"
printf "Installation complete!\n"
printf "==================================\n"
printf "\n"
printf "Next steps:\n"
printf "1. Log out and back in for group membership to take effect\n"
printf "2. Verify your config at: /etc/af-pro-display/config.toml\n"
printf "3. Start the service: sudo systemctl start af-pro-display\n"
printf "4. Enable autostart: sudo systemctl enable af-pro-display\n"
printf "5. Check status: sudo systemctl status af-pro-display\n"
printf "6. View logs: journalctl -u af-pro-display -f\n"
printf "\n"
printf "If you have issues, run 'sensors' to find your CPU temp path\n"
printf "and update it in /etc/af-pro-display/config.toml\n"
