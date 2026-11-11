# Goprox

Goprox is a private, encrypted proxy you host yourself. You run the server on
a machine you control, and the apps on your computer reach the internet
through it.

It has two parts:

- **goprox-server** runs on a Linux or macOS machine, such as a VPS, a home
  server, or a Raspberry Pi. Your traffic exits from this machine.
- **gptui** is the client. It runs in a terminal on macOS, Linux, and Windows.

Goprox is a proxy for the apps you point at it. It is not a VPN and does not
route the whole device.

## Features

- A setup script creates the server's certificate and password for you and
  installs the server as a service that keeps running across reboots.
- Encrypted connection that only accepts your own server's certificate.
- A terminal client with mouse and keyboard control, live traffic statistics,
  and a built-in connection test.
- One switch to send macOS or GNOME desktop traffic through the proxy, and to
  restore your previous settings when you disconnect.
- A standard SOCKS5 proxy on `127.0.0.1:1080` for browsers and command-line
  tools.
- Share access with someone else as a single passphrase-protected file.
- Single-file programs with nothing else to install on the client.

## 1. Set up the server

Do these steps on the Linux or macOS machine that will be your server.

### Step 1. Download the server

Download the server for your machine from the
[releases page](https://github.com/naviko/goprox-dist/releases):

| Machine | File |
| --- | --- |
| Linux, x86-64 | `goprox-server-linux-amd64.tar.gz` |
| Linux, ARM64 (Raspberry Pi and similar) | `goprox-server-linux-arm64.tar.gz` |
| macOS, Apple Silicon | `goprox-server-darwin-arm64.tar.gz` |
| macOS, Intel | `goprox-server-darwin-amd64.tar.gz` |

For example, on a Linux x86-64 machine:

```bash
mkdir goprox && cd goprox
curl -fsSL https://github.com/naviko/goprox-dist/releases/latest/download/goprox-server-linux-amd64.tar.gz | tar -xz
```

The `goprox` folder now holds `goprox-server` and a setup script,
`create-install-linux.sh` or `create-install-osx.sh`.

### Step 2. Create the certificate and password

Run the setup script in that folder:

```bash
bash create-install-linux.sh    # Linux
bash create-install-osx.sh      # macOS
```

It prints the tunnel password and creates these files in the folder:

| File | Purpose |
| --- | --- |
| `server.pem` | Server certificate and private key. Keep it on the server. |
| `goprox.crt` | Public certificate. The client needs a copy. |
| `password` | The tunnel password. To use your own, replace the line in this file. |
| `install-goprox-service-linux.sh` or `install-goprox-service-osx.sh` | Installs the server as a service. |

### Step 3. Install the service

```bash
sudo bash install-goprox-service-linux.sh    # Linux
sudo bash install-goprox-service-osx.sh      # macOS
```

The server now runs in the background and starts again after a reboot.

To change a setting such as the port, edit the server flags inside that file
before you run it. Run it again after any later change.
`./goprox-server --help` lists every flag.

### Step 4. Open the port

Allow **UDP port 4433** to reach the server. The scripts do not change any
firewall.

- On a cloud server, allow it in the provider's firewall or security group.
- On a home server, forward it on your router.
- If the server runs its own firewall, allow it there too, for example
  `sudo ufw allow 4433/udp`.

### Step 5. Copy the certificate to the client

On the computer that will run gptui:

```bash
scp <user>@<server>:goprox/goprox.crt .
```

### Manage the server

| Task | Linux | macOS |
| --- | --- | --- |
| Check status | `sudo systemctl status goprox-server` | `sudo launchctl print system/com.goprox.server` |
| Watch the log | `sudo journalctl -u goprox-server -f` | `tail -f server.log` in the server folder |
| Restart | `sudo systemctl restart goprox-server` | `sudo launchctl kickstart -k system/com.goprox.server` |
| Show the password | `cat password` in the server folder | `cat password` in the server folder |

**Update** by downloading the newest server from the releases page into the
same folder (step 1), then restarting. Your certificate, password, and
settings are kept.

**Change the password** by replacing the line in the `password` file, then
restarting.

**Uninstall:**

```bash
# Linux
sudo systemctl disable --now goprox-server
sudo rm /etc/systemd/system/goprox-server.service

# macOS
sudo launchctl bootout system/com.goprox.server
sudo rm /Library/LaunchDaemons/com.goprox.server.plist
```

## 2. Install the client

### macOS

```bash
# Apple Silicon
curl -fsSL https://github.com/naviko/goprox-dist/releases/latest/download/gptui-darwin-arm64.tar.gz | tar -xz

# Intel
curl -fsSL https://github.com/naviko/goprox-dist/releases/latest/download/gptui-darwin-amd64.tar.gz | tar -xz
```

### Linux

```bash
# x86-64
curl -fsSL https://github.com/naviko/goprox-dist/releases/latest/download/gptui-linux-amd64.tar.gz | tar -xz

# ARM64
curl -fsSL https://github.com/naviko/goprox-dist/releases/latest/download/gptui-linux-arm64.tar.gz | tar -xz
```

### Windows

In PowerShell (use `gptui-windows-arm64.zip` on ARM devices):

```powershell
Invoke-WebRequest https://github.com/naviko/goprox-dist/releases/latest/download/gptui-windows-amd64.zip -OutFile gptui.zip
Expand-Archive gptui.zip -DestinationPath .
```

Put `goprox.crt` from your server in the same folder as `gptui`.

## 3. Connect

Start the client from its folder:

```bash
./gptui          # macOS and Linux
.\gptui.exe      # Windows Terminal or PowerShell
```

Fill in the form with the values from your server setup:

| Field | Value |
| --- | --- |
| Server | Your server's IP address or hostname |
| Port | `4433` |
| Password | The tunnel password |
| Certificate | `goprox.crt`, or choose **Browse** |

Choose **Connect**, then **Test**. The status shows **VERIFIED** when a
request has gone out through your server. gptui remembers your settings, so
next time you only choose Connect.

You can click any field or button, or use the keyboard:

| Key | Action |
| --- | --- |
| Arrow keys, Tab | Move between fields and buttons |
| Enter | Choose the focused button |
| Ctrl+N | Connect or disconnect |
| Ctrl+T | Test the proxy |
| F1 | Help |
| F2 | Command menu |
| F3 | Connection statistics |
| Ctrl+Q | Disconnect and quit |

## 4. Send traffic through the proxy

**Whole desktop (macOS and GNOME):** turn on **System proxy** in gptui before
you connect. Safari, Chrome, and other apps that follow the system settings
then use the proxy. Your previous settings come back when you disconnect or
quit.

**One app (any platform, including Windows):** set the app's proxy to SOCKS5,
host `127.0.0.1`, port `1080`. Turn on remote DNS if the app offers it. In
Firefox this is under Settings → Network Settings → Manual proxy
configuration, with "Proxy DNS when using SOCKS v5" ticked.

**Command line:**

```bash
curl --proxy socks5h://127.0.0.1:1080 https://example.com
```

To confirm your traffic leaves from the server, compare your public address
with and without the proxy:

```bash
curl https://ifconfig.me
curl --proxy socks5h://127.0.0.1:1080 https://ifconfig.me
```

## Share access with someone else

1. In gptui, choose **Share** and pick a passphrase of at least 8 characters.
   This saves one `.config` file containing the server address, port,
   password, and certificate, protected by that passphrase.
2. Send them the file and a link to this page. Send the passphrase separately,
   for example by phone.
3. They install gptui, put the file in the same folder, and start gptui. It
   asks for the passphrase and fills in everything. If they already use gptui,
   they press **Ctrl+O** and open the file.

## Troubleshooting

**Connect works but Test fails or times out.** The client cannot reach the
server. Check that the server is running and that UDP port 4433 is allowed in
the cloud firewall or router as well as on the server. The port is UDP, not
TCP.

**The server log shows authentication failures.** The password in gptui does
not match the server. Show the server's password with
`cat password` in the server folder.

**"certificate pin mismatch".** The `goprox.crt` on the client is not the one
from this server. Copy it from the server again.

**macOS says gptui "cannot be opened".** This happens when the file was
downloaded with a browser. Either use the `curl` command above, or run
`xattr -d com.apple.quarantine gptui` once.

**macOS server is unreachable.** If the macOS firewall is on, allow incoming
connections for `goprox-server` under System Settings → Network → Firewall →
Options.

**System proxy stayed on after a crash.** Start gptui and choose **Clean Up**.

## Versions and downloads

All downloads are on the
[releases page](https://github.com/naviko/goprox-dist/releases), with a
`SHA256SUMS` file for each release. To check a download yourself:

```bash
curl -fsSLO https://github.com/naviko/goprox-dist/releases/latest/download/gptui-darwin-arm64.tar.gz
curl -fsSLO https://github.com/naviko/goprox-dist/releases/latest/download/SHA256SUMS
shasum -a 256 --ignore-missing -c SHA256SUMS      # Linux: sha256sum --ignore-missing -c SHA256SUMS
```

`./gptui --version` and `goprox-server --version` print the version followed
by the time it was built, such as `v0.0.9-2026_11_11_18_19_43`.

Update the client by downloading it again. Update the server as described
under "Manage the server". Use the same release on both when you can.
