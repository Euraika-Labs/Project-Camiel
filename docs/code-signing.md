# Code Signing — Camiel Windows Builds

> **Author:** Euraika development team  
> **Last updated:** 2026-06-05  
> **TL;DR:** Code signing tells Windows "this software is from a trusted developer." Without it, SmartScreen shows a scary warning to every player who downloads Camiel.

---

## Table of Contents

1. [What Is Code Signing?](#what-is-code-signing)
2. [Windows SmartScreen Explained](#windows-smartscreen-explained)
3. [Free Options](#free-options)
4. [Paid Options](#paid-options)
5. [Environment Variables](#environment-variables)
6. [GitHub Actions signtool Step](#github-actions-signtool-step)
7. [Local signtool Command](#local-signtool-command)
8. [Self-Signed Certificates — Dev Only](#self-signed-certificates--dev-only)
9. [DO NOT Commit Certificates](#do-not-commit-certificates)
10. [Troubleshooting](#troubleshooting)

---

## What Is Code Signing?

Code signing is the process of digitally signing a compiled executable (`.exe`) with a certificate issued by a trusted Certificate Authority (CA). It proves to Windows and end users that:

- The executable was built by a specific, verified organisation or individual.
- The executable has not been tampered with since it was signed.
- The publisher can be traced back to a real identity.

When a player downloads Camiel from a website, email attachment, or game portal, Windows checks the signature before deciding whether to show a SmartScreen warning.

---

## Windows SmartScreen Explained

**SmartScreen** is Windows Defender's reputation-based filter. It checks every downloaded executable against Microsoft's reputation database.

| Scenario | Result |
|----------|--------|
| Executable is unsigned | ⚠️ "Windows protected your PC" — SmartScreen warning |
| Executable is signed with a new/Unknown certificate | ⚠️ "This app has an unknown publisher" warning |
| Executable is signed with an established, trusted certificate | ✅ No warning — Camiel runs normally |

**Reputation build-up:** Even after signing with a valid certificate, SmartScreen needs days to weeks to establish a reputation for that certificate. EV certificates (see Paid Options) bypass this waiting period entirely.

---

## Free Options

### SignPath.io (Free Tier Available)

[SignPath.io](https://signpath.io) is a cloud-based code signing service with a free tier for open-source and small projects.

**How it works:**
1. Upload your `.exe` to the SignPath web dashboard.
2. Select a signing certificate (SignPath provides one from a trusted CA).
3. Download the signed executable.

**Free tier limits:**
- 5 signing sessions per month on the free plan.
- Suitable for low-frequency releases (e.g. one release per month).
- No CI/CD integration on the free tier — manual upload required.

**For Camiel:** If you release infrequently, SignPath's free tier is sufficient. For automated CI/CD signing, a paid plan or alternative is needed.

---

## Paid Options

### DigiCert — OV / EV Code Signing

| Certificate | Cost (approx.) | SmartScreen bypass |
|-------------|----------------|--------------------|
| OV (Organisation Validation) | €150–300 / year | No — reputation builds over time |
| EV (Extended Validation) | €300–600 / year | Yes — immediate trust |

**DigiCert** (`digicert.com`) is the premium choice. Their EV certificates are widely trusted and work immediately with SmartScreen. DigiCert has a well-documented REST API for CI/CD integration.

### SSL.com — Affordable OV / EV

[SSL.com](https://ssl.com) offers OV and EV code signing certificates at lower price points than DigiCert. They also provide `escctl`, a CLI tool for cloud-based signing that integrates directly with GitHub Actions — no certificate file leaves their servers.

### Sectigo / Comodo

[Sectigo](https://sectigo.com) (formerly Comodo) offers budget OV certificates starting around €80/year. Widely trusted root, good for initial releases where budget is a constraint.

---

## Environment Variables

Two environment variables control code signing in the Camiel CI pipeline:

### `AUTHENTICODE_CERT_PATH`

Path to the `.pfx` (PKCS#12) certificate file on the CI runner.

```bash
# Example — GitHub Actions secret stores the cert, decoded at runtime
AUTHENTICODE_CERT_PATH=/tmp/camiel-signing.pfx
```

The certificate is stored as a Base64-encoded GitHub Secret and decoded in the CI step:

```bash
echo "$AUTHENTICODE_CERT_B64" | base64 -d > /tmp/camiel-signing.pfx
```

### `AUTHENTICODE_PASSWORD`

Password that protects the `.pfx` file. Stored as a GitHub Secret, never hardcoded.

```bash
AUTHENTICODE_PASSWORD=your-pfx-password
```

**Security note:** Both secrets are encrypted at rest by GitHub and only exposed to workflow runs triggered by trusted refs (`main` or release tags). They are NOT available to pull request runs from forks.

---

## GitHub Actions signtool Step

The signtool step in `.github/workflows/export.yml` decodes the certificate, signs the executable, and skips gracefully if no certificate is configured:

```yaml
- name: Decode signing certificate
  env:
    AUTHENTICODE_CERT_B64: ${{ secrets.AUTHENTICODE_CERT_B64 }}
  run: |
    if [ -z "$AUTHENTICODE_CERT_B64" ]; then
      echo "::notice::AUTHENTICODE_CERT_B64 not set — skipping code signing"
      exit 0
    fi
    echo "$AUTHENTICODE_CERT_B64" | base64 -d > /tmp/camiel-signing.pfx
    echo "✓ Certificate decoded"

- name: Code-sign Windows executable
  env:
    AUTHENTICODE_CERT_PATH: /tmp/camiel-signing.pfx
    AUTHENTICODE_PASSWORD: ${{ secrets.AUTHENTICODE_PASSWORD }}
  run: |
    if [ ! -f "$AUTHENTICODE_CERT_PATH" ]; then
      echo "::notice::Signing certificate not found — skipping signtool"
      exit 0
    fi
    signtool sign \
      /v \
      /f "$AUTHENTICODE_CERT_PATH" \
      /p "$AUTHENTICODE_PASSWORD" \
      /fd SHA256 \
      /tr http://timestamp.digicert.com \
      /td SHA256 \
      builds/*.exe
    echo "✓ Code signing complete"
```

**SKIPPED if cert absent:** Both steps check for the presence of the certificate secret and exit early with a notice log if it is not set. This means a CI run without signing configured will still produce a valid (but unsigned) executable.

---

## Local signtool Command

To sign a Camiel executable on a local Windows machine:

```powershell
# 1. Export from Godot
godot --headless --path . --export-release "Windows Desktop" builds/Camiel.exe

# 2. Sign with signtool (requires Windows SDK installed)
signtool sign `
  /v `
  /f camiel-signing.pfx `
  /p YOUR_PASSWORD `
  /fd SHA256 `
  /tr http://timestamp.digicert.com `
  /td SHA256 `
  builds/Camiel.exe

# 3. Verify the signature
signtool verify /pa /v builds/Camiel.exe
```

**Prerequisites:** Install [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/) which includes `signtool.exe`.

---

## Self-Signed Certificates — Dev Only

A self-signed certificate is one you generate yourself without a CA. It is useful for local development testing but **will not work for distribution**:

```powershell
# Generate a self-signed code signing certificate (Windows PowerShell)
New-SelfSignedCertificate `
  -Type CodeSigningCert `
  -Subject "CN=Camiel Dev, O=Euraika, C=NL" `
  -KeyUsage DigitalSignature `
  -KeyAlgorithm RSA `
  -KeyLength 4096 `
  -CertStoreLocation Cert:\CurrentUser\My `
  -NotAfter (Get-Date).AddYears(1)
```

**Limitations of self-signed certs:**
- SmartScreen shows a warning on every run — no different from unsigned.
- Cannot be used for code that will be distributed to other users.
- The certificate is only trusted on the machine that generated it.

**Never use a self-signed certificate for a release build.**

---

## DO NOT Commit Certificates

**This is critical.** Certificate files (`.pfx`, `.p12`, `.pem` with private keys) must NEVER be committed to the repository. If committed, you must treat the certificate as compromised and request a new one from your CA.

```
# ❌ WRONG — never do this
git add camiel-signing.pfx
git commit -m "add signing cert"
git push origin main

# ✅ CORRECT — use GitHub Secrets
gh secret set AUTHENTICODE_CERT_B64 --body "$(base64 -i camiel-signing.pfx | tr -d '\n')"
```

**Add this to `.gitignore` to prevent accidental commits:**

```
# Code signing certificates
*.pfx
*.p12
*.pem
```

---

## Troubleshooting

### "Signtool error: No certificate were found"

The `.pfx` file was not decoded correctly. Verify:

```bash
# Check the base64 secret decodes to a valid file
echo "$AUTHENTICODE_CERT_B64" | base64 -d > /tmp/test.pfx
ls -la /tmp/test.pfx   # Should be non-zero size
file /tmp/test.pfx     # Should report "PKCS#7" or "Microsoft PKCS#7"
```

### "Signtool error: The specified password is incorrect"

The `AUTHENTICODE_PASSWORD` secret does not match the `.pfx` file password. Re-enter the password in GitHub Secrets.

### SmartScreen still shows a warning after signing

New certificates need a **reputation build-up** period (typically 3–14 days). EV certificates bypass this. For OV certificates, Microsoft provides a [SmartScreen reputation request form](https://feedback.microsoft.com) once you have a verified certificate and a history of clean submissions.

### "Signtool error: The certificate is not valid for signing"

The certificate may not include the **Code Signing** OID (1.3.6.1.4.1.311.79.1). Some OV certificates are issued only for web server use (SSL/TLS). Check with your CA that the certificate is specifically for "Code Signing" (not "Server Authentication").

---

*Maintained by: Euraika development team*  
*Last reviewed: 2026-06-05*
