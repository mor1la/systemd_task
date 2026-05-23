#!/bin/bash
set -e

if [ ! -f app1.env ] || [ ! -f app2.env ]; then
    echo "Env files are missing. Create them from examples first:"
    echo "  cp app1.env.example app1.env"
    echo "  cp app2.env.example app2.env"
    echo "Then edit app1.env and app2.env if needed."
    exit 1
fi

sudo cp app1.service /etc/systemd/system/
sudo cp app2@.service /etc/systemd/system/
sudo cp apps.target /etc/systemd/system/

sudo mkdir -p /opt/app1/conf /opt/app2/conf
sudo cp app1.env /opt/app1/conf/app1.env
sudo cp app2.env /opt/app2/conf/app2.env

if ! id app1 >/dev/null 2>&1; then
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin app1
fi

if ! id app2 >/dev/null 2>&1; then
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin app2
fi

sudo chown -R app1:app1 /opt/app1
sudo chown -R app2:app2 /opt/app2

sudo systemctl daemon-reload
sudo systemctl enable apps.target
sudo systemctl start apps.target
