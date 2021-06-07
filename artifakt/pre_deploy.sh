#!/bin/sh

# @see https://github.com/Sylius/Sylius/issues/12685
git apply patches/fix_doctrine_config.patch

# Composer
if [[ "$ARTIFAKT_ENVIRONMENT_CRITICALITY" == "prod" ]]; then
    COMPOSER_MEMORY_LIMIT=-1 composer install --ansi --no-dev
else
    COMPOSER_MEMORY_LIMIT=-1 composer install --ansi
fi

# Check requirements before everything else
php bin/console sylius:install:check-requirements

if [[ "$IS_INSTALLED" == "false" ]]; then
    # Installing project/DB (@see https://docs.sylius.com/en/1.9/cookbook/configuration/installation-commands.html)
    yes Y | php bin/console sylius:install:database -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi
    yes Y | php bin/console sylius:install:sample-data -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi
    php bin/console sylius:install:setup -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
    php bin/console sylius:install:assets -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
else
    # Build already installed project
    php bin/console sylius:fixtures:load -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
    php bin/console sylius:install:assets -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
fi

# Cache clear
php bin/console cache:clear

# Installing assets
yarn install
yarn build
