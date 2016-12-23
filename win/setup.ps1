# Set-PSDebug -Trace 1
################################################
# check Administrator
################################################
if ((-not (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) -Or ((Get-ExecutionPolicy) -ne "Unrestricted")) {
    Write-Host "Please run `"setup.bat`" as administrator."
    Write-Host "Press any key to exit"
    [Console]::ReadKey() | Out-Null
    exit 1
}

################################################
# Auto Login
################################################
$DefaultUserName = "k"
$DefaultPassword = Read-Host "Enter Password"
$DefaultDomainName = ""
$RegLogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-itemproperty -path $RegLogonKey -name "AutoAdminLogon" -value 1
Set-itemproperty -path $RegLogonKey -name "DefaultUsername" -value $DefaultUserName
Set-itemproperty -path $RegLogonKey -name "DefaultPassword" -value $DefaultPassword
if($DefaultDomainName -ne "") {
    Set-itemproperty -path $RegLogonKey -name "DefaultDomainName" -value $DefaultDomainName
}

################################################
# Disable UAC
################################################
New-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system" -Name PromptOnSecureDesktop -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system" -Name ConsentPromptBehaviorAdmin -PropertyType DWord -Value 0 -Force
# New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

################################################
# Explorer settings
################################################
# Disable Start_NotifyNewApps
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_NotifyNewApps -Value 0
# Disable HideFileExt
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\HideFileExt" -Name UncheckedValue -Value 0
# Disable MinAnimate
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -Value 0
# Disable TaskbarAnimations
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAnimations -Type DWord -Value 0
# Set UserPreferencesMask
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Value ([byte[]]"94 32 03 80 12 00 00 00".Split(' ') | % {"0x$_"})

################################################
# caps2ctrl
################################################
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" -Name "Scancode Map" -Type DWord -Value ([byte[]]"00,00,00,00,00,00,00,00,02,00,00,00,1d,00,3a,00,00,00,00,00".Split(',') | % {"0x$_"}) -Force

################################################
# Enable Developer Mode
################################################
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1 -Force

################################################
# Rename hostname
################################################
(Get-WmiObject Win32_ComputerSystem).Rename("k-win10")

################################################
# iSCSI
################################################
Set-Service msiscsi -startuptype "automatic"
Start-Service msiscsi
New-IscsiTargetPortal -TargetPortalAddress 192.168.1.250

################################################
# DvorakJ
################################################
$dest = "C:\Program Files (x86)\DvorakJ"
if (-not (Test-Path $dest)) {
    $src = "$env:TEMP\DvorakJ"
    Invoke-WebRequest -Uri "http://blechmusik.xii.jp/dvorakj/download" -OutFile "$src.zip"
    Expand-Archive "$src.zip" $dest
    Remove-Item -Recurse -Force "$src.zip"
}
Register-ScheduledTask -TaskName DvorakJ -Trigger (New-ScheduledTaskTrigger -AtLogOn) -RunLevel Highest -Action (New-ScheduledTaskAction -Execute "C:\Program Files (x86)\DvorakJ\DvorakJ.exe") -Settings (New-ScheduledTaskSettingsSet -DisallowHardTerminate -AllowStartIfOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit 0)

################################################
# MacType
################################################
$dest = "C:\Program Files\MacType"
if (-not (Test-Path $dest)) {
    # MacType 1.2016.904.0
    $exe = "$env:TEMP\MacType.exe"
    Invoke-WebRequest -Uri "https://github.com/snowie2000/mactype/releases/download/v1.2016.904.0/MacTypeInstaller_2016_0904_0.exe" -OutFile $exe
    Start-Process -Wait -FilePath $exe -ArgumentList "/quiet"
    Remove-Item $exe

    # MacTypePatch 1.19
    $zipUri = "https://www.dropbox.com/s/bdtxsj3oiggvn96/MacTypePatch_1.19.zip?dl=1"
    $zipPath = "$env:TEMP\MacTypePatch_1.19"
    Invoke-WebRequest -Uri $zipUri -OutFile "$zipPath.zip"
    Expand-Archive "$zipPath.zip" $env:TEMP
    Copy-Item "$zipPath\win8.1 or later\UserParams.ini" "$dest\UserParams.ini"
    Unblock-File "$zipPath\EasyHK32.dll","$zipPath\EasyHK64.dll"
    Copy-Item "$zipPath\EasyHK32.dll" "C:\Windows\SysWOW64\EasyHK32.dll" -Force
    Copy-Item "$zipPath\EasyHK32.dll" "$dest\EasyHK32.dll" -Force
    Copy-Item "$zipPath\EasyHK64.dll" "C:\Windows\System32\EasyHK64.dll" -Force
    Copy-Item "$zipPath\EasyHK64.dll" "$dest\EasyHK64.dll" -Force
    Remove-Item -Recurse -Force "$zipPath","$zipPath.zip"
}

################################################
# QTTabBar
################################################
$dest = "C:\Program Files\QTTabBar"
if (-not (Test-Path $dest)) {
    $zipUri = "http://qttabbar-ja.wdfiles.com/local--files/qttabbar/QTTabBar_1038.zip"
    $zipPath = "$env:TEMP\QTTabBar"
    Invoke-WebRequest -Uri $zipUri -OutFile "$zipPath.zip"
    Expand-Archive "$zipPath.zip" $zipPath
    Start-Process -Wait -FilePath "$zipPath\QTTabBar.exe" -ArgumentList "/quiet"
    Remove-Item -Recurse -Force "$zipPath","$zipPath.zip"
}

################################################
# Chocolatey
################################################
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
RefreshEnv
choco install -y googlechrome.dev GoogleJapaneseInput VisualStudioCode ConEmu RapidEE

################################################
# Windows Features
################################################
# bash on Ubuntu
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart

################################################
# Windows Update
################################################
if(-not (Test-Path C:\WindowsUpdate)){ md C:\WindowsUpdate }
(New-Object System.Net.WebClient).DownloadFile("http://www.vwnet.jp/Windows/PowerShell/ps1/autowindowsupdate.txt", "C:\WindowsUpdate\AutoWindowsUpdate.ps1")
C:\WindowsUpdate\AutoWindowsUpdate.ps1 Full
