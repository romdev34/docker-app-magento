# Installation et utilisation

#### prérequis 

* récupérer les clés d'acces https://commercemarketplace.adobe.com/customer/accessKeys/
*  Créer fichier auth.json en indiquant les clés d'accès

* Il faut récupérer un fichier env.php dans app/etc/
  sous ce format
  https://github.com/artifakt-io/base-magento/blob/2.4/app/etc/env.php.sample


## architecture docker
Cloner le projet
git clone git@gitlab.com:docker3580037/app-magento.git

 créer un dossier .composer à la racine do projet et y mettre le fichier .auth.json

 Vérifier les variables dans le fichier .env
 Créer un fichier .env.prod sur le serveur concerné

## installation des soures (sans récupération projet existant)

Changer la version de l'image en fonction des versions images app-php dispos

```shell
docker run -it --rm \
-u $(id -u):$(id -g) \
-v $(pwd):/src \
-e COMPOSER_AUTH="$(cat ./auth.json)" \
ulysse699/composer:latest \
create-project --repository-url=https://repo.magento.com/ magento/project-community-edition src
```
>Si erreur "file_put_contents(/.config/composer/auth.json): Failed to open stream: Permission denied" 
```shell
docker run -it --rm \
-u $(id -u):$(id -g) \
-v $(pwd):/src \
-v .composer:/.config/composer \
-e COMPOSER_AUTH="$(cat ./auth.json)" \
ulysse699/composer:latest \
create-project --repository-url=https://repo.magento.com/ magento/project-community-edition src
```
## installation des soures avec projet existant
Il faut placer les sources dans un dossier src

## MAJ des droits
>dans le dossier magento
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +

find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

chown -R :<web server group> .

chmod u+x bin/magento

> Copier coller le fichier auth.json dans le dossier src crée précédemment.**

`` vérifier que le .gitignore a bien été crée dans src/
Si non le récupérer dans la version officielle magento dans github par exemple:
https://github.com/magento/magento2/blob/2.4.6-p2/.gitignore``
in
## Installation de magento

### prerequis
penser à enlever le fichier .env.php si on doit réinstaller le projet

rajouter dans /etc/hosts le nom de domaine souhaité

mettre à jour les droits mysql

```shell
docker compose -f docker-compose.prod.yml exec mysql bash -c "mysql -uroot -proot << EOF
REVOKE ALL PRIVILEGES ON *.* FROM 'rootless'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'rootless'@'%';
ALTER USER 'rootless'@'%' REQUIRE NONE WITH
MAX_QUERIES_PER_HOUR 0
MAX_CONNECTIONS_PER_HOUR 0
MAX_UPDATES_PER_HOUR 0
MAX_USER_CONNECTIONS 0;
EOF"
```
### installation
```shell
docker compose exec magento bash
bin/magento \
        setup:install \
        --base-url=$BASE_URL\
        --db-host=$MYSQL_HOST \
        --db-name=$MYSQL_DATABASE \
        --db-user=$MYSQL_USER \
        --db-password=$MYSQL_PASSWORD \
        --admin-firstname=$ADMIN_FIRSTNAME \
        --admin-lastname=$ADMIN_LASTNAME \
        --admin-email=$ADMIN_EMAIL \
        --admin-user=$ADMIN_USER \
        --admin-password=$ADMIN_PASSWORD \
        --language=$LANGUAGE \
        --currency=$CURRENCY \
        --timezone=$TIMEZONE \
        --search-engine $SEARCH_ENGINE \
        --elasticsearch-host $ELASTICSEARCH_HOST \
        --elasticsearch-port $ELASTICSEARCH_PORT \
        --use-rewrites=$USE_REWRITE \
        --backend-frontname=$BACKEND_FRONTNAME \
        --session-save=redis \
        --session-save-redis-host=$REDIS_SESSION_HOST \
        --session-save-redis-port=$REDIS_SESSION_PORT \
        --session-save-redis-log-level=1 \
        --session-save-redis-db=2 \
        --cache-backend-redis-server=$REDIS_CACHE_HOST \
        --cache-backend=redis \
        --cache-backend-redis-port=$REDIS_CACHE_PORT \
        --cache-backend-redis-db=0 \
        --cache-backend-redis-compress-data=1 \
        --cache-backend-redis-password="" \
        --cache-backend-redis-compression-lib=""
```

### commandes jouer en local
Compilation
```shell
rm -rf $(pwd)/src/generated/*; \
docker compose -f docker-compose.local exec magento \
bin/magento \
setup:di:compile
```

