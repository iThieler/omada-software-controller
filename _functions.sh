#!/bin/bash

# Function ping given IP and return TRUE if available
function pingIP() {
  if ping -c 1 $1 &> /dev/null; then
    true
  else
    false
  fi
}

# Function give the entered IP to FUNCTION pingIP. Returns true if IP is pingable if not, you cancheck and change the IP
function checkIP() {
  # Call with: checkIP "192.168.0.1"
  # you can also call with: if checkIP "${nas_ip}"; then ipExist=true; else ipExist=false; fi
  if [ -n $1 ]; then ip="$1"; else ip=""; fi
  while ! pingIP ${ip}; do
    ip=$(whip_alert_inputbox_cancel "OK" "Abbrechen" "CHECK IP" "Die angegebene IP-Adresse kann nicht gefunden werden, bitte prüfen und noch einmal versuchen!" "${ip}")
    RET=$?
    if [ $RET -eq 1 ]; then return 1; fi  # Check if User selected cancel
  done
}

# Function checked if an Package is installed, returned true or false
function checkPKG() {
  if [ $(dpkg-query -s "${1}" | grep -cw "Status: install ok installed") -eq 1 ]; then
    true
  else
    false
  fi
}

# Function generates a random secure Linux password
function generatePassword() {
  # Call with: generatePassword 12 >> 12 is the password length
  chars=({0..9} {a..z} {A..Z} "_" "%" "+" "-" ".")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function generates a random API-Key
function generateAPIKey() {
  # Call with: generateAPIKey 32 >> 32 is the API-Key length
  chars=({0..9} {a..f})
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function update Server (Host)
function updateHost() {
  {
    echo -e "XXX\n12\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get update 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n25\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n47\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get dist-upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n64\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get autoremove -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n98\nSystemupdate wird ausgeführt ...\nXXX"
  } | whiptail --gauge --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " SYSTEMPREPARATION " "The server will be checked for system updates ..." 10 80 0

  return 0
}

# Function generates an Filebackup
function bakFILE() {
  # Call with: bakFILE backup "path/to/file/filename.ext"
  # Call with: bakFILE recover "path/to/file/filename.ext"
  mode=$1
  file=$2

  if [[ $mode == "backup" ]]; then
    if [ -f "${file}.bak" ]; then
      rm "${file}.bak"
    fi
    cp "${file}" "${file}.bak"
  elif [[ $mode == "recover" ]]; then
    if [ -f "${file}.bak" ]; then
      rm "${file}"
      cp "${file}.bak" "${file}"
      rm "${file}.bak"
    else
      echoLOG r "No file backup of ${file} was found. The requested file could not be restored."
    fi
  fi
}

# Function clean the Shell History and exit
function cleanup() {
  cat /dev/null > ~/.bash_history && history -c && history -w
  sleep 5
}

# Function write event to logfile and echo colorized in shell
function echoLOG() {
  typ=$1
  text=$(echo -e $2 | sed ':a;N;$!ba;s/\n/ /g' | sed 's/ +/ /g')
  logfile="/root/log_iThieler-Proxmox-Script.txt"
  nc='\033[0m'
  red='\033[1;31m'
  green='\033[1;32m'
  yellow='\033[1;33m'
  blue='\033[1;34m'
  
  if [ ! -f "${logfile}" ]; then touch "${logfile}"; fi

    if [[ $typ == "r" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${red}ERROR${nc}]  $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [ERROR]  $text" >> "${logfile}"
  elif [[ $typ == "g" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${green}OK${nc}]     $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [OK]     $text" >> "${logfile}"
  elif [[ $typ == "y" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${yellow}WAIT${nc}]   $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [WAIT]   $text" >> "${logfile}"
  elif [[ $typ == "b" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${blue}INFO${nc}]   $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [INFO]   $text" >> "${logfile}"
  elif [[ $typ == "no" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')           $text"
    echo -e "$(date +'%Y-%m-%d  %T')           $text" >> "${logfile}"
  fi
}

################################
##   normal Whiptail Boxes    ##
################################

# give an whiptail message box
function whip_message() {
  #call whip_message "title" "message"
  whiptail --msgbox --ok-button " OK " --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${1} " "${2}" 0 80
  echoLOG b "${2}"
}

# give a whiptail question box
function whip_yesno() {
  #call whip_yesno "btn1" "btn2" "title" "message"  >> btn1 = true  btn2 = false
  whiptail --yesno --yes-button " ${1} " --no-button " ${2} " --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${3} " "${4}" 0 80
  yesno=$?
  if [ ${yesno} -eq 0 ]; then true; else false; fi
}

# give a whiptail box with input field
function whip_inputbox() {
  #call whip_inputbox "btn" "title" "message" "default value"
  input=$(whiptail --inputbox --ok-button " ${1} " --nocancel --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${2} " "\n${3}" 0 80 "${4}" 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! There must be an input !!!" ""
  else
    echo "${input}"
  fi
}

# give a whiptail box with input field and cancel button
function whip_inputbox_cancel() {
  #call whip_inputbox_cancel "btn1" "btn2" "title" "message" "default value"
  input=$(whiptail --inputbox --ok-button " ${1} " --cancel-button " ${2} " --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${3} " "\n${4}" 0 80 "${5}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then
    echo cancel
  else
    if [[ $input == "" ]]; then
      whip_inputbox_cancel "$1" "$2" "$3" "$4\n\n!!! There must be an input !!!" ""
    else
      echo "${input}"
    fi
  fi
}

# give a whiptail box with input field for passwords
function whip_inputbox_password() {
  #call whip_inputbox_password "btn" "title" "message"
  input=$(whiptail --passwordbox --ok-button " ${1} " --nocancel --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${2} " "\n${3}" 0 80 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! There must be an input !!!" ""
  else
    echo "${input}"
  fi
}

# give a whiptail box with input field for automatic generated passwords
function whip_inputbox_password_autogenerate() {
  #call whip_inputbox_password_autogenerate "btn" "title" "message"
  input=$(whiptail --passwordbox --ok-button " ${1} " --nocancel --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${2} " "\n${3}" 0 80 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    echo $(generatePassword 26)
  else
    echo "${input}"
  fi
}

#######################################
##   Whiptail Boxes in alert mode    ##
#######################################

# give an whiptail message box in alert mode
function whip_alert() {
  #call whip_alert "title" "message"
  NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS_ALERT \
    whiptail --msgbox --ok-button " OK " --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${1} " "${2}" 0 80
    echoLOG r "${2}"
}

# give an whiptail question box in alert mode
function whip_alert_yesno() {
  #call whip_alert_yesno "btn1" "btn2" "title" "message"  >> btn1 = true  btn2 = false
  NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS_ALERT \
    whiptail --yesno --yes-button " ${1} " --no-button " ${2} " --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${3} " "${4}" 0 80
    yesno=$?
    if [ ${yesno} -eq 0 ]; then echoLOG r "${4} ${blue}${1}${nc}"; else echoLOG r "${4} ${blue}${2}${nc}"; fi
    if [ ${yesno} -eq 0 ]; then true; else false; fi
}

# give a whiptail box with input field in alert mode
function whip_alert_inputbox() {
  #call whip_alert_inputbox "btn" "title" "message" "default value"
  NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS_ALERT \
  input=$(whiptail --inputbox --ok-button " ${1} " --nocancel --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${2} " "\n${3}" 0 80 "${4}" 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! There must be an input !!!" ""
  else
    echo "${input}"
  fi
}

# give a whiptail box with input field and cancel button in alert mode
function whip_alert_inputbox_cancel() {
  #call whip_alert_inputbox_cancel "btn1" "btn2" "title" "message" "default value"
  NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS_ALERT \
  input=$(whiptail --inputbox --ok-button " ${1} " --cancel-button " ${2} " --backtitle "© 2023 - iThieler's Omada Software Controller Installer" --title " ${3} " "\n${4}" 0 80 "${5}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then
    echo cancel
  else
    if [[ $input == "" ]]; then
      whip_inputbox_cancel "$1" "$2" "$3" "$4\n\n!!! There must be an input !!!" ""
    else
      echo "${input}"
    fi
  fi
}
