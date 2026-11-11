#!/usr/bin/env bash
# Prepares goprox-server to run as a service on macOS.
#
# Put this script in the same folder as goprox-server and run:
#   bash create-install-osx.sh
#
# It creates, in that folder:
#   server.pem          server certificate and private key (keep private)
#   goprox.crt          public certificate for the client
#   password            tunnel password
#   install-goprox-service-osx.sh  installs the service; edit its flags, then run it with sudo
set -euo pipefail

directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
service_user="$(id -un)"
cd "${directory}"

if [[ ! -f goprox-server ]]; then
  echo "Put this script in the same folder as goprox-server." >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required to create the certificate." >&2
  exit 1
fi
if [[ -e server.pem ]]; then
  echo "server.pem already exists. Delete it first to create a new certificate." >&2
  exit 1
fi
chmod 755 goprox-server

# Create the certificate, its private key, and the tunnel password.
umask 077
openssl req -x509 -newkey rsa:3072 -nodes -days 3650 -subj "/CN=goprox" \
  -keyout server.key -out goprox.crt
cat goprox.crt server.key > server.pem
rm server.key
chmod 644 goprox.crt
openssl rand -hex 16 > password

# Write the file that installs the service. Everything in it is plain text the
# user can edit before running it.
umask 022
cat > install-goprox-service-osx.sh <<GENERATED
#!/usr/bin/env bash
# Installs goprox-server as a service that starts at boot.
#
# To change a setting, edit the flags in the ProgramArguments list below (one
# flag per <string> line), then run:
#   sudo bash install-goprox-service-osx.sh
# Run it again after any later change. "goprox-server --help" lists every flag.
set -euo pipefail

cat > /Library/LaunchDaemons/com.goprox.server.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.goprox.server</string>
  <key>UserName</key><string>${service_user}</string>
  <key>WorkingDirectory</key><string>${directory}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${directory}/goprox-server</string>
    <string>--port=4433</string>
    <string>--cert=${directory}/server.pem</string>
    <string>--password-file=${directory}/password</string>
    <string>--shaping=balanced</string>
    <string>--logfile=${directory}/server.log</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict>
</plist>
PLIST

launchctl bootout system/com.goprox.server 2>/dev/null || true
launchctl bootstrap system /Library/LaunchDaemons/com.goprox.server.plist
echo "goprox-server is installed and running."
GENERATED

echo
echo "Created in ${directory}:"
echo "  server.pem          server certificate and private key (keep private)"
echo "  goprox.crt          public certificate; copy it to the client"
echo "  password            tunnel password: $(cat password)"
echo "  install-goprox-service-osx.sh  installs the service"
echo
echo "Next: edit the flags in install-goprox-service-osx.sh if you want, then run:"
echo "  sudo bash ${directory}/install-goprox-service-osx.sh"
