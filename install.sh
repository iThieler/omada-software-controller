#!/bin/bash
#date:      05 March 2023
#updated:   

# MongoDB Version
MongoDB_Version="4.4"
# Let's Encrypt needs
Certbot_URL=""
Certbot_Email=""
# Omada Software Controller Version
Omada_Version="5.9.9"
Omada_Date="2023-02-27"

# Check Ubuntu Version
if ! lsb_release -c | grep -cw "focal" &>/dev/null; then echo -e "\e[1;31mERROR: Script only supports Ubuntu 20.04 (focal)! \e[0m" && exit; fi

# Import the MongoDB 4.4 public key and add repo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 656408E390CFB1F5
echo "deb http://repo.mongodb.org/apt/ubuntu $OsVer/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Update and upgrade Server
apt update && apt upgrade -y

# Install Software dependencies
apt -y install openjdk-8-jre-headless mongodb-org jsvc curl snapd

# Download Omada Software Controller package and install
OmadaPackageUrl="https://static.tp-link.com/upload/software/$(echo $Omada_Date | cut -d- -f1)/$(echo $Omada_Date | cut -d- -f1,2 | tr -d '-')/$(echo $Omada_Date | cut -d- -f1,2,3 | tr -d '-')/Omada_SDN_Controller_v${Omada_Version}_Linux_x64.deb"
wget $OmadaPackageUrl -P /tmp/
dpkg -i /tmp/$(basename $OmadaPackageUrl)

# Install certbot via snap
snap install core; sudo snap refresh core
snap install certbot --classic
ln -s /snap/bin/certbot /usr/bin/certbot
certbot certonly --standalone -d ${Certbot_URL} -m ${Certbot_Email} -n
if ! tpeap status | grep -cw "not running" &>/dev/nul; then tpeap stop; fi
rm /opt/tplink/EAPController/data/keystore/*
cp /etc/letsencrypt/live/${Certbot_URL}/cert.pem /opt/tplink/EAPController/data/keystore/eap.cer
openssl pkcs12 -export -inkey /etc/letsencrypt/live/${Certbot_URL}/privkey.pem -in /etc/letsencrypt/live/${Certbot_URL}/cert.pem -certfile /etc/letsencrypt/live/${Certbot_URL}/chain.pem -name eap -out omada-certificate.p12 -password pass:tplink
keytool -importkeystore -srckeystore omada-certificate.p12 -srcstorepass tplink -srcstoretype pkcs12 -destkeystore /opt/tplink/EAPController/data/keystore/eap.keystore -deststorepass tplink -deststoretype pkcs12
if tpeap status | grep -cw "not running" &>/dev/nul; then tpeap start; fi

# Genearte Skript for renew cronjob
cat > /opt/renew_certificate.sh <<EOF
if ! tpeap status | grep -cw "not running" &>/dev/nul; then tpeap stop; fi
rm /opt/tplink/EAPController/data/keystore/*
cp /etc/letsencrypt/live/${Certbot_URL}/cert.pem /opt/tplink/EAPController/data/keystore/eap.cer
openssl pkcs12 -export -inkey /etc/letsencrypt/live/${Certbot_URL}/privkey.pem -in /etc/letsencrypt/live/${Certbot_URL}/cert.pem -certfile /etc/letsencrypt/live/${Certbot_URL}/chain.pem -name eap -out omada-certificate.p12 -password pass:tplink
keytool -importkeystore -srckeystore omada-certificate.p12 -srcstorepass tplink -srcstoretype pkcs12 -destkeystore /opt/tplink/EAPController/data/keystore/eap.keystore -deststorepass tplink -deststoretype pkcs12
if tpeap status | grep -cw "not running" &>/dev/nul; then tpeap start; fi
EOF
chmod +x /opt/renew_certificate.sh
crontab -l | { cat; echo "15 3 1 * * /opt/renew_certificate.sh"; } | crontab -

hostIP=$(hostname -I | cut -f1 -d' ')
echo -e "\n\nOmada SDN Controller is now installed!\nPlease Visit https://${hostIP}:8043 to manage your devices."
