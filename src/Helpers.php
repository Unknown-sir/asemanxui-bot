<?php
class Helpers {
    public static function sendTelegramMessage($token, $chatId, $text) {
        $url = "https://api.telegram.org/bot{$token}/sendMessage";
        self::httpRequest($url, ['chat_id' => $chatId, 'text' => $text]);
    }

    public static function httpRequest($url, $data = [], $method = 'POST', $headers = [], $returnHeader = false) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        if ($method === 'POST') {
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
        }
        if ($returnHeader) curl_setopt($ch, CURLOPT_HEADER, true);

        $response = curl_exec($ch);
        $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        curl_close($ch);

        return $returnHeader 
            ? ['header' => substr($response, 0, $headerSize), 'body' => substr($response, $headerSize)]
            : $response;
    }
}