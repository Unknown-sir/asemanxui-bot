<?php
class Panel {
    private $url = 'http://your-xui-panel.com';
    private $apiKey = 'YOUR_PANEL_API_KEY';
    private $type = 'sanaei'; // یا 'alireza'

    public function getUserStatus($userId) {
        $loginUrl = $this->type === 'sanaei' ? "$this->url/panel/api/login" : "$this->url/xui/api/login";
        $postFields = ['username' => 'admin', 'password' => 'admin']; // باید از کانفیگ گرفته بشه
        $session = $this->login($loginUrl, $postFields);

        if (!$session) return null;

        $endpoint = $this->type === 'sanaei' 
            ? "$this->url/panel/inbound/update/$userId" 
            : "$this->url/xui/inbound/update/$userId";
        
        $response = Helpers::httpRequest($endpoint, [], 'GET', ["Cookie: $session"]);
        $data = json_decode($response, true);

        return $data && isset($data['volume'], $data['days_left'])
            ? ['volume' => $data['volume'], 'days' => $data['days_left']]
            : null;
    }

    private function login($url, $postFields) {
        $response = Helpers::httpRequest($url, $postFields, 'POST', [], true);
        preg_match('/^Set-Cookie:\s*([^;]*)/mi', $response['header'], $match);
        return $match[1] ?? null;
    }
}