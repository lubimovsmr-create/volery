<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=UTF-8');

function respond(int $status, bool $ok, string $message): void
{
    http_response_code($status);
    echo json_encode([
        'ok' => $ok,
        'message' => $message,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
    respond(405, false, 'Метод не поддерживается.');
}

$name = trim((string)($_POST['name'] ?? ''));
$phone = trim((string)($_POST['phone'] ?? ''));
$website = trim((string)($_POST['website'] ?? ''));

// Honeypot: should stay empty for real users.
if ($website !== '') {
    respond(400, false, 'Запрос отклонен.');
}

$name = preg_replace('/[\r\n]+/u', ' ', $name) ?? '';
$phone = preg_replace('/[\r\n]+/u', ' ', $phone) ?? '';

if ($name === '' || mb_strlen($name) < 2 || mb_strlen($name) > 80) {
    respond(422, false, 'Проверьте имя.');
}

$digits = preg_replace('/\D+/', '', $phone) ?? '';
if (strlen($digits) === 11 && ($digits[0] === '7' || $digits[0] === '8')) {
    $digits = substr($digits, 1);
}
if (strlen($digits) !== 10) {
    respond(422, false, 'Проверьте телефон.');
}

$formattedPhone = sprintf(
    '+7 (%s) %s-%s-%s',
    substr($digits, 0, 3),
    substr($digits, 3, 3),
    substr($digits, 6, 2),
    substr($digits, 8, 2)
);

$to = 'volgavol63@mail.ru';
$subjectRaw = 'Новая заявка с сайта Вольеры Самара';
$subject = function_exists('mb_encode_mimeheader')
    ? mb_encode_mimeheader($subjectRaw, 'UTF-8', 'B', "\r\n")
    : $subjectRaw;

$host = (string)($_SERVER['HTTP_HOST'] ?? 'localhost');
$host = preg_replace('/:\d+$/', '', $host) ?? 'localhost';
$host = preg_replace('/[^a-z0-9.\-]+/i', '', $host) ?? 'localhost';

$fromDomain = $host !== '' ? $host : 'example.com';
$from = 'no-reply@' . $fromDomain;

$bodyLines = [
    'Новая заявка с сайта',
    '',
    'Имя: ' . $name,
    'Телефон: ' . $formattedPhone,
    '',
    'Дата: ' . date('Y-m-d H:i:s'),
    'IP: ' . (string)($_SERVER['REMOTE_ADDR'] ?? 'unknown'),
    'User-Agent: ' . (string)($_SERVER['HTTP_USER_AGENT'] ?? 'unknown'),
];
$body = implode("\r\n", $bodyLines);

$headers = [
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'From: ' . $from,
];

$sent = @mail($to, $subject, $body, implode("\r\n", $headers));

if (!$sent) {
    respond(500, false, 'Не удалось отправить заявку. Попробуйте чуть позже.');
}

respond(200, true, 'Заявка отправлена.');
