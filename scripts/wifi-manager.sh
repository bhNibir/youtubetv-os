#!/bin/bash

# WiFi Management Script for YouTube TV OS

case "$1" in
    "scan")
        sudo iwlist wlan0 scan | grep -E "ESSID|Quality|Encryption"
        ;;
    "connect")
        SSID="$2"
        PASSWORD="$3"
        
        # Backup current config
        sudo cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.bak
        
        # Add network configuration
        sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null <<EOF

network={
    ssid="$SSID"
    psk="$PASSWORD"
    key_mgmt=WPA-PSK
}
EOF
        
        # Reconfigure WiFi
        sudo wpa_cli -i wlan0 reconfigure
        sleep 5
        
        # Check connection
        if iwconfig wlan0 | grep -q "ESSID:\"$SSID\""; then
            echo "Connected to $SSID successfully"
            exit 0
        else
            echo "Failed to connect to $SSID"
            exit 1
        fi
        ;;
    "disconnect")
        sudo wpa_cli -i wlan0 disconnect
        echo "Disconnected from WiFi"
        ;;
    "status")
        iwconfig wlan0 | grep ESSID
        ;;
    *)
        echo "Usage: $0 {scan|connect SSID PASSWORD|disconnect|status}"
        exit 1
        ;;
esac