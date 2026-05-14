#!/bin/bash

# Configuração de logging e tratamento de erros
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== INICIANDO CONFIGURAÇÃO DA INSTÂNCIA ==="
date

sleep 60

# --- Instala CloudWatch Agent ---
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start
sudo apt install jq -y

# --- Parâmetros (substitua via Terraform/CloudFormation) ---
PHP_VERSION="${PHP_VERSION}"
APP_DOMAIN="${APP_DOMAIN}"
APP_PATH="/var/www/${APP_DOMAIN}"
DB_HOST="${DB_HOST}"
DB_USER="${DB_USER}"
DB_NAME="${DB_NAME}"
EFS_ID="${EFS_ID}"
SECRETS_WP="${SECRETS_WP}"
SECRETS_ARN="${SECRETS_ARN}"
SECRETS_SFTP="${SECRETS_SFTP}"
AWS_REGION="${AWS_REGION}"
REDIS_HOST="${REDIS_HOST}"

# --- Configuração do Sistema ---
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common awscli unzip git binutils rustc cargo pkg-config libssl-dev gettext nfs-common python3-pip

# Instala PHP + extensões + nginx
sudo apt install -y nginx php${PHP_VERSION} php${PHP_VERSION}-fpm \
php${PHP_VERSION}-cli php${PHP_VERSION}-mysql php${PHP_VERSION}-curl \
php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath \
php${PHP_VERSION}-soap php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-readline \
php${PHP_VERSION}-redis

# Instala dependências Python
sudo pip3 install botocore

# Prepara o diretório e monta EFS
sudo mkdir -p ${APP_PATH}
sudo mount -t efs -o tls ${EFS_ID}:/ ${APP_PATH}
grep -q "${EFS_ID}:/ ${APP_PATH} efs" /etc/fstab || echo "${EFS_ID}:/ ${APP_PATH} efs _netdev,tls 0 0" | sudo tee -a /etc/fstab

# Configuração do Banco de Dados
sudo tee ${APP_PATH}/config.php > /dev/null <<EOF
<?php
\$db_host = '${DB_HOST}';
\$db_user = '${DB_USER}';
\$db_name = '${DB_NAME}';
\$db_pass = '';
EOF

SECRET_VALUE=$(aws secretsmanager get-secret-value --region "$AWS_REGION" --secret-id "$SECRETS_ARN" --query 'SecretString' --output text)
DB_PASS=$(echo "$SECRET_VALUE" | jq -r '.password')
sed -i "s/\$db_pass = ''/\$db_pass = '$DB_PASS'/g" ${APP_PATH}/config.php

# --- Configuração do Nginx ---
sudo tee /etc/nginx/sites-available/${APP_DOMAIN} > /dev/null <<EOL
server {
    listen 80;
    server_name ${APP_DOMAIN} www.${APP_DOMAIN};
    root ${APP_PATH};
    index index.php index.html index.htm;

    access_log /var/log/nginx/${APP_DOMAIN}-access.log;
    error_log /var/log/nginx/${APP_DOMAIN}-error.log;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
        add_header Access-Control-Allow-Origin "*";
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# --- Instalação do WP-CLI ---
if ! command -v wp &> /dev/null; then
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
fi

# Verifica se o WordPress já está instalado
if [ ! -f "${APP_PATH}/wp-config.php" ]; then
  sudo chown -R www-data:www-data ${APP_PATH}
  sudo -u www-data wp core download --path=${APP_PATH} --skip-packages
  sudo -u www-data wp config create \
    --path=${APP_PATH} \
    --dbname=${DB_NAME} \
    --dbuser=${DB_USER} \
    --dbpass='' \
    --dbhost=${DB_HOST} \
    --skip-check
fi

# Define variável para o arquivo de configuração
WP_CONFIG_FILE="${APP_PATH}/wp-config.php"
TMP_CONFIG_FILE="${APP_PATH}/wp-config.tmp.php"

# Insere o bloco HTTPS antes do require_once
awk '
  /require_once ABSPATH . '\''wp-settings.php'\'';/ {
    print "if (isset($_SERVER[\"HTTP_X_FORWARDED_PROTO\"]) && $_SERVER[\"HTTP_X_FORWARDED_PROTO\"] === \"https\") {"
    print "    $_SERVER[\"HTTPS\"] = \"on\";"
    print "}"
    print "define(\"FORCE_SSL_ADMIN\", true);"
  }
  { print }
' "$WP_CONFIG_FILE" > "$TMP_CONFIG_FILE" && sudo mv "$TMP_CONFIG_FILE" "$WP_CONFIG_FILE"

# --- Atualiza URLs para https:// ---
sudo -u www-data wp option update home "https://${APP_DOMAIN}" --path=${APP_PATH}
sudo -u www-data wp option update siteurl "https://${APP_DOMAIN}" --path=${APP_PATH}

# Injeta senha no wp-config.php
SECRET_VALUE=$(aws secretsmanager get-secret-value --region "$AWS_REGION" --secret-id "$SECRETS_ARN" --query 'SecretString' --output text)
DB_PASS=$(echo "$SECRET_VALUE" | jq -r '.password')

# Substitui a senha vazia pela senha real no wp-config.php
sed -i "s/define( 'DB_PASSWORD', '' );/define( 'DB_PASSWORD', '$DB_PASS' );/" ${APP_PATH}/wp-config.php

# Verifica se WordPress já está instalado antes de instalar
if ! sudo -u www-data wp core is-installed --path=${APP_PATH} 2>/dev/null; then
  echo "Instalando WordPress..."
  
  WP_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 16)

  aws secretsmanager put-secret-value \
    --region "${AWS_REGION}" \
    --secret-id "${SECRETS_WP}" \
    --secret-string "{\"username\": \"admin\", \"password\": \"$WP_PASSWORD\"}"

  sudo wp core install \
    --url="https://${APP_DOMAIN}" \
    --title="WordPress Site" \
    --admin_user="admin" \
    --admin_password="$WP_PASSWORD" \
    --admin_email="admin@admin.com" \
    --path="${APP_PATH}" \
    --allow-root
    
  echo "WordPress instalado com sucesso!"
