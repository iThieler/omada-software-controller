#!/bin/bash
# Load Functionfile
source <(curl -s https://raw.githubusercontent.com/iThieler/omada-software-controller/main/_functions.sh)

clear
echo -e "
  _ _____ _    _     _         _
 (_)_   _| |_ (_)___| |___ _ _( )___
 | | | | | ' \| / -_) / -_) '_|/(_-<
 |_| |_| |_||_|_\___|_\___|_|   /__/
 Omada Software Controller Installer                                          
"

# set iThieler's CI
# loads whiptail color sheme
if [ -f ~/.iThielers_NEWT_COLORS ]; then
  echoLOG b "iThieler's CI-Files found"
  export NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS
else
  echoLOG b "no CI-Files found"
  if wget -q https://raw.githubusercontent.com/iThieler/omada-software-controller/main/newt_colors_file.txt -O ~/.iThielers_NEWT_COLORS; then
    echoLOG g "download normal mode CI-File"
    export NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS
  else
    echoLOG r "download normal mode CI-File"
  fi
  if wget -q https://raw.githubusercontent.com/iThieler/omada-software-controller/main/newt_colors_alert_file.txt -O ~/.iThielers_NEWT_COLORS_ALERT; then
    echoLOG g "download alert mode CI-File"
  else
    echoLOG r "download alert mode CI-File"
  fi
fi

# MongoDB Version
MongoDB_Version="4.4"
# Let's Encrypt needs
Certbot_URL=$(whip_inputbox "OK" "CERTBOT" "What is the Domainname (FQDN) of your server?" "omada.mydomain.com")
Certbot_Email=$(whip_inputbox "OK" "CERTBOT" "Which e-mail address is used for certificate messages?" "acme@mydomain.com")
# Omada Software Controller Version
sel=("1" "Install Version 5.9.9" \
     "2" "Install Version 5.8.4" \
     "3" "Install Version 5.7.4" \
     "4" "Install Version 5.6.3" \
     "5" "Install Version 5.5.6" \
     "6" "Install Version 5.4.6" \
     "7" "Install Version 5.3.1" \
     "8" "Install Version 5.1.7" \
     "9" "Install Version 5.0.30"
     "Q" "I want to abort!")
menuSelection=$(whiptail --menu --nocancel --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " CONFIGURING OMADA SOFTWARE CONTROLLER " "\nWhich version do you want to install?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

if [[ $menuSelection == "1" ]]; then
  Omada_Version="5.9.9"
  Omada_Date="2023-02-27"
elif [[ $menuSelection == "2" ]]; then
  Omada_Version="5.8.4"
  Omada_Date="2023-01-30"
elif [[ $menuSelection == "3" ]]; then
  Omada_Version="5.7.4"
  Omada_Date="2022-11-21"
elif [[ $menuSelection == "4" ]]; then
  Omada_Version="5.6.3"
  Omada_Date="2022-10-24"
elif [[ $menuSelection == "5" ]]; then
  Omada_Version="5.5.6"
  Omada_Date="2022-08-22"
elif [[ $menuSelection == "6" ]]; then
  Omada_Version="5.4.6"
  Omada_Date="2022-07-29"
elif [[ $menuSelection == "7" ]]; then
  Omada_Version="5.3.1"
  Omada_Date="2022-05-07"
elif [[ $menuSelection == "8" ]]; then
  Omada_Version="5.1.7"
  Omada_Date="2022-03-22"
elif [[ $menuSelection == "9" ]]; then
  Omada_Version="5.0.30"
  Omada_Date="2022-01-20"
elif [[ $menuSelection == "Q" ]]; then
  echoLOG y "one moment please, while finishing script"
  cleanup
  echoLOG g "Bye :-)"
  exit 0
else
  exit 1
fi

# Check Ubuntu Version
if ! lsb_release -c | grep -cw "focal" &>/dev/null; then echoLOG r "Script only supports Ubuntu 20.04 (focal)!" && exit 1; fi

echoLOG b "OK, let's get started. Your selection is"
echoLOG no "Omada Software Controller - Version ${Omada_Version} from ${Omada_Date}"
echoLOG no "MongoDB - Version ${MongoDB_Version}"
echoLOG no "FQDN for SSL Certification - ${Certbot_URL}"
echoLOG no "E-Mail for SSL Certification - ${Certbot_Email}"

# Import the MongoDB 4.4 public key and add repo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 656408E390CFB1F5 &>/dev/null
echo "deb http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list &>/dev/null

# Update and upgrade Server
echoLOG b "Updating package repository"
apt-get update 2>&1 >/dev/null

# Install Software dependencies
echoLOG y "Install Software dependencies"
for PACKAGE in openjdk-8-jre-headless mongodb-org jsvc curl snapd; do
  sleep 2
  if checkPKG $PACKAGE; then
    echoLOG b "already installed: $PACKAGE"
  else
    if apt-get install -y $PACKAGE 2>&1 >/dev/null; then
      echoLOG g "install Package: $PACKAGE"
    else
      echoLOG r "install Package: $PACKAGE"
      exit 1
    fi
  fi
done

# Update Server
echoLOG b "Update & Upgrade"
if updateHost; then
  echoLOG g "first full server update"
else
  echoLOG r "first full server update"
  exit 1
fi

# Install certbot via snap
if snap install core 2>&1 >/dev/null; then
  snap refresh core 2>&1 >/dev/null
  echoLOG g "install SNAP Core"
else
  echoLOG r "install SNAP Core"
  exit 1
fi

if snap install certbot --classic &>/dev/null; then
  ln -s /snap/bin/certbot /usr/bin/certbot
  echoLOG g "install Certbot"
else
  echoLOG r "install Certbot"
  exit 1
fi

if certbot certonly --standalone --agree-tos -d ${Certbot_URL} -m ${Certbot_Email} -n 2>&1 >/dev/null; then
  echoLOG g "create Let's Encrypt certificate"
else
  echoLOG r "create Let's Encrypt certificate"
  exit 1
fi

# Genearte Skript for renew cronjob
cat > /opt/renew_certificate.sh <<EOF
if ! tpeap status | grep -cw "not running" &>/dev/nul; then tpeap stop; fi
rm /opt/tplink/EAPController/data/keystore/*
cp /etc/letsencrypt/live/${Certbot_URL}/cert.pem /opt/tplink/EAPController/data/keystore/eap.cer
openssl pkcs12 -export -inkey /etc/letsencrypt/live/${Certbot_URL}/privkey.pem -in /etc/letsencrypt/live/${Certbot_URL}/cert.pem -certfile /etc/letsencrypt/live/${Certbot_URL}/chain.pem -name eap -out omada-certificate.p12 -password pass:tplink &>/dev/nul
keytool -importkeystore -srckeystore omada-certificate.p12 -srcstorepass tplink -srcstoretype pkcs12 -destkeystore /opt/tplink/EAPController/data/keystore/eap.keystore -deststorepass tplink -deststoretype pkcs12 &>/dev/nul
if tpeap status | grep -cw "not running" &>/dev/nul; then
  if tpeap start &>/dev/nul; then exit 0; else exit 1; fi
fi
EOF
chmod +x /opt/renew_certificate.sh
crontab -l | { cat; echo "15 3 1 * * /opt/renew_certificate.sh"; } | crontab -

# Download Omada Software Controller package and install
URL="https://static.tp-link.com/upload/software/$(echo $Omada_Date | cut -d- -f1)/$(echo $Omada_Date | cut -d- -f1,2 | tr -d '-')/$(echo $Omada_Date | cut -d- -f1,2,3 | tr -d '-')/Omada_SDN_Controller_v${Omada_Version}_Linux_x64.deb"
FILE="~/$(basename "$URL")"
if [ -f ${FILE} ]; then rm -f ${FILE}; fi

if wget -q ${URL} -O ${FILE}; then
    echoLOG g "download Omada Software Controller package"
  else
    echoLOG r "download Omada Software Controller package"
fi

if dpkg -i $FILE 2>&1 >/dev/null; then
  echoLOG g "install Omada Software Controller"
else
  echoLOG r "install Omada Software Controller"
  exit 1
fi

if /opt/renew_certificate.sh; then
  echoLOG g "WebGUI secured with SSL certificate"
else
  echoLOG r "WebGUI secured with SSL certificate"
fi

if ! tpeap status | grep -cw "not running" &>/dev/nul; then
  echoLOG y "Omada SDN Controller is now installed!"
  echo "Please visit the following URL to manage your devices:"
  echo "  https://${Certbot_URL}:8043"
  echoLOG y "Have Fun :-)!"
else
  echoLOG r "Omada SDN Controller could not be installed :-(!"
fi

exit
