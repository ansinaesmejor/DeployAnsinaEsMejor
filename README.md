https://ansinaesmejor.com/web/database/selector
systemctl list-unit-files --all
sudo systemctl restart odoo13
sudo systemctl status odoo13


# DeployAnsinaEsMejor
# worker_analizer.sh

  GNU nano 4.8                                                                                         /opt/config/odoo13.conf                                                                                          Modified  


[options]
; This is the password that allows database operations:
;admin_passwd =
db_host = False
db_port = False
;db_user =
;db_password =
data_dir = /opt/odoosrc/data
logfile= /opt/odoosrc/log/odoo13-server.log

############# addons path ######################################

addons_path =
    /opt/odoosrc/13.0/extra-addons,
    /opt/odoosrc/13.0/odoo/addons

#################################################################

xmlrpc_port = 3369
;dbfilter = odoo13
logrotate = True
;limit_time_real = 1000
;limit_time_cpu = 1000

workers = 9
limit_memory_hard = 742084881
limit_memory_soft = 593667904
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
max_cron_threads = 1








