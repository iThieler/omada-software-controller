#!/bin/bash
#date:      05 March 2023
#updated:   

# MongoDB Version
MongoDB_Version="4.4"
# Omada Software Controller Version
Omada_Version="5.9.9"
Omada_Date="2023-02-27"

OS=$(hostnamectl status | grep "Operating System")

if [[ $OS = *"Ubuntu 20.04"* ]]; then
    OsVer=focal
else
    echo -e "\e[1;31mERROR: Script only supports Ubuntu 20.04! \e[0m"
    exit
fi

# Import the MongoDB 4.4 public key and add repo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 656408E390CFB1F5
echo "deb http://repo.mongodb.org/apt/ubuntu $OsVer/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Install/update dependencies
apt update && apt upgrade -y
apt -y install openjdk-8-jre-headless mongodb-org jsvc curl

# Download Omada Software Controller package and install
OmadaPackageUrl="https://static.tp-link.com/upload/software/$(echo $Omada_Date | cut -d- -f1)/$(echo $Omada_Date | cut -d- -f1,2 | tr -d '-')/$(echo $Omada_Date | cut -d- -f1,2,3 | tr -d '-')/Omada_SDN_Controller_v${Omada_Version}_Linux_x64.deb
wget $OmadaPackageUrl -P /tmp/
dpkg -i /tmp/$(basename $OmadaPackageUrl)

hostIP=$(hostname -I | cut -f1 -d' ')
echo -e "\n\nOmada SDN Controller is now installed!\nPlease Visit https://${hostIP}:8043 to manage your devices."
