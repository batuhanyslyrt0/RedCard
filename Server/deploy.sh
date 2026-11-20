#!/usr/bin/env bash
# Uploads Red Card's server files to the server and (re)starts the service.
# Run from the project folder:  Server/deploy.sh
#
# First time only (on the server, after the DNS record exists):
#   ln -s /etc/nginx/sites-available/redcard.batudev.com.conf /etc/nginx/sites-enabled/
#   nginx -t && systemctl reload nginx
#   certbot --nginx -d redcard.batudev.com
set -euo pipefail

SERVER="${SERVER:-root@185.187.170.33}"
REMOTE_DIR="/var/www/redcard.batudev.com"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Publish the current rules next to the privacy page.
cp "$HERE/../Rules/rules.json" "$HERE/public/rules.json"

ssh "$SERVER" "mkdir -p $REMOTE_DIR/data $REMOTE_DIR/tools && chmod 700 $REMOTE_DIR/data"
scp "$HERE/server.js" "$SERVER:$REMOTE_DIR/server.js"
scp "$HERE/tools/report-stats.js" "$SERVER:$REMOTE_DIR/tools/report-stats.js"
scp -r "$HERE/public" "$SERVER:$REMOTE_DIR/"
scp "$HERE/nginx/redcard.batudev.com.conf" "$SERVER:/etc/nginx/sites-available/redcard.batudev.com.conf.new"

# Start or restart the report receiver on port 3200.
ssh "$SERVER" "cd $REMOTE_DIR && (pm2 restart redcard --update-env || PORT=3200 pm2 start server.js --name redcard) && pm2 save"

echo
echo "Uploaded. The nginx config was saved as redcard.batudev.com.conf.new;"
echo "compare it with the live one before replacing it, because certbot adds HTTPS lines to the live file."
