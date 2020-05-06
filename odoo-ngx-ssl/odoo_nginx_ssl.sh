#!/bin/bash
# Copyright 2018 Odooerpcloud

# Este script instala nginx y lo configura para trabajar con
# workers, redireccionando la salida del modulo im_chat que da un error
# en el log en la libreria bus.Bus, tambien el tema del longpolling odoo
#
#
# Default Odoo PORT
PORT=3369

echo "Ingrese el nombre de dominio para el servidor (ejemplo: odooerpcloud.com):"
read domain

echo "Ingrese un email (ejemplo: info@odooerpcloud.com):"
read email

echo "************************************************"
echo "**********Actualizando repositorios...**********"
echo "************************************************"
echo "************************************************"
sudo apt-get update

echo "*************** instalar configurar certificados **********************"

sudo apt-get -y install software-properties-common
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt-get update
sudo apt-get -y install certbot
certbot certonly --standalone -d $domain,www.$domain -m $email --agree-tos -n


echo "************************************************"
echo "**********Instalando Nginx... ******************"
echo "************************************************"
echo "************************************************"
sudo service nginx stop
sudo apt-get install -y nginx

echo "************************************************"
echo "**********Configurando Nginx... ****************"
echo "************************************************"
echo "************************************************"

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

echo "***************************************************"
echo "**********Comprobando configuracion...*************"
echo "***************************************************"
echo "***************************************************"
sudo nginx -t

echo "***************************************************"
echo "**********Reiniciando servicios...*****************"
echo "***************************************************"
echo "***************************************************"

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
echo "**********Terminado***********************************************"
echo "***********Ya puede acceder a su instancia http://$domain*********"
echo "******************************************************************"
