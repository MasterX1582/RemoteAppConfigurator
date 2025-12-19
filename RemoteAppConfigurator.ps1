#Requires -RunAsAdministrator
<#
.SYNOPSIS
    RemoteApp Configurator - GUI tool for enabling and managing RemoteApps on Windows 10/11

.DESCRIPTION
    This tool simplifies the process of:
    - Enabling Remote Desktop Protocol (RDP)
    - Configuring registry settings for RemoteApp
    - Registering applications as RemoteApps
    - Generating RDP files for client connections

.NOTES
    Author: RemoteApp Configurator
    Requires: Windows 10/11 Pro or Enterprise, Administrator privileges
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================
# XAML GUI Definition
# ============================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RemoteApp Configurator" 
        Height="1020" Width="900"
        MinHeight="1020" MinWidth="800"
        WindowStartupLocation="CenterScreen"
        Background="#1e1e2e">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#89b4fa"/>
            <Setter Property="Foreground" Value="#1e1e2e"/>
            <Setter Property="BorderBrush" Value="#89b4fa"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#b4befe"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#45475a"/>
                    <Setter Property="Foreground" Value="#6c7086"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#cdd6f4"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#cdd6f4"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="BorderBrush" Value="#45475a"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="2"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ListBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="BorderBrush" Value="#45475a"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        <Style TargetType="ListBoxItem">
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="Padding" Value="10,8"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#45475a"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#3b3d4d"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="BorderBrush" Value="#45475a"/>
            <Setter Property="Foreground" Value="#cdd6f4"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#cdd6f4"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="RemoteApp Configurator" FontSize="28" FontWeight="Bold" Foreground="#89b4fa"/>
            <TextBlock Text="Configure and manage RemoteApps on Windows 10/11" FontSize="14" Foreground="#a6adc8" Margin="0,5,0,0"/>
        </StackPanel>
        
        <!-- System Status -->
        <Border Grid.Row="1" Background="#313244" CornerRadius="8" Padding="15" Margin="0,0,0,15">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto" MinWidth="220"/>
                            <ColumnDefinition Width="Auto" MinWidth="220"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                <TextBlock Text="RDP Registry: " FontWeight="SemiBold" Width="110"/>
                                <TextBlock x:Name="txtRdpStatus" Text="Checking..." Foreground="#f9e2af"/>
                            </StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                <TextBlock Text="RemoteApp Policy: " FontWeight="SemiBold" Width="110"/>
                                <TextBlock x:Name="txtPolicyStatus" Text="Checking..." Foreground="#f9e2af"/>
                            </StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                <TextBlock Text="Port 3389: " FontWeight="SemiBold" Width="110"/>
                                <TextBlock x:Name="txtPortStatus" Text="Checking..." Foreground="#f9e2af"/>
                            </StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                <TextBlock Text="Firewall: " FontWeight="SemiBold" Width="110"/>
                                <TextBlock x:Name="txtFirewallStatus" Text="Checking..." Foreground="#f9e2af"/>
                            </StackPanel>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Margin="20,0,0,0">
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                <TextBlock Text="TermService: " FontWeight="SemiBold" Width="100"/>
                                <TextBlock x:Name="txtTermService" Text="Checking..." Foreground="#f9e2af"/>
                            </StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                <TextBlock Text="Computer: " FontWeight="SemiBold" Width="100"/>
                                <TextBlock x:Name="txtComputerName" Text="" Foreground="#94e2d5"/>
                            </StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                <TextBlock Text="IP Address: " FontWeight="SemiBold" Width="100"/>
                                <TextBlock x:Name="txtIpAddress" Text="" Foreground="#94e2d5"/>
                            </StackPanel>
                        </StackPanel>
                    </Grid>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <StackPanel Orientation="Horizontal">
                        <Button x:Name="btnEnableRdp" Content="Enable RDP" Width="110"/>
                        <Button x:Name="btnEnablePolicy" Content="Enable Policy" Width="110"/>
                        <Button x:Name="btnRefresh" Content="Refresh" Width="90"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                        <Button x:Name="btnDisableRdp" Content="Disable RDP" Width="110" Background="#f38ba8"/>
                        <Button x:Name="btnDisablePolicy" Content="Reset Policy" Width="110" Background="#f38ba8"/>
                        <Button x:Name="btnResetAll" Content="Reset All" Width="90" Background="#f38ba8"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Main Content -->
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <!-- Left Panel: Add Application -->
            <Border Grid.Column="0" Background="#313244" CornerRadius="8" Padding="15">
                <StackPanel>
                    <TextBlock Text="Add New RemoteApp" FontSize="18" FontWeight="SemiBold" Foreground="#a6e3a1" Margin="0,0,0,15"/>
                    
                    <TextBlock Text="Application Name:" Margin="0,0,0,5"/>
                    <TextBox x:Name="txtAppName" Margin="0,0,0,10"/>
                    
                    <TextBlock Text="Application Path:" Margin="0,0,0,5"/>
                    <Grid Margin="0,0,0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBox x:Name="txtAppPath" Grid.Column="0"/>
                        <Button x:Name="btnBrowse" Content="Browse..." Grid.Column="1" Margin="5,0,0,0"/>
                    </Grid>
                    
                    <TextBlock Text="Command Line Arguments (optional):" Margin="0,0,0,5"/>
                    <TextBox x:Name="txtCommandLine" Margin="0,0,0,10"/>
                    
                    <TextBlock Text="Icon Path (optional, defaults to app path):" Margin="0,0,0,5"/>
                    <Grid Margin="0,0,0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBox x:Name="txtIconPath" Grid.Column="0"/>
                        <Button x:Name="btnBrowseIcon" Content="Browse..." Grid.Column="1" Margin="5,0,0,0"/>
                    </Grid>
                    
                    <Button x:Name="btnAddApp" Content="+ Add RemoteApp" HorizontalAlignment="Left" Background="#a6e3a1" Margin="0,0,0,15"/>
                    
                    <!-- Quick Add Section -->
                    <Border Background="#45475a" CornerRadius="6" Padding="10">
                        <StackPanel>
                            <TextBlock Text="Quick Add Installed Apps" FontWeight="SemiBold" Margin="0,0,0,10"/>
                            <ListBox x:Name="lstInstalledApps" Height="145" SelectionMode="Single">
                                <ListBox.ItemTemplate>
                                    <DataTemplate>
                                        <TextBlock Text="{Binding DisplayName}"/>
                                    </DataTemplate>
                                </ListBox.ItemTemplate>
                            </ListBox>
                            <Button x:Name="btnQuickAdd" Content="Add Selected" HorizontalAlignment="Left" Margin="0,10,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </Border>
            
            <!-- Right Panel: Registered Apps -->
            <Border Grid.Column="2" Background="#313244" CornerRadius="8" Padding="15">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <TextBlock Grid.Row="0" Text="Registered RemoteApps" FontSize="18" FontWeight="SemiBold" Foreground="#f5c2e7" Margin="0,0,0,10"/>
                    
                    <!-- Server Address for RDP -->
                    <Border Grid.Row="1" Background="#45475a" CornerRadius="4" Padding="10" Margin="0,0,0,10">
                        <StackPanel>
                            <TextBlock Text="Server Address for RDP Files:" FontWeight="SemiBold" Margin="0,0,0,5"/>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" Margin="0,0,15,0">
                                    <RadioButton x:Name="rbComputerName" Content="Computer Name" IsChecked="True" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                                    <RadioButton x:Name="rbIpAddress" Content="IP Address" Foreground="#cdd6f4" Margin="0,0,0,5"/>
                                    <RadioButton x:Name="rbCustom" Content="Custom:" Foreground="#cdd6f4"/>
                                </StackPanel>
                                <TextBox x:Name="txtCustomAddress" Grid.Column="1" VerticalAlignment="Bottom" IsEnabled="False"/>
                            </Grid>
                        </StackPanel>
                    </Border>
                    
                    <ListBox x:Name="lstRemoteApps" Grid.Row="2" MinHeight="200">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <StackPanel Margin="5">
                                    <TextBlock Text="{Binding Name}" FontWeight="SemiBold" FontSize="14"/>
                                    <TextBlock Text="{Binding Path}" FontSize="11" Foreground="#a6adc8" TextTrimming="CharacterEllipsis"/>
                                </StackPanel>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>
                    
                    <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,15,0,0">
                        <Button x:Name="btnRemoveApp" Content="Remove" Background="#f38ba8"/>
                        <Button x:Name="btnGenerateRdp" Content="Generate RDP File" Background="#fab387"/>
                        <Button x:Name="btnGenerateAllRdp" Content="Export All" Background="#fab387"/>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>
        
        <!-- Footer / Log -->
        <Border Grid.Row="3" Background="#313244" CornerRadius="8" Padding="10" Margin="0,15,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name="txtLog" Grid.Column="0" IsReadOnly="True" TextWrapping="Wrap" 
                         Height="80" VerticalScrollBarVisibility="Auto"
                         Background="#1e1e2e" BorderThickness="0"/>
                <Button x:Name="btnClearLog" Grid.Column="1" Content="Clear" VerticalAlignment="Top"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ============================================
