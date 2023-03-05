<h1 align="center" id="heading">Install Script for Omada Software Controller</h1>

<p align="center"><sub> Always remember to use due diligence when obtaining scripts and automation tasks from third party websites. Primarily, I created this script to make the installation and setup of TP-Link's Omada Software Controller easier and also faster for me. If you want to use a script, do it. </sub></p>

<p align="center">
  <a href="https://github.com/iThieler/omada-software-controller/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" ></a>
  <a href="https://ko-fi.com/U7U3FUTLF"><img src="https://img.shields.io/badge/%E2%98%95-Buy%20me%20a%20coffee-red" /></a>
</p><br><br>

<p align="center"><img src="https://upload.wikimedia.org/wikipedia/commons/8/82/Gnu-bash-logo.svg" height="100"/></p>

This script performs the following tasks.
- Complete update and upgrade of the server after adding required package sources.
- Installation of required software tools
- Installation of MongoDB (version 4.4)
- Download and install Omada_SDN_Controller DEB package (version 5.9.9)
- Restarting the server
 
Run the following command in your shell. ⚠️ **UBUNTU 20.04 ONLY**

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/omada-software-controller/main/install.sh)
```
