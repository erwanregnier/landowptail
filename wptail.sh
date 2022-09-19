#!/bin/sh
echo "Website name?"
read wbname
echo "Folder name?"
read fdname
echo "Creating..."
mkdir $fdname
cd $fdname
composer create-project roots/bedrock app
lando init --recipe wordpress --source cwd --name "$wbname" --webroot app/web
cd app
composer require timber/timber
echo "Setting .env file"
> .env
APPJSON=`lando info --format json`
echo -n "DB_HOST=" >> .env
echo $APPJSON | jq '.[] | select(.service=="database").internal_connection.host' >> .env

echo -n "DB_NAME=" >> .env
echo $APPJSON | jq '.[] | select(.service=="database").creds.database' >> .env

echo -n "DB_USER=" >> .env
echo $APPJSON | jq '.[] | select(.service=="database").creds.user'  >> .env

echo -n "DB_PASSWORD=" >> .env
echo $APPJSON | jq '.[] | select(.service=="database").creds.password' >> .env

echo "WP_ENV='development'" >> .env

echo -n "WP_HOME=" >> .env
echo $APPJSON | jq '.[] | select(.service=="appserver").urls[1]' >> .env

echo 'WP_SITEURL="${WP_HOME}wp"' >> .env
echo "DB prefix?"
read dbprefx
echo -n "DB_PREFIX=" >> .env 
echo \"$dbprefx\" >> .env
echo "Generate WP salts"
curl -s https://api.wordpress.org/secret-key/1.1/salt | sed "s/^define('\(.*\)',\ *'\(.*\)');$/\1='\2'/g" >> .env
cd web/app/themes
tailpress new --name $fdname $fdname
read -p "Start it now? (y/N) " yn
case $yn in 
	y ) lando start;;
	* ) ;;
esac
echo "End"
