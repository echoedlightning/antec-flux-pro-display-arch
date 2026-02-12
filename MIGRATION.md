# Migration Guide: Ubuntu to Arch Linux

## Key Differences Between Ubuntu and Arch Versions

### Package Management
| Aspect | Ubuntu | Arch Linux |
|--------|--------|------------|
| Package format | `.deb` | `.pkg.tar.zst` via PKGBUILD |
| Package manager | `apt` | `pacman` / `makepkg` |
| Package repos | Official repos | Official repos + AUR |

### System Paths
| File Type | Ubuntu | Arch Linux |
|-----------|--------|------------|
| Systemd services | `/lib/systemd/system/` | `/usr/lib/systemd/system/` |
| Udev rules | `/lib/udev/rules.d/` | `/usr/lib/udev/rules.d/` |
| Config files | `/etc/` | `/etc/` (same) |
| Binaries | `/usr/bin/` | `/usr/bin/` (same) |

### Group Management
- **Ubuntu**: `plugdev` group exists by default
- **Arch**: `plugdev` group must be created manually

### Dependencies
| Ubuntu Package | Arch Package | Notes |
|---------------|--------------|-------|
| `build-essential` | `base-devel` | Build tools |
| `libusb-1.0-0-dev` | Included in `base-devel` | USB support |
| `libudev-dev` | `systemd` | Udev support |
| `nvidia-utils` | `nvidia-utils` | Same name |
| `lm-sensors` | `lm_sensors` | Note the underscore |

## Step-by-Step Migration

### 1. Remove Ubuntu Version (if installed)
```bash
# On Ubuntu system
sudo systemctl stop af-pro-display
sudo systemctl disable af-pro-display
sudo apt remove af-pro-display
```

### 2. Install on Arch Linux

#### Option A: Quick Install (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/install-arch.sh | bash
```

#### Option B: Using PKGBUILD
```bash
# Download the files
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/PKGBUILD
curl -O https://raw.githubusercontent.com/YOUR-USERNAME/antec-flux-pro-display-arch/main/af-pro-display.install

# Build and install
makepkg -si
```

#### Option C: Manual Build
```bash
# Install dependencies
sudo pacman -S rust cargo git base-devel systemd lm_sensors

# Clone original repo
git clone https://github.com/nishtahir/antec-flux-pro-display.git
cd antec-flux-pro-display

# Build
cargo build --release

# Install (use Arch paths)
sudo install -Dm755 target/release/af-pro-display /usr/bin/af-pro-display
sudo install -Dm644 packaging/af-pro-display.service /usr/lib/systemd/system/af-pro-display.service
sudo install -Dm644 packaging/99-af-pro-display.rules /usr/lib/udev/rules.d/99-af-pro-display.rules

# Create config
sudo mkdir -p /etc/af-pro-display
sudo cp packaging/config.toml /etc/af-pro-display/config.toml
```

### 3. Configure for Arch

#### Update CPU Sensor Path
On Arch, CPU temperature paths may differ:

```bash
# Find your sensors
./detect-sensors.sh

# Or manually:
find /sys/class/hwmon -name "temp*_input"

# Update config
sudo nano /etc/af-pro-display/config.toml
```

Common Arch CPU sensor locations:
- **AMD (k10temp)**: `/sys/class/hwmon/hwmon*/temp1_input`
- **Intel (coretemp)**: `/sys/class/hwmon/hwmon*/temp1_input`
- **AMD Zen (zenpower)**: `/sys/class/hwmon/hwmon*/temp1_input`

#### Set Up Permissions
```bash
# Create plugdev group (doesn't exist by default on Arch)
sudo groupadd -r plugdev

# Add your user
sudo usermod -aG plugdev $USER

# Reload udev
sudo udevadm control --reload-rules
sudo udevadm trigger

# Log out and back in for group changes
```

### 4. Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable af-pro-display
sudo systemctl start af-pro-display

# Check status
sudo systemctl status af-pro-display

# View logs
journalctl -u af-pro-display -f
```

## Configuration Migration

If you have custom configuration from Ubuntu, you can transfer it:

### Ubuntu config location
```
~/.config/af-pro-display/config.toml
```

### Arch config location
```
/etc/af-pro-display/config.toml
```

### Transfer config
```bash
# Copy from Ubuntu backup
sudo cp ~/ubuntu-backup/config.toml /etc/af-pro-display/config.toml

# Verify CPU sensor path is valid on Arch
cat /sys/class/hwmon/hwmon0/temp1_input

# Update if needed
sudo nano /etc/af-pro-display/config.toml
```

## Troubleshooting

### Common Issues After Migration

#### Issue: Service fails to start
**Solution**: Check CPU sensor path is correct for Arch
```bash
./detect-sensors.sh
sudo nano /etc/af-pro-display/config.toml
sudo systemctl restart af-pro-display
```

#### Issue: Permission denied on USB device
**Solution**: Ensure you're in plugdev group and logged out/in
```bash
groups | grep plugdev
sudo usermod -aG plugdev $USER
# Log out and log back in
```

#### Issue: NVIDIA GPU not detected
**Solution**: Install nvidia-utils
```bash
sudo pacman -S nvidia-utils
sudo systemctl restart af-pro-display
```

#### Issue: Different hwmon number
**Solution**: Arch may assign different hwmon numbers
```bash
# Find the correct one
find /sys/class/hwmon -name "temp*_input" -exec sh -c 'echo "{}:" && cat {}' \;

# Update config with correct path
sudo nano /etc/af-pro-display/config.toml
```

## Verification Checklist

After migration, verify:

- [ ] Service is running: `systemctl is-active af-pro-display`
- [ ] No errors in logs: `journalctl -u af-pro-display -n 20`
- [ ] USB device detected: `lsusb | grep "2022:0522"`
- [ ] Temperature reading: Display shows CPU temp
- [ ] GPU temperature (if NVIDIA): Display shows GPU temp
- [ ] Service starts on boot: `systemctl is-enabled af-pro-display`

## Performance Notes

The Arch version should perform identically to the Ubuntu version. Both:
- Use the same Rust codebase
- Poll at the same interval (200ms default)
- Support the same hardware (NVIDIA GPUs via NVML)
- Use the same USB communication protocol

## Additional Arch-Specific Considerations

### AUR Package (Future)
Consider submitting to the AUR for easier installation:
1. Create AUR package with the PKGBUILD
2. Submit to aur.archlinux.org
3. Users can install via AUR helpers: `yay -S af-pro-display`

### systemd Hardening
The Arch service includes additional hardening options:
- `NoNewPrivileges=true`
- `PrivateTmp=true`
- `ProtectSystem=strict`
- `ProtectHome=true`
- `ReadWritePaths=/sys/class/hwmon`

These can be adjusted in `/usr/lib/systemd/system/af-pro-display.service` if needed.

### Rolling Release Considerations
Arch is a rolling release distribution:
- Keep Rust toolchain updated: `sudo pacman -Syu rust`
- Monitor for breaking changes in dependencies
- Check logs after system updates
- Rebuild if kernel modules change

## Support

For Arch-specific issues, refer to:
- Arch Wiki: https://wiki.archlinux.org/
- This repository's issues
- Arch forums: https://bbs.archlinux.org/

For general application issues, see:
- Original repository: https://github.com/nishtahir/antec-flux-pro-display
