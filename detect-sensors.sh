#!/bin/bash
# Helper script to detect CPU temperature sensor on Arch Linux

echo "Detecting CPU temperature sensors..."
echo ""

# Check if lm_sensors is installed
if ! command -v sensors &> /dev/null; then
    echo "Warning: lm_sensors not installed."
    echo "Install it with: sudo pacman -S lm_sensors"
    echo ""
fi

# Find all temperature sensors
echo "Available temperature sensors:"
echo "=============================="

sensor_count=0
declare -a sensors

while IFS= read -r -d '' sensor; do
    sensor_count=$((sensor_count + 1))
    sensors+=("$sensor")
    
    # Try to get the sensor name
    hwmon_dir=$(dirname "$sensor")
    name=""
    
    if [ -f "$hwmon_dir/name" ]; then
        name=$(cat "$hwmon_dir/name")
    fi
    
    # Get current temperature
    temp=""
    if [ -r "$sensor" ]; then
        temp_raw=$(cat "$sensor" 2>/dev/null)
        if [ ! -z "$temp_raw" ]; then
            temp=$((temp_raw / 1000))
        fi
    fi
    
    # Get temperature label
    label=""
    label_file="${sensor%_input}_label"
    if [ -f "$label_file" ]; then
        label=$(cat "$label_file")
    fi
    
    echo "$sensor_count. $sensor"
    [ ! -z "$name" ] && echo "   Name: $name"
    [ ! -z "$label" ] && echo "   Label: $label"
    [ ! -z "$temp" ] && echo "   Current: ${temp}°C"
    echo ""
done < <(find /sys/class/hwmon -name "temp*_input" -print0 2>/dev/null)

if [ $sensor_count -eq 0 ]; then
    echo "No temperature sensors found!"
    echo ""
    echo "Try running: sudo sensors-detect"
    exit 1
fi

# Suggest likely CPU sensors
echo "Suggested CPU sensors:"
echo "====================="

# Look for common CPU sensor names and highlight them
for sensor in "${sensors[@]}"; do
    hwmon_dir=$(dirname "$sensor")
    if [ -f "$hwmon_dir/name" ]; then
        name=$(cat "$hwmon_dir/name")
        # Check for label
        label_file="${sensor%_input}_label"
        label=""
        if [ -f "$label_file" ]; then
            label=$(cat "$label_file")
        fi
        
        case "$name" in
            k10temp)
                if [ "$label" = "Tctl" ]; then
                    echo "✓✓ RECOMMENDED: $sensor ($name - $label) ← USE THIS FOR AMD"
                else
                    echo "✓ $sensor ($name${label:+ - $label})"
                fi
                ;;
            coretemp)
                echo "✓ RECOMMENDED: $sensor ($name) ← USE THIS FOR INTEL"
                ;;
            zenpower)
                echo "✓ $sensor ($name)"
                ;;
        esac
    fi
done

echo ""
echo "To use a sensor, update /etc/af-pro-display/config.toml with:"
echo "cpu_device = \"<sensor_path>\""
echo ""

# If sensors command is available, show output
if command -v sensors &> /dev/null; then
    echo "Output from 'sensors' command:"
    echo "=============================="
    sensors
fi