# Helper Functions
# ============================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] $Level : $Message"
    $script:Window.Dispatcher.Invoke([action]{
        $txtLog.AppendText("$logMessage`r`n")
        $txtLog.ScrollToEnd()
    })
}

function Get-RdpStatus {
    try {
        $rdpEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections
        return ($rdpEnabled -eq 0)
    }
    catch {
        return $false
    }
}

function Get-RemoteAppPolicyStatus {
    try {
        # Check registry key for allowing unlisted programs
        $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        if (Test-Path $policyPath) {
            $value = (Get-ItemProperty -Path $policyPath -Name "fAllowUnlistedRemotePrograms" -ErrorAction SilentlyContinue).fAllowUnlistedRemotePrograms
            if ($value -eq 1) { return $true }
        }
        
        # Also check the direct Terminal Server path
        $tsPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList'
        if (Test-Path $tsPath) {
            $value = (Get-ItemProperty -Path $tsPath -Name "fDisabledAllowList" -ErrorAction SilentlyContinue).fDisabledAllowList
            if ($value -eq 1) { return $true }
        }
        
        return $false
    }
    catch {
        return $false
    }
}

function Enable-Rdp {
    try {
        # Enable RDP in registry
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1 -Force
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "fEnableWinStation" -Value 1 -Force
        
        # Enable firewall rules
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        
        # Set required services to start automatically
        Set-Service -Name SessionEnv -StartupType Automatic -ErrorAction SilentlyContinue
        Set-Service -Name TermService -StartupType Automatic -ErrorAction SilentlyContinue
        Set-Service -Name UmRdpService -StartupType Automatic -ErrorAction SilentlyContinue
        
        # Start dependent services first
        Start-Service -Name SessionEnv -ErrorAction SilentlyContinue
        Start-Service -Name UmRdpService -ErrorAction SilentlyContinue
        
        # Restart TermService to apply all changes
        try {
            Stop-Service -Name TermService -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        } catch {}
        Start-Service -Name TermService -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        # Verify port is listening
        $portListening = $null -ne (Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue)
        
        return $portListening
    }
    catch {
        return $false
    }
}

