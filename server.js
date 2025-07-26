const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const PORT = 8080;

// Serve static files
app.use(express.static(path.join(__dirname, 'web')));
app.use(express.json());

// System utilities
const execPromise = (command) => {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject({ error: error.message, stderr });
            } else {
                resolve(stdout.trim());
            }
        });
    });
};

// WiFi Management
app.get('/api/wifi/scan', async (req, res) => {
    try {
        const result = await execPromise('sudo iwlist wlan0 scan | grep -E "ESSID|Quality|Encryption"');
        const networks = parseWifiScan(result);
        res.json(networks);
    } catch (error) {
        res.status(500).json({ error: 'Failed to scan WiFi networks' });
    }
});

app.post('/api/wifi/connect', async (req, res) => {
    const { ssid, password } = req.body;
    try {
        // Create wpa_supplicant configuration
        const config = `
network={
    ssid="${ssid}"
    psk="${password}"
}`;
        
        await execPromise(`echo '${config}' | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf`);
        await execPromise('sudo wpa_cli -i wlan0 reconfigure');
        
        res.json({ success: true, message: 'Connecting to WiFi...' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to connect to WiFi' });
    }
});

app.post('/api/wifi/disconnect', async (req, res) => {
    try {
        await execPromise('sudo wpa_cli -i wlan0 disconnect');
        res.json({ success: true, message: 'Disconnected from WiFi' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to disconnect WiFi' });
    }
});

// Bluetooth Management
app.get('/api/bluetooth/scan', async (req, res) => {
    try {
        await execPromise('sudo bluetoothctl power on');
        await execPromise('sudo bluetoothctl discoverable on');
        const result = await execPromise('timeout 10 sudo bluetoothctl scan on');
        const devices = await execPromise('sudo bluetoothctl devices');
        
        res.json({ devices: devices.split('\n').filter(line => line.trim()) });
    } catch (error) {
        res.status(500).json({ error: 'Failed to scan Bluetooth devices' });
    }
});

app.post('/api/bluetooth/connect', async (req, res) => {
    const { address } = req.body;
    try {
        await execPromise(`sudo bluetoothctl connect ${address}`);
        res.json({ success: true, message: 'Connected to Bluetooth device' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to connect to Bluetooth device' });
    }
});

// System Management
app.get('/api/system/info', async (req, res) => {
    try {
        const [uptime, memory, cpu, temp] = await Promise.all([
            execPromise('uptime -p'),
            execPromise('free -h | grep Mem'),
            execPromise('cat /proc/loadavg'),
            execPromise('vcgencmd measure_temp')
        ]);
        
        res.json({
            uptime,
            memory: memory.split(/\s+/),
            cpu: cpu.split(' ')[0],
            temperature: temp.replace('temp=', '')
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get system info' });
    }
});

app.post('/api/system/power', async (req, res) => {
    const { action } = req.body;
    try {
        if (action === 'shutdown') {
            await execPromise('sudo shutdown -h now');
        } else if (action === 'reboot') {
            await execPromise('sudo reboot');
        }
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Failed to execute power action' });
    }
});

// Settings Management
app.get('/api/settings', (req, res) => {
    try {
        const settingsPath = path.join(__dirname, 'config', 'settings.json');
        if (fs.existsSync(settingsPath)) {
            const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
            res.json(settings);
        } else {
            const defaultSettings = {
                theme: 'dark',
                virtualKeyboard: true,
                autoConnect: false,
                screenTimeout: 0
            };
            res.json(defaultSettings);
        }
    } catch (error) {
        res.status(500).json({ error: 'Failed to load settings' });
    }
});

app.post('/api/settings', (req, res) => {
    try {
        const settingsPath = path.join(__dirname, 'config', 'settings.json');
        fs.writeFileSync(settingsPath, JSON.stringify(req.body, null, 2));
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Failed to save settings' });
    }
});

// Helper function to parse WiFi scan results
function parseWifiScan(scanResult) {
    const networks = [];
    const lines = scanResult.split('\n');
    let currentNetwork = {};
    
    for (const line of lines) {
        if (line.includes('ESSID:')) {
            if (currentNetwork.ssid) {
                networks.push(currentNetwork);
            }
            currentNetwork = {
                ssid: line.split('ESSID:')[1].replace(/"/g, '').trim()
            };
        } else if (line.includes('Quality=')) {
            const quality = line.match(/Quality=(\d+\/\d+)/);
            if (quality) {
                currentNetwork.quality = quality[1];
            }
        } else if (line.includes('Encryption key:')) {
            currentNetwork.encrypted = line.includes('on');
        }
    }
    
    if (currentNetwork.ssid) {
        networks.push(currentNetwork);
    }
    
    return networks;
}

// Socket.IO for real-time updates
io.on('connection', (socket) => {
    console.log('Client connected');
    
    socket.on('disconnect', () => {
        console.log('Client disconnected');
    });
});

server.listen(PORT, () => {
    console.log(`YouTube TV OS Server running on port ${PORT}`);
});