<?php

return [
    'database' => [
        'host' => getenv('TEMU_DB_HOST') ?: '127.0.0.1',
        'port' => (int) (getenv('TEMU_DB_PORT') ?: 3306),
        'name' => getenv('TEMU_DB_NAME') ?: 'lost_and_found_campus',
        'user' => getenv('TEMU_DB_USER') ?: 'root',
        'password' => getenv('TEMU_DB_PASSWORD') ?: '',
    ],
    'cors_origin' => getenv('TEMU_CORS_ORIGIN') ?: '*',
];

