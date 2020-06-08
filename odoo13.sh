#!/bin/bash
# Copyright 2019 odooerpcloud.com
# AVISO IMPORTANTE!!! (WARNING!!!)
# ASEGURESE DE TENER UN SERVIDOR / VPS CON AL MENOS > 1GB DE RAM
# You must to have at least > 1GB of RAM

domain=ansinaesmejor.com
email=ansinaesmejor@gmail.com
# VARIABLE MAX MEMORY PERCENT
CMD_M=80

OS_NAME=$(lsb_release -cs)
usuario=$USER
DIR_PATH=$(pwd)
VCODE=13
VERSION=13.0
PORT=3369
DEPTH=1
PATHBASE=/opt/odoosrc
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/$VERSION/extra-addons
PATHREPOS_MX=$PATHREPOS/MX

if [[ $OS_NAME == "disco" ]];

then
	echo $OS_NAME
	OS_NAME="bionic"

fi

wk64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_amd64.deb"
wk32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_i386.deb"

sudo adduser --system --quiet --shell=/bin/bash --home=$PATHBASE --gecos 'ODOO' --group $usuario
sudo adduser $usuario sudo

# add universe repository & update (Fix error download libraries)
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y git bc
# Update and install Postgresql
sudo apt-get install postgresql -y
sudo su - postgres -c "createuser -s $usuario"

sudo mkdir $PATHBASE
sudo mkdir $PATHBASE/$VERSION
sudo mkdir $PATHREPOS
sudo mkdir $PATHREPOS_MX
sudo mkdir $PATH_LOG
cd $PATHBASE
# Download Odoo from git source
sudo git clone https://github.com/odoo/odoo.git -b $VERSION --depth $DEPTH $PATHBASE/$VERSION/odoo

# Install python3 and dependencies for Odoo
sudo apt-get -y install gcc python3-dev libxml2-dev libxslt1-dev \
 libevent-dev libsasl2-dev libldap2-dev libpq-dev \
 libpng-dev libjpeg-dev

sudo apt-get -y install python3 python3-pip
sudo apt-get -y install python-pip
sudo pip3 install libsass vobject qrcode num2words setuptools

# FIX wkhtml* dependencie Ubuntu Server 18.04
sudo apt-get -y install libxrender1

# Install nodejs and less
sudo apt-get install -y npm node-less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

# Download & install WKHTMLTOPDF
sudo rm $PATHBASE/wkhtmltox_0.12.5-1*.deb
sudo rm wkhtmltox_0.12.5-1*.deb
if [[ "`getconf LONG_BIT`" == "32" ]];

then
	sudo wget $wk32
else
	sudo wget $wk64
fi

sudo dpkg -i --force-depends wkhtmltox_0.12.5-1*.deb
sudo ln -s /usr/local/bin/wkhtml* /usr/bin


# install python requirements file (Odoo)
sudo pip3 install -r $PATHBASE/$VERSION/odoo/requirements.txt
sudo apt-get -f -y install

# worker_analizer
# CONST 1GB
CONST_1GB="1024*1024*1024"

arithmetic() {
  echo "scale=0; $1" | bc
}

calculateWorkers(){
  if [ $(calculateMaxMemory) -le $(arithmetic "$CONST_1GB") ]; then echo 1 # 1GB
  elif [ $(calculateMaxMemory) -le $(arithmetic "2*$CONST_1GB") ]; then echo 2 # 2GB
  elif [ $(calculateMaxMemory) -le $(arithmetic "3*$CONST_1GB") ]; then echo 3 # 3GB
  else
    echo $(arithmetic "1+$(calculateNumCores)*2")
  fi
}

calculateMemTotal () {
  echo $(arithmetic "$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')*1024")
}

calculateNumCores(){
  echo $(nproc)
}

calculateMaxMemory() {
  echo $(arithmetic "$(calculateMemTotal)*$CMD_M/100")
}

calculateLimitMemoryHard() {
  echo $(arithmetic "$(calculateMaxMemory)/$(calculateWorkers)")
}

