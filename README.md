# Clonar de GitHub repositorios

cd /opt/odoosrc/13.0/extra-addons/

sudo git clone https://github.com/itadmin01/ansinaesmejor.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/ansinaesmejor

sudo pip3 install conekta

sudo pip3 install xmltodict

sudo apt-get install python3-openssl

sudo git clone https://github.com/itadmin01/Odoo_CFDI_3.3.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/Odoo_CFDI_3.3

sudo git clone https://github.com/odoomates/odooapps.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/odooapps

nano /opt/config/odoo13.conf

# Diagnostico

sudo systemctl restart odoo13

sudo systemctl status odoo13

systemctl list-unit-files --all

# DeployAnsinaEsMejor

sudo apt-get -y install git

sudo git clone -b 13.0 --depth 1 https://github.com/ansinaesmejor/DeployAnsinaEsMejor.git DeployAnsinaEsMejor

cd DeployAnsinaEsMejor

sudo chmod +x odoo13.sh

sudo ./odoo13.sh

# Links

https://ansinaesmejor.com/web/database/selector

# GitHub SSH

ls -al ~/.ssh

ssh-keygen -t rsa -b 4096 -C "ansinaesmejor@gmail.com"

eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_rsa

sudo apt-get install xclip

cd ~/.ssh

xclip -sel clip < ~/. id_rsa.pub

ssh -T git@github.com

# odoodeploy

(Copyright 2019 - OdooERPCloud)

https://www.odooerpcloud.com

Odoo Deploy Tools

## odoo.service

This file is used from odooxx.sh for to install Odoo Start Service

## odooxx.sh
This script install Odoo in Your Server

## Requirements

* Tested on Ubuntu Server / Desktop 16.04LTS Or 18.04.LTS
* This script should works on Debian Also (no tested).

## Enviroments

* Ubuntu Desktop 18.04 LTS (Local PC)
* Ubuntu Server 18.04 LTS (VPS)

    * OVH
    * Google Cloud
    * Amazon AWS
    * Digital Ocean

## How to install

### Ubuntu Desktop

1. Copy this Folder in your System (Desktop, Downloads, etc.)
2. Go to Directory and open a terminal
3. chmod +x  *.sh
4. Execute: ./odooxx.sh
5. Enjoy

### Ubuntu Server (VPS)

1. Copy this Folder in your User Home Directory using Filezilla or WinSCP OR SCP command)
2. Go to this Folder by terminal
3. chmod +x  *.sh
4. Execute: ./odooxx.sh
5. Enjoy

### Odoo Service Manager

* sudo systemctl status odooxx (shows state Odoo service)
* sudo systemctl start odooxx (start service)
* sudo systemctl stop odooxx (stop service)
* sudo systemctl restart odooxx (restart service)
* sudo tail -f /opt/deploy/log/ (Shows Live Odoo Log)


### Source Odoo location

* /opt/odoosrc (All Source)
* /opt/odoosrc/extra-addons (Extra Addons)
* /opt/odoosrc/extra-addons/oca (Put here your OCA Extra Addons)
* /opt/odoosrc/data (Filestore)
* /opt/odoosrc/log/ (Log file)



Script Odoo + Nginx + SSL
=========================

# Requirements: Ubuntu >= 16.04

Copy all files in any directory (server, vps, PC)

1 Your domain must be mapping to IP Server before to install this Script (DNS)

Example: mydomain.com > 54.168.45.45 (Your VPS / Server IP) 

2 Check as execute program

3 Run this script as root user

4 Enter a valid domain and email
