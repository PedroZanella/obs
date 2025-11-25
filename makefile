# Diretório onde estão os arquivos Terraform
TERRAFORM_DIR=./terraform

# Arquivo de variáveis (se estiver usando)
TFVARS=terraform.tfvars

# Comando base do Terraform
TF=terraform -chdir=$(TERRAFORM_DIR)

# Alvo padrão
default: aws-deploy

# Inicializa o Terraform
init:
	@echo " Inicializando Terraform..."
	$(TF) init

# Valida os arquivos
validate:
	@echo " Validando configuração..."
	$(TF) validate

# Formata os arquivos
fmt:
	@echo "Formatando arquivos..."
	$(TF) fmt

# Gera o plano
plan:
	@echo "Gerando plano de execução..."
	$(TF) plan -var-file=$(TFVARS)

# Aplica a infraestrutura
apply:
	@echo "Aplicando infraestrutura..."
	$(TF) apply -var-file=$(TFVARS) -auto-approve


# Destroi a infraestrutura
destroy:
	@echo " Destruindo infraestrutura..."
	$(TF) destroy -var-file=$(TFVARS) -auto-approve

# Alvo principal: deploy completo
aws-deploy: init validate fmt plan apply output