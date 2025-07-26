// YouTube TV OS Application
class YouTubeTVOS {
    constructor() {
        this.socket = io();
        this.currentTheme = 'dark';
        this.virtualKeyboardEnabled = true;
        this.shiftActive = false;
        this.activeInput = null;
        this.settings = {};
        
        this.init();
    }

    init() {
        this.updateTime();
        this.loadSettings();
        this.setupEventListeners();
        this.setupKeyboardNavigation();
        
        // Update time every minute
        setInterval(() => this.updateTime(), 60000);
    }

    updateTime() {
        const now = new Date();
        const timeString = now.toLocaleTimeString('en-US', { 
            hour: '2-digit', 
            minute: '2-digit',
            hour12: false 
        });
        document.getElementById('current-time').textContent = timeString;
    }

    async loadSettings() {
        try {
            const response = await fetch('/api/settings');
            this.settings = await response.json();
            this.applySettings();
        } catch (error) {
            console.error('Failed to load settings:', error);
        }
    }

    async saveSettings() {
        try {
            await fetch('/api/settings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(this.settings)
            });
        } catch (error) {
            console.error('Failed to save settings:', error);
        }
    }

    applySettings() {
        if (this.settings.theme) {
            this.setTheme(this.settings.theme);
        }
        if (this.settings.virtualKeyboard !== undefined) {
            this.virtualKeyboardEnabled = this.settings.virtualKeyboard;
        }
    }

    setupEventListeners() {
        // Input focus events for virtual keyboard
        document.addEventListener('focusin', (e) => {
            if (e.target.tagName === 'INPUT' && this.virtualKeyboardEnabled) {
                this.activeInput = e.target;
                this.showKeyboard();
            }
        });

        document.addEventListener('focusout', (e) => {
            if (e.target.tagName === 'INPUT') {
                setTimeout(() => {
                    if (!document.activeElement || document.activeElement.tagName !== 'INPUT') {
                        this.hideKeyboard();
                    }
                }, 100);
            }
        });

        // Socket events
        this.socket.on('connect', () => {
            console.log('Connected to server');
        });

        this.socket.on('disconnect', () => {
            console.log('Disconnected from server');
        });
    }

    setupKeyboardNavigation() {
        document.addEventListener('keydown', (e) => {
            const focusableElements = document.querySelectorAll(
                'button, input, select, .control-card, .app-card, .network-item, .device-item'
            );
            const currentIndex = Array.from(focusableElements).indexOf(document.activeElement);

            switch (e.key) {
                case 'ArrowRight':
                    e.preventDefault();
                    this.focusNext(focusableElements, currentIndex);
                    break;
                case 'ArrowLeft':
                    e.preventDefault();
                    this.focusPrevious(focusableElements, currentIndex);
                    break;
                case 'ArrowDown':
                    e.preventDefault();
                    this.focusDown(focusableElements, currentIndex);
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    this.focusUp(focusableElements, currentIndex);
                    break;
                case 'Enter':
                    if (document.activeElement && document.activeElement.click) {
                        document.activeElement.click();
                    }
                    break;
                case 'Escape':
                    this.closePanel();
                    break;
            }
        });
    }

    focusNext(elements, currentIndex) {
        const nextIndex = (currentIndex + 1) % elements.length;
        elements[nextIndex].focus();
    }

    focusPrevious(elements, currentIndex) {
        const prevIndex = currentIndex <= 0 ? elements.length - 1 : currentIndex - 1;
        elements[prevIndex].focus();
    }

    focusDown(elements, currentIndex) {
        // Simple implementation - can be enhanced for grid navigation
        const nextIndex = Math.min(currentIndex + 3, elements.length - 1);
        elements[nextIndex].focus();
    }

    focusUp(elements, currentIndex) {
        // Simple implementation - can be enhanced for grid navigation
        const prevIndex = Math.max(currentIndex - 3, 0);
        elements[prevIndex].focus();
    }

    setTheme(theme) {
        this.currentTheme = theme;
        document.body.setAttribute('data-theme', theme);
        
        const themeCard = document.querySelector('.theme-card');
        const themeIcon = themeCard.querySelector('.card-icon');
        const themeTitle = themeCard.querySelector('.card-title');
        
        if (theme === 'dark') {
            themeIcon.textContent = '☀️';
            themeTitle.textContent = 'Light';
        } else {
            themeIcon.textContent = '🌙';
            themeTitle.textContent = 'Dark';
        }
    }

    toggleTheme() {
        const newTheme = this.currentTheme === 'dark' ? 'light' : 'dark';
        this.setTheme(newTheme);
        this.settings.theme = newTheme;
        this.saveSettings();
    }

    // Panel Management
    openPanel(panelId) {
        this.closePanel();
        const panel = document.getElementById(panelId);
        if (panel) {
            panel.classList.add('active');
            // Focus first focusable element in panel
            const firstFocusable = panel.querySelector('button, input, select');
            if (firstFocusable) {
                firstFocusable.focus();
            }
        }
    }

    closePanel() {
        const activePanel = document.querySelector('.panel.active');
        if (activePanel) {
            activePanel.classList.remove('active');
        }
        this.hideKeyboard();
    }

    // WiFi Management
    async openWifiPanel() {
        this.openPanel('wifi-panel');
        await this.scanWifi();
    }

    async scanWifi() {
        const networksDiv = document.getElementById('wifi-networks');
        networksDiv.innerHTML = '<div class="loading"></div> Scanning for networks...';
        
        try {
            const response = await fetch('/api/wifi/scan');
            const networks = await response.json();
            
            networksDiv.innerHTML = '';
            networks.forEach(network => {
                const networkDiv = document.createElement('div');
                networkDiv.className = 'network-item';
                networkDiv.innerHTML = `
                    <div>
                        <strong>${network.ssid}</strong>
                        <br><small>Quality: ${network.quality || 'Unknown'}</small>
                    </div>
                    <button onclick="app.connectWifi('${network.ssid}', ${network.encrypted})">
                        ${network.encrypted ? '🔒 Connect' : '📶 Connect'}
                    </button>
                `;
                networksDiv.appendChild(networkDiv);
            });
        } catch (error) {
            networksDiv.innerHTML = '<p>Failed to scan networks. Please try again.</p>';
        }
    }

    async connectWifi(ssid, encrypted) {
        let password = '';
        if (encrypted) {
            password = prompt(`Enter password for ${ssid}:`);
            if (!password) return;
        }

        try {
            const response = await fetch('/api/wifi/connect', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ ssid, password })
            });
            
            const result = await response.json();
            alert(result.message || 'Connected successfully');
            
            if (result.success) {
                document.getElementById('wifi-status').textContent = `📶 ${ssid}`;
            }
        } catch (error) {
            alert('Failed to connect to WiFi');
        }
    }

    async disconnectWifi() {
        try {
            const response = await fetch('/api/wifi/disconnect', { method: 'POST' });
            const result = await response.json();
            alert(result.message);
            
            if (result.success) {
                document.getElementById('wifi-status').textContent = '📶 Disconnected';
            }
        } catch (error) {
            alert('Failed to disconnect WiFi');
        }
    }

    // Bluetooth Management
    async openBluetoothPanel() {
        this.openPanel('bluetooth-panel');
        await this.scanBluetooth();
    }

    async scanBluetooth() {
        const devicesDiv = document.getElementById('bluetooth-devices');
        devicesDiv.innerHTML = '<div class="loading"></div> Scanning for devices...';
        
        try {
            const response = await fetch('/api/bluetooth/scan');
            const result = await response.json();
            
            devicesDiv.innerHTML = '';
            result.devices.forEach(device => {
                const deviceDiv = document.createElement('div');
                deviceDiv.className = 'device-item';
                const parts = device.split(' ');
                const address = parts[1];
                const name = parts.slice(2).join(' ') || 'Unknown Device';
                
                deviceDiv.innerHTML = `
                    <div>
                        <strong>${name}</strong>
                        <br><small>${address}</small>
                    </div>
                    <button onclick="app.connectBluetooth('${address}')">Connect</button>
                `;
                devicesDiv.appendChild(deviceDiv);
            });
        } catch (error) {
            devicesDiv.innerHTML = '<p>Failed to scan devices. Please try again.</p>';
        }
    }

    async connectBluetooth(address) {
        try {
            const response = await fetch('/api/bluetooth/connect', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ address })
            });
            
            const result = await response.json();
            alert(result.message || 'Connected successfully');
        } catch (error) {
            alert('Failed to connect to Bluetooth device');
        }
    }

    // Search and Navigation
    openSearchPanel() {
        this.openPanel('search-panel');
        document.getElementById('search-input').focus();
    }

    performSearch() {
        const query = document.getElementById('search-input').value;
        if (query) {
            const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(query)}`;
            window.location.href = searchUrl;
        }
    }

    navigateToUrl() {
        const url = document.getElementById('search-input').value;
        if (url) {
            let finalUrl = url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
                finalUrl = 'https://' + url;
            }
            window.location.href = finalUrl;
        }
    }

    // Power Management
    async openPowerPanel() {
        this.openPanel('power-panel');
        await this.loadSystemInfo();
    }

    async loadSystemInfo() {
        const systemInfoDiv = document.getElementById('system-info');
        systemInfoDiv.innerHTML = '<div class="loading"></div> Loading system information...';
        
        try {
            const response = await fetch('/api/system/info');
            const info = await response.json();
            
            systemInfoDiv.innerHTML = `
                <h3>System Information</h3>
                <p><strong>Uptime:</strong> ${info.uptime}</p>
                <p><strong>Memory:</strong> ${info.memory[2]} used / ${info.memory[1]} total</p>
                <p><strong>CPU Load:</strong> ${info.cpu}</p>
                <p><strong>Temperature:</strong> ${info.temperature}</p>
            `;
        } catch (error) {
            systemInfoDiv.innerHTML = '<p>Failed to load system information.</p>';
        }
    }

    async powerAction(action) {
        const confirmMessage = action === 'shutdown' ? 
            'Are you sure you want to shutdown the system?' : 
            'Are you sure you want to reboot the system?';
            
        if (confirm(confirmMessage)) {
            try {
                await fetch('/api/system/power', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action })
                });
            } catch (error) {
                console.error('Power action failed:', error);
            }
        }
    }

    // Settings Management
    openSettingsPanel() {
        this.openPanel('settings-panel');
        this.loadSettingsUI();
    }

    loadSettingsUI() {
        document.getElementById('virtual-keyboard-toggle').checked = this.virtualKeyboardEnabled;
        document.getElementById('theme-select').value = this.currentTheme;
        document.getElementById('auto-connect-toggle').checked = this.settings.autoConnect || false;
    }

    toggleVirtualKeyboard() {
        this.virtualKeyboardEnabled = document.getElementById('virtual-keyboard-toggle').checked;
        this.settings.virtualKeyboard = this.virtualKeyboardEnabled;
        this.saveSettings();
    }

    changeTheme() {
        const newTheme = document.getElementById('theme-select').value;
        this.setTheme(newTheme);
        this.settings.theme = newTheme;
        this.saveSettings();
    }

    // Virtual Keyboard
    showKeyboard() {
        if (this.virtualKeyboardEnabled) {
            document.getElementById('virtual-keyboard').classList.add('active');
        }
    }

    hideKeyboard() {
        document.getElementById('virtual-keyboard').classList.remove('active');
        this.activeInput = null;
    }

    typeKey(key) {
        if (!this.activeInput) return;

        if (key === 'Enter') {
            this.activeInput.blur();
            return;
        }

        if (key === ' ') {
            this.activeInput.value += ' ';
        } else {
            const finalKey = this.shiftActive ? key.toUpperCase() : key;
            this.activeInput.value += finalKey;
        }

        // Trigger input event
        this.activeInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    backspace() {
        if (!this.activeInput) return;
        this.activeInput.value = this.activeInput.value.slice(0, -1);
        this.activeInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    toggleShift() {
        this.shiftActive = !this.shiftActive;
        const shiftKey = document.querySelector('.key.shift');
        if (this.shiftActive) {
            shiftKey.classList.add('active');
        } else {
            shiftKey.classList.remove('active');
        }
    }

    // App Navigation
    openYouTubeTV() {
        window.location.href = 'https://www.youtube.com/tv';
    }
}

// Global functions for HTML onclick handlers
function openWifiPanel() { app.openWifiPanel(); }
function openBluetoothPanel() { app.openBluetoothPanel(); }
function openSearchPanel() { app.openSearchPanel(); }
function openPowerPanel() { app.openPowerPanel(); }
function openSettingsPanel() { app.openSettingsPanel(); }
function toggleTheme() { app.toggleTheme(); }
function closePanel() { app.closePanel(); }
function scanWifi() { app.scanWifi(); }
function scanBluetooth() { app.scanBluetooth(); }
function performSearch() { app.performSearch(); }
function navigateToUrl() { app.navigateToUrl(); }
function powerAction(action) { app.powerAction(action); }
function toggleVirtualKeyboard() { app.toggleVirtualKeyboard(); }
function changeTheme() { app.changeTheme(); }
function openYouTubeTV() { app.openYouTubeTV(); }
function typeKey(key) { app.typeKey(key); }
function backspace() { app.backspace(); }
function toggleShift() { app.toggleShift(); }
function hideKeyboard() { app.hideKeyboard(); }

// Initialize the application
const app = new YouTubeTVOS();