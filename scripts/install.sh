#!/usr/bin/env bash
set -e

echo "Installing dependencies..."
if [ -x "$(command -v apt-get)" ]; then
  sudo apt-get update -y
  sudo apt-get install -y unzip
else
  sudo yum update -y
  sudo yum install -y unzip wget
fi


echo "Fetching Nomad..."
NOMAD=0.5.2
cd /tmp
wget https://releases.hashicorp.com/nomad/${NOMAD}/nomad_${NOMAD}_linux_amd64.zip -O nomad.zip

echo "Installing Nomad..."
unzip nomad.zip >/dev/null
chmod +x nomad
sudo mv nomad /usr/local/bin/nomad
sudo mkdir -p /opt/nomad/data

# Read from the file we created
SERVER_COUNT=$(cat /tmp/nomad-server-count | tr -d '\n')
NOMAD_JOIN=$(cat /tmp/nomad-server-addr | tr -d '\n')

# Write the flags to a temporary file
cat >/tmp/nomad_flags << EOF
NOMAD_FLAGS="-server -bootstrap-expect=${SERVER_COUNT} -join=${NOMAD_JOIN} -data-dir=/opt/nomad/data"
EOF

if [ -f /tmp/upstart.conf ];
then
  echo "Installing Upstart service..."
  sudo mkdir -p /etc/nomad.d
  sudo mkdir -p /etc/service
  sudo chown root:root /tmp/upstart.conf
  sudo mv /tmp/upstart.conf /etc/init/nomad.conf
  sudo chmod 0644 /etc/init/nomad.conf
  sudo mv /tmp/nomad_flags /etc/service/nomad
  sudo chmod 0644 /etc/service/nomad
else
  echo "Installing Systemd service..."
  sudo mkdir -p /etc/systemd/system/nomad.d
  sudo chown root:root /tmp/nomad.service
  sudo mv /tmp/nomad.service /etc/systemd/system/nomad.service
  sudo chmod 0644 /etc/systemd/system/nomad.service
  sudo mv /tmp/nomad_flags /etc/sysconfig/nomad
  sudo chown root:root /etc/sysconfig/nomad
  sudo chmod 0644 /etc/sysconfig/nomad
fi