MAJ des statics
```shell
rm -rf $(pwd)/src/var/view_preprocessed/*; \
rm -rf $(pwd)/src/pub/static/*; \
docker compose -f docker-compose.local exec magento \
bin/magento \
setup:static-content:deploy \
--jobs=6 \
--force \
fr_FR \
en_US
```

MAJ de la bdd
```shell
docker compose -f docker-compose.local exec magento \
bin/magento \
setup:upgrade
```
cache clean
```shell
docker compose -f docker-compose.local exec magento \
bin/magento \
cache:clean
```
cache flush
```shell
docker compose -f docker-compose.local exec magento \
bin/magento \
cache:flush
```

reindex
```shell
docker compose -f docker-compose.local exec magento \
bin/magento \
indexer:reindex
```

Docker compose up build
```shell
docker compose -f docker-compose.local.yml up --build
```

Docker compose up
```shell
docker compose -f docker-compose.local.yml up
```

Docker compose down
```shell
docker compose -f docker-compose.local.yml down
```

Bash conteneur magento
```shell
docker compose -f docker-compose.local.yml exec magento bash
```

NB si soucis avec la base de donnée, on peut réinitialiser le volume avec
```shell
docker compose -f docker-compose.local.yml down -v
```
Voir le status des process
```shell
docker compose -f docker-compose.local.yml exec -it magento supervisorctl status
```
### commandes à jouer en production

### en prod
MAJ de la bdd
```shell
docker compose exec magento \
bin/magento \
setup:upgrade
```
Compilation
```shell
docker compose exec magento \
bin/magento \
setup:di:compile
```
MAJ des statics
```shell
bin/magento \
setup:static-content:deploy \
--jobs=6 \
--force \
--strategy=quick \
en_US fr_FR
```
cache clean
```shell
docker compose -f docker-compose.prod exec magento \
bin/magento \
cache:clean
```
cache flush
```shell
docker compose -f docker-compose.prod exec magento \
bin/magento \
cache:flush
```
reindex
```shell
docker compose -f docker-compose.prod exec magento \
bin/magento \
indexer:reindex
```
Docker compose up build
```shell
docker compose -f docker-compose.prod.yml up --build
```
Docker compose up
```shell
docker compose -f docker-compose.prod.yml up 
```
Docker compose down
```shell
docker compose -f docker-compose.prod.yml down
```
Bash conteneur magento
```shell
docker compose -f docker-compose.prod.yml exec magento bash
```
NB si soucis avec la base de donnée, on peut réinitialiser le volume avec
```shell
docker compose -f docker-compose.prod.yml down -v
```
Voir le status des process
```shell
docker compose -f docker-compose.prod.yml exec -it magento supervisorctl status
```
arreter un process (exemple server-fpm)
```shell
docker compose -f docker-compose.prod.yml exec -it magento supervisorctl stop server:server-fpm
```
## Install dans k8s
TODO...

## MAIL
Si erreur Unsupported sendmail command flags \"/usr/sbin/sendmail-local --smtp-addr=mailhog:1025\"; must be one of \"-bs\" or \"-t\" 

Rajouter dans app/etc/env.php (pour mailhog ou mailpit si mailpit)
```
    'system' => [
        'default' => [
            'system' => [
                'smtp' => [
                    'disable' => '0',
                    'transport' => 'smtp',
                    'host' => 'mailhog',
                    'port' => '1025',
                    'auth' => 'none'
                ]
            ]
        ]
    ],
```
## REDIS
```shell
bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=$REDIS_CACHE_HOST --cache-backend-redis-db=0
bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=$REDIS_CACHE_HOST --page-cache-redis-db=1
bin/magento setup:config:set --session-save=redis --session-save-redis-host=$REDIS_SESSION_HOST --session-save-redis-port=$REDIS_SESSION_PORT --session-save-redis-log-level=1  
```
j'avais un soucis avec le session save au moment de mes tests donc peut etre éviter la partie session pour redis

### CLEAR LE CACHE REDIS
````shell
docker compose -f docker-compose.prod.yml exec -it redis-cache redis-cli FLUSHALL
````
````shell
docker compose -f docker-compose.prod.yml exec -it redis-session redis-cli FLUSHALL
````
 ## VARNISH
> SI ON UTILISE VARNISH
````shell
bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2
````

```shell
bin/magento \
config:set \
system/full_page_cache/ttl \
"86400"
```

```shell
bin/magento \
config:set \
system/full_page_cache/varnish/access_list \
"$(docker compose exec varnish hostname -i)"
```

```shell
bin/magento \
config:set \
system/full_page_cache/varnish/backend_host \
"magento"
```

```shell
bin/magento \
config:set \
system/full_page_cache/varnish/backend_port \
"8080"
```

