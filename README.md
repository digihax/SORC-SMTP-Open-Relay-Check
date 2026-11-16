# SORC - SMTP Open Relay Check

SORC is a focused PowerShell utility for reviewing SMTP relay acceptance on
servers you are authorized to test. It sends real messages to configured recipients;
it is not a passive port check.

It reads SMTP server IPs or hostnames, checks the target port, then attempts
controlled sends using internal and external sender/recipient combinations. Results
are written to separate files for review.

## Intended Use

Use SORC for defensive validation, red-team assessments and configuration review
of SMTP systems you own or are authorized to test.

## What It Tests

For each server, SORC can test:

- Internal sender to internal recipient
- Internal sender to external recipient
- External sender to internal recipient
- External sender to external recipient

The important result is whether an external relay attempt is accepted by the SMTP
server and reaches the recipient. A gateway, filter or firewall may accept the SMTP
transaction and block delivery later, so review the destination mailbox and server
logs as well.

## Requirements

- Windows PowerShell
- Network access to the target SMTP hosts
- An `OpenSMTP.txt` file in the current working directory
- Internal/external recipient mailboxes you control
- Authorization to test the listed SMTP servers

## Configuration

Edit the top of `SORC.ps1`:

```powershell
$internalRecipient = "relay-check@example.com"
$externalRecipient = "relay-check@example.net"
$fromAddresses = "sender@example.com", "sender@example.net"
$delay = 15
$specialSmtpServers = @("192.0.2.10", "192.0.2.11")
$ports = 25, 8025
```

- `internalRecipient`: Recipient at the domain you are testing.
- `externalRecipient`: Recipient outside the tested domain.
- `fromAddresses`: Sender addresses to test. Include at least one internal-looking sender and one external sender.
- `delay`: Seconds between server entries. Currently skipped if any tested port
  for that server was closed, even if another was open.
- `specialSmtpServers`: Servers that should be tested on every port listed in `$ports`.
- `ports`: Extra ports to test for special servers. Non-special servers use port `25`.

## Input File

Run from the checkout and create `OpenSMTP.txt` there: it is read relative to the
**working directory**, not `$PSScriptRoot`. There are no command-line parameters.
Check that the file exists and replace all sender/recipient placeholders first.

Example:

```text
192.0.2.10
192.0.2.11
mail.example.com
```

Entries are trimmed, sorted and deduplicated; blank lines are ignored. Comments
are not supported. Use one hostname/IP per line. The script enforces no IP allowlist.

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

Historical `EmailSent` filenames and `Success` fields mean `SmtpClient.Send`
returned without an exception: **SMTP acceptance, not confirmed mailbox delivery**.
Internal/external labels come from the configured recipient. Confirm destination
mailboxes and server/gateway logs before calling a result an open relay.

## Validation and limitations

Default two senders times two recipients means four possible sends per reachable
port. The progress counter tracks planned send combinations, not servers or ETA;
closed-port combinations are subtracted without sending.

Offline input and counting fixtures run under Windows PowerShell 5.1 and PowerShell
7. They do not send SMTP messages.

```powershell
powershell -NoProfile -File .\tests\input_fixture.ps1
```

The script is Windows-oriented (`Test-NetConnection` and .NET `SmtpClient`). It
does not configure SMTP AUTH or STARTTLS. Error classification depends on exception
wording, not a complete SMTP status parser. `PortClosed` can also mean filtering
or a transient failure. Input-file failure has no explicit fail-fast guard; verify
`Test-Path .\OpenSMTP.txt` before running. Reports append to existing files.

## Notes And Cautions

- Start with a small input file to verify your sender and recipient configuration.
- Keep delays high enough to avoid generating unnecessary mail volume or triggering rate limits.
- Review `IP-SMTP-Investigate.txt` and `OpenSMTPLog.txt` manually; not every SMTP server uses the same error wording.

## License

MIT; existing attribution remains in [LICENSE](LICENSE).