calculateLimitMemorySoft() {
  echo $(arithmetic "$(calculateLimitMemoryHard)*80/100")
}

confworkers=$(calculateWorkers)
conflimit_memory_hard=$(calculateLimitMemoryHard)
conflimit_memory_soft=$(calculateLimitMemorySoft)
conflimit_request=8192
conflimit_time_cpu=60
conflimit_time_real=120
confmax_cron_threads=1

cd $DIR_PATH

sudo mkdir /opt/config
sudo rm /opt/config/odoo$VCODE.conf
sudo touch /opt/config/odoo$VCODE.conf

echo "
[options]
; This is the password that allows database operations:
;admin_passwd =
db_host = False
db_port = False
;db_user =
;db_password =
data_dir = $PATHBASE/data
logfile= $PATH_LOG/odoo$VCODE-server.log

############# addons path ######################################

addons_path =
    $PATHREPOS,
    $PATHREPOS/ansinaesmejor,
    $PATHREPOS/Odoo_CFDI_3.3,
    $PATHREPOS/server-tools,
    $PATHREPOS/web,
    $PATHREPOS/social,
    $PATHREPOS/website,
    $PATHREPOS/server-brand,
    $PATHREPOS/product-attribute,
    $PATHREPOS/stock-logistics-warehouse,
    $PATHREPOS/account-financial-tools,
    $PATHREPOS/partner-contact,
    $PATHREPOS/stock-logistics-barcode,
    $PATHREPOS/knowledge,
    $PATHBASE/$VERSION/odoo/addons

#################################################################

xmlrpc_port = $PORT
;dbfilter = odoo13
logrotate = True

workers = $confworkers
limit_memory_hard = $conflimit_memory_hard
limit_memory_soft = $conflimit_memory_soft
limit_request = $conflimit_request
limit_time_cpu = $conflimit_time_cpu
limit_time_real = $conflimit_time_real
max_cron_threads = $confmax_cron_threads

" | sudo tee --append /opt/config/odoo$VCODE.conf

sudo rm /etc/systemd/system/odoo$VCODE.service
sudo touch /etc/systemd/system/odoo$VCODE.service
sudo chmod +x /etc/systemd/system/odoo$VCODE.service
echo "
[Unit]
Description=odoo13
After=postgresql.service

[Service]
Type=simple
User=$usuario
ExecStart=$PATHBASE/$VERSION/odoo/odoo-bin --config /opt/config/odoo$VCODE.conf

[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/odoo$VCODE.service
sudo systemctl daemon-reload
sudo systemctl enable odoo$VCODE.service
sudo systemctl start odoo$VCODE

sudo chown -R $usuario: $PATHBASE
sudo chown -R $usuario: /opt/config



# Copyright 2018 Odooerpcloud

# Este script instala nginx y lo configura para trabajar con
# workers, redireccionando la salida del modulo im_chat que da un error
# en el log en la libreria bus.Bus, tambien el tema del longpolling odoo
#
#

echo "*************** instalar configurar certificados **********************"

sudo apt-get -y install software-properties-common
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt-get update
sudo apt-get -y install certbot
certbot certonly --standalone -d $domain,www.$domain -m $email --agree-tos -n


echo "**********Instalando Nginx... ******************"
sudo service nginx stop
sudo apt-get install -y nginx

echo "**********Configurando Nginx... ****************"

#sudo rm /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-available/$domain
sudo rm /etc/nginx/sites-available/odoo
sudo rm /etc/nginx/sites-enable/$domain
sudo rm /etc/nginx/sites-enable/odoo

sudo touch /etc/nginx/sites-available/$domain
sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
sudo mkdir /etc/nginx/ssl
sudo openssl dhparam -out /etc/nginx/ssl/dhp-2048.pem 2048


echo "
upstream odoo {
    server 127.0.0.1:$PORT;
}
#### Activar esto cuando se use workers unicamente ######
upstream openerp-im {
    server 127.0.0.1:8072 weight=1 fail_timeout=0;
}

server {
    listen 443 default;
    server_name $domain;

    client_max_body_size 200m;
    proxy_read_timeout 300000;

    access_log	/var/log/nginx/odoo.access.log;
    error_log	/var/log/nginx/odoo.error.log;

    ssl on;
    ssl_certificate	/etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key	/etc/letsencrypt/live/$domain/privkey.pem;
    keepalive_timeout	60;

    ssl_ciphers	HIGH:!aNULL!ADH:!MD5;
    ssl_protocols	TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/nginx/ssl/dhp-2048.pem;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass http://odoo;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;

        proxy_set_header    Host \$host;
        proxy_set_header    X-Real-IP \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Host  \$host;
        proxy_set_header    X-Forwarded-Proto https;
    }

    location ~* /web/static/ {
        proxy_cache_valid 200 60m;
        proxy_buffering on;
		expires 864000;
        proxy_pass http://odoo;
    }
    #### Activar esto cuando se use workers unicamente ######
    location /longpolling/ {
    	proxy_pass http://127.0.0.1:8072;
    }
    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
    gzip on;
    gzip_min_length 1000;
    gzip_proxied    expired no-cache no-store private auth;
}