```shell
varnishadm 'ban req.url ~ .'
```

```shell
 varnishlog
```

```shell
varnishlog -g raw -i backend_health
```
>TODO a  debugguer
Si 503  avec varnish potentiellement un soucis avec le .probe.url du fichier de config.
Potentiellement on peut avoir un soucis de config de cache avec le env.php
indiquer l'IP / PORT du container / server varnish
php bin/magento setup:config:set --no-interaction --http-cache-hosts=192.168.192.10:80

Récupérer la valeur des fichiers env.php et config.php et les recréer ces fichiers dans le dossier src

Supprimer l'image, re build l'image re push l'image et normalement magento devrait etre installé avec env.php et config.php et le script de l'upgrade du compile et des statics devraient etres lancé au moment du lancement de l'image magento.

Activer le https pour les URL front et back
docker exec magento bin/magento config:set web/secure/use_in_frontend 1
docker exec testmage-magento-1 bin/magento config:set web/secure/use_in_adminhtml 1

Vérifier dans le store config également l'URL de l'admin si nécessaire

## RABBITMQ
modifier le env.php selon les RABBITMQ_USER et RABBITMQ_PASSWORD définis dans le env et dans docker-compose.yml

```'queue' => [
    'consumers_wait_for_messages' => 1,
    'amqp' => [
        'host' => 'rabbitmq',
        'port' => '5672',
        'user' => 'rootless',
        'password' => 'nopassword',
        'virtualhost' => 'magento'
    ]
]
```

## DOCKER
* Construction de l'image magento 
```shell
docker build . \
--tag ulysse699/app-magento:latest \
--build-arg "UID=$(id -u)" \
--build-arg "GID=$(id -g)" \
--build-arg "GIT_COMMIT=$(git rev-parse HEAD)" \
--build-arg "COMPOSER_AUTH=$(cat ./auth.json)" \
--build-arg "STATIC_LANGUAGES=en_US fr_FR" \
--build-arg "STATIC_JOBS=6"
```

* Push de l'image dans le registry
```
docker push ulysse699/app-magento:latest
```
## COMPOSER
Pour jouer un composer install faire
```shell
docker run -it --rm \
-u $(id -u):$(id -g) \
-v $(pwd)/src:/src \
-e COMPOSER_AUTH="$(cat ./.composer/auth.json)" \
ulysse699/composer:latest \
install
```

un composer update faire
```shell
docker run -it --rm \
-u $(id -u):$(id -g) \
-v $(pwd)/src:/src \
-e COMPOSER_AUTH="$(cat ./.composer/auth.json)" \
ulysse699/composer:latest \
update
```
## LOGS
Voir les logs
```shell
docker container logs docker-app-magento-magento-1
```

## SSL en local
générer les certificats en local dans traefik/certs
Les importer dans chrome et firefox
```text
# Add into /etc/hosts
127.0.0.1 traefik.dev.local
127.0.0.1 mailhog.dev.local
127.0.0.1 phpmyadmin.dev.local
127.0.0.1 rabbitmq.dev.local
127.0.0.1 magento-dev.local
```


## Tests

PHPUnit

```shell
docker run -it --rm \
-u $(id -u):$(id -g) \
-v $(pwd)/src:/src \
ulysse699/php:v8.2 \
/src/bin/phpunit \
--do-not-cache-result
```
## ELASTICSUITE / MAGESUITE

Il faut impérativement installer les plugins suivants
bin/elasticsearch-plugin install analysis-phonetic;
bin/elasticsearch-plugin install analysis-icu;

De plus il faut que node ^v14 soit installer. J'ai testé avec la version 18 cela ne fonctionnait pas.
Il faut également installer yarn.

Pour la config de ES il faut modifier la conf comme ceci (si l'host est bien elasticsearch)
>bin/magento config:set -le smile_elasticsuite_core_base_settings/es_client/servers elasticsearch:9200
bin/magento config:set -le smile_elasticsuite_core_base_settings/es_client/enable_https_mode 0
bin/magento config:set -le smile_elasticsuite_core_base_settings/es_client/enable_http_auth 0
bin/magento config:set -le smile_elasticsuite_core_base_settings/es_client/http_auth_user ""
bin/magento config:set -le smile_elasticsuite_core_base_settings/es_client/http_auth_pwd ""
bin/magento config:set -le catalog/search/engine elasticsuite

Lorsque l'on souhaite switcher d'une version avec elasticsuite / magesuite a la version de base
Il faut rejouer le setup install
Il faut remettre par défaut le theme luma dans la base de donnée
Il faut désintaller et réinstaller la base selon l'installation choisie

## CRONS
le processus cron est géré dans le supervisor