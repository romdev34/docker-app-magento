#!/bin/bash
set -e

PROXY_FILE="/var/www/generated/code/Magento/Framework/App/ResourceConnection/Proxy.php"

(>&2 echo "[*] Bootstrap MAGENTO")


if [ "$MAGE_MODE" != "developer" ]; then
  (>&2 echo "[*] STARTING MAGENTO PRODUCTION MODE")
  composer install \
  --optimize-autoloader \
  --no-dev;

  composer dump-autoload 

  if [ ! -f "$PROXY_FILE" ]; then
    echo "[!] Proxy class missing: $PROXY_FILE"
    echo "[*] Forcing Magento into developer mode to generate missing proxies"
    bin/magento deploy:mode:set developer
    bin/magento maintenance:enable

    bin/magento setup:di:compile
    (>&2 echo "[*] Bootstrap DEPLOY STATIC")

    bin/magento \
    setup:static-content:deploy \
    --jobs=6 \
    --force \
    --strategy=quick \
    en_US fr_FR

    bin/magento \
    setup:static-content:deploy \
    --jobs=6 \
    --force \
    --strategy=quick \
    --area adminhtml \
    fr_FR

    # Nettoyage final du cache
    (>&2 echo "[*] Cleaning cache")
    bin/magento cache:flush
  else
    (>&2 echo "[*] Mode maintenance activé")
    bin/magento deploy:mode:set production
    (>&2 echo "[*] Disabling maintenance mode")
    bin/magento maintenance:disable
  fi

  if [ -f "/var/www/app/etc/env.php" ]; then
    # on redirige le retour de la bin/magento se:db:status dans dev/null pour ne pas l'afficher et on redirige les erreurs dans l'output qui lui meme a été déja redirigé dans une pseudo classe pour ne pas etre affiché
    until mysql -h"mysql" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
    # on reidirige le message Waiting for DATABASE to be ready... dans le STDERR et donc afficher l'erreur avec le message
        (echo >&2 "[!] Waiting for DATABASE to be ready...")
        sleep 2
    #
    done

    bin/magento setup:upgrade --keep-generated
    bin/magento maintenance:disable
  else
    (>&2 echo "[*] STARTING MAGENTO DEVELOPER MODE")
    composer install
  fi
fi