function Enable-RemoteAppPolicy {
    try {
        # Create/set the policy to allow unlisted remote programs
        $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        if (-not (Test-Path $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }
        Set-ItemProperty -Path $policyPath -Name "fAllowUnlistedRemotePrograms" -Value 1 -Type DWord -Force
        
        # Also configure the TSAppAllowList
        $tsPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList'
        if (-not (Test-Path $tsPath)) {
            New-Item -Path $tsPath -Force | Out-Null
        }
        Set-ItemProperty -Path $tsPath -Name "fDisabledAllowList" -Value 1 -Type DWord -Force
        
        # Create Applications subkey if not exists
        $appsPath = "$tsPath\Applications"
        if (-not (Test-Path $appsPath)) {
            New-Item -Path $appsPath -Force | Out-Null
        }
        
        return $true
    }
    catch {
        return $false
    }
}

function Disable-Rdp {
    try {
        # Disable RDP in registry
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1 -Force
        
        # Disable firewall rules
        Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        
        # Stop the RDP service
        Stop-Service -Name TermService -Force -ErrorAction SilentlyContinue
        
        # Set services back to manual
        Set-Service -Name SessionEnv -StartupType Manual -ErrorAction SilentlyContinue
        Set-Service -Name TermService -StartupType Manual -ErrorAction SilentlyContinue
        Set-Service -Name UmRdpService -StartupType Manual -ErrorAction SilentlyContinue
        
        return $true
    }
    catch {
        return $false
    }
}

function Disable-RemoteAppPolicy {
    try {
        # Remove the policy for allowing unlisted remote programs
        $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        if (Test-Path $policyPath) {
            Remove-ItemProperty -Path $policyPath -Name "fAllowUnlistedRemotePrograms" -ErrorAction SilentlyContinue
        }
        
        # Reset the TSAppAllowList setting
        $tsPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList'
        if (Test-Path $tsPath) {
            Set-ItemProperty -Path $tsPath -Name "fDisabledAllowList" -Value 0 -Type DWord -Force
        }
        
        return $true
    }
    catch {
        return $false
    }
}

function Reset-AllSettings {
    $rdpResult = Disable-Rdp
    $policyResult = Disable-RemoteAppPolicy
    return ($rdpResult -and $policyResult)
}

function Get-RegisteredRemoteApps {
    $apps = [System.Collections.ArrayList]::new()
    $appsPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications'
    
    if (Test-Path $appsPath) {
        Get-ChildItem -Path $appsPath | ForEach-Object {
            $appKey = $_.PSPath
            $name = $_.PSChildName
            $path = (Get-ItemProperty -Path $appKey -Name "Path" -ErrorAction SilentlyContinue).Path
            $cmdLine = (Get-ItemProperty -Path $appKey -Name "CommandLineSetting" -ErrorAction SilentlyContinue).CommandLineSetting
            $iconPath = (Get-ItemProperty -Path $appKey -Name "IconPath" -ErrorAction SilentlyContinue).IconPath
            
            [void]$apps.Add([PSCustomObject]@{
                Name = $name
                Path = $path
                CommandLine = $cmdLine
                IconPath = $iconPath
            })
        }
    }
    
    return $apps
}

function Add-RemoteApp {
    param(
        [string]$Name,
        [string]$Path,
        [string]$CommandLine = "",
        [string]$IconPath = ""
    )
    
    try {
        $appsPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications'
        
        # Ensure parent path exists
        if (-not (Test-Path $appsPath)) {
            New-Item -Path $appsPath -Force | Out-Null
        }
        
        $appPath = "$appsPath\$Name"
        
        # Create app key
        if (-not (Test-Path $appPath)) {
            New-Item -Path $appPath -Force | Out-Null
        }
        
        # Set properties
        Set-ItemProperty -Path $appPath -Name "Name" -Value $Name -Type String -Force
        Set-ItemProperty -Path $appPath -Name "Path" -Value $Path -Type String -Force
        
        # Command line setting: 0 = not allowed, 1 = allowed, 2 = required
        if ($CommandLine) {
            Set-ItemProperty -Path $appPath -Name "CommandLineSetting" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $appPath -Name "RequiredCommandLine" -Value $CommandLine -Type String -Force
        } else {
            Set-ItemProperty -Path $appPath -Name "CommandLineSetting" -Value 0 -Type DWord -Force
        }
        
        # Icon
        if ($IconPath) {
            Set-ItemProperty -Path $appPath -Name "IconPath" -Value $IconPath -Type String -Force
        } else {
            Set-ItemProperty -Path $appPath -Name "IconPath" -Value $Path -Type String -Force
        }
        Set-ItemProperty -Path $appPath -Name "IconIndex" -Value 0 -Type DWord -Force
        
        return $true
    }
    catch {
        Write-Log "Error adding app: $_" "ERROR"
        return $false
    }
}

function Remove-RemoteApp {
    param([string]$Name)
    
    try {
        $appPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\$Name"
        if (Test-Path $appPath) {
            Remove-Item -Path $appPath -Recurse -Force
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function New-RdpFile {
    param(
        [string]$AppName,
        [string]$AppPath,
        [string]$ServerAddress,
        [string]$OutputPath,
        [string]$CommandLine = ""
    )
    
    $rdpContent = @"
screen mode id:i:2
use multimon:i:0
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:1
allow desktop composition:i:1
disable full window drag:i:0
disable menu anims:i:0
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
full address:s:$ServerAddress
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:0
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:1
negotiate security layer:i:1
remoteapplicationmode:i:1
remoteapplicationname:s:$AppName
remoteapplicationprogram:s:$AppPath
disableremoteappcapscheck:i:1
alternate shell:s:rdpinit.exe
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
drivestoredirect:s:
"@

    if ($CommandLine) {
        $rdpContent += "`r`nremoteapplicationcmdline:s:$CommandLine"
    }
    
    try {
        $rdpContent | Out-File -FilePath $OutputPath -Encoding ASCII -Force
        return $true
    }
    catch {
        return $false
    }
}

function Get-InstalledApplications {
    $apps = [System.Collections.ArrayList]::new()
    
    # Get apps from registry (64-bit)
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    
    foreach ($path in $regPaths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -and $_.InstallLocation -and $_.DisplayName -notmatch '^\$\{' } |
        ForEach-Object {
            # Try to find the executable
            $exePath = $null
            if ($_.InstallLocation) {
                $possibleExe = Get-ChildItem -Path $_.InstallLocation -Filter "*.exe" -Recurse -Depth 1 -ErrorAction SilentlyContinue | 
                               Select-Object -First 1
                if ($possibleExe) {
                    $exePath = $possibleExe.FullName
                }
            }
            
            if ($exePath) {
                [void]$apps.Add([PSCustomObject]@{
                    DisplayName = $_.DisplayName
                    Path = $exePath
                })
            }
        }
    }
    
    # Add common system apps
    $commonApps = @(
        @{Name="Notepad"; Path="C:\Windows\System32\notepad.exe"},
        @{Name="Calculator"; Path="C:\Windows\System32\calc.exe"},
        @{Name="Paint"; Path="C:\Windows\System32\mspaint.exe"},
        @{Name="WordPad"; Path="C:\Program Files\Windows NT\Accessories\wordpad.exe"},
        @{Name="Command Prompt"; Path="C:\Windows\System32\cmd.exe"},
        @{Name="PowerShell"; Path="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"},
        @{Name="File Explorer"; Path="C:\Windows\explorer.exe"}
    )
    
    foreach ($app in $commonApps) {
        if (Test-Path $app.Path) {
            [void]$apps.Add([PSCustomObject]@{
                DisplayName = $app.Name
                Path = $app.Path
            })
        }
    }
    
    return @($apps | Sort-Object DisplayName -Unique)
}

# ============================================
# Create Window
# ============================================

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtRdpStatus = $Window.FindName("txtRdpStatus")
$txtPolicyStatus = $Window.FindName("txtPolicyStatus")
$txtComputerName = $Window.FindName("txtComputerName")
$btnEnableRdp = $Window.FindName("btnEnableRdp")
$btnEnablePolicy = $Window.FindName("btnEnablePolicy")
$btnRefresh = $Window.FindName("btnRefresh")
$btnDisableRdp = $Window.FindName("btnDisableRdp")
$btnDisablePolicy = $Window.FindName("btnDisablePolicy")
$btnResetAll = $Window.FindName("btnResetAll")
$txtAppName = $Window.FindName("txtAppName")
$txtAppPath = $Window.FindName("txtAppPath")
$txtCommandLine = $Window.FindName("txtCommandLine")
$txtIconPath = $Window.FindName("txtIconPath")
$btnBrowse = $Window.FindName("btnBrowse")
$btnBrowseIcon = $Window.FindName("btnBrowseIcon")
$btnAddApp = $Window.FindName("btnAddApp")
$lstInstalledApps = $Window.FindName("lstInstalledApps")
$btnQuickAdd = $Window.FindName("btnQuickAdd")
$lstRemoteApps = $Window.FindName("lstRemoteApps")
$btnRemoveApp = $Window.FindName("btnRemoveApp")
$btnGenerateRdp = $Window.FindName("btnGenerateRdp")
$btnGenerateAllRdp = $Window.FindName("btnGenerateAllRdp")
$txtLog = $Window.FindName("txtLog")
$btnClearLog = $Window.FindName("btnClearLog")
$txtIpAddress = $Window.FindName("txtIpAddress")
$txtPortStatus = $Window.FindName("txtPortStatus")
$txtFirewallStatus = $Window.FindName("txtFirewallStatus")
$txtTermService = $Window.FindName("txtTermService")
$rbComputerName = $Window.FindName("rbComputerName")
$rbIpAddress = $Window.FindName("rbIpAddress")
$rbCustom = $Window.FindName("rbCustom")
$txtCustomAddress = $Window.FindName("txtCustomAddress")

# ============================================
# UI Update Functions
# ============================================

function Update-Status {
    # RDP Status
    if (Get-RdpStatus) {
        $txtRdpStatus.Text = "[OK] Enabled"
        $txtRdpStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
        $btnEnableRdp.IsEnabled = $false
    } else {
        $txtRdpStatus.Text = "[X] Disabled"
        $txtRdpStatus.Foreground = [System.Windows.Media.Brushes]::Salmon
        $btnEnableRdp.IsEnabled = $true
    }
    
    # Policy Status
    if (Get-RemoteAppPolicyStatus) {
        $txtPolicyStatus.Text = "[OK] Configured"
        $txtPolicyStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
        $btnEnablePolicy.IsEnabled = $false
    } else {
        $txtPolicyStatus.Text = "[X] Not Configured"
        $txtPolicyStatus.Foreground = [System.Windows.Media.Brushes]::Salmon
        $btnEnablePolicy.IsEnabled = $true
    }
    
    # Computer Name
    $txtComputerName.Text = $env:COMPUTERNAME
    
    # IP Address
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress
    if ($ip) {
        $txtIpAddress.Text = $ip
    } else {
        $txtIpAddress.Text = "Not found"
    }
    
    # Port 3389 Status
    $portListening = $null -ne (Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue)
    if ($portListening) {
        $txtPortStatus.Text = "[OK] Listening"
        $txtPortStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
    } else {
        $txtPortStatus.Text = "[X] Not Listening"
        $txtPortStatus.Foreground = [System.Windows.Media.Brushes]::Salmon
    }
    
    # Firewall Status
    $fwRules = Get-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq $true -and $_.Action -eq 'Allow' }
    if ($fwRules.Count -ge 2) {
        $txtFirewallStatus.Text = "[OK] Rules Enabled"
        $txtFirewallStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
    } else {
        $txtFirewallStatus.Text = "[X] Rules Disabled"
        $txtFirewallStatus.Foreground = [System.Windows.Media.Brushes]::Salmon
    }
    
    # TermService Status
    $termSvc = Get-Service -Name TermService -ErrorAction SilentlyContinue
    if ($termSvc.Status -eq 'Running') {
        $txtTermService.Text = "[OK] Running"
        $txtTermService.Foreground = [System.Windows.Media.Brushes]::LightGreen
    } else {
        $txtTermService.Text = "[X] $($termSvc.Status)"
        $txtTermService.Foreground = [System.Windows.Media.Brushes]::Salmon
    }
    
    # Update button state based on overall status
    if ((Get-RdpStatus) -and $portListening) {
        $btnEnableRdp.IsEnabled = $false
    } else {
        $btnEnableRdp.IsEnabled = $true
    }
}

function Update-RemoteAppsList {
    $apps = @(Get-RegisteredRemoteApps)
    $lstRemoteApps.ItemsSource = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new([PSObject[]]$apps)
}

function Update-InstalledAppsList {
    $apps = @(Get-InstalledApplications)
    $lstInstalledApps.ItemsSource = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new([PSObject[]]$apps)
}

# ============================================
# Event Handlers
# ============================================

$btnRefresh.Add_Click({
    Update-Status
    Update-RemoteAppsList
    Write-Log "Status refreshed"
})

$btnEnableRdp.Add_Click({
    Write-Log "Enabling Remote Desktop..." "INFO"
    Write-Log "Setting registry, firewall, and starting services..." "INFO"
    
    $result = Enable-Rdp
    Update-Status
    
    if ($result) {
        Write-Log "Remote Desktop enabled and port 3389 is listening!" "SUCCESS"
    } else {
        Write-Log "RDP configured but port 3389 not listening. Try rebooting the server." "WARN"
    }
})

$btnEnablePolicy.Add_Click({
    if (Enable-RemoteAppPolicy) {
        Write-Log "RemoteApp policy configured successfully" "SUCCESS"
        Update-Status
    } else {
        Write-Log "Failed to configure RemoteApp policy" "ERROR"
    }
})

$btnDisableRdp.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to disable Remote Desktop?`n`nThis will:`n- Disable RDP in registry`n- Disable firewall rules`n- Stop RDP services",
        "Confirm Disable RDP",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Write-Log "Disabling Remote Desktop..." "INFO"
        if (Disable-Rdp) {
            Write-Log "Remote Desktop disabled successfully" "SUCCESS"
        } else {
            Write-Log "Failed to disable Remote Desktop" "ERROR"
        }
        Update-Status
    }
})

$btnDisablePolicy.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to reset the RemoteApp policy?`n`nThis will disable the RemoteApp policy settings.`nRegistered apps will remain but won't be accessible remotely.",
        "Confirm Reset Policy",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Write-Log "Resetting RemoteApp policy..." "INFO"
        if (Disable-RemoteAppPolicy) {
            Write-Log "RemoteApp policy reset to default" "SUCCESS"
        } else {
            Write-Log "Failed to reset RemoteApp policy" "ERROR"
        }
        Update-Status
    }
})

