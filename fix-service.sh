#!/usr/bin/env bash
# Fix script for af-pro-display service issues

printf "Fixing af-pro-display service...\n\n"

# Stop the service first
printf "Stopping service...\n"
sudo systemctl stop af-pro-display 2>/dev/null || true

# Check where the binary actually is
if [ -f "/usr/bin/af-pro-display" ]; then
    BINARY_PATH="/usr/bin/af-pro-display"
    printf "✓ Found binary at: %s\n" "$BINARY_PATH"
elif [ -f "/usr/local/bin/af-pro-display" ]; then
    BINARY_PATH="/usr/local/bin/af-pro-display"
    printf "✓ Found binary at: %s\n" "$BINARY_PATH"
else
    printf "✗ ERROR: af-pro-display binary not found!\n"
    printf "  Please reinstall the application.\n"
    exit 1
fi

# Find your CPU temperature sensor
printf "\nDetecting CPU temperature sensor...\n"
CPU_SENSOR=""

# Look for k10temp (AMD)
K10TEMP=$(find /sys/class/hwmon -type f -name "temp1_input" 2>/dev/null | while read -r sensor; do
    name_file=$(dirname "$sensor")/name
    if [ -f "$name_file" ] && grep -q "k10temp" "$name_file" 2>/dev/null; then
        echo "$sensor"
        break
    fi
done)

if [ -n "$K10TEMP" ]; then
    CPU_SENSOR="$K10TEMP"
    printf "✓ Found AMD CPU sensor (k10temp): %s\n" "$CPU_SENSOR"
fi

# Fallback to first available temp sensor
if [ -z "$CPU_SENSOR" ]; then
    CPU_SENSOR=$(find /sys/class/hwmon -name "temp1_input" 2>/dev/null | head -n 1)
    if [ -n "$CPU_SENSOR" ]; then
        printf "✓ Using first available sensor: %s\n" "$CPU_SENSOR"
    else
        printf "✗ WARNING: No temperature sensor found, using default\n"
        CPU_SENSOR="/sys/class/hwmon/hwmon0/temp1_input"
    fi
fi

# Create the correct service file
printf "\nCreating correct service file...\n"
sudo tee /usr/lib/systemd/system/af-pro-display.service > /dev/null << EOF
[Unit]
Description=Antec Flux Pro Display Service
After=network.target systemd-udev-settle.service
Wants=systemd-udev-settle.service

[Service]
Type=simple
ExecStart=$BINARY_PATH --config /etc/af-pro-display/config.toml
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

printf "✓ Service file created at: /usr/lib/systemd/system/af-pro-display.service\n"

# Remove old service file if it exists in wrong location
if [ -f "/etc/systemd/system/af-pro-display.service" ]; then
    printf "\nRemoving old service file from /etc/systemd/system/...\n"
    sudo rm /etc/systemd/system/af-pro-display.service
    printf "✓ Removed old service file\n"
fi

# Update config file
printf "\nUpdating configuration file...\n"
sudo mkdir -p /etc/af-pro-display

sudo tee /etc/af-pro-display/config.toml > /dev/null << EOF
# Antec Flux Pro Display Configuration
# Path to CPU temperature sensor
cpu_device = "$CPU_SENSOR"

# Polling interval in milliseconds
polling_interval = 200
EOF

printf "✓ Config updated at: /etc/af-pro-display/config.toml\n"
printf "  CPU sensor: %s\n" "$CPU_SENSOR"

# Test if we can read the sensor
if [ -f "$CPU_SENSOR" ] && [ -r "$CPU_SENSOR" ]; then
    TEMP=$(cat "$CPU_SENSOR" 2>/dev/null)
    if [ -n "$TEMP" ]; then
        TEMP_C=$((TEMP / 1000))
        printf "  Current reading: %d°C\n" "$TEMP_C"
    fi
else
    printf "  ✗ WARNING: Cannot read sensor file!\n"
fi

# Reload systemd
printf "\nReloading systemd daemon...\n"
sudo systemctl daemon-reload
printf "✓ Daemon reloaded\n"

# Try to start the service
printf "\nStarting service...\n"
if sudo systemctl start af-pro-display; then
    printf "✓ Service started successfully!\n"
else
    printf "✗ Service failed to start. Checking logs...\n"
    journalctl -u af-pro-display -n 20 --no-pager
    exit 1
fi

# Check status
sleep 2
if sudo systemctl is-active --quiet af-pro-display; then
    printf "\n✓ Service is running!\n"
    sudo systemctl status af-pro-display --no-pager -l
else
    printf "\n✗ Service is not running. Checking logs...\n"
    journalctl -u af-pro-display -n 20 --no-pager
    exit 1
fi

printf "\n==================================\n"
printf "Fix completed successfully!\n"
printf "==================================\n"
printf "\nYour configuration:\n"
printf "  Binary: %s\n" "$BINARY_PATH"
printf "  Config: /etc/af-pro-display/config.toml\n"
printf "  CPU Sensor: %s\n" "$CPU_SENSOR"
printf "\nTo enable autostart: sudo systemctl enable af-pro-display\n"
printf "To view logs: journalctl -u af-pro-display -f\n"

hi
