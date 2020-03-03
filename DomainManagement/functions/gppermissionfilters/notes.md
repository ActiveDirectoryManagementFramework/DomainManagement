# Notes on implementing GP Permissions

Allow explicitly defining a permission on a single GPO by name.

Problem: Manual Labor is bad

- Allow defining access rules across the board.
- Allow defining access rules to GPOs according to filter rules.

Filterrules:

- Managed / Unmanaged GPO
- Name / Name pattern
- Link location
  - Direct OU
  - Direct OU and sub-OUs

Example:

```text
Filter1 = Managed
Filter2 = Linked in OU XYZ
Filter3 = Name Pattern ABC

"Filter":  "Filter1 -and (Filter2 -or -not Filter3)"
```

Processing-wise, this filter rule would then be substituted by truth statements on whether the filter rules matched or not:

```powershell
$filterResults['Filter1'] # List of all GPOs that are in
$policy.DisplayName
$logicHolder['Filter1'] = $policy.DisplayName -in $filterResults['Filter1']
$logicHolder['Filter2'] = $policy.DisplayName -in $filterResults['Filter2']
$logicHolder['Filter3'] = $policy.DisplayName -in $filterResults['Filter3']

'$logicHolder["Filter1"] -and ($logicHolder["Filter2"] -or -not $logicHolder["Filter3"])' | iex
```

The filter condition is parsed, partially at definition time (for syntax errors) and partially at runtime (for legal tokens):

```powershell
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput(" Filter1 -and (Filter2 -or -not Filter3 ", [ref]$tokens, [ref]$errors)
```

- `$errors` catches syntax error on config provisioning.
- `$tokens` contains list of tokens and will be evaluated at runtime, as at define time not all filters may be available yet (multiple contexts)

> Token kinds and their rules:

- LParen = Fine
- RParen = Fine
- EndOfInput = Fine
- Parameter = "-and", "-or" and "-not" are fine
- Identifier = All registered filter are fine
- Anything else = Not fine