$btnResetAll.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to reset ALL settings?`n`nThis will:`n- Disable Remote Desktop`n- Reset RemoteApp policy`n- Disable firewall rules`n- Stop RDP services`n`nRegistered apps will remain in registry.",
        "Confirm Reset All",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Write-Log "Resetting all settings to default..." "INFO"
        if (Reset-AllSettings) {
            Write-Log "All settings reset to default successfully" "SUCCESS"
        } else {
            Write-Log "Some settings may have failed to reset" "WARN"
        }
        Update-Status
    }
})

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    $dialog.Title = "Select Application"
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtAppPath.Text = $dialog.FileName
        
        # Auto-fill name if empty
        if ([string]::IsNullOrWhiteSpace($txtAppName.Text)) {
            $txtAppName.Text = [System.IO.Path]::GetFileNameWithoutExtension($dialog.FileName)
        }
    }
})

$btnBrowseIcon.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Icon files (*.ico;*.exe)|*.ico;*.exe|All files (*.*)|*.*"
    $dialog.Title = "Select Icon"
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtIconPath.Text = $dialog.FileName
    }
})

$btnAddApp.Add_Click({
    $name = $txtAppName.Text.Trim()
    $path = $txtAppPath.Text.Trim()
    $cmdLine = $txtCommandLine.Text.Trim()
    $iconPath = $txtIconPath.Text.Trim()
    
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Log "Please enter an application name" "WARN"
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Log "Please select an application path" "WARN"
        return
    }
    
    if (-not (Test-Path $path)) {
        Write-Log "Application path does not exist: $path" "ERROR"
        return
    }
    
    if (Add-RemoteApp -Name $name -Path $path -CommandLine $cmdLine -IconPath $iconPath) {
        Write-Log "Added RemoteApp: $name" "SUCCESS"
        Update-RemoteAppsList
        
        # Clear fields
        $txtAppName.Text = ""
        $txtAppPath.Text = ""
        $txtCommandLine.Text = ""
        $txtIconPath.Text = ""
    } else {
        Write-Log "Failed to add RemoteApp: $name" "ERROR"
    }
})

