# general config
LANG=en_US.UTF-8
LANGUAGE=en_US
LC_ALL=C
SHELL=/bin/bash
BASH_ENV=/etc/bash.bashrc
DEBIAN_FRONTEND=noninteractive
USER=root
HOME=/root

# variable config
DOMAIN=cdash.nersc.gov

# min (0-59) hr (0-23) dom (0-31) mon (1-12) dow (0-6, Sunday=0)
# * * * * * ${SHELL} -l -c env | tee /var/www/cdash/environment.txt
# * * * * * ${SHELL} -l -c backup-cdash
@daily ${SHELL} -l -i /var/www/cdash/run-maintenance.sh
@monthly source /etc/profile && renew-cdash-cert -m 'nersc.cdash@outlook.com' -d ${DOMAIN}
