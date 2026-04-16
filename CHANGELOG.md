# Changelog

## v4.0 — Complete Rewrite

### New Features
- **Non-standard port support** — rustscan scans all 65535 ports; services identified by name+product, not port number
- **Scan cache** — `~/.cache/authfinder-ng/<ip>.cache` (24h TTL). Second run with new creds skips scan entirely
- **Separate `-i` / `-P` flags** — user file and password file independently, creates cartesian spray
- **Auto domain detection** — extracts domain and hostname from SMB banner automatically
- **Null/anonymous auth check** — tests SMB null, LDAP anonymous bind, FTP anonymous before spending creds
- **Safe round-robin spray** — default spray mode cycles 1 pass per user per round (lockout-safe)
- **SOCKS5 proxy support** — `--proxy socks5://127.0.0.1:1080` for pivoting through tunnels
- **`--add-to-hosts`** — auto-adds discovered hostname to `/etc/hosts`
- **`--linux` mode** — SSH-focused with Linux commands (`id`, `uname`, `hostname`)
- **Lockout protection** — per-user fail counter, auto-pause, lockout policy check
- **Per-command display** — every command printed (`[CMD]`) before execution
- **Markdown report** — `--report file.md` saves full hit table + command log
- **Command log** — all executed commands saved for documentation
- **Tool auto-detection** — resolves `nxc`/`netexec`/`crackmapexec`, `xfreerdp3`/`xfreerdp`, `impacket-*`/`*.py`
- **HTTP basic auth** — curl probe + hydra fallback
- **FTP testing** — nxc ftp + hydra fallback + anonymous check
- **LDAP testing** — auth check + auto user enumeration on hit

### Bug Fixes (from v3.0)
- Fixed: `evil-winrm` built as `echo 'cmd' | evil-winrm` — replaced with `nxc winrm -x`
- Fixed: MSSQL multi `-command` flag syntax — replaced with `nxc mssql -x`
- Fixed: psexec success detection on `"Found writable share"` — uses proper output parsing
- Fixed: `xfreerdp` cert flag inconsistency — auto-detects `/cert:ignore` vs `/cert-ignore`
- Fixed: No tool check before running — `check_tools()` always runs at startup
- Fixed: `-f` cred file required alternating lines — now supports `user:pass` per line
- Fixed: Single `-p` flag served both single password and password file — split into `-p` / `-P`

### Architecture
- **Discovery pipeline**: rustscan → nmap -sV → service fingerprint → protocol handler
- **Service mapping**: port → service name → product string (3-level priority)
- **Thread-safe I/O**: flock-based output serialization for parallel target processing
- **Error advisor**: pattern-matched error messages with actionable fix tips

---

## v3.0 (original)
- Multi-protocol support: WinRM, SMBexec, WMI, PsExec, ATExec, MSSQL, RDP, SSH
- NXC-based execution engine
- Post-exploitation next steps
- Credential file support (alternating lines format)
- Hash auto-detection

## v2.0 (original, needs review)
- Early prototype with basic protocol coverage

## v1.0 (original)
- Initial release