else
  echo "WordPress já está instalado, pulando instalação..."
fi

# Adiciona configuração Redis se ainda não existir
sudo wp config set WP_REDIS_HOST "${REDIS_HOST}" --path=${APP_PATH} --allow-root
sudo wp config set WP_REDIS_PORT 6379 --raw --path=${APP_PATH} --allow-root
sudo wp config set WP_CACHE_KEY_SALT "${APP_DOMAIN}_" --path=${APP_PATH} --allow-root 
sudo wp config set WP_REDIS_CLIENT "phpredis" --path=${APP_PATH} --allow-root 
sudo wp config set WP_CACHE true --raw --path=${APP_PATH} --allow-root 

# Instala e ativa plugin Redis Cache
sudo -u www-data wp plugin install redis-cache --activate --path=${APP_PATH}
sudo -u www-data wp redis enable --path=${APP_PATH}

# Instala e ativa plugin CDN Enabler
sudo -u www-data wp plugin install cdn-enabler --activate --path=${APP_PATH}
sudo -u www-data wp option update cdn_enabler "$(cat <<EOF
{
  "url": "${CLOUDFRONT_DOMAIN}",
  "dirs": "wp-content,wp-includes",
  "exclusions": "",
  "relative": false,
  "https": true,
  "cdn_url_https": "${CLOUDFRONT_DOMAIN}"
}
EOF
)" --format=json --path="${APP_PATH}"

# Ativação do site
sudo ln -sf /etc/nginx/sites-available/${APP_DOMAIN} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Permissões finais
sudo chown -R www-data:www-data ${APP_PATH}
sudo chmod -R 755 ${APP_PATH}
sudo find ${APP_PATH} -type d -exec chmod 755 {} \;
sudo find ${APP_PATH} -type f -exec chmod 644 {} \;

# Reinicia serviços
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl restart php${PHP_VERSION}-fpm

# Verifica status dos serviços
echo "Verificando status dos serviços..."
sudo systemctl status nginx --no-pager
sudo systemctl status php${PHP_VERSION}-fpm --no-pager

# Remove bootstrap do userdata
sudo rm -rf /var/lib/cloud/*

# Instalar o SFTP (apenas se habilitado)
if [ -n "${SECRETS_SFTP}" ]; then
  sudo apt install openssh-server

  # Adicionar usuário www-data no SFTP e ativar autenticação por senha
  SFTP_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 16)

  aws secretsmanager put-secret-value \
    --region "${AWS_REGION}" \
    --secret-id "${SECRETS_SFTP}" \
    --secret-string "{\"username\": \"www-data\", \"password\": \"$SFTP_PASSWORD\"}"

  echo "www-data:$SFTP_PASSWORD" | chpasswd

  cat <<EOF >> /etc/ssh/sshd_config

Match User www-data
    ChrootDirectory /var/www
    ForceCommand internal-sftp
    AllowTCPForwarding no
    X11Forwarding no

PubkeyAuthentication no
PasswordAuthentication yes
EOF

  sudo usermod -s /bin/bash www-data
  sudo systemctl restart sshd
  
  echo "SFTP configurado com sucesso!"
else
  echo "SFTP desabilitado, pulando configuração..."
fi

echo "=== CONFIGURAÇÃO CONCLUÍDA COM SUCESSO ==="
date