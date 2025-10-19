# Variables
DOCKER_COMPOSE = docker-compose
APP_CONTAINER = app
WEB_CONTAINER = web
DB_CONTAINER = db
QUEUE_CONTAINER = queue
SCHEDULER_CONTAINER = scheduler
CACHE_CONTAINER = cache

# Obtener UID y GID del usuario actual
export USER_ID := $(shell id -u)
export GROUP_ID := $(shell id -g)

.PHONY: help init setup up down restart rebuild logs shell test migrate fresh seed artisan composer npm cache-clear queue-restart status

help:
	@echo "Comandos disponibles para Laravel:"
	@echo ""
	@echo "🚀 Inicio:"
	@echo "  make init              - [SOLO PRIMERA VEZ] Crear proyecto Laravel 11"
	@echo "  make setup             - [OTROS DEVS] Configurar proyecto clonado"
	@echo ""
	@echo "🐳 Docker:"
	@echo "  make up                - Levantar contenedores"
	@echo "  make down              - Detener contenedores"
	@echo "  make restart           - Reiniciar contenedores"
	@echo "  make rebuild           - Reconstruir contenedores"
	@echo "  make logs              - Ver logs"
	@echo "  make shell             - Entrar al contenedor"

init:
	@echo "🚀 Inicializando proyecto Laravel 11..."
	@echo "👤 Usuario: $(USER_ID):$(GROUP_ID)"
	@mkdir -p docker storage/logs/nginx backups
	@echo "🏗️  Construyendo contenedores..."
	@$(DOCKER_COMPOSE) build
	@echo "▶️  Iniciando servicios base..."
	@$(DOCKER_COMPOSE) up -d db cache
	@echo "⏳ Esperando base de datos..."
	@sleep 15
	@if [ ! -f composer.json ]; then \
	    echo "📦 Instalando Laravel 11 en carpeta temporal..."; \
	    mkdir -p .laravel-temp; \
	    $(DOCKER_COMPOSE) run --rm -v $(PWD)/.laravel-temp:/tmp/laravel $(APP_CONTAINER) \
	        composer create-project laravel/laravel:^11.0 /tmp/laravel --no-interaction; \
	    echo "📂 Moviendo archivos de Laravel..."; \
	    cp -r .laravel-temp/* .laravel-temp/.* . 2>/dev/null || true; \
	    rm -rf .laravel-temp; \
	    echo "✅ Laravel instalado"; \
	fi
	@echo "📦 Instalando dependencias de Composer..."
	@$(DOCKER_COMPOSE) run --rm $(APP_CONTAINER) composer install --no-interaction
	@echo "📝 Configurando .env para Docker..."
	@if [ -f configure-env.sh ]; then \
	    ./configure-env.sh; \
	else \
	    if [ -f .env.example ] && [ ! -f .env ]; then cp .env.example .env; fi; \
	    sed -i 's/^DB_CONNECTION=sqlite/DB_CONNECTION=mysql/' .env; \
	    sed -i 's|^# DB_HOST=.*|DB_HOST=db|' .env; \
	    sed -i 's|^# DB_PORT=.*|DB_PORT=3306|' .env; \
	    sed -i 's|^# DB_DATABASE=.*|DB_DATABASE=laravel|' .env; \
	    sed -i 's|^# DB_USERNAME=.*|DB_USERNAME=laravel|' .env; \
	    sed -i 's|^# DB_PASSWORD=.*|DB_PASSWORD=secret|' .env; \
	    sed -i 's|^REDIS_HOST=.*|REDIS_HOST=cache|' .env; \
	    sed -i 's|^CACHE_STORE=.*|CACHE_STORE=redis|' .env; \
	    sed -i 's|^SESSION_DRIVER=.*|SESSION_DRIVER=redis|' .env; \
	    sed -i 's|^QUEUE_CONNECTION=.*|QUEUE_CONNECTION=redis|' .env; \
	fi
	@echo "🔑 Generando APP_KEY..."
	@$(DOCKER_COMPOSE) run --rm $(APP_CONTAINER) php artisan key:generate --force
	@echo "🗄️  Ejecutando migraciones..."
	@$(DOCKER_COMPOSE) run --rm $(APP_CONTAINER) php artisan migrate --force
	@echo "🎉 Iniciando todos los servicios..."
	@$(DOCKER_COMPOSE) up -d
	@echo ""
	@echo "✅ ¡Proyecto Laravel 11 creado!"
	@echo "🌐 Accede a: http://localhost:8080"

setup:
	@echo "🔧 Configurando proyecto Laravel clonado..."
	@echo "👤 Usuario: $(USER_ID):$(GROUP_ID)"
	@mkdir -p storage/logs/nginx backups
	@echo "🏗️  Construyendo contenedores..."
	@$(DOCKER_COMPOSE) build
	@echo "▶️  Iniciando servicios base..."
	@$(DOCKER_COMPOSE) up -d db cache
	@echo "⏳ Esperando base de datos..."
	@sleep 15
	@echo "📝 Creando archivo .env..."
	@if [ ! -f .env ]; then \
	    cp .env.example .env; \
	fi
	@echo "🔧 Configurando .env para Docker..."
	@if [ -f configure-env.sh ]; then \
	    ./configure-env.sh; \
	else \
	    sed -i 's/^DB_CONNECTION=sqlite/DB_CONNECTION=mysql/' .env; \
	    sed -i 's|^# DB_HOST=.*|DB_HOST=db|' .env; \
	    sed -i 's|^# DB_PORT=.*|DB_PORT=3306|' .env; \
	    sed -i 's|^# DB_DATABASE=.*|DB_DATABASE=laravel|' .env; \
	    sed -i 's|^# DB_USERNAME=.*|DB_USERNAME=laravel|' .env; \
	    sed -i 's|^# DB_PASSWORD=.*|DB_PASSWORD=secret|' .env; \
	    sed -i 's|^REDIS_HOST=.*|REDIS_HOST=cache|' .env; \
	    sed -i 's|^CACHE_STORE=.*|CACHE_STORE=redis|' .env; \
	    sed -i 's|^SESSION_DRIVER=.*|SESSION_DRIVER=redis|' .env; \
	    sed -i 's|^QUEUE_CONNECTION=.*|QUEUE_CONNECTION=redis|' .env; \
	fi
	@echo "📦 Instalando dependencias de Composer..."
	@$(DOCKER_COMPOSE) run --rm $(APP_CONTAINER) composer install --no-interaction
	@echo "🔑 Generando APP_KEY..."
	@$(DOCKER_COMPOSE) run --rm $(APP_CONTAINER) php artisan key:generate --force
	@echo "🗄️  Ejecutando migraciones..."
	@$(DOCKER_COMPOSE) run --rm $(APP_CONTAINER) php artisan migrate --force
	@echo "🎉 Iniciando todos los servicios..."
	@$(DOCKER_COMPOSE) up -d
	@echo ""
	@echo "✅ ¡Proyecto configurado!"
	@echo "🌐 Accede a: http://localhost:8080"

up:
	@$(DOCKER_COMPOSE) up -d

down:
	@$(DOCKER_COMPOSE) down

restart:
	@$(DOCKER_COMPOSE) restart

rebuild:
	@$(DOCKER_COMPOSE) down
	@$(DOCKER_COMPOSE) build
	@$(DOCKER_COMPOSE) up -d

logs:
	@$(DOCKER_COMPOSE) logs -f

app-logs:
	@$(DOCKER_COMPOSE) logs $(APP_CONTAINER) -f

web-logs:
	@$(DOCKER_COMPOSE) logs $(WEB_CONTAINER) -f

shell:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) sh

artisan:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan $(cmd)

migrate:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan migrate

fresh:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan migrate:fresh --seed

seed:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan db:seed

test:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan test

composer:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) composer $(cmd)

composer-install:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) composer install

npm:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) npm $(cmd)

npm-install:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) npm install

cache-clear:
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan cache:clear
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan config:clear
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan route:clear
	@$(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan view:clear

queue-restart:
	@$(DOCKER_COMPOSE) restart $(QUEUE_CONTAINER)

status:
	@$(DOCKER_COMPOSE) ps

redis-status:
	@$(DOCKER_COMPOSE) exec $(CACHE_CONTAINER) redis-cli ping

git-init:
	@git init
	@git add .
	@git commit -m "Initial commit: Laravel 11 con Docker setup"
	@echo "✅ Repositorio Git inicializado"

git-status:
	@git status

git-commit:
	@if [ -z "$(msg)" ]; then echo "Error: usa msg='mensaje'"; exit 1; fi
	@git add .
	@git commit -m "$(msg)"

git-push:
	@git push

git-pull:
	@git pull

clean:
	@echo "🧹 Limpieza completa del proyecto..."
	@$(DOCKER_COMPOSE) down --volumes
	@rm -rf vendor node_modules bootstrap/cache/* storage/logs/* .laravel-temp
	@echo "✅ Limpieza completa"