server {
    listen	80;
    server_name www.$domain $domain;
    listen [::]:80 ipv6only=on;

    add_header Strict-Transport-Security max-age=2592000;
    return 301 https://\$host\$request_uri;
}" > /etc/nginx/sites-available/$domain

echo "**********Comprobando configuracion...*************"
sudo nginx -t

echo "**********Reiniciando servicios...*****************"

# sudo /etc/init.d/odoo-server restart


# Fix error 400 uri too large
sudo sed -i '/large_client_header_buffers/d' /etc/nginx/nginx.conf
sudo sed -i 's/sendfile on;/large_client_header_buffers 4 32k;\n\tsendfile on;/' /etc/nginx/nginx.conf
sudo /etc/init.d/nginx restart


# ############## Crontab para renovar certificados SSL  ######################
# ################### todos los lunes en la madrugada ########################
sudo -u root bash << eof
whoami
cd /root
echo "Agregando crontab para renovar certificados SSL..."

sudo crontab -l | sed -e '/certbot/d; /nginx/d' > temporal

echo "
35 2 * * 1 /root/renew_ssl.sh" >> temporal
crontab temporal
rm temporal
eof

sudo cp ./renew_ssl.sh /root

echo "******************************************************************"

echo "Odoo $VERSION Installation has finished!! ;) by odooerpcloud.com"
echo "You can access from: http://mydomain.com:$PORT  or http://localhost:$PORT"

echo "El nombre de dominio para el servidor: http://$domain"
echo "email: $email"

echo "******************************************************************"

sudo git clone https://github.com/ansinaesmejor/ansinaesmejor.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/ansinaesmejor
sudo git clone https://github.com/ansinaesmejor/Odoo_CFDI_3.3.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/Odoo_CFDI_3.3
sudo git clone https://github.com/ansinaesmejor/server-tools.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/server-tools
sudo git clone https://github.com/ansinaesmejor/web.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/web
sudo git clone https://github.com/ansinaesmejor/social.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/social
sudo git clone https://github.com/ansinaesmejor/website.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/website
sudo git clone https://github.com/ansinaesmejor/server-brand.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/server-brand
sudo git clone https://github.com/ansinaesmejor/product-attribute.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/product-attribute
sudo git clone https://github.com/ansinaesmejor/stock-logistics-warehouse.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/stock-logistics-warehouse
sudo git clone https://github.com/ansinaesmejor/account-financial-tools.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/account-financial-tools
sudo git clone https://github.com/ansinaesmejor/partner-contact.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/partner-contact
sudo git clone https://github.com/ansinaesmejor/stock-logistics-barcode.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/stock-logistics-barcode
sudo git clone https://github.com/ansinaesmejor/knowledge.git -b 13.0 --depth 1 /opt/odoosrc/13.0/extra-addons/knowledge
