#!/bin/bash

# بررسی دسترسی روت
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[33mPlease run as root\033[0m"
    exit 1
fi

# نصب پیش‌نیازها
echo -e "\n\e[92mInstalling dependencies...\033[0m\n"
apt-get update -y
apt-get install -y apache2 php libapache2-mod-php php-mysql phpmyadmin mysql-server git wget unzip curl php-ssh2 libssh2-1-dev libssh2-1 php-soap
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
a2enconf phpmyadmin.conf
systemctl restart apache2
systemctl enable mysql.service apache2
systemctl start mysql.service apache2
ufw allow 'Apache'

# کلون کردن پروژه
echo -e "\n\e[92mCloning Aseman bot...\033[0m\n"
git clone https://github.com/Unknown-sir/asemanxui-bot.git /var/www/html/asemanxui-bot
if [ $? -ne 0 ]; then
    echo -e "\n\033[91mFailed to clone repository!\033[0m\n"
    exit 1
fi
chown -R www-data:www-data /var/www/html/asemanxui-bot/
chmod -R 755 /var/www/html/asemanxui-bot/

# نصب پنل
RANDOM_CODE=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 40)
mkdir "/var/www/html/asemanpanel${RANDOM_CODE}"
wget -O "/var/www/html/asemanpanel${RANDOM_CODE}/asemanpanel.zip" https://github.com/Unknown-sir/asemanxui-bot/releases/download/1.0.0/asemanpanel.zip
if [ $? -ne 0 ]; then
    echo -e "\n\033[91mFailed to download panel!\033[0m\n"
    exit 1
fi
cd "/var/www/html/asemanpanel${RANDOM_CODE}/" && unzip asemanpanel.zip && rm asemanpanel.zip
chown -R www-data:www-data "/var/www/html/asemanpanel${RANDOM_CODE}/"
chmod -R 755 "/var/www/html/asemanpanel${RANDOM_CODE}/"

# دریافت اطلاعات از کاربر
echo -e "\n\e[92mSetup configuration...\033[0m\n"
read -p "Enter the domain (e.g., yourdomain.com): " domainname
if [ -z "$domainname" ]; then
    echo -e "\n\033[91mDomain required!\033[0m\n"
    exit 1
fi

read -p "Enter bot token: " botToken
if [ -z "$botToken" ]; then
    echo -e "\n\033[91mBot token required!\033[0m\n"
    exit 1
fi

read -p "Enter admin chat ID: " chatId
if [ -z "$chatId" ]; then
    echo -e "\n\033[91mAdmin chat ID required!\033[0m\n"
    exit 1
fi

# تنظیم فایل baseInfo.php
cat > /var/www/html/asemanxui-bot/config/baseInfo.php <<EOL
<?php
error_reporting(0);
\$botToken = '$botToken';
\$dbUserName = 'aseman_user';
\$dbPassword = 'randompass';
\$dbName = 'aseman_db';
\$botUrl = 'https://$domainname/asemanxui-bot/';
\$admin = '$chatId';
?>
EOL

# تنظیم دیتابیس
mysql -e "CREATE DATABASE aseman_db;" || { echo -e "\n\033[91mFailed to create database!\033[0m\n"; exit 1; }
mysql -e "CREATE USER 'aseman_user'@'localhost' IDENTIFIED BY 'randompass';" || { echo -e "\n\033[91mFailed to create user!\033[0m\n"; exit 1; }
mysql -e "GRANT ALL PRIVILEGES ON aseman_db.* TO 'aseman_user'@'localhost';" || { echo -e "\n\033[91mFailed to grant privileges!\033[0m\n"; exit 1; }
mysql -e "FLUSH PRIVILEGES;"
mysql aseman_db < /var/www/html/asemanxui-bot/database/schema.sql || { echo -e "\n\033[91mFailed to import schema!\033[0m\n"; exit 1; }

# تنظیم کرون‌جاب‌ها
crontab -l 2>/dev/null | { cat; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/message.php >/dev/null 2>&1"; } | crontab -
crontab -l 2>/dev/null | { cat; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/rewardReport.php >/dev/null 2>&1"; } | crontab -
crontab -l 2>/dev/null | { cat; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/warnusers.php >/dev/null 2>&1"; } | crontab -
crontab -l 2>/dev/null | { cat; echo "* * * * * curl https://$domainname/asemanxui-bot/settings/gift2all.php >/dev/null 2>&1"; } | crontab -
crontab -l 2>/dev/null | { cat; echo "*/3 * * * * curl https://$domainname/asemanxui-bot/settings/tronChecker.php >/dev/null 2>&1"; } | crontab -
crontab -l 2>/dev/null | { cat; echo "* * * * * curl https://$domainname/asemanpanel${RANDOM_CODE}/backupnutif.php >/dev/null 2>&1"; } | crontab -

# تنظیم وب‌هوک و ارسال پیام موفقیت
curl -F "url=https://$domainname/asemanxui-bot/index.php" "https://api.telegram.org/bot$botToken/setWebhook"
curl -s -X POST "https://api.telegram.org/bot$botToken/sendMessage" -d chat_id="$chatId" -d text="✅ ربات آسمان با موفقیت نصب شد!"

echo -e "\n\e[92mAseman bot installed successfully!\033[0m\n"
exit 0
