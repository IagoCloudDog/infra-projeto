#!/bin/bash

# Atualização do sistema
sudo apt-get update
sudo apt-get upgrade -y

# Install CloudWatch Agent
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start

# Instalação de dependências
sudo apt install -y sqlite3 apt-transport-https ca-certificates curl software-properties-common awscli

# Adicionar repositório do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Adicionar o usuário ao grupo 'docker'
sudo usermod -aG docker ubuntu

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Habilitar e iniciar o serviço Docker
sudo systemctl enable docker
sudo systemctl start docker

# Clonar repositório do OpenVPN-UI
sudo -u ubuntu git clone https://github.com/d3vilh/openvpn-server /home/ubuntu/openvpn-server

CUSTOMER_NAME="${CUSTOMER_NAME}"
VPC_RANGE="${VPC_RANGE}"
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
DB_HOST_PATH=/home/ubuntu/openvpn-server/db
DB_FILE=$DB_HOST_PATH/data.db

# Entrar no diretório do repositório
cd /home/ubuntu/openvpn-server

# Gerar senha do admin e atualizar Secrets Manager
ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 16)
aws secretsmanager put-secret-value \
  --region "${AWS_REGION}" \
  --secret-id "${SECRETS_OPENVPN}" \
  --secret-string "{\"username\": \"admin\", \"password\": \"$ADMIN_PASSWORD\"}"

# Atualizar docker-compose.yml com usuário e senha
sudo sed -i "s/OPENVPN_ADMIN_USERNAME=admin/OPENVPN_ADMIN_USERNAME=admin/" docker-compose.yml
sudo sed -i "s/OPENVPN_ADMIN_PASSWORD=gagaZush/OPENVPN_ADMIN_PASSWORD=$ADMIN_PASSWORD/" docker-compose.yml

# Atualizar client.conf com IP da instância e comentar redirect-gateway
sudo sed -i "s/remote 127.0.0.1 1194 udp/remote $EC2_IP 1194 udp/" /home/ubuntu/openvpn-server/config/client.conf
sudo sed -i "s/^redirect-gateway def1/#redirect-gateway def1/" /home/ubuntu/openvpn-server/config/client.conf

sudo sed -i "s/\"UA\"/\"BR\"/" /home/ubuntu/openvpn-server/config/easy-rsa.vars
sudo sed -i "s/\"KY\"/\"SP\"/" /home/ubuntu/openvpn-server/config/easy-rsa.vars
sudo sed -i "s/\"Kyiv\"/\"Mogi das Cruzes\"/" /home/ubuntu/openvpn-server/config/easy-rsa.vars
sudo sed -i "s/\"SweetHome\"/\"${CUSTOMER_NAME}\"/" /home/ubuntu/openvpn-server/config/easy-rsa.vars
sudo sed -i "s/\"sweet@home.net\"/\"nome@${CUSTOMER_NAME}.com.br\"/" /home/ubuntu/openvpn-server/config/easy-rsa.vars
sudo sed -i "s/\"MyOrganizationalUnit\"/\"DevOps\"/" /home/ubuntu/openvpn-server/config/easy-rsa.vars

VPC_DNS="$(echo ${VPC_RANGE} | cut -d'.' -f1-3).2"

sudo cat > /home/ubuntu/openvpn-server/server.conf << EOF
management 0.0.0.0 2080

dev tun
port 1194
proto udp

topology subnet
keepalive 10 120
max-clients 100

persist-key
persist-tun
explicit-exit-notify 1

user nobody
group nogroup

client-config-dir /etc/openvpn/staticclients
ifconfig-pool-persist pki/ipp.txt

ca pki/ca.crt
cert pki/issued/server.crt
key pki/private/server.key
crl-verify pki/crl.pem
dh pki/dh.pem

tls-crypt pki/ta.key
tls-version-min 1.2
remote-cert-tls client

cipher AES-256-GCM
data-ciphers AES-256-GCM:AES-192-GCM:AES-128-GCM

auth SHA512

server 10.0.70.0 255.255.255.0
push "dhcp-option DNS $VPC_DNS"
push "dhcp-option DNS 8.8.8.8"
push "route ${VPC_RANGE} 255.255.0.0"

log /var/log/openvpn/openvpn.log
verb 3
status /var/log/openvpn/openvpn-status.log
status-version 2
EOF

