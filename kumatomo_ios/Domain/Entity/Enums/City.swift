import Foundation

enum City: String, CaseIterable, Codable {
    case kumamoto = "熊本市"
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

    var displayName: String { rawValue }
}
