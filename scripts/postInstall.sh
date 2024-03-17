# set env vars
set -o allexport; source .env; set +o allexport;

echo "Waiting for Friendica to be ready..."
sleep 30s;

if [ -e "./initialized" ]; then
    echo "Already initialized, skipping..."
else
    sed -i 's@http://172.17.0.1:5000;@http://127.0.0.1:5000;@g' /opt/elestio/nginx/conf.d/${DOMAIN}.conf

    docker exec elestio-nginx nginx -s reload;
    touch "./initialized"
fi