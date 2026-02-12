# Antec Flux Pro Display - Arch Linux Fork

This is an Arch Linux adaptation of the [antec-flux-pro-display](https://github.com/nishtahir/antec-flux-pro-display) service that displays CPU and GPU temperatures on the Antec Flux Pro display.

## Features

- Real-time CPU temperature monitoring
- NVIDIA GPU temperature support through NVML
- Automatic USB device detection and management
- Systemd service integration
- Optimized for Arch Linux

## Prerequisites

- Arch Linux
- Rust toolchain (will be installed by the script)
- Antec Flux Pro case with display
- USB connection to the case display

## Installation Methods

### Method 1: Quick Install Script (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/install-arch.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/install-arch.sh
chmod +x install-arch.sh
./install-arch.sh
```

### Method 2: Manual Installation

1. Install dependencies:
```bash
sudo pacman -S rust cargo git base-devel systemd lm_sensors
# Optional for NVIDIA GPU support
sudo pacman -S nvidia-utils
```

2. Clone and build:
```bash
git clone https://github.com/YOUR-USERNAME/antec-flux-pro-display-arch.git
cd antec-flux-pro-display-arch
cargo build --release
```

3. Install:
```bash
sudo install -Dm755 target/release/af-pro-display /usr/bin/af-pro-display
sudo install -Dm644 af-pro-display.service /usr/lib/systemd/system/af-pro-display.service
sudo install -Dm644 99-af-pro-display.rules /usr/lib/udev/rules.d/99-af-pro-display.rules
sudo mkdir -p /etc/af-pro-display
sudo cp config.toml /etc/af-pro-display/config.toml
```

4. Set up permissions:
```bash
# Create plugdev group if it doesn't exist
sudo groupadd -r plugdev 2>/dev/null || true
# Add your user to the group
sudo usermod -aG plugdev $USER
# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Method 3: Using PKGBUILD (AUR-style)

```bash
# Download PKGBUILD
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/PKGBUILD

# Build and install
makepkg -si
```

## Configuration

Edit the configuration file at `/etc/af-pro-display/config.toml`:

```toml
# Path to CPU temperature sensor
cpu_device = "/sys/class/hwmon/hwmon0/temp1_input"

# Polling interval in milliseconds
polling_interval = 200
```

### Finding Your CPU Temperature Sensor

1. Install and run lm_sensors:
```bash
sudo pacman -S lm_sensors
sudo sensors-detect  # Follow the prompts
sensors  # Display current readings
```

2. Locate the temperature file:
```bash
# For AMD CPUs (k10temp):
find /sys/class/hwmon -name "temp1_input" -exec grep -l "k10temp" {} \; 2>/dev/null

# For Intel CPUs (coretemp):
find /sys/class/hwmon -name "temp1_input" -exec grep -l "coretemp" {} \; 2>/dev/null

# Or just list all temperature sensors:
find /sys/class/hwmon -name "temp*_input"
```

3. Update the `cpu_device` path in `/etc/af-pro-display/config.toml`

## Service Management

```bash
# Start the service
sudo systemctl start af-pro-display

# Enable autostart on boot
sudo systemctl enable af-pro-display

# Check status
sudo systemctl status af-pro-display

# View logs
journalctl -u af-pro-display -f

# Stop the service
sudo systemctl stop af-pro-display

# Restart after config changes
sudo systemctl restart af-pro-display
```

## Troubleshooting

### Permission Issues

1. Verify the USB device is detected:
```bash
lsusb | grep "2022:0522"
```

2. Check udev rules are applied:
```bash
ls -l /dev/bus/usb/$(lsusb | grep "2022:0522" | awk '{print $2,$4}' | sed 's/ /\//' | sed 's/://')
```

3. Verify group membership:
```bash
groups | grep plugdev
```

If you just added yourself to the group, **log out and log back in** for changes to take effect.

4. Check service logs:
```bash
journalctl -u af-pro-display -n 50 --no-pager
```

### Temperature Reading Issues

1. Verify the temperature file exists and is readable:
```bash
cat /sys/class/hwmon/hwmon0/temp1_input
```

2. Check file permissions:
```bash
ls -l /sys/class/hwmon/hwmon*/temp*_input
```

3. Find all available temperature sensors:
```bash
sensors
# or
find /sys/class/hwmon -name "temp*_input" -exec sh -c 'echo "{}:" && cat {}' \;
```

### NVIDIA GPU Issues

1. Verify NVIDIA drivers are installed:
```bash
nvidia-smi
```

2. Check NVML library is available:
```bash
ldconfig -p | grep nvidia
```

### Service Won't Start

1. Check for errors in the journal:
```bash
sudo journalctl -u af-pro-display -xe
```

2. Try running manually to see detailed output:
```bash
sudo /usr/bin/af-pro-display --config /etc/af-pro-display/config.toml
```

3. Verify systemd service file syntax:
```bash
sudo systemd-analyze verify af-pro-display.service
```

## Differences from Ubuntu Version

- Uses Arch-specific paths (`/usr/lib/systemd/system` instead of `/lib/systemd/system`)
- Uses `pacman` instead of `apt` for package management
- Creates `plugdev` group if it doesn't exist (not default on Arch)
- Optimized systemd service with Arch-appropriate hardening
- Install script detects common Arch CPU temperature sensor locations

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop af-pro-display
sudo systemctl disable af-pro-display

# Remove files
sudo rm /usr/bin/af-pro-display
sudo rm /usr/lib/systemd/system/af-pro-display.service
sudo rm /usr/lib/udev/rules.d/99-af-pro-display.rules
sudo rm -rf /etc/af-pro-display

# Reload systemd and udev
sudo systemctl daemon-reload
sudo udevadm control --reload-rules

# Optionally remove user from plugdev group
sudo gpasswd -d $USER plugdev
```

## Contributing

Contributions are welcome! This is a fork specifically for Arch Linux compatibility. For general issues with the application, please see the [upstream repository](https://github.com/nishtahir/antec-flux-pro-display).

## Credits

- Original project by [nishtahir](https://github.com/nishtahir/antec-flux-pro-display)
- Inspired by work from [AKoskovich](https://github.com/AKoskovich/antec_flux_pro_display_service)
- Arch Linux adaptation by [Your Name]

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## Resources

- [Arch Linux systemd documentation](https://wiki.archlinux.org/title/Systemd)
- [Arch Linux udev documentation](https://wiki.archlinux.org/title/Udev)
- [lm_sensors documentation](https://wiki.archlinux.org/title/Lm_sensors)
- [Original Ubuntu repository](https://github.com/nishtahir/antec-flux-pro-display)
