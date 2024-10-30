# AWS Systems Manager - Instalação Automatizada de Agentes de Segurança

## 1. Visão Geral do Processo

A instalação automatizada dos agentes de segurança segue o seguinte fluxo:

1. EC2s são provisionadas com o SSM Agent (via Terraform)
2. Systems Manager Run Command executa o script de instalação
3. SNS envia notificação de conclusão
4. Monitoramento via Systems Manager

## 2. Configuração do Systems Manager

### 2.1 Documento SSM (Command Document)
```yaml
# security-agent-installer.yaml
schemaVersion: '2.2'
description: 'Instalação Automatizada do Agente de Segurança'
parameters:
  AgentVersion:
    type: String
    description: 'Versão do agente de segurança'
    default: '1.0.0'
  AgentSource:
    type: String
    description: 'URL ou S3 bucket com o instalador'
    default: 's3://security-agents/agent-installer.sh'

mainSteps:
  - action: aws:downloadContent
    name: downloadInstaller
    inputs:
      sourceType: S3
      sourceInfo:
        path: '{{ AgentSource }}'
      destinationPath: /tmp/install-agent.sh

  - action: aws:runShellScript
    name: installAgent
    inputs:
      runCommand:
        - chmod +x /tmp/install-agent.sh
        - /tmp/install-agent.sh
        - systemctl status security-agent
        - rm /tmp/install-agent.sh

  - action: aws:runShellScript
    name: verifyInstallation
    inputs:
      runCommand:
        - |
          if systemctl is-active --quiet security-agent; then
            echo "Agente instalado com sucesso"
            exit 0
          else
            echo "Falha na instalação do agente"
            exit 1
          fi
```

## 3. Execução da Instalação Automatizada

### 3.1 Via AWS CLI
```bash
# Executar em todas as instâncias com tag específica
aws ssm send-command \
    --document-name "SecurityAgentInstaller" \
    --targets "Key=tag:Environment,Values=Production" \
    --parameters '{"AgentVersion":["1.0.0"]}' \
    --comment "Instalação automatizada do agente de segurança" \
    --notify \
    --notification-config '{"NotificationArn":"arn:aws:sns:REGION:ACCOUNT:TOPIC","NotificationEvents":["Success","Failed"],"NotificationType":"Command"}'
```

### 3.2 Via Console AWS
1. Acesse o AWS Systems Manager
2. Navegue até Run Command
3. Selecione o documento "SecurityAgentInstaller"
4. Escolha os targets (instâncias)
5. Configure os parâmetros
6. Configure as notificações SNS
7. Execute o comando

## 4. Monitoramento e Verificação

### 4.1 Verificar Status da Execução
```bash
# Listar todas as execuções
aws ssm list-command-invocations \
    --filters Key=DocumentName,Values=SecurityAgentInstaller

# Verificar detalhes de uma execução específica
aws ssm get-command-invocation \
    --command-id "command-id" \
    --instance-id "instance-id"
```

### 4.2 Logs e Outputs
- Os logs da execução são armazenados no CloudWatch Logs
- O status é enviado para o SNS configurado
- O Systems Manager mantém o histórico de execuções

## 5. Troubleshooting

### 5.1 Problemas Comuns
1. **Falha de Conexão**
   - Verificar IAM Role
   - Verificar Security Groups
   - Verificar SSM Agent

2. **Falha na Instalação**
   - Verificar logs no CloudWatch
   - Verificar permissões
   - Verificar disponibilidade do instalador

### 5.2 Comandos de Diagnóstico
```bash
# Verificar status do SSM Agent
aws ssm describe-instance-information

# Verificar conectividade
aws ssm get-connection-status \
    --target "instance-id"
```

## 6. Automatização com Terraform

```hcl
# SSM Document
resource "aws_ssm_document" "security_agent_installer" {
  name            = "SecurityAgentInstaller"
  document_type   = "Command"
  document_format = "YAML"
  content        = file("security-agent-installer.yaml")

  tags = {
    Environment = "Production"
  }
}

# SNS Topic para notificações
resource "aws_sns_topic" "ssm_notifications" {
  name = "ssm-notifications"
}

# IAM Role para execução
resource "aws_iam_role" "ssm_automation" {
  name = "ssm-automation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}
```

## 7. Práticas Recomendadas

1. **Segurança**
   - Use IAM roles com menor privilégio
   - Criptografe os instaladores no S3
   - Use VPC Endpoints para Systems Manager

2. **Operacional**
   - Configure timeout adequado
   - Implemente retry logic
   - Mantenha logs detalhados
   - Configure alertas para falhas

3. **Manutenção**
   - Atualize regularmente os agentes
   - Mantenha backups dos instaladores
   - Documente as versões instaladas
