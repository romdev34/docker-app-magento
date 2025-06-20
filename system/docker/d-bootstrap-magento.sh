#!/bin/bash
set -e

(>&2 echo "[*] Bootstrap MAGENTO")

  if [ "$MAGE_MODE" != "developer" ]
  then
    (>&2 echo "[*] STARTING MAGENTO PRODUCTION MODE")
    composer install \
    --prefer-dist \
    --no-autoloader \
    --no-interaction \
    --no-scripts \
    --no-progress \
    --no-dev; \
    composer dump-autoload
  else
  (>&2 echo "[*] STARTING MAGENTO DEVELOPER MODE")
  composer install
  fi

if [ -f "/var/www/app/etc/env.php" ]; then

  if [ "$(bin/magento setup:db:status)" == '1' ]; then

    bin/magento setup:upgrade --keep-generated

  fi
# on redirige le retour de la bin/magento se:db:status dans dev/null pour ne pas l'afficher et on redirige les erreurs dans l'output qui lui meme a été déja redirigé dans une pseudo classe pour ne pas etre affiché
  until bin/magento setup:db:status >/dev/null 2>&1; do
# on reidirige le message Waiting for upgrade... dans le STDERR et donc afficher l'erreur avec le message
    (echo >&2 "[!] Waiting for upgrade to be ready...")

    sleep 2
#
  done

  if [ "$MAGE_MODE" != "developer" ]
  then

      (>&2 echo "[*] Bootstrap COMPILE")
      bin/magento se:di:co &&
      (>&2 echo "[*] Bootstrap DEPLOY STATIC")
      bin/magento \
      setup:static-content:deploy \
      --jobs=6 \
      --force
  fi
fi