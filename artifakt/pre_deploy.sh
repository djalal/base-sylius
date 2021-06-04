#!/bin/sh

# @see https://github.com/Sylius/Sylius/issues/12685
git apply patches/fix_doctrine_config.patch

# Composer
if [[ "$ARTIFAKT_ENVIRONMENT_CRITICALITY" == "prod" ]]; then
    COMPOSER_MEMORY_LIMIT=-1 composer install --ansi --no-dev
else
    COMPOSER_MEMORY_LIMIT=-1 composer install --ansi
fi

# Installing project/DB (@see https://docs.sylius.com/en/1.9/cookbook/configuration/installation-commands.html)
if [[ "$IS_INSTALLED" == "false" ]]; then
    php bin/console sylius:install -e $ARTIFAKT_ENVIRONMENT_CRITICALITY -n
fi

# Installing assets
yarn install
yarn build
