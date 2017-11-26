#!/bin/bash
echo "⋅ Starting CouchDB…"
sudo -b -i -u couchdb sh -c '/home/couchdb/bin/couchdb'

export public_port=1443
export server_port=8080
export instance_domain=codingexperts.nl
export COZY_ADMIN_PASSWORD=asd3eeiuhasiuhd83e
export server_pass=asd3eeiuhasiuhd83e

if [ ! -f "/etc/cozy/cozy-admin-passphrase" ]; then
echo -e "$COZY_ADMIN_PASSWORD\n$COZY_ADMIN_PASSWORD" | /usr/local/bin/cozy-stack config passwd /etc/cozy/ > /dev/null
fi 
#for pid in $(pgrep cozy-stack); do kill -15 $pid;done
echo "Starting Cozy stack…"
sudo -b -u cozy sh -c '/usr/local/bin/cozy-stack serve --log-level debug --host 0.0.0.0'
#cozy-stack instances destroy "cozy.tools:8080" 2>/dev/null
sleep 10
echo "⋅ Creating instance…"
echo "Creating instance"

if [ ! -f "/etc/cozy/${instance_domain}.key" ]; then
  cozy-stack instances add --host 0.0.0.0 --apps drive,photos,collect,settings,onboarding --passphrase "$server_pass" "${instance_domain}:${public_port}"


  echo "⋅ Creating certificate…"
  openssl req -x509 -nodes -newkey rsa:4096 -keyout "/etc/cozy/${instance_domain}.key" -out "/etc/cozy/${instance_domain}.crt" -days 365 -subj "/CN=\*.${instance_domain}"
  echo "⋅ Configuring NGinx…"
  sed "s/%PORT%/$public_port/g; s/%DOMAIN%/$instance_domain/g; s/%SERVER_PORT%/$server_port/g" /etc/cozy/nginx-config > "/etc/nginx/sites-available/${instance_domain}.conf"
fi

echo "⋅ Starting NGinx…"

if [ ! -f "/etc/nginx/sites-available/${instance_domain}.conf" ]; then
  ln -s "/etc/nginx/sites-available/${instance_domain}.conf" /etc/nginx/sites-enabled/
fi

# nginx config
FOUND=`fgrep -c "daemon off" /etc/nginx/nginx.conf`
if [ ! $FOUND -eq 0 ]; then
  sed -i '1idaemon off;\' /etc/nginx/nginx.conf
fi
nginx
