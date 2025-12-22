<?php

namespace App\Enums;

enum Municipality: string
{
    // 熊本市 区
    case KUMAMOTO_CHUO = '熊本市中央区';
    case KUMAMOTO_HIGASHI = '熊本市東区';
    case KUMAMOTO_NISHI = '熊本市西区';
    case KUMAMOTO_MINAMI = '熊本市南区';
    case KUMAMOTO_KITA = '熊本市北区';

    // 市
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

    // 町村
    case MISATO = '美里町';
    case GYOKUTO = '玉東町';
    case NANKAN = '南関町';
    case NAGASU = '長洲町';
    case NAGOMI = '和水町';
    case OZU = '大津町';
    case KIKUYO = '菊陽町';
    case MINAMIOGUNI = '南小国町';
    case OGUNI = '小国町';
    case UBUYAMA = '産山村';
    case TAKAMORI = '高森町';
    case NISHIHARA = '西原村';
    case MINAMIASO = '南阿蘇村';
    case MIFUNE = '御船町';
    case KASHIMA = '嘉島町';
    case MASHIKI = '益城町';
    case KOSA = '甲佐町';
    case YAMATO = '山都町';
    case HIKAWA = '氷川町';
    case ASHIKITA = '芦北町';
    case TSUNAGI = '津奈木町';
    case NISHIKI = '錦町';
    case TARAGI = '多良木町';
    case YUNOMAE = '湯前町';
    case MIZUKAMI = '水上村';
    case SAGARA = '相良村';
    case ITSUKI = '五木村';
    case YAMAE = '山江村';
    case KUMA = '球磨村';
    case ASAGIRI = 'あさぎり町';
    case REIHOKU = '苓北町';

    public static function names(): array
    {
        return array_map(fn(self $c) => $c->value, self::cases());
    }
}

