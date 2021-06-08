#!/bin/sh

# Remove 'main instance ready' flag
sudo rm /mnt/shared/main_instance_ready.flag

# @see https://github.com/Sylius/Sylius/issues/12685
git apply patches/fix_doctrine_config.patch

# Composer
if [[ "$ARTIFAKT_ENVIRONMENT_CRITICALITY" == "prod" ]]; then
    COMPOSER_MEMORY_LIMIT=-1 composer install --ansi --no-interaction --no-dev
else
    COMPOSER_MEMORY_LIMIT=-1 composer install --ansi --no-interaction
fi

# Check requirements before everything else
php bin/console sylius:install:check-requirements

if [[ $ARTIFAKT_IS_MAIN_INSTANCE -eq 1 ]]; then
    if [[ "$IS_INSTALLED" == "false" ]]; then
        # Install fresh DB and project (@see https://docs.sylius.com/en/1.9/cookbook/configuration/installation-commands.html)
        printf "y\ny\n" | php bin/console sylius:install:database -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi
        printf "y\n" | php bin/console sylius:install:sample-data -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi
        php bin/console sylius:install:setup -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
    else
        # Load fixtures
        php bin/console sylius:fixtures:load -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
    fi

    sudo touch /mnt/shared/main_instance_ready.flag
else
    # Wait until main instance is ready before carry on
    until [[ -f "/mnt/shared/main_instance_ready.flag" ]];
    do sleep 10 && echo "Waiting main instance...";
    done;
    echo "Main instance ready";
    sudo rm /mnt/shared/main_instance_ready.flag
fi

# Install/Build assets
php bin/console sylius:install:assets -e $ARTIFAKT_ENVIRONMENT_CRITICALITY --ansi -n
yarn install
GULP_ENV=$ARTIFAKT_ENVIRONMENT_CRITICALITY yarn build
