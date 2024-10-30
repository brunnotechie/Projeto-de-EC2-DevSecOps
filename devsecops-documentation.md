# Documentação do Projeto DevSecOps AWS
## Instalação Automatizada de Agentes de Segurança

### Índice
1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Estrutura do Projeto](#estrutura-do-projeto)
4. [Configuração Inicial](#configuração-inicial)
5. [Execução do Projeto](#execução-do-projeto)
6. [Monitoramento e Verificação](#monitoramento-e-verificação)
7. [Troubleshooting](#troubleshooting)

### Visão Geral

Este projeto implementa uma solução DevSecOps automatizada na AWS para provisionar infraestrutura e instalar agentes de segurança em múltiplas instâncias EC2. A solução utiliza:
- Terraform para IaC (Infrastructure as Code)
- AWS Systems Manager para automação
- Amazon SNS para notificações
- EC2 para hospedagem das aplicações

### Pré-requisitos

1. **Ferramentas Locais**
   - AWS CLI instalado e configurado
   - Terraform (versão ≥ 1.0.0)
   - Git

2. **Credenciais AWS**
   - Acesso programático configurado
   - Permissões necessárias:
     - EC2
     - VPC
     - Systems Manager
     - SNS
     - IAM

3. **Configurações AWS**
   - Região AWS definida
   - Limites de serviço verificados

### Estrutura do Projeto

```plaintext
devsecops-aws/
├── main.tf             # Recursos principais
├── variables.tf        # Definição de variáveis
├── terraform.tfvars    # Valores das variáveis
├── outputs.tf          # Outputs do Terraform
└── scripts/
    └── install_agent.sh # Script de instalação do agente
```

### Configuração Inicial

1. **Clone do Repositório**
```bash
git clone [URL_DO_REPOSITORIO]
cd devsecops-aws
```

2. **Configuração das Variáveis**
Crie um arquivo `terraform.tfvars` com as seguintes variáveis:
```hcl
aws_region         = "us-east-1"
project_name       = "devsecops"
vpc_cidr          = "10.0.0.0/16"
instance_count    = 2
notification_email = "seu.email@dominio.com"
```

3. **Configuração do AWS CLI**
```bash
aws configure
# Insira suas credenciais quando solicitado
```

### Execução do Projeto

1. **Inicialização do Terraform**
```bash
terraform init
```
*O que faz:* Inicializa o diretório de trabalho do Terraform, baixa os providers necessários e prepara o ambiente.

2. **Planejamento da Infraestrutura**
```bash
terraform plan -out=tfplan
```
*O que faz:* 
- Verifica o estado atual
- Compara com a configuração desejada
- Gera um plano de execução
- Salva o plano em um arquivo

3. **Aplicação da Infraestrutura**
```bash
terraform apply tfplan
```
*O que faz:*
- Cria a VPC e subnets
- Provisiona as instâncias EC2
- Configura o Systems Manager
- Cria o tópico SNS
- Configura as IAM roles

4. **Instalação dos Agentes de Segurança**
```bash
aws ssm send-command \
    --document-name "${var.project_name}-security-agent-install" \
    --targets "Key=tag:Name,Values=${var.project_name}-server-*" \
    --region ${var.aws_region}
```
*O que faz:*
- Executa o documento SSM em todas as instâncias marcadas
- Instala o agente de segurança
- Configura o serviço
- Inicia o agente

### Monitoramento e Verificação

1. **Verificação do Status da Instalação**
```bash
aws ssm list-command-invocations \
    --command-id [COMMAND_ID] \
    --details
```

2. **Verificação dos Agentes**
```bash
aws ssm describe-instance-information
```

3. **Verificação das Notificações**
- Verifique seu email para confirmação do SNS
- Monitore as notificações de conclusão

### Troubleshooting

1. **Problemas Comuns e Soluções**

   a. **Falha na Criação de Recursos**
   - Verifique as permissões IAM
   - Confirme os limites de serviço
   ```bash
   terraform plan -refresh-only
   ```

   b. **Falha na Instalação do Agente**
   - Verifique a conectividade da instância
   - Confirme o status do Systems Manager
   ```bash
   aws ssm get-command-invocation \
       --command-id [COMMAND_ID] \
       --instance-id [INSTANCE_ID]
   ```

2. **Logs e Diagnóstico**
   - Logs do Systems Manager: AWS Console → Systems Manager → Run Command
   - Logs do EC2: AWS Console → EC2 → Instances → Instance → Actions → Monitor and troubleshoot → Get system log

### Limpeza do Ambiente

1. **Remoção da Infraestrutura**
```bash
terraform destroy
```
*O que faz:*
- Remove todas as instâncias EC2
- Deleta a VPC e recursos associados
- Remove as configurações do Systems Manager
- Limpa o tópico SNS
- Remove as IAM roles

### Considerações de Segurança

1. **Boas Práticas Implementadas**
   - Instâncias em subnets privadas
   - Mínimo privilégio nas IAM roles
   - Comunicação segura via Systems Manager
   - Notificações automatizadas

2. **Monitoramento de Segurança**
   - Verifique regularmente os logs
   - Monitore as notificações SNS
   - Mantenha o agente de segurança atualizado

### Próximos Passos

1. **Melhorias Sugeridas**
   - Implementar backup automatizado
   - Adicionar monitoramento avançado
   - Configurar rotação automática de credenciais

2. **Manutenção**
   - Atualize regularmente os agentes
   - Revise as políticas de segurança
   - Mantenha o Terraform atualizado

