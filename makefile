# Diretório onde estão os arquivos Terraform
TERRAFORM_DIR=./terraform

# Arquivo de variáveis (se estiver usando)
TFVARS=terraform.tfvars

# Comando base do Terraform
TF=terraform -chdir=$(TERRAFORM_DIR)

# Importa variáveis do .env (não versionado)
include .env
export

# Alvo padrão: quando rodar só "make"
default: full-deploy

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

DOCKER=sudo docker

# Gera o htpasswd usando variáveis do .env
htpasswd:
	@echo "🔐 Gerando arquivo htpasswd..."
	$(DOCKER) run --rm httpd:2.4 htpasswd -Bbn $(USER) $(PASS) > $(HTPASSWD_FILE)
	@chmod 640 nginx/.htpasswd

# Gera certificados self-signed (para testes)
certs:
	@echo "Gerando certificados SSL..."
	mkdir -p $(CERT_DIR)
	sudo chown -R $(USER):$(USER) $(CERT_DIR)
	sudo chmod -R 755 $(CERT_DIR)
	openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
	-keyout $(CERT_DIR)/server.key -out $(CERT_DIR)/server.crt \
	-subj "/CN=localhost"
	@chmod 600 $(CERT_DIR)/server.key
	@chmod 644 $(CERT_DIR)/server.crt

# Sobe toda a stack Docker
docker-up:
	@echo "Subindo containers Docker..."
	docker compose up -d

# Derruba os containers
docker-down:
	@echo "Derrubando containers Docker..."
	docker compose down

# Limpa arquivos gerados
clean:
	@echo "Limpando arquivos gerados..."
	rm -f nginx/.htpasswd
	rm -rf $(CERT_DIR)

# Deploy completo: Terraform + segurança + Docker
full-deploy: init validate fmt plan apply htpasswd certs docker-up