# Criar/atualizar tabela o_v_client_config
mkdir -p $DB_HOST_PATH
sqlite3 $DB_FILE <<SQL
CREATE TABLE IF NOT EXISTS o_v_client_config (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile VARCHAR(64) NOT NULL UNIQUE,
    func_mode INTEGER NOT NULL DEFAULT 0,
    device VARCHAR(255) NOT NULL DEFAULT '',
    server_address VARCHAR(255) NOT NULL DEFAULT '',
    port INTEGER NOT NULL DEFAULT 0,
    resolve_retry VARCHAR(255) NOT NULL DEFAULT '',
    o_v_client_user VARCHAR(255) NOT NULL DEFAULT '',
    o_v_client_group VARCHAR(255) NOT NULL DEFAULT '',
    persist_tun VARCHAR(255) NOT NULL DEFAULT '',
    persist_key VARCHAR(255) NOT NULL DEFAULT '',
    remote_cert_t_l_s VARCHAR(255) NOT NULL DEFAULT '',
    open_vpn_server_port VARCHAR(255) NOT NULL DEFAULT '',
    proto VARCHAR(255) NOT NULL DEFAULT '',
    ca VARCHAR(255) NOT NULL DEFAULT '',
    cert VARCHAR(255) NOT NULL DEFAULT '',
    key VARCHAR(255) NOT NULL DEFAULT '',
    ta VARCHAR(255) NOT NULL DEFAULT '',
    cipher VARCHAR(255) NOT NULL DEFAULT '',
    redirect_gateway VARCHAR(255) NOT NULL DEFAULT '',
    auth VARCHAR(255) NOT NULL DEFAULT '',
    auth_no_cache VARCHAR(255) NOT NULL DEFAULT '',
    tls_client VARCHAR(255) NOT NULL DEFAULT '',
    verbose VARCHAR(255) NOT NULL DEFAULT '',
    auth_user_pass VARCHAR(255) NOT NULL DEFAULT '',
    t_f_a_issuer VARCHAR(255) NOT NULL DEFAULT '',
    custom_conf_one VARCHAR(255) NOT NULL DEFAULT '',
    custom_conf_two VARCHAR(255) NOT NULL DEFAULT '',
    custom_conf_three VARCHAR(255) NOT NULL DEFAULT ''
);
DELETE FROM o_v_client_config WHERE profile='default';
INSERT INTO o_v_client_config (
    profile, device, server_address, port, resolve_retry, o_v_client_user, o_v_client_group,
    persist_tun, persist_key, remote_cert_t_l_s, open_vpn_server_port, proto, cipher,
    redirect_gateway, auth, auth_no_cache, tls_client, verbose, custom_conf_one, custom_conf_two, custom_conf_three
) VALUES (
    'default', 'tun', '$EC2_IP', 1194, 'resolv-retry infinite', 'nobody', 'nogroup',
    'persist-tun', 'persist-key', 'remote-cert-tls server', '1194', 'udp', 'AES-256-GCM',
    '#redirect-gateway def1', 'SHA512', 'auth-nocache', 'tls-client', '3',
    '#Custom Option One', '#Custom Option Two', '#Custom Option Three'
);
-- Atualiza tabela easy_r_s_a_config
CREATE TABLE IF NOT EXISTS easy_r_s_a_config (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile VARCHAR(64) NOT NULL UNIQUE,
    easy_r_s_a_d_n VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_req_country VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_req_province VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_req_city VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_req_org VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_req_email VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_req_ou VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_req_cn VARCHAR(255) NOT NULL DEFAULT '',
    easy_r_s_a_key_size INTEGER NOT NULL DEFAULT 2048,
    easy_r_s_a_ca_expire INTEGER NOT NULL DEFAULT 3650,
    easy_r_s_a_cert_expire INTEGER NOT NULL DEFAULT 825,
    easy_r_s_a_cert_renew INTEGER NOT NULL DEFAULT 30,
    easy_r_s_a_crl_days INTEGER NOT NULL DEFAULT 180
);
DELETE FROM easy_r_s_a_config WHERE profile='default';
INSERT INTO easy_r_s_a_config (
    profile, easy_r_s_a_d_n, easy_r_s_a_req_country, easy_r_s_a_req_province,
    easy_r_s_a_req_city, easy_r_s_a_req_org, easy_r_s_a_req_email, easy_r_s_a_req_ou
) VALUES (
    'default', 'org', 'BR', 'SP', 'Mogi das Cruzes', '${CUSTOMER_NAME}', 'nome@${CUSTOMER_NAME}.com.br', 'DevOps'
);
SQL

# Subir container
sudo docker compose up -d

echo "Instalação e configuração concluídas!"