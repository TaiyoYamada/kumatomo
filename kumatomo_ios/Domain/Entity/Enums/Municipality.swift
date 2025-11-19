import Foundation

enum Municipality: String, CaseIterable, Codable {
    // 熊本市
    case kumamotoChuo = "熊本市中央区"
    case kumamotoHigashi = "熊本市東区"
    case kumamotoNishi = "熊本市西区"
    case kumamotoMinami = "熊本市南区"
    case kumamotoKita = "熊本市北区"

    // 市
    case yatsushiro = "八代市"
    case hitoyoshi = "人吉市"
    case arao = "荒尾市"
    case minamata = "水俣市"
    case tamana = "玉名市"
    case yamaga = "山鹿市"
    case kikuchi = "菊池市"
    case uto = "宇土市"
    case kamiamakusa = "上天草市"
    case uki = "宇城市"
    case aso = "阿蘇市"
    case amakusa = "天草市"
    case goshi = "合志市"

    // 町村
    case misato = "美里町"
    case gyokuto = "玉東町"
    case nankan = "南関町"
    case nagasu = "長洲町"
    case nagomi = "和水町"
    case ozu = "大津町"
    case kikuyo = "菊陽町"
    case minamioguni = "南小国町"
    case oguni = "小国町"
    case ubuyama = "産山村"
    case takamori = "高森町"
    case nishihara = "西原村"
    case minamiaso = "南阿蘇村"
    case mifune = "御船町"
    case kashima = "嘉島町"
    case mashiki = "益城町"
    case kosa = "甲佐町"
    case yamato = "山都町"
    case hikawa = "氷川町"
    case ashikita = "芦北町"
    case tsunagi = "津奈木町"
    case nishiki = "錦町"
    case taragi = "多良木町"
    case yunomae = "湯前町"
    case mizukami = "水上村"
    case sagara = "相良村"
    case itsuki = "五木村"
    case yamae = "山江村"
    case kuma = "球磨村"
    case asagiri = "あさぎり町"
    case reihoku = "苓北町"

    var displayName: String {
        return self.rawValue
    }

    var region: Region {
        switch self {
        case .kumamotoChuo, .kumamotoHigashi, .kumamotoNishi, .kumamotoMinami, .kumamotoKita:
            return .kumamotoCity
        case .yatsushiro, .hikawa:
            return .yatsushiro
        case .hitoyoshi, .taragi, .yunomae, .mizukami, .sagara, .itsuki, .yamae, .kuma, .asagiri:
            return .hitoyoshi
        case .arao, .tamana, .nankan, .nagasu, .nagomi, .gyokuto:
            return .tamana
        case .yamaga, .kikuchi, .goshi, .ozu, .kikuyo:
            return .kikuchi
        case .uto, .uki, .mifune, .kashima, .mashiki, .kosa:
            return .uto
        case .aso, .minamioguni, .oguni, .ubuyama, .takamori, .nishihara, .minamiaso:
            return .aso
        case .amakusa, .kamiamakusa, .reihoku:
            return .amakusa
        default:
            return .other
        }
    }
}

enum Region: String, CaseIterable {
    case kumamotoCity = "熊本市"
    case yatsushiro = "八代地域"
    case hitoyoshi = "人吉・球磨地域"
    case tamana = "玉名地域"
    case kikuchi = "菊池地域"
    case uto = "宇城地域"
    case aso = "阿蘇地域"
    case amakusa = "天草地域"
    case other = "その他"

    var municipalities: [Municipality] {
        return Municipality.allCases.filter { $0.region == self }
    }
}