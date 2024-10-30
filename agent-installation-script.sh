#!/bin/bash
# install_agent.sh

# Configuração de logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Variáveis
AGENT_VERSION="1.0.0"
AGENT_URL="https://security-agent-repository/agent-${AGENT_VERSION}.tar.gz"
INSTALL_DIR="/opt/security-agent"

# Função para logging
log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

# Função de limpeza
cleanup() {
    log "Realizando limpeza..."
    rm -f /tmp/agent.tar.gz
    rm -rf /tmp/agent
}

# Tratamento de erros
set -e
trap cleanup EXIT

# Início da instalação
log "Iniciando instalação do agente de segurança v${AGENT_VERSION}"

# Criar diretório de instalação
log "Criando diretório de instalação"
mkdir -p ${INSTALL_DIR}

# Download do agente
log "Baixando agente de segurança"
curl -L -o /tmp/agent.tar.gz ${AGENT_URL}

# Verificação do download
if [ $? -ne 0 ]; then
    log "Erro no download do agente"
    exit 1
fi

# Extrair arquivo
log "Extraindo agente"
tar -xzf /tmp/agent.tar.gz -C ${INSTALL_DIR}

# Configurar o serviço
log "Configurando serviço do agente"
cat << EOF > /etc/systemd/system/security-agent.service
[Unit]
Description=Security Agent Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=${INSTALL_DIR}/bin/security-agent
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
log "Recarregando systemd"
systemctl daemon-reload

# Iniciar e habilitar o serviço
log "Iniciando e habilitando o serviço"
systemctl enable security-agent
systemctl start security-agent

# Verificar status do serviço
if systemctl is-active --quiet security-agent; then
    log "Agente instalado e iniciado com sucesso"
    exit 0
else
    log "Erro ao iniciar o serviço do agente"
    exit 1
fi
