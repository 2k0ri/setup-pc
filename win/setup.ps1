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
Param(
    $DefaultUserName = "k",
    $DefaultPassword = Read-Host "Enter Password",
    $DefaultDomainName = ""
)
$RegLogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-itemproperty -path $RegLogonKey -name "AutoAdminLogon" -value 1
Set-itemproperty -path $RegLogonKey -name "DefaultUsername" -value $DefaultUserName
Set-itemproperty -path $RegLogonKey -name "DefaultPassword" -value $DefaultPassword
if($DefaultDomainName -ne "")
{
    Set-itemproperty -path $RegLogonKey -name "DefaultDomainName" -value $DefaultDomainName
}

################################################
# DvorakJ Service
################################################
Register-ScheduledTask -TaskName DvorakJ -Trigger (New-ScheduledTaskTrigger -AtLogOn) -RunLevel Highest -Action (New-ScheduledTaskAction -Execute "C:\Program Files (x86)\DvorakJ\DvorakJ.exe") -Settings (New-ScheduledTaskSettingsSet -DisallowHardTerminate -AllowStartIfOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 3))
