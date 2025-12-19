# RemoteApp Configurator

A GUI tool for enabling and managing RemoteApps on Windows 10/11 without requiring Windows Server.

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Enable & Configure
- **Enable Remote Desktop** - One-click RDP activation with firewall configuration and service management
- **Configure RemoteApp Policy** - Automatically sets required registry keys
- **Real-time Status Monitoring** - View RDP registry, port listening, firewall rules, and service status

### Manage Applications
- **Add RemoteApps** - Browse and register any application as a RemoteApp
- **Quick Add** - Select from detected installed applications
- **Remove Apps** - Unregister applications from RemoteApp

### Generate Connection Files
- **Server Address Selection** - Choose between Computer Name, IP Address, or Custom address
- **Generate RDP Files** - Create connection files for individual apps
- **Export All** - Batch export RDP files for all registered RemoteApps

### Reset & Disable
- **Disable RDP** - Revert Remote Desktop to disabled state
- **Reset Policy** - Remove RemoteApp policy configurations
- **Reset All** - One-click reset of all settings to Windows defaults

## Status Indicators

The tool displays real-time status for:

| Indicator | Description |
|-----------|-------------|
| **RDP Registry** | Whether Remote Desktop is enabled in registry |
| **RemoteApp Policy** | Whether RemoteApp policy is configured |
| **Port 3389** | Whether RDP is actively listening for connections |
| **Firewall** | Whether Remote Desktop firewall rules are enabled |
| **TermService** | Whether the Remote Desktop Services service is running |
| **Computer Name** | Local computer name for RDP connections |
| **IP Address** | Local IP address for RDP connections |

All indicators should show `[OK]` in green for RemoteApp to function properly.

## Requirements

- Windows 10/11 Pro or Enterprise edition (Home edition not supported)
- Administrator privileges
- PowerShell 5.1 or later (included with Windows)

## Installation

No installation required. Simply download and run.

## Usage

### Method 1: Using the Launcher (Recommended)
Double-click `Launch-RemoteAppConfigurator.bat` - it will automatically request administrator privileges.

### Method 2: Direct PowerShell Execution
1. Open PowerShell as Administrator
2. Navigate to the tool directory
3. Run: `.\RemoteAppConfigurator.ps1`

## How It Works

### Server-Side Configuration (This Tool)

1. **Enable RDP** - Performs the following:
   - Sets `fDenyTSConnections = 0` in registry
   - Enables `fEnableWinStation` for RDP-Tcp listener
   - Enables Windows Firewall rules for Remote Desktop
   - Sets required services to Automatic startup (SessionEnv, TermService, UmRdpService)
   - Starts all RDP-related services
   - Verifies port 3389 is listening

2. **Enable Policy** - Sets registry keys to allow RemoteApp connections:
   - `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\fAllowUnlistedRemotePrograms = 1`
   - `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\fDisabledAllowList = 1`

3. **Register Apps** - Creates entries under `TSAppAllowList\Applications` for each app

### Disable/Reset Functions

- **Disable RDP** - Sets `fDenyTSConnections = 1`, disables firewall rules, stops services, sets services to Manual
- **Reset Policy** - Removes `fAllowUnlistedRemotePrograms`, sets `fDisabledAllowList = 0`
- **Reset All** - Combines both operations

### Client-Side Connection

1. Copy the generated `.rdp` file to the client machine
2. Double-click the RDP file to connect
3. Enter credentials when prompted
4. The application will appear as if running locally

## Registry Structure

```
HKLM:\System\CurrentControlSet\Control\Terminal Server
├── fDenyTSConnections = 0 (RDP enabled)
└── WinStations\RDP-Tcp
    └── fEnableWinStation = 1

HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList
├── fDisabledAllowList = 1
└── Applications
    ├── Notepad
    │   ├── Name = "Notepad"
    │   ├── Path = "C:\Windows\System32\notepad.exe"
    │   ├── IconPath = "C:\Windows\System32\notepad.exe"
    │   ├── IconIndex = 0
    │   └── CommandLineSetting = 0
    └── [Other Apps...]

HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services
└── fAllowUnlistedRemotePrograms = 1
```

## RDP File Format

Generated RDP files include RemoteApp-specific settings:

```ini
full address:s:SERVER_ADDRESS
remoteapplicationmode:i:1
remoteapplicationname:s:AppName
remoteapplicationprogram:s:C:\Path\To\App.exe
disableremoteappcapscheck:i:1
alternate shell:s:rdpinit.exe
prompt for credentials:i:1
```

## Limitations

- **Single Session** - Windows 10/11 Pro/Enterprise allows only one concurrent RDP session
- **Licensing** - No RDS licensing required for personal use, but limited to one user at a time
- **Network** - Client must be able to reach the host machine (same network, VPN, or port forwarding)
- **Windows Edition** - Windows Home edition does not support RDP server functionality

## Troubleshooting

### Error 0x204 - Cannot connect to remote computer

This error means the client cannot reach the server. Check:

1. **Port 3389 not listening** (most common)
   - Verify "Port 3389" shows `[OK] Listening` in the tool
   - If not, click "Enable RDP" and wait for services to start
   - If still not listening, **reboot the server**

2. **Services not running**
   - Check that TermService shows `[OK] Running`
   - Dependent services (SessionEnv, UmRdpService) should also be running

3. **Firewall blocking**
   - Verify "Firewall" shows `[OK] Rules Enabled`
   - Check if third-party firewall/antivirus is blocking port 3389

4. **Wrong address**
   - Try using IP Address instead of Computer Name
   - Verify the server IP is reachable: `Test-NetConnection -ComputerName SERVER_IP -Port 3389`

5. **Network issues**
   - Ensure client and server are on the same network or have proper routing
   - Check for VPN or firewall rules blocking traffic

### RemoteApp doesn't launch
- Ensure the application path is correct
- Verify the policy is enabled (green status)
- Restart the host machine after initial configuration

### "The remote computer disconnected the session"
- The target application may have crashed
- Check Event Viewer for errors
- Try running the app locally first to confirm it works

### Services won't start
- Open Services (services.msc) and check for errors
- Try rebooting the server
- Verify Windows is Pro/Enterprise edition, not Home

## Security Considerations

- Only enable RDP on trusted networks
- Use strong passwords for all user accounts
- Network Level Authentication (NLA) is enabled by default
- Limit which users can connect via Remote Desktop Users group
- Consider using a VPN for remote access over the internet
- Use the Disable/Reset buttons to turn off RDP when not needed

## Files

| File | Description |
|------|-------------|
| `RemoteAppConfigurator.ps1` | Main GUI application |
| `Launch-RemoteAppConfigurator.bat` | Launcher with auto-elevation |
| `README.md` | This documentation |

## License

MIT License - Feel free to modify and distribute.

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.
