# GOPROX package

This is a private proxy solution.  Feel free to use it for your own purposes and host it yourself, just make sure to generate your own certificates.  Works great on a Raspberry Pi or any other Linux machine.

## Files in this folder

| File | Description |
|------|-------------|
| `gpui` | macOS GUI client |
| `goprox-client` | macOS CLI client (launched automatically by gpui) |
| `goprox-server` | Linux relay server |
| `client_*.crt` | client certificate for TLS pinning (goes on the Mac for testing purposes) |
| `gen-cert.sh` | script to generate a fresh TLS certificate pair |

---

## Overview

goprox is a two-part system:

- The **SERVER** runs on a Linux machine (a VPS, home server, etc.) and is the machine that your traffic exits from.
- The **CLIENT** runs on your Mac. The `gpui` app is the easiest way to use it.

You need two passwords. Pick them yourself and write them down:

1. **PFX password** — protects the certificate file on disk. Can be anything. You only type this once when starting the server.
2. **Tunnel password** — authenticates the Mac to the server at connect time. Both sides must use the same value. Can be anything.

---

## Step 1 — Generate a certificate (run once)

The certificate encrypts traffic between the Mac and the server. You generate it once and keep both output files.

Open Terminal, navigate to this folder, then run:

```bash
bash gen-cert.sh
```

It will ask you to type a PFX password (your choice — write it down). It produces two files:

- `server_YYYY_MM_DD_HH_MM.pfx` — goes on the Linux server
- `client_YYYY_MM_DD_HH_MM.crt` — stays on your Mac (gpui uses this)

---

## Step 2 — Set up the server (Linux machine)

Copy the following files to your Linux machine (use scp, sftp, etc.):

- `goprox-server`
- `server_YYYY_MM_DD_HH_MM.pfx`

Make the binary executable and start it:

```bash
chmod +x goprox-server
./goprox-server \
  --port=4433 \
  --cert=server_2025_01_01_12_00.pfx \
  --certpass=<your PFX password> \
  --password=<your tunnel password>
```

Replace the filename, PFX password, and tunnel password with your own values. The server will keep running in the foreground and log connections to the console. To keep it running after you close the terminal, use `screen`, `tmux`, or a systemd service.

> Default port is **4433 (UDP)**. Make sure that port is open in your firewall.

---

## Step 3 — Connect from your Mac

Put this whole folder somewhere permanent on your Mac (e.g. `~/Applications/goprox/`).

Double-click `gpui`, then fill in the form:

| Field | Value |
|-------|-------|
| Server Host | the IP address or hostname of your Linux machine |
| Server Port | `4433` (or whatever you used above) |
| Password | your tunnel password |
| Certificate | click Browse and select the `client_*.crt` file in this folder |

Click **Connect**. The status label should change to **Running**.

To route all macOS app traffic through the proxy, check **Use macOS Proxy**.
To test that it is working, click **Test Proxy** — it will fetch https://whatismyip.com through the tunnel and show the result in the log.

---

## Troubleshooting

**"certificate file is not readable"**
Make sure the path in the Certificate field points to the `client_*.crt` file.

**Connection times out immediately**
Check that the server is running and that port 4433 (UDP) is open in the firewall on your Linux machine.

**"could not authenticate" in the server log**
The tunnel password on the Mac does not match the one used to start the server.

**Need a new certificate** (e.g. the old one expired or you lost it)
Run `bash gen-cert.sh` again, copy the new `.pfx` to the server, restart the server with the new filename, and update the Certificate path in gpui.
