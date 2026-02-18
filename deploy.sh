#!/bin/bash
set -e

cd /home/paul/polling-api-docs

git pull

uv run mkdocs build

sudo rm -rf /var/www/polling-api-docs
sudo cp -r site /var/www/polling-api-docs
sudo chown -R www-data:www-data /var/www/polling-api-docs
sudo chmod -R 755 /var/www/polling-api-docs

sudo nginx -t && sudo systemctl reload nginx

echo "Deploy complete!"
