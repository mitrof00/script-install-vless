#!/bin/bash

# Install XRAY
apt install curl
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo "Ваш маскировочный домен? (по умолчанию s-kaupat.fi)"
read name
if [ -z $name ]
then
name=s-kaupat.fi
fi
echo $name

echo "Название профиля (ENG)? (по умолчанию название виртуальной машины)"
read host
if [ -z $host ]
then
host=$(hostname)
fi
echo $host

#UUID
UUID=$(xray uuid)
echo $UUID > UUID
sed -i "s/ваш_UUID/${UUID}/g" config.json
sed -i "s/ваш_UUID/${UUID}/g" profile.txt
# Gen Key
xray x25519 > pk
PrK=$(sed -n '1p' pk | cut -d " " -f 2)
echo $PrK
PbK=$(sed -n '2p' pk | cut -d " " -f 3)
echo $PbK
sed -i "s/ваш_ПРИВАТНЫЙ_ключ/${PrK}/g" config.json
sed -i "s/ваш_публичный_ключ/${PbK}/g" profile.txt
IP=$(hostname -I | cut -d " " -f 1)
echo $IP
sed -i "s/IP_адрес_вашего_сервера/${IP}/g" config.json
sed -i "s/IP_адрес_вашего_сервера/${IP}/g" profile.txt
sed -i "s/ваш_маскировочный_домен/${name}/g" config.json
sed -i "s/домен_сайта/${name}/g" profile.txt
sed -i "s/Название профиля/${host}/g" profile.txt

cp config.json /usr/local/etc/xray/
# Restart Xray
systemctl restart xray

# Status Xray
systemctl status xray
