#!/bin/bash
set -e

(>&2 echo "[*] Bootstrap MAGENTO")

  if [ "$MAGE_MODE" != "developer" ]
  then
    (>&2 echo "[*] STARTING MAGENTO PRODUCTION MODE")
    composer install \
    --no-interaction \
    --no-scripts \
    --no-progress \
    --no-dev;
  else
  (>&2 echo "[*] STARTING MAGENTO DEVELOPER MODE")
  composer install
  fi

if [ -f "/var/www/app/etc/env.php" ]; then

  if [ "$(bin/magento setup:db:status)" == '1' ]; then

    bin/magento setup:upgrade --keep-generated

  fi
  
# 3. Test Magento DB
until bin/magento setup:db:status >/dev/null 2>&1; do
  echo "[!] Waiting for Magento database..."
  sleep 2
done

# 4. Optimisation finale
composer dump-autoload --optimize --classmap-authoritative


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