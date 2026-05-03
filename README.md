# SORC - SMTP Open Relay Check

SORC is a PowerShell script for checking whether SMTP servers may allow open relay behavior.

It reads a list of SMTP server IPs or hostnames, checks whether the target port is reachable, then attempts controlled SMTP sends using internal and external sender/recipient combinations. Results are written to separate output files so findings can be reviewed after the run.

## Intended Use

Use this only against systems you own or are explicitly authorized to test.

The script is designed for defensive validation, red-team assessment, and configuration review of known SMTP infrastructure.

## What It Tests

For each server, SORC can test:

- Internal sender to internal recipient
- Internal sender to external recipient
- External sender to internal recipient
- External sender to external recipient

The most important result is whether an external relay attempt is accepted by the SMTP server and actually reaches the recipient. Some environments accept the SMTP transaction but block delivery later with a gateway, filter, or firewall, so review mailboxes and logs too.

## Requirements

- Windows PowerShell
- Network access to the target SMTP hosts
- An `OpenSMTP.txt` file in the same folder as `SORC.ps1`
- Authorization to test the listed SMTP servers

## Configuration

Edit the top of `SORC.ps1`:

```powershell
$internalRecipient = "You@TestedDomain.com"
$externalRecipient = "Someone@ExternalDomain.com"
$fromAddresses = "test@example.com", "FakeEmailAddress@gmail.com"
$delay = 15
$specialSmtpServers = @("1.2.x.y", "3.4.x.y")
$ports = 25, 8025
```

- `internalRecipient`: Recipient at the domain you are testing.
- `externalRecipient`: Recipient outside the tested domain.
- `fromAddresses`: Sender addresses to test. Include at least one internal-looking sender and one external sender.
- `delay`: Seconds to wait between tested servers when a port was open.
- `specialSmtpServers`: Servers that should be tested on every port listed in `$ports`.
- `ports`: Extra ports to test for special servers. Non-special servers use port `25`.

## Input File

Create `OpenSMTP.txt` next to the script.

Example:

```text
192.0.2.10
192.0.2.11
mail.example.com
```

Blank lines are ignored and duplicates are removed.

## Running

Run from PowerShell:

```powershell
.\SORC.ps1
```

## Output Files

The script writes results into files in the current folder:

```text
IP-RelayBlockedByPolicy.txt
IP-SMTPPortOpen-Timeout.txt
IP-SMTPEmailSentInternal.txt
IP-SMTPEmailSentExternal.txt
IP-SMTP-Investigate.txt
IP-SMTPPortClosed.txt
IP-SMTPRelayDenied.txt
OpenSMTPLog.txt
```

Successful SMTP acceptance is not always proof of delivered mail. Confirm results by checking the destination mailboxes and server-side logs.

## Notes And Cautions

- Do not run this against third-party systems without permission.
- Start with a small input file to verify your sender and recipient configuration.
- Keep delays high enough to avoid generating unnecessary mail volume or triggering rate limits.
- Review `IP-SMTP-Investigate.txt` and `OpenSMTPLog.txt` manually; not every SMTP server uses the same error wording.
