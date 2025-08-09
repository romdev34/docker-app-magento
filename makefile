# Nom du conteneur Magento (modifiable ici si besoin)
MAGENTO_CONTAINER := $(shell docker ps --filter "ancestor=docker-app-magento-magento" --format '{{.Names}}' | head -n 1)
REDIS_CACHE_CONTAINER := $(shell docker ps --filter "name=redis-cache" --format '{{.Names}}' | head -n 1)
REDIS_SESSION_CONTAINER := $(shell docker ps --filter "name=redis-session" --format '{{.Names}}' | head -n 1)


down-prod:
	docker compose -f docker-compose.prod.yml down
up-prod:
	docker compose -f docker-compose.prod.yml up -d
up-prod-build:
	docker compose -f docker-compose.prod.yml up --build
down-local:
	docker compose -f docker-compose.local.yml down
up-local:
	docker compose -f docker-compose.local.yml up -d
up-local-build:
	docker compose -f docker-compose.local.yml up --build
# Magento - Bash
bash:
	docker exec -ti $(MAGENTO_CONTAINER) bash

# Magento - Compilation & statics
se-di:
	docker exec -ti $(MAGENTO_CONTAINER) bin/magento setup:di:compile

deploy-statics:
	docker exec -ti $(MAGENTO_CONTAINER) bash -c "rm -rf var/view_preprocessed/*"
	docker exec -ti $(MAGENTO_CONTAINER) bash -c "rm -rf pub/static/*"
	docker exec -ti $(MAGENTO_CONTAINER) bin/magento setup:static-content:deploy --jobs=6 --strategy=quick --force fr_FR en_US
	$(MAKE) cc

se-up:
	docker exec -ti $(MAGENTO_CONTAINER) bin/magento setup:upgrade --keep-generated

# Magento - Cache
cc:
	docker exec -ti $(MAGENTO_CONTAINER) bin/magento cache:clean

cf:
	docker exec -ti $(MAGENTO_CONTAINER) bin/magento cache:flush

# Magento - Index
reindex:
	docker exec -ti $(MAGENTO_CONTAINER) bin/magento indexer:reindex

# Redis
redis-cache-flush:
	docker exec -ti $(REDIS_CACHE) redis-cli FLUSHALL

redis-session-flush:
	docker exec -ti $(REDIS_SESSION) redis-cli FLUSHALL

# Logs
logs:
	docker logs $(MAGENTO_CONTAINER)