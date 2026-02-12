# Quick Reference - Antec Flux Pro Display (Arch Linux)

## One-Line Install
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/install-arch.sh | bash
```

## Essential Commands

### Service Management
```bash
sudo systemctl start af-pro-display      # Start service
sudo systemctl stop af-pro-display       # Stop service
sudo systemctl restart af-pro-display    # Restart service
sudo systemctl status af-pro-display     # Check status
sudo systemctl enable af-pro-display     # Enable on boot
sudo systemctl disable af-pro-display    # Disable on boot
```

### Logs & Debugging
```bash
journalctl -u af-pro-display -f          # Follow logs live
journalctl -u af-pro-display -n 50       # Last 50 lines
journalctl -u af-pro-display -xe         # Show errors
sudo systemctl status af-pro-display     # Service status
```

### Configuration
```bash
sudo nano /etc/af-pro-display/config.toml    # Edit config
cat /etc/af-pro-display/config.toml          # View config
./detect-sensors.sh                          # Find sensors
sensors                                      # Show all temps
```

### Diagnostics
```bash
lsusb | grep "2022:0522"                 # Check USB device
groups | grep plugdev                     # Check group membership
ls -l /usr/lib/udev/rules.d/99-af*       # Check udev rules
cat /sys/class/hwmon/hwmon0/temp1_input  # Test sensor read
find /sys/class/hwmon -name "temp*_input" # Find all sensors
```

### Permissions
```bash
sudo usermod -aG plugdev $USER           # Add user to group
groups                                    # Check current groups
sudo udevadm control --reload-rules      # Reload udev
sudo udevadm trigger                     # Trigger udev
```

## File Locations

| Item | Path |
|------|------|
| Binary | `/usr/bin/af-pro-display` |
| Service | `/usr/lib/systemd/system/af-pro-display.service` |
| Udev rules | `/usr/lib/udev/rules.d/99-af-pro-display.rules` |
| Config | `/etc/af-pro-display/config.toml` |

## Config Example
```toml
cpu_device = "/sys/class/hwmon/hwmon0/temp1_input"
polling_interval = 200
```

## Common Sensor Paths

### AMD CPUs
```
/sys/class/hwmon/hwmon0/temp1_input    # k10temp
/sys/class/hwmon/hwmon1/temp1_input    # zenpower
```

### Intel CPUs
```
/sys/class/hwmon/hwmon0/temp1_input    # coretemp
/sys/class/hwmon/hwmon2/temp1_input    # Package temp
```

## Quick Fixes

### Service Won't Start
```bash
./detect-sensors.sh                          # Find correct sensor
sudo nano /etc/af-pro-display/config.toml   # Update path
sudo systemctl restart af-pro-display       # Restart
journalctl -u af-pro-display -xe            # Check errors
```

### Permission Issues
```bash
sudo usermod -aG plugdev $USER              # Add to group
# LOG OUT AND BACK IN
groups | grep plugdev                        # Verify
sudo udevadm control --reload-rules         # Reload udev
sudo udevadm trigger                        # Apply rules
```

### NVIDIA GPU Not Working
```bash
sudo pacman -S nvidia-utils                 # Install drivers
nvidia-smi                                   # Test driver
sudo systemctl restart af-pro-display       # Restart service
```

## Installation Methods

### Method 1: Script
```bash
curl -fsSL URL/install-arch.sh | bash
```

### Method 2: PKGBUILD
```bash
makepkg -si
```

### Method 3: Manual
```bash
sudo pacman -S rust cargo git base-devel systemd
git clone https://github.com/nishtahir/antec-flux-pro-display.git
cd antec-flux-pro-display
cargo build --release
# Copy files to Arch paths (see README-ARCH.md)
```

## Uninstall
```bash
sudo systemctl stop af-pro-display
sudo systemctl disable af-pro-display
sudo rm /usr/bin/af-pro-display
sudo rm /usr/lib/systemd/system/af-pro-display.service
sudo rm /usr/lib/udev/rules.d/99-af-pro-display.rules
sudo rm -rf /etc/af-pro-display
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
```

## Need Help?

1. Check logs: `journalctl -u af-pro-display -f`
2. Run diagnostics: `./detect-sensors.sh`
3. Read docs: `README-ARCH.md`
4. Check USB: `lsusb | grep "2022:0522"`
5. Verify config: `cat /etc/af-pro-display/config.toml`

## Tips

- **Log out after adding to plugdev group**
- Use `sensors` to verify temperature readings
- Default polling: 200ms (adjustable in config)
- Service runs as root for hardware access
- Udev rules auto-apply on USB plug/unplug
