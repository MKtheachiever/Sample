<#
.SYNOPSIS
	Performs specific tasks based on the provided argument.
.DESCRIPTION
	This PowerShell script accepts an argument and performs specific tasks based on the argument value.
	The script includes options for silent execution, domain checks, network connection tests, and more.
.PARAMETER Silent
	Specifies whether to perform the steps silently.
.EXAMPLE
	PS> ./my-script.ps1 -Silent
	Runs the script in silent mode, performing silent steps.
.LINK
	https://github.com/your-repo/my-script
.NOTES
	Purpose: Task automation and customization
#>

param (
    [switch]$Silent
)

# Function to write log entries to the Windows Event Log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Information", "Warning", "Error")]
        [string]$LogLevel
    )
    
    # Create an EventLogEntryType based on the specified log level
    switch ($LogLevel) {
        "Information" { $eventType = [System.Diagnostics.EventLogEntryType]::Information }
        "Warning"     { $eventType = [System.Diagnostics.EventLogEntryType]::Warning }
        "Error"       { $eventType = [System.Diagnostics.EventLogEntryType]::Error }
    }
    
    # Write the log entry to the Application event log
    Write-EventLog -LogName "Application" -Source "MyScript" -EventId 1000 -EntryType $eventType -Message $Message
}

# Function to get the domain using WMI
function GetDomain {
    try {
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        return $computerSystem.Domain
    }
    catch {
        return "Error retrieving domain information"
    }
}

# Function to test network connection
function TestNetworkConnection {
    try {
        $result = Test-NetConnection -ComputerName "abc.net"
        
        if ($result.TcpTestSucceeded -eq 1) {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}

# Function to perform PingCheck
function PingCheck {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerName,
        [Parameter(Mandatory=$true)]
        [int]$MaxPingCount,
        [Parameter(Mandatory=$true)]
        [int]$CheckEvery
    )
    
    $pingCheck = $true
    $count = 0
    
    while ($pingCheck -and $count -lt $MaxPingCount) {
        $pingResult = Test-Connection -ComputerName $ServerName -Count 1 -Quiet
        
        if (-not $pingResult) {
            $pingCheck = $true
        }
        else {
            $pingCheck = $false
        }
        
        $count++
        Start-Sleep -Milliseconds $CheckEvery
    }
    
    return $pingCheck
}

# Main script logic
try {
    # Start script execution
    Write-Log -Message "Script started" -LogLevel "Information"
    
    if ($Silent) {
        # Perform silent steps if the -Silent argument is provided
        Write-Log -Message "Performing silent steps" -LogLevel "Information"
        
        # Call the external PowerShell script using Start-Process
        $externalScriptPath = "C:\Windows\SysWOW64\abc.ps1"
        Write-Log -Message "Calling external script: $externalScriptPath" -LogLevel "Information"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-File `"$externalScriptPath`"" -Wait
        
        # Additional silent steps logic goes here
    }
    else {
        # Perform regular steps if the -Silent argument is not provided
        Write-Log -Message "Performing regular steps" -LogLevel "Information"
        
        # Get the domain using the GetDomain
        $domain = GetDomain
        Write-Log -Message "Domain: $domain" -LogLevel "Information"
        # Check the domain and perform corresponding steps using regular expression
        if ($domain -match "abc\.com") {
            Write-Log -Message "Domain contains 'abc.com'. Performing specific steps" -LogLevel "Information"
            # Specific steps for domain containing "abc.com"
            
            # Test network connection to "abc.net" if domain is "abc.com"
            $connectionStatus = TestNetworkConnection
            Write-Log -Message "Network Connection Test Result: $connectionStatus" -LogLevel "Information"

            if ($connectionStatus) {
                Write-Log -Message "Connection test successful. Quitting the script." -LogLevel "Information"
                Exit
            }
        }
        else {
            Write-Log -Message "Domain does not contain 'abc.com'. Performing general steps" -LogLevel "Information"
            # General steps for other domains
            
            # Perform PingCheck if domain does not contain "abc.com"
            $pingCheckResult = PingCheck -ServerName "abc.com" -MaxPingCount 5 -CheckEvery 1000
            Write-Log -Message "PingCheck Result: $pingCheckResult" -LogLevel "Information"

            if ($pingCheckResult) {
                Write-Log -Message "PingCheck returned true. Quitting the script." -LogLevel "Information"
                Exit
            }
        }
    }
        
    # Check if AD only machine
    $isADJoined = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
    if (!$isADJoined){
        Write-Log -Message "Logged on with Local Account - Script terminated" -LogLevel "Information" 
        Exit      
    }

    Write-Log -Message "Script completed successfully" -LogLevel "Information"
}
catch {
    # Error handling
    $errorMessage = $_.Exception.Message
    Write-Log -Message "An error occurred: $errorMessage" -LogLevel "Error"
    
    # Optionally, perform additional error handling or send notification
    # Send-MailMessage -To "your@email.com" -Subject "Script Error" -Body $errorMessage -SmtpServer "smtp.example.com"
}
finally {
    # Clean up or perform any necessary final actions
    Write-Log -Message "Script finished" -LogLevel "Information"
}