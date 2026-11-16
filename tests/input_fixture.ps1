# Offline only: import two AST expressions, never execute the SMTP script.
$ErrorActionPreference='Stop'
$src=Join-Path (Split-Path $PSScriptRoot -Parent) 'SORC.ps1'
$tokens=$null; $perr=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($src,[ref]$tokens,[ref]$perr)
if($perr.Count){throw 'SORC syntax errors'}
$assignment=$ast.FindAll({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -eq 'smtpServers'},$true)|Select-Object -First 1
if(-not $assignment){throw 'Input assignment not found'}
function Get-Content { @(' 192.0.2.10 ','','192.0.2.11','192.0.2.10','   ') }
$smtpServers=@(& ([scriptblock]::Create($assignment.Right.Extent.Text)))
if($smtpServers.Count -ne 2 -or $smtpServers[0] -ne '192.0.2.10' -or $smtpServers[1] -ne '192.0.2.11'){throw 'Input normalization failed'}
$loop=$ast.FindAll({param($n) $n -is [System.Management.Automation.Language.ForEachStatementAst] -and $n.Body.Extent.Text -match '\$totalCombinations\s*\+='},$true)|Select-Object -First 1
if(-not $loop){throw 'Count loop not found'}
$specialSmtpServers=@('192.0.2.10');$ports=25,8025;$fromAddresses='sender@example.com','sender@example.net'
$totalCombinations=0
. ([scriptblock]::Create($loop.Extent.Text))
if($totalCombinations -ne 12){throw 'Mixed-port planned count failed'}
$smtpServers=@();$totalCombinations=0
. ([scriptblock]::Create($loop.Extent.Text))
if($totalCombinations -ne 0){throw 'Empty-list count failed'}
'PASS: input normalization, mixed-port planned count and empty input; no network'
