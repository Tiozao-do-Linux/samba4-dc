#!/bin/bash
set -e

function echo_line {
    echo "________________________________________________________________________________"
    echo "$@"
    echo "================================================================================"
}

if [ ! -f "${_SAMBA_CONF_DIR}/smb.conf" ]; then
    cat << '_EOF'
 ____________________________________________________________________________
/\                                                                           \
\_|                 Active Directory Domain Controler - ADDC                 |
  |                         Debian Linux com Samba4                          |
  |   _______________________________________________________________________|_
   \_/_________________________________________________________________________/

_EOF
    echo_line "Provisionando Domínio ${_DOMAIN} com REALM ${_REALM} ..."
    sleep 5
    samba-tool domain provision \
        --server-role=dc \
        --realm=${_REALM:-SEUDOMINIO.COM.BR} \
        --use-rfc2307 \
        --domain=${_DOMAIN:-SEUDOMINIO} \
        --adminpass=${_PASSWORD:-SuperSecretPassword@2025} \
        --dns-backend=${_DNS_BACKEND:-SAMBA_INTERNAL} \
        --option="dns forwarder = ${_DNS_FORWARDER_1:-1.1.1.1} ${_DNS_FORWARDER_2:-8.8.8.8}" \
        --option="template shell = /bin/bash" \
        --option="log level = 0"
    
    # Executar procedimentos após o provisionamento
    if [ -f "${_PROVISION_DIR}/post-provision.sh" ]; then
        ${_PROVISION_DIR}/post-provision.sh
    fi
fi

# Copiar a configuração gerada para o kerberos
cp ${_SAMBA_LIB_DIR}/private/krb5.conf /etc/

_DATE_TIME=`date`   #`date +%4Y/%m/%d-%H:%M:%S%z`

echo_line "Domínio ${_DOMAIN} já provisionado. Iniciando em ${_DATE_TIME}..."

# Configurar o log level do servidor
sed -i "s/log level = 0/log level = 1 auth_json_audit:3 dsdb_json_audit:5 dsdb_password_json_audit:5 dsdb_group_json_audit:5 dsdb_transaction_json_audit:5/g" ${_SAMBA_CONF_DIR}/smb.conf

exec samba -i -M single
