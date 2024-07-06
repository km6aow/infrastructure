#!/usr/local/bin/bash
pushd /usr/local/www/drupal9
composer outdated "drupal/*"
# composer show drupal/core-recommended
composer update "drupal/core-*" --with-all-dependencies
popd

