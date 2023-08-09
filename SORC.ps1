# Define Recipient email addresses for internal and external testing.
$internalRecipient = "You@TestedDomain.com"
$externalRecipient = "Someone@ExternalDomain.com"

# Define sender addresses to test - a legit email from target domain, possibly a random from the tested domain, and a valid @ExternalDomain are suggested.
$fromAddresses = "test@example.com", "FakeEmailAddress@gmail.com"

# Read the SMTP server information from "OpenSMTP.txt" and remove duplicates.
$smtpServers = Get-Content -Path "OpenSMTP.txt" | Sort-Object | Get-Unique

# Define the result files for different outcomes.
$policyBlockedFile = "./IP-RelayBlockedByPolicy.txt"
$timeoutFile = "./IP-SMTPPortOpen-Timeout.txt"
$internalSuccessFile = "./IP-SMTPEmailSentInternal.txt"
$externalSuccessFile = "./IP-SMTPEmailSentExternal.txt"
$investigateFile = "./IP-SMTP-Investigate.txt"
$closedPortFile = "./IP-SMTPPortClosed.txt"
$RelayDeniedFile = "./IP=SMTPRelayDenied.txt"

# Define a log file for error messages.
$logFile = "./OpenSMTPLog.txt"

# Define a delay in seconds (15 seconds by default).
$delay = 15

# Define the special SMTP servers and the ports to test.  Port 25 is tested by default.  If you want another port tested for a subset of IPs, list here.
$specialSmtpServers = "1.2.x.y, 3.4.x.y"
$ports = 25, 8025

# Calculate the total number of IP address, port, from address, and recipient combinations to test.
$totalCombinations = ($smtpServers.Count - $specialSmtpServers.Count) * $fromAddresses.Count * 2
$totalCombinations += $specialSmtpServers.Count * $ports.Count * $fromAddresses.Count * 2

# Loop through each IP address (server) in the file.
foreach ($smtpServer in $smtpServers) {
    # Determine the ports to test based on the server IP.
    $portsToTest = if ($smtpServer -in $specialSmtpServers) { $ports } else { 25 }

    # Initialize a flag to track if the delay should be skipped.
    $skipDelay = $false

    # Try to send an email for each SMTP server, port, from address, and recipient.
    foreach ($port in $portsToTest) {
        foreach ($fromAddress in $fromAddresses) {
            Write-Host ("Now testing " + $smtpServer + ":" + $port + " from " + $fromAddress) -ForegroundColor Yellow

            # Test if the port is open before trying to send an email.
            Write-Host ("Testing to see if port " + $port + " responds on " + $smtpServer) -ForegroundColor Yellow
            $portOpen = Test-NetConnection -ComputerName $smtpServer -Port $port -WarningAction SilentlyContinue | Select-Object -ExpandProperty TcpTestSucceeded

            if ($portOpen) {
                foreach ($recipient in $internalRecipient, $externalRecipient) {
                    $serverType = if ($recipient -eq $internalRecipient) { "internal" } else { "external" }
                    $subject = "Red Team SMTP Test - $smtpServer - Port: $port - From: $fromAddress"
                    $body = "This is an $serverType test email sent through IP: $smtpServer, Port: $port, From: $fromAddress, To: $recipient"

                    try {
                        # Create a new SMTP client for the server and port.
                        Write-Host ("Creating SMTP client for " + $smtpServer + ":" + $port + " from " + $fromAddress) -ForegroundColor Yellow
                        $smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $port)

                        # Set a connection timeout (in milliseconds).
                        $smtpClient.Timeout = 5000

                        # Attempt to send the email.
                        Write-Host ("Sending email to " + $recipient + " through " + $smtpServer + ":" + $port + " from " + $fromAddress) -ForegroundColor Yellow
                        $smtpClient.Send($fromAddress, $recipient, $subject, $body)

                        # Output a success message if the email is sent.
                        $message = "Email sent through $smtpServer - Port: $port - Type: $serverType - Recipient: $recipient - From: $fromAddress - Success"
                        Write-Host $message -ForegroundColor Green

                        # Write the success to the appropriate file.
                        $successFile = if ($serverType -eq "internal") { $internalSuccessFile } else { $externalSuccessFile }
                        "$smtpServer, $port, $fromAddress, $recipient, Success" | Out-File -Append -FilePath $successFile

                    } catch {
                        # Output an error message if an exception is thrown.
                        $errorMessage = "Error occurred for $smtpServer - Port: $port - Type: $serverType - From: $fromAddress - Recipient: $recipient - Error: $($_.Exception.Message)"
                        Write-Host $errorMessage -ForegroundColor Red

                        # Log the error message.
                        "$smtpServer, $port, $fromAddress, $recipient, $errorMessage" | Out-File -Append -FilePath $logFile

                        # Store the IP, port, from address, recipient, and the error message based on the error message.
                        $output = "$smtpServer, $port, $fromAddress, $recipient, $errorMessage"
                        if ($_.Exception.Message -like "*5.7.0*") {
                            Write-Host ("Policy violation detected for " + $smtpServer + ":" + $port + " from " + $fromAddress + " to " + $recipient) -ForegroundColor Orange
                            $output | Out-File -Append -FilePath $policyBlockedFile
                        } elseif ($_.Exception.Message -like "*The operation has timed out*") {
                            Write-Host ("Timeout detected for " + $smtpServer + ":" + $port + " from " + $fromAddress + " to " + $recipient) -ForegroundColor Orange
                            $output | Out-File -Append -FilePath $timeoutFile
                        } elseif ($_.Exception.Message -like "*5.7.1*" -or $_.Exception.Message -like "*4.7.1 **") {
                            Write-Host ("Relay denied detected for " + $smtpServer + ":" + $port + " from " + $fromAddress + " to " + $recipient) -ForegroundColor Orange
                            $output | Out-File -Append -FilePath $RelayDeniedFile
                        } else {
                            Write-Host ("Unexpected error for " + $smtpServer + ":" + $port + " from " + $fromAddress + " to " + $recipient) -ForegroundColor Orange
                            $output | Out-File -Append -FilePath $investigateFile
                        }
                    }
                }
            } else {
                # The port is not open. Write the server and port to the closed port file and skip the delay.
                Write-Host ("Port " + $port + " is closed on " + $smtpServer) -ForegroundColor Red
                "$smtpServer, $port" | Out-File -Append -FilePath $closedPortFile
                $skipDelay = $true
            }

            # Decrement the total combinations and display the countdown.
            $totalCombinations--
            Write-Host ("$totalCombinations combinations remaining") -ForegroundColor Cyan
        }
    }

    if (-not $skipDelay) {
        # Sleep for the specified delay.
        Write-Host ("Starting delay of " + $delay + " seconds") -ForegroundColor Yellow
        Start-Sleep -Seconds $delay
        Write-Host "Delay complete" -ForegroundColor Yellow
    }
}
