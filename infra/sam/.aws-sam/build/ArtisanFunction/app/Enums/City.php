<?php

namespace App\Enums;

enum City: string
{
    case KUMAMOTO = '熊本市';
    case YATSUHIRO = '八代市';
    case HITOYOSHI = '人吉市';
    case ARAO = '荒尾市';
    case MINAMATA = '水俣市';
    case TAMANA = '玉名市';
    case YAMAGA = '山鹿市';
    case KIKUCHI = '菊池市';
    case UTO = '宇土市';
    case KAMIAMAKUSA = '上天草市';
    case UKI = '宇城市';
    case ASO = '阿蘇市';
    case AMAKUSA = '天草市';
    case GOSHI = '合志市';

    public static function names(): array
    {
        return array_map(fn(self $c) => $c->value, self::cases());
    }
}

