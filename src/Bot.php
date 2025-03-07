<?php
require_once __DIR__ . '/../config/baseInfo.php';
require_once __DIR__ . '/Panel.php';
require_once __DIR__ . '/Helpers.php';

class Bot {
    private $pdo;
    private $panel;

    public function __construct() {
        global $botToken, $dbUserName, $dbPassword, $dbName, $admin;
        $this->panel = new Panel();
        $this->initDatabase($dbUserName, $dbPassword, $dbName);
        $this->setWebhook($botToken);
    }

    private function initDatabase($user, $pass, $name) {
        try {
            $this->pdo = new PDO("mysql:host=localhost;dbname=$name;charset=utf8mb4", $user, $pass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
            ]);
        } catch (PDOException $e) {
            Helpers::sendTelegramMessage($GLOBALS['botToken'], $GLOBALS['admin'], "خطای دیتابیس: " . $e->getMessage());
            exit;
        }
    }

    private function setWebhook($token) {
        global $botUrl;
        Helpers::httpRequest("https://api.telegram.org/bot{$token}/setWebhook", ['url' => $botUrl . 'index.php']);
    }

    public function processUpdate() {
        $update = json_decode(file_get_contents('php://input'), true);
        $chatId = $update['message']['chat']['id'] ?? null;
        $text = $update['message']['text'] ?? '';

        if (!$chatId) return;

        $commands = [
            '/start' => 'handleStart',
            '/status' => 'handleStatus',
            '/backup' => 'handleBackup',
        ];

        $method = $commands[strtolower($text)] ?? 'handleUnknown';
        $this->$method($chatId);
    }

    private function handleStart($chatId) {
        Helpers::sendTelegramMessage($GLOBALS['botToken'], $chatId, "به ربات آسمان خوش آمدید!\n/status - وضعیت اشتراک\n/backup - بک‌آپ دستی");
    }

    private function handleStatus($chatId) {
        $status = $this->panel->getUserStatus($chatId);
        $message = $status 
            ? "وضعیت:\nحجم: {$status['volume']} GB\nزمان: {$status['days']} روز"
            : "خطا در دریافت اطلاعات!";
        Helpers::sendTelegramMessage($GLOBALS['botToken'], $chatId, $message);
    }

    private function handleBackup($chatId) {
        global $admin;
        if ($chatId != $admin) {
            Helpers::sendTelegramMessage($GLOBALS['botToken'], $chatId, "فقط مدیر می‌تواند بک‌آپ بگیرد!");
            return;
        }
        $result = $this->createBackup();
        Helpers::sendTelegramMessage($GLOBALS['botToken'], $chatId, $result ? "بک‌آپ با موفقیت ایجاد شد!" : "خطا در بک‌آپ!");
    }

    private function handleUnknown($chatId) {
        Helpers::sendTelegramMessage($GLOBALS['botToken'], $chatId, "دستور نامعتبر! از /start استفاده کنید.");
    }

    private function createBackup() {
        $file = "/var/backups/aseman/backup_" . date('Ymd_His') . ".sql";
        $command = "mysqldump -u {$GLOBALS['dbUserName']} -p{$GLOBALS['dbPassword']} {$GLOBALS['dbName']} > $file";
        exec($command, $output, $returnVar);
        return $returnVar === 0;
    }
}