$btnQuickAdd.Add_Click({
    $selected = $lstInstalledApps.SelectedItem
    if ($null -eq $selected) {
        Write-Log "Please select an application from the list" "WARN"
        return
    }
    
    $name = $selected.DisplayName -replace '[^\w\s-]', ''
    $path = $selected.Path
    
    if (Add-RemoteApp -Name $name -Path $path) {
        Write-Log "Added RemoteApp: $name" "SUCCESS"
        Update-RemoteAppsList
    } else {
        Write-Log "Failed to add RemoteApp: $name" "ERROR"
    }
})

$btnRemoveApp.Add_Click({
    $selected = $lstRemoteApps.SelectedItem
    if ($null -eq $selected) {
        Write-Log "Please select a RemoteApp to remove" "WARN"
        return
    }
    
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to remove '$($selected.Name)'?",
        "Confirm Removal",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        if (Remove-RemoteApp -Name $selected.Name) {
            Write-Log "Removed RemoteApp: $($selected.Name)" "SUCCESS"
            Update-RemoteAppsList
        } else {
            Write-Log "Failed to remove RemoteApp: $($selected.Name)" "ERROR"
        }
    }
})

$btnGenerateRdp.Add_Click({
    $selected = $lstRemoteApps.SelectedItem
    if ($null -eq $selected) {
        Write-Log "Please select a RemoteApp" "WARN"
        return
    }
    
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "RDP files (*.rdp)|*.rdp"
    $dialog.FileName = "$($selected.Name).rdp"
    $dialog.Title = "Save RDP File"
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $serverAddress = Get-SelectedServerAddress
        Write-Log "Using server address: $serverAddress"
        
        if (New-RdpFile -AppName $selected.Name -AppPath $selected.Path -ServerAddress $serverAddress -OutputPath $dialog.FileName) {
            Write-Log "Generated RDP file: $($dialog.FileName)" "SUCCESS"
        } else {
            Write-Log "Failed to generate RDP file" "ERROR"
        }
    }
})

