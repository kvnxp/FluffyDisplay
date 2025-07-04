import Foundation

struct Resolution {
    let width, height, ppi: Int32
    let hiDPI: Bool
    let description: String
    init(_ width: Int32, _ height: Int32, _ ppi: Int32, _ hiDPI: Bool, _ description: String) {
        self.width = width
        self.height = height
        self.ppi = ppi
        self.hiDPI = hiDPI
        self.description = description
    }
    init(_ width: Int, _ height: Int, _ ppi: Int, _ hiDPI: Bool, _ description: String) {
        self.init(Int32(width), Int32(height), Int32(ppi), hiDPI, description)
    }
}

let predefResolutions: [Resolution] = [
    Resolution(6016, 3384, 218, true,  "Apple Pro Display XDR"),
    Resolution(5120, 2880, 218, true,  "UHD+, 27-inch Apple Studio Display, 27-inch iMac with Retina 5K display"),
    Resolution(4480, 2520, 218, true,  "24-inch iMac (23.5-inch)"),
    Resolution(5120, 2160, 200, true,  "21:9, 64∶27, 237:100 (27.8-inch)"),
    Resolution(4096, 2304, 219, true,  "21.5-inch iMac with Retina 4K display"),
    Resolution(3840, 2400, 200, true,  "WQUXGA"),
    Resolution(3840, 2160, 200, true,  "UHD"),
    Resolution(3456, 2234, 254, true,  "16.2-inch MacBook Pro"),
    Resolution(5120, 1440, 200, true,  "32:9, 356:100, DQHD (26.6-inch)"),
    Resolution(3840, 1600, 200, true,  "WQHD+, UW-QHD+, 21:9, 240:100 (20.8-inch)"),
    Resolution(3440, 1440, 200, true,  "21:9, 239:100 (18.6-inch)"),
    Resolution(3840, 1080, 200, true,  "DFHD"),
    Resolution(3024, 1964, 254, true,  "14.2-inch MacBook Pro"),
    Resolution(3072, 1920, 226, true,  "16-inch MacBook Pro with Retina display"),
    Resolution(2880, 1864, 224, true,  "15.3-inch MacBook Air"),
    Resolution(2880, 1800, 220, true,  "15.4-inch MacBook Pro with Retina display"),
    Resolution(2560, 1664, 224, true,  "13.6-inch MacBook Air"),
    Resolution(2560, 1600, 227, true,  "WQXGA, 13.3-inch MacBook Pro with Retina display"),
    Resolution(2560, 1440, 109, false, "27-inch Apple Thunderbolt display"),
    Resolution(2304, 1440, 226, true,  "12-inch MacBook with Retina display"),
    Resolution(2048, 1536, 150, false, "QXGA"),
    Resolution(2048, 1152, 150, false, "QWXGA"),
    Resolution(1920, 1200, 98,  false, "WUXGA, 23-inch Apple Cinema HD Display"),
    Resolution(1600, 1200, 125, false, "UXGA"),
    Resolution(1920, 1080, 102, false, "HD, 21.5-inch iMac"),
    Resolution(1680, 1050, 99,  false, "WSXGA+, Apple Cinema Display (20-inch), 20-inch iMac"),
    Resolution(1600, 1024, 86,  false, "WSXGA, Apple Cinema Display (22-inch)"),
    Resolution(1440, 900,  127, false, "WXGA+, 13.3-inch MacBook Air"),
    Resolution(1400, 1050, 125, false, "SXGA+"),
    Resolution(1366, 768,  135, false, "11.6-inch MacBook Air"),
    Resolution(1280, 1024, 100, false, "SXGA"),
    Resolution(1280, 800,  113, false, "13.3-inch MacBook Pro"),
]
