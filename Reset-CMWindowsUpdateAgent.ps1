<#

Windows Update Remediation Script

This script is designed to be run in an SCCM managed update environment using the Run Script action, 
however there is nothing to stop it from being run manually or via a package.

Authored by: Blake Erwin

Version: 7

#>

$logstring = "##########################################"

$logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

 

#Stop services

 

try {

$logstring = "Stopping Windows Update related services"

$logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

 

Stop-Service wuauserv -Force

Stop-Service BITS -Force

Stop-Service cryptsvc -Force

Stop-Service msiserver -Force

 

$logstring = "Services stopped successully"

$logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

}

catch {

    $logstring =  ("Error Encountered stopping services: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

      }

 

#Remove old backup of SoftwareDistribuiton folder if there

try {

    $logstring = "Checking for previously backed up Windows Update folder"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

 

    if (Test-Path C:\Windows\SoftwareDistribution.old) {

        try {

            $logstring = "Found old backup of Windows Update folder.  Removing backup."

            $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

 

            Remove-Item C:\Windows\SoftwareDistribution.old -Force -Recurse

            $logstring = "Found old backup of Windows Update folder.  Removing backup."

            $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

            }

        catch {

        $logstring =  ("Error Encountered removing Windows Update folder: " + $_.Exception.Message)

        $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

              }

        }

    }

catch {

    $logstring =  ("Error Encountered removing backup of Windows Update Folder: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

     }

 

#Rename SoftwareDistribution folder

try {

    $logstring = "Renaming Windows Update folder to .old"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    Rename-Item C:\Windows\SoftwareDistribution C:\Windows\SoftwareDistribution.old -Force

    $logstring = "Successfully renamed Windows Update folder"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    }

catch {

    $logstring =  ("Error Encountered renaming backup of Windows Update Folder: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

      }

 

 

#Find the SCCM Expected WSUS Server

try {

    $logstring = "Finding WSUS server which SCCM client expects"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    $wuserver = (Get-WmiObject -Namespace ROOT\ccm\scanagent -Query "SELECT * FROM CCM_SUPLocationList WHERE ScanMethod='WUA'").CurrentScanPath

    $logstring = "SCCM expects WSUS server to be: " + $wuserver

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    }

catch {

    $logstring =  ("Error Encountered checking WMI for WSUS server: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

      }

#New Section Testing WSUS Server Connection

try {

    $logstring = "Testing WSUS Server Connection"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    $length = $wuserver.Length

    $ServerName = $wuserver.Substring(7, $length - 12)

    $Port = $wuserver.Substring($ServerName.Length + 8, 4)

    $logstring = "Testing Server " + $ServerName + " on Port " + $Port

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    $TCPTestStatus = Test-NetConnection -ComputerName $ServerName -Port $Port -InformationLevel Quiet

    $logstring = "Testing Result is " + $TCPTestStatus

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    }

catch {

    $logstring =  ("Error Encountered Testing WSUS Server Connection: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

      }

#Set WUA Server to SCCM SUP

try {

    $logstring = "Setting Windows Update Registry keys to point to WSUS server expected by SCCM"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name WUServer -Value $wuserver

    Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name WUStatusServer -Value $wuserver

    $logstring = "Registry keys pointed to expected WSUS server"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

}

catch {

    $logstring =  ("Error Encountered while setting Windows Update Registry keys: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

      }

 

#Reset Policy file to clear cache of old WSUS settings

try {

    $logstring = "Clearing local group policy cache to force redownload"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    if (Test-Path C:\Windows\System32\GroupPolicy\Machine\Registry.pol.old) {Remove-Item C:\Windows\System32\GroupPolicy\Machine\Registry.pol.old -Force}

    if (Test-Path C:\Windows\System32\GroupPolicy\Machine\Registry.pol) {Rename-Item C:\Windows\System32\GroupPolicy\Machine\Registry.pol C:\Windows\System32\GroupPolicy\Machine\Registry.pol.old -Force}

    if (Test-Path C:\windows\system32\catroot2.old) {Remove-Item C:\windows\system32\catroot2.old -Force}

    if (Test-Path C:\windows\system32\catroot2) {Rename-Item C:\windows\system32\catroot2 C:\windows\system32\catroot2.old -Force}

    $logstring = "Local policy cache cleared"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    }

catch {

    $logstring =  ("Error Encountered while clearing local policy cache: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

       }

 

 

#Start services

try {

    $logstring = "Starting services back up"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    Start-Service BITS

    Start-Service wuauserv

    Start-Service cryptsvc

    Start-Service msiserver

    $logstring = "Services started successfully"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    }

catch {

    $logstring =  ("Error Encountered while starting services: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

       }

 

 

#Wait a few seconds

Start-Sleep -Seconds 5

 

#Start second process which will sleep 30 seconds before restarting the SCCM service and triggering the software update scan and deployment cycles

try {

    $logstring = "Sending secondary command to restart SCCM service and schedule Windows Update scan"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    Start-Process powershell  -WindowStyle Hidden -Verb runas -ArgumentList "-command Invoke-Command -ScriptBlock {(Start-Sleep -Seconds 10), (Restart-Service CcmExec), (Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule '{00000000-0000-0000-0000-000000000113}' | Out-Null), (Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule '{00000000-0000-0000-0000-000000000108}' | Out-Null)}"

    $logstring = "Successfully sent command"

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

    }

catch {

    $logstring =  ("Error Encountered while sending command: " + $_.Exception.Message)

    $logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append

       }

$logstring = "##########################################"

$logstring | Out-File -FilePath C:\Log\WindowsUpdateRemediation.log -Append