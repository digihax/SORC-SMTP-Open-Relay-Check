# OpenSMTPRelayCheck
Powershell script to test a list of IPs for misconfiguration

Fairly straightforward, but a few worthy notes:

A file, OpenSMTP.txt, with the IPs you want to check, is required.

Set the $delay variable (in seconds -- 30 * 60 for 30m, for example) for the delay between IPs tested.

The script tests the port to see if it accepts connections, before attempting to send the email.

Presuming you know the target domain (if not, set the from/to emails accordingly), each iteration
will attempt 4 emails: 2 from the Sender/Target domain, 2 from an external domain, and the recipients 
will be either the same/Target domain, or an externa domain, to see which variations may get through.

The sent emails will include the IP, Port, From, and To senders -- the SMTP server may send, but another device (FW?) may block. 
This is common -- FW rules will limit who can send outbound SMTP, ideally.

Several files will be created:
$policyBlockedFile = "./IP-RelayBlockedByPolicy.txt" -- 5.7.1 SMTP server errors go here -- relay is denied by policy.<br>
$timeoutFile = "./IP-SMTPPortOpen-Timeout.txt" - If a port tests as open, but the communication times out, it goes here<br>
$internalSuccessFile = "./IP-SMTPEmailSentInternal.txt" - SMTP server gave no errors and processed the email send attempt - if it was received -- open relay.<br>
$externalSuccessFile = "./IP-SMTPEmailSentExternal.txt" - SMTP server gave no errors and processed the email send attempt - if it was received -- open relay.<br>
$investigateFile = "./IP-SMTP-Investigate.txt" - Some other message was received -- review manually<br>
$closedPortFile = "./IP-SMTPPortClosed.txt" - The network connection test failed, the port appears closed.<br>
$RelayDeniedFile = "./IP=SMTPRelayDenied.txt" - 4.7.1 SMTP server errors go here - relay is denied<br>

That's it!  Enjoy
