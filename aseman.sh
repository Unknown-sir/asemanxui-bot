#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[33mPlease run as root\033[0m"
    exit
fi

echo -e "\n\e[92mInstalling dependencies...\033[0m\n"
apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql phpmyadmin mysql-server git wget unzip curl php-ssh2 libssh2-1-dev libssh2-1 php-soap
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
a2enconf phpmyadmin.conf
systemctl restart apache2
systemctl enable mysql.service apache2
systemctl start mysql.service apache2
ufw allow 'Apache'

echo -e "\n\e[92mCloning Aseman bot...\033[0m\n"
git clone https://github.com/Unknown-sir/asemanxui-bot.git /var/www/html/asemanxui-bot
chown -R www-data:www-data /var/www/html/asemanxui-bot/
chmod -R 755 /var/www/html/asemanxui-bot/

RANDOM_CODE=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 40)
mkdir "/var/www/html/asemanpanel${RANDOM_CODE}"
wget -O /var/www/html/asemanpanel.zip https://github.com/Unknown-sir/asemanxui-bot/releases/download/1.0.0/asemanpanel.zip
mv /var/www/html/asemanpanel.zip "/var/www/html/asemanpanel${RANDOM_CODE}/"
cd "/var/www/html/asemanpanel${RANDOM_CODE}/" && unzip asemanpanel.zip && rm asemanpanel.zip
chown -R www-data:www-data "/var/www/html/asemanpanel${RANDOM_CODE}/"
chmod -R 755 "/var/www/html/asemanpanel${RANDOM_CODE}/"

read -p "Enter the domain: " domainname
if [ -z "$domainname" ]; then
    echo -e "\n\033[91mDomain required!\033[0m\n"
    exit
fi

read -p "Enter bot token: " botToken
read -p "Enter admin chat ID: " chatId

echo -e "<?php\nerror_reporting(0);\n\$botToken = '$botToken';\n\$dbUserName = 'aseman_user';\n\$dbPassword = 'randompass';\n\$dbName = 'aseman_db';\n\$botUrl = 'https://$domainname/asemanxui-bot/';\n\$admin = $chatId;\n?>" > /var/www/html/asemanxui-bot/config/baseInfo.php

mysql -e "CREATE DATABASE aseman_db; CREATE USER 'aseman_user'@'localhost' IDENTIFIED BY 'randompass'; GRANT ALL PRIVILEGES ON aseman_db.* TO 'aseman_user'@'localhost'; FLUSH PRIVILEGES;"
mysql aseman_db < /var/www/html/asemanxui-bot/database/schema.sql

(crontab -l ; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/message.php >/dev/null 2>&1") | crontab -
(crontab -l ; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/rewardReport.php >/dev/null 2>&1") | crontab -
(crontab -l ; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/warnusers.php >/dev/null 2>&1") | crontab -
(crontab -l ; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/gift2all.php >/dev/null 2>&1") | crontab -
(crontab -l ; echo "*/3 * * * * curl https://$domainname/asemanxui-bot/settings/tronChecker.php >/dev/null 2>&1") | crontab -
(crontab -l ; echo "* * * * * curl https://$domainname/asemanpanel${RANDOM_CODE}/backupnutif.php >/dev/null 2>&1") | crontab -

curl -F "url=https://$domainname/asemanxui-bot/index.php" "https://api.telegram.org/bot$botToken/setWebhook"
curl -s -X POST "https://api.telegram.org/bot$botToken/sendMessage" -d chat_id="$chatId" -d text="✅ ربات آسمان با موفقیت نصب شد!"
echo -e "\n\e[92mAseman bot installed successfully!\033[0m\n"