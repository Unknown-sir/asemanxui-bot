#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[33mPlease run as root\033[0m"
    exit
fi

PS3="Please Select Action: "
options=("Update bot" "Update panel" "Backup" "Exit")
select opt in "${options[@]}"; do
    case $opt in
        "Update bot")
            read -p "Are you sure? [y/n]: " answer
            if [ "$answer" = "y" ]; then
                mv /var/www/html/asemanxui-bot/config/baseInfo.php /root/
                rm -r /var/www/html/asemanxui-bot/
                git clone https://github.com/Unknown-sir/asemanxui-bot.git /var/www/html/asemanxui-bot
                chown -R www-data:www-data /var/www/html/asemanxui-bot/
                chmod -R 755 /var/www/html/asemanxui-bot/
                mv /root/baseInfo.php /var/www/html/asemanxui-bot/config/
                echo -e "\n\e[92mBot updated!\033[0m\n"
            fi
            break;;
        "Update panel")
            read -p "Are you sure? [y/n]: " answer
            if [ "$answer" = "y" ]; then
                cd /var/www/html/ && find . -mindepth 1 -maxdepth 1 ! -name asemanxui-bot -type d -exec rm -r {} \;
                RANDOM_CODE=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 40)
                mkdir "/var/www/html/asemanpanel${RANDOM_CODE}"
                wget -O /var/www/html/asemanpanel.zip https://github.com/Unknown-sir/asemanxui-bot/releases/download/1.0.0/asemanpanel.zip
                mv /var/www/html/asemanpanel.zip "/var/www/html/asemanpanel${RANDOM_CODE}/"
                cd "/var/www/html/asemanpanel${RANDOM_CODE}/" && unzip asemanpanel.zip && rm asemanpanel.zip
                chown -R www-data:www-data "/var/www/html/asemanpanel${RANDOM_CODE}/"
                chmod -R 755 "/var/www/html/asemanpanel${RANDOM_CODE}/"
                echo -e "\n\e[92mPanel updated!\033[0m\n"
            fi
            break;;
        "Backup")
            mkdir -p /var/backups/aseman
            mysqldump -u aseman_user -prandompass aseman_db > /var/backups/aseman/backup_$(date +%Y%m%d_%H%M%S).sql
            echo -e "\n\e[92mBackup created!\033[0m\n"
            break;;
        "Exit")
            exit;;
    esac
done