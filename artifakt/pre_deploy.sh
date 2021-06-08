#!/bin/sh

# Remove 'main instance ready' flag
rm /mnt/shared/main_instance_ready.flag

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

if [[ $ARTIFAKT_IS_MAIN_INSTANCE -eq 1 ]]; then
    if [[ "$IS_INSTALLED" == "false" ]]; then
        # Install fresh DB and project (@see https://docs.sylius.com/en/1.9/cookbook/configuration/installation-commands.html)
        yes Y | php bin/console sylius:install:database -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi
        yes Y | php bin/console sylius:install:sample-data -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi
        php bin/console sylius:install:setup -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
        php bin/console sylius:install:assets -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
    else
        # Load fixtures
        php bin/console sylius:fixtures:load -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
    fi

    touch /mnt/shared/main_instance_ready.flag
else
    # Wait until main instance is ready before carry on
    #until [[ -f "/mnt/shared/main_instance_ready.flag" ]];
    #do sleep 10 && echo "Database is not up to date, waiting...";
    #done;
    #echo "Database is up to date.";
    #rm /mnt/shared/main_instance_ready.flag
    true
fi

# Install/Build assets
php bin/console sylius:install:assets -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
yarn install
GULP_ENV=$ARTIFAKT_ENVIRONMENT_CRITICALITY yarn build
