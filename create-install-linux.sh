#!/usr/bin/env bash
# Prepares goprox-server to run as a service on Linux.
#
# Put this script in the same folder as goprox-server and run:
#   bash create-install-linux.sh
#
# It creates, in that folder:
#   server.pem          server certificate and private key (keep private)
#   goprox.crt          public certificate for the client
#   password            tunnel password
#   install-goprox-service-linux.sh  installs the service; edit its flags, then run it with sudo
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
cat > install-goprox-service-linux.sh <<GENERATED
#!/usr/bin/env bash
# Installs goprox-server as a service that starts at boot.
#
# To change a setting, edit the flags on the ExecStart line below, then run:
#   sudo bash install-goprox-service-linux.sh
# Run it again after any later change. "goprox-server --help" lists every flag.
set -euo pipefail

cat > /etc/systemd/system/goprox-server.service <<'UNIT'
[Unit]
Description=Goprox server
After=network-online.target
Wants=network-online.target

[Service]
User=${service_user}
WorkingDirectory=${directory}
ExecStart="${directory}/goprox-server" --port=4433 "--cert=${directory}/server.pem" "--password-file=${directory}/password" --shaping=balanced "--logfile=${directory}/server.log"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable goprox-server
systemctl restart goprox-server
systemctl --no-pager status goprox-server
GENERATED

echo
echo "Created in ${directory}:"
echo "  server.pem          server certificate and private key (keep private)"
echo "  goprox.crt          public certificate; copy it to the client"
echo "  password            tunnel password: $(cat password)"
echo "  install-goprox-service-linux.sh  installs the service"
echo
echo "Next: edit the flags in install-goprox-service-linux.sh if you want, then run:"
echo "  sudo bash ${directory}/install-goprox-service-linux.sh"
