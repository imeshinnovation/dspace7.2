#!/bin/bash
set -e

/etc/init.d/postgresql start

sudo su postgres -c "psql -v  --username 'postgres' <<-EOSQL
        CREATE DATABASE dspace;
        CREATE USER dspace with encrypted password 'dspace';
        ALTER ROLE dspace WITH PASSWORD 'dspace';
        ALTER DATABASE dspace OWNER TO dspace;
        GRANT ALL PRIVILEGES ON DATABASE dspace TO dspace;
        \c dspace;
        CREATE EXTENSION pgcrypto;
EOSQL"

sudo su dspace -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.1/install.sh | bash"

sudo su dspace -c "source ~/.nvm/nvm.sh && nvm install 16.18.1 && nvm use 16.18.1 && npm i --location=global yarn nodemon pm2"

cd /opt/DSpace-dspace-7.2/dspace/target/dspace-installer/

#npm i -g npm
#npm i -g yarn nodemon pm2

sudo ant fresh_install

sudo cp -R /dspace/webapps/server /opt/tomcat/webapps/
sudo cp -R /opt/DSpace-dspace-7.2/dspace/solr/* /opt/solr-8.11.2/server/solr/configsets/
sudo /dspace/bin/dspace database migrate

sudo chown -R dspace:dspace /opt/dspace-angular-dspace-7.2/

mkdir -p /dspace-frontend/config
chown -R dspace:dspace /dspace-frontend


cat << 'EOF' > /dspace-frontend/dspace-ui.json
{
    "apps": [
        {
           "name": "dspace-ui",
           "cwd": "/dspace-frontend",
           "script": "dist/server/main.js",
           "env": {
              "NODE_ENV": "production"
           }
        }
    ]
}
EOF

sudo su dspace -c "source ~/.nvm/nvm.sh && cd /opt/dspace-angular-dspace-7.2 && yarn install"
sudo su dspace -c "source ~/.nvm/nvm.sh && cd /opt/dspace-angular-dspace-7.2 && yarn build:prod"

cp -R /opt/dspace-angular-dspace-7.2/dist /dspace-frontend/
cp -R /opt/dspace-angular-dspace-7.2/config/config.example.yml /dspace-frontend/config/config.prod.yml

sudo chown -R dspace:dspace /dspace-frontend/

sudo su dspace -c "source ~/.nvm/nvm.sh && cd /dspace-frontend && pm2 start dspace-ui.json"
sudo su dspace -c "source ~/.nvm/nvm.sh && cd /dspace-frontend && pm2 save"
#sudo su dspace -c "source ~/.nvm/nvm.sh && cd /dspace-frontend && pm2 startup"