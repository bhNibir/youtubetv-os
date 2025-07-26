#!/bin/bash

# Bluetooth Management Script for YouTube TV OS

case "$1" in
    "scan")
        # Enable Bluetooth
        sudo bluetoothctl power on
        sudo bluetoothctl discoverable on
        
        # Scan for devices
        timeout 10 sudo bluetoothctl scan on &
        sleep 10
        
        # List discovered devices
        sudo bluetoothctl devices
        ;;
    "connect")
        DEVICE_ADDRESS="$2"
        
        # Pair and connect
        sudo bluetoothctl pair "$DEVICE_ADDRESS"
        sudo bluetoothctl trust "$DEVICE_ADDRESS"
        sudo bluetoothctl connect "$DEVICE_ADDRESS"
        
        if sudo bluetoothctl info "$DEVICE_ADDRESS" | grep -q "Connected: yes"; then
            echo "Connected to $DEVICE_ADDRESS successfully"
            exit 0
        else
            echo "Failed to connect to $DEVICE_ADDRESS"
            exit 1
        fi
        ;;
    "disconnect")
        DEVICE_ADDRESS="$2"
        sudo bluetoothctl disconnect "$DEVICE_ADDRESS"
        echo "Disconnected from $DEVICE_ADDRESS"
        ;;
    "list")
        sudo bluetoothctl devices
        ;;
    *)
        echo "Usage: $0 {scan|connect DEVICE_ADDRESS|disconnect DEVICE_ADDRESS|list}"
        exit 1
        ;;
esac