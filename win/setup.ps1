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
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" -Name "Scancode Map" -Type Binary -Value ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x1d,0x00,0x3a,0x00,0x00,0x00,0x00,0x00)) -Force

################################################
# Enable Developer Mode
################################################
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1 -Force

################################################
# Rename hostname
################################################
(Get-WmiObject Win32_ComputerSystem).Rename("k-win10")

################################################
# iSCSI Initiator
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
    Invoke-WebRequest -Uri "http://blechmusik.xii.jp/resources/app/DvorakJ/archive/2014/06/dj_2014-06-07.zip" -OutFile "$src.zip"
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
    Invoke-WebRequest -Uri "http://www.mactype.net/station/Release/MacTypeInstaller_2017_0628_0.exe" -OutFile $exe
    Start-Process -Wait -FilePath $exe -ArgumentList "/quiet /qn /qb"
    Remove-Item $exe
}

################################################
# GekiOreRegEd
################################################
$dest = "C:\Program Files (x86)\GekiOreRegEd"
if (-not (Test-Path $dest)) {
    $exe = "$env:TEMP\GekiOreKaiInst.exe"
    Invoke-WebRequest -Uri "http://web.archive.org/web/20110712142724/http://textexpage.s154.xrea.com/software/gekiorekai/GekiOreKaiInst.exe" -OutFile $exe
    Start-Process -Wait -FilePath $exe -ArgumentList "/silent /SP-"
    Remove-Item $exe
    taskkill.exe /F /IM GekiOreRegEdit.exe
}

################################################
# Chocolatey
################################################
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
RefreshEnv
choco install -y googlechrome GoogleJapaneseInput qttabbar VisualStudioCode ConEmu RapidEE sandboxie registryexplorer

################################################
# Windows Features
################################################
# bash on Ubuntu
if((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
}

################################################
# Windows Update
################################################
if(-not (Test-Path C:\WindowsUpdate)){ md C:\WindowsUpdate }
(New-Object System.Net.WebClient).DownloadFile("http://www.vwnet.jp/Windows/PowerShell/ps1/autowindowsupdate.txt", "C:\WindowsUpdate\AutoWindowsUpdate.ps1")
C:\WindowsUpdate\AutoWindowsUpdate.ps1 Full