$btnGenerateAllRdp.Add_Click({
    $apps = Get-RegisteredRemoteApps
    if ($apps.Count -eq 0) {
        Write-Log "No RemoteApps registered" "WARN"
        return
    }
    
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select folder to save RDP files"
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $folder = $dialog.SelectedPath
        $serverAddress = Get-SelectedServerAddress
        Write-Log "Using server address: $serverAddress"
        $count = 0
        
        foreach ($app in $apps) {
            $filePath = Join-Path $folder "$($app.Name).rdp"
            if (New-RdpFile -AppName $app.Name -AppPath $app.Path -ServerAddress $serverAddress -OutputPath $filePath) {
                $count++
            }
        }
        
        Write-Log "Generated $count RDP files in: $folder" "SUCCESS"
    }
})

$btnClearLog.Add_Click({
    $txtLog.Clear()
})

# Radio button handlers
$rbCustom.Add_Checked({
    $txtCustomAddress.IsEnabled = $true
})

$rbCustom.Add_Unchecked({
    $txtCustomAddress.IsEnabled = $false
})

# Helper function to get selected server address
function Get-SelectedServerAddress {
    if ($rbComputerName.IsChecked) {
        return $env:COMPUTERNAME
    } elseif ($rbIpAddress.IsChecked) {
        return $txtIpAddress.Text
    } else {
        $custom = $txtCustomAddress.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($custom)) {
            return $env:COMPUTERNAME
        }
        return $custom
    }
}

# ============================================
# Initialize
# ============================================

Update-Status
Update-RemoteAppsList
Update-InstalledAppsList
Write-Log "RemoteApp Configurator initialized"

# Show window
$Window.ShowDialog() | Out-Null
