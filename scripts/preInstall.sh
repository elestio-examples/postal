set env vars
set -o allexport; source .env; set +o allexport;

apt install  -y git curl jq snapd
snap install bcrypt-tool

mkdir -p ./postal/{config,install,mariadb} && chown -R 1001:1001 ./postal 
git clone https://postalserver.io/start/install ./postal/install

docker-compose up -d

sleep 30s;

PWD=$(pwd)
./postal/install/bin/postal bootstrap ${DOMAIN} $PWD/postal/config
./postal/install/bin/postal initialize


UUID=`cat /proc/sys/kernel/random/uuid`
PW_HASH=`/snap/bin/bcrypt-tool hash ${ADMIN_PASSWORD} 10`

docker-compose exec -T mariadb mariadb -u root -ppostal postal -e "INSERT INTO users (id, uuid, email_address, password_digest, time_zone, admin) VALUES (1, '${UUID}', '${ADMIN_EMAIL}', '${PW_HASH}', 'UTC', 1);"
docker-compose exec -T mariadb mariadb -u root -ppostal postal -e "UPDATE users SET password_digest=\"${PW_HASH}\" WHERE id='1';"

SECRET_KEY=${SECRET_KEY:-`openssl rand -hex 128`}


sed -i "s~password: postal~password: ${MARIADB_ROOT_PASSWORD}~g" ./postal/config/postal.yml

docker-compose down;
sed -i -e "s~# ~~g" ./docker-compose.yml
docker-compose up -d

