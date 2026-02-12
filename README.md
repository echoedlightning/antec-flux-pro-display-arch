# Antec Flux Pro Display - Arch Linux Fork

An Arch Linux adaptation of the [antec-flux-pro-display](https://github.com/nishtahir/antec-flux-pro-display) service for displaying CPU and GPU temperatures on the Antec Flux Pro case display.

## 🚀 Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/install-arch.sh | bash
```

After installation:
1. Log out and back in (for group membership)
2. Configure: `sudo nano /etc/af-pro-display/config.toml`
3. Start: `sudo systemctl start af-pro-display`
4. Enable: `sudo systemctl enable af-pro-display`

## 📦 What's Included

This repository contains everything needed to run antec-flux-pro-display on Arch Linux:

### Core Files
- **`PKGBUILD`** - Arch package build script for makepkg/AUR
- **`af-pro-display.service`** - Systemd service file with Arch-specific paths
- **`99-af-pro-display.rules`** - Udev rules for USB device permissions
- **`config.toml`** - Default configuration file
- **`af-pro-display.install`** - Post-install/upgrade hooks for pacman

### Installation & Tools
- **`install-arch.sh`** - Automated installation script
- **`detect-sensors.sh`** - Helper to find CPU temperature sensors
- **`README-ARCH.md`** - Comprehensive Arch Linux documentation
- **`MIGRATION.md`** - Guide for migrating from Ubuntu version

## 🔧 Installation Options

### Option 1: Quick Install Script
```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/install-arch.sh | bash

# Or download and inspect first
wget https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/install-arch.sh
chmod +x install-arch.sh
./install-arch.sh
```

### Option 2: PKGBUILD (AUR-style)
```bash
# Download files
git clone https://github.com/YOUR-USERNAME/antec-flux-pro-display-arch.git
cd antec-flux-pro-display-arch

# Build and install
makepkg -si
```

### Option 3: Manual Installation
See [README-ARCH.md](README-ARCH.md#method-2-manual-installation) for detailed manual steps.

## ⚙️ Configuration

Find your CPU temperature sensor:
```bash
./detect-sensors.sh
```

Edit configuration:
```bash
sudo nano /etc/af-pro-display/config.toml
```

Example configuration:
```toml
cpu_device = "/sys/class/hwmon/hwmon0/temp1_input"
polling_interval = 200
```

## 🎯 Key Differences from Ubuntu Version

| Aspect | Ubuntu | Arch Linux |
|--------|--------|------------|
| Systemd path | `/lib/systemd/system/` | `/usr/lib/systemd/system/` |
| Udev path | `/lib/udev/rules.d/` | `/usr/lib/udev/rules.d/` |
| Package format | `.deb` | `.pkg.tar.zst` |
| Package manager | `apt` | `pacman` |
| plugdev group | Pre-exists | Must create |
| lm_sensors pkg | `lm-sensors` | `lm_sensors` |

## 📋 File Descriptions

### PKGBUILD
Arch Linux package build script following [Arch packaging standards](https://wiki.archlinux.org/title/PKGBUILD). Handles:
- Dependency installation (rust, cargo, systemd)
- Building from source with proper Rust toolchain
- Installation to correct Arch Linux paths
- Post-installation hooks via .install file

### af-pro-display.service
Systemd service unit with:
- Proper ordering (after network and udev)
- Automatic restarts on failure
- Security hardening (NoNewPrivileges, ProtectSystem, etc.)
- Journal logging
- Arch-specific executable paths

### 99-af-pro-display.rules
Udev rule that:
- Detects Antec Flux Pro USB device (2022:0522)
- Sets permissions (0660, group plugdev)
- Adds uaccess tag for user sessions

### config.toml
Configuration with:
- CPU sensor path (must be customized per system)
- Polling interval in milliseconds
- Comments explaining how to find correct values

### install-arch.sh
Automated installer that:
- Checks for Arch Linux
- Installs dependencies via pacman
- Clones and builds from source
- Creates plugdev group if needed
- Adds user to plugdev group
- Installs service and udev rules
- Auto-detects CPU sensor path
- Provides post-install instructions

### detect-sensors.sh
Diagnostic tool that:
- Scans /sys/class/hwmon for temperature sensors
- Identifies likely CPU sensors (k10temp, coretemp, zenpower)
- Shows current temperatures
- Provides sensor paths for config.toml
- Runs `sensors` command if lm_sensors installed

### af-pro-display.install
Pacman install hooks that:
- Create plugdev group on installation
- Add post-install instructions
- Reload udev and systemd
- Restart service on upgrades
- Clean up on removal

## 🐛 Troubleshooting

### Quick Diagnostics
```bash
# Check service status
sudo systemctl status af-pro-display

# View logs
journalctl -u af-pro-display -f

# Verify USB device
lsusb | grep "2022:0522"

# Check group membership
groups | grep plugdev

# Find sensors
./detect-sensors.sh
```

### Common Issues

**Service won't start**
- Check config path: `cat /etc/af-pro-display/config.toml`
- Verify sensor exists: `cat /sys/class/hwmon/hwmon0/temp1_input`
- Run `./detect-sensors.sh` to find correct path

**Permission denied**
- Ensure in plugdev group: `groups | grep plugdev`
- Log out and back in after adding to group
- Check udev rules: `ls -l /usr/lib/udev/rules.d/99-af-pro-display.rules`

**NVIDIA GPU not detected**
- Install nvidia-utils: `sudo pacman -S nvidia-utils`
- Verify driver: `nvidia-smi`
- Restart service: `sudo systemctl restart af-pro-display`

See [README-ARCH.md](README-ARCH.md#troubleshooting) for detailed troubleshooting.

## 📚 Documentation

- **[README-ARCH.md](README-ARCH.md)** - Complete Arch Linux documentation
- **[MIGRATION.md](MIGRATION.md)** - Ubuntu to Arch migration guide
- **[Upstream README](https://github.com/nishtahir/antec-flux-pro-display/blob/main/README.md)** - Original project documentation

## 🔗 Resources

- [Arch Wiki - systemd](https://wiki.archlinux.org/title/Systemd)
- [Arch Wiki - udev](https://wiki.archlinux.org/title/Udev)
- [Arch Wiki - lm_sensors](https://wiki.archlinux.org/title/Lm_sensors)
- [Arch Wiki - PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD)
- [Original Project](https://github.com/nishtahir/antec-flux-pro-display)

## 👥 Credits

- **Original Author**: [nishtahir](https://github.com/nishtahir/antec-flux-pro-display)
- **Inspiration**: [AKoskovich](https://github.com/AKoskovich/antec_flux_pro_display_service)
- **Arch Adaptation**: Vibe coded by yours truly (Go figure)

## 📄 License

GNU General Public License v3.0 - See LICENSE file for details

## 🤝 Contributing

Contributions are welcome! This is an Arch-specific fork. For general application issues, please see the [upstream repository](https://github.com/nishtahir/antec-flux-pro-display).

### To Contribute:
1. Fork this repository
2. Create a feature branch
3. Test on Arch Linux
4. Submit a pull request

### Potential Improvements:
- [ ] Submit to AUR
- [ ] Add systemd timer for periodic sensor recalibration
- [ ] Support for additional GPU vendors (AMD via sysfs)
- [ ] Configuration validation tool
- [ ] Animated display modes
- [ ] Multi-sensor aggregation

## 🎉 Getting Started

Ready to get started? Pick your installation method:

1. **Want it quick?** → Use `install-arch.sh`
2. **Want a package?** → Use `PKGBUILD`
3. **Want control?** → Follow manual steps in README-ARCH.md

Questions? Check the troubleshooting section or open an issue!
