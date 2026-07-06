import Foundation
import TKLocalize

public enum Currency: Codable, CaseIterable, RawRepresentable, Sendable {
    case JPY
    case USD
    case EUR
    case RUB
    case AED
    case KZT
    case UAH
    case GBP
    case CHF
    case CNY
    case KRW
    case IDR
    case INR
    case UZS
    case BYN
    case BRL
    case TRY
    case NGN
    case THB
    case BDT
    case CAD
    case ILS
    case GEL
    case VND
    case AUD
    case ZAR
    case ARS
    case COP
    case ETB
    case KES
    case UGX
    case VES
    case GRAM
    case BTC

    public init?(rawValue: String) {
        // Legacy code, kept for persisted state and backend strings
        if rawValue == "TON" {
            self = .GRAM
            return
        }
        guard let currency = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self = currency
    }

    public init?(code: String) {
        self.init(rawValue: code)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        guard let currency = Currency(code: code) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown currency code: \(code)"
            )
        }
        self = currency
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var code: String {
        self.rawValue
    }

    public var rawValue: String {
        switch self {
        case .JPY: return "JPY"
        case .USD: return "USD"
        case .EUR: return "EUR"
        case .RUB: return "RUB"
        case .AED: return "AED"
        case .KZT: return "KZT"
        case .UAH: return "UAH"
        case .GBP: return "GBP"
        case .CHF: return "CHF"
        case .CNY: return "CNY"
        case .KRW: return "KRW"
        case .IDR: return "IDR"
        case .INR: return "INR"
        case .UZS: return "UZS"
        case .BYN: return "BYN"
        case .BRL: return "BRL"
        case .TRY: return "TRY"
        case .NGN: return "NGN"
        case .THB: return "THB"
        case .BDT: return "BDT"
        case .CAD: return "CAD"
        case .ILS: return "ILS"
        case .GEL: return "GEL"
        case .VND: return "VND"
        case .AUD: return "AUD"
        case .ZAR: return "ZAR"
        case .ARS: return "ARS"
        case .COP: return "COP"
        case .ETB: return "ETB"
        case .KES: return "KES"
        case .UGX: return "UGX"
        case .VES: return "VES"
        case .GRAM: return "GRAM"
        case .BTC: return "BTC"
        }
    }

    public var symbol: String {
        switch self {
        case .USD: return "$"
        case .JPY: return "¥"
        case .AED: return rawValue
        case .EUR: return "€"
        case .CHF: return "₣"
        case .CNY: return "¥"
        case .GBP: return "£"
        case .IDR: return "Rp"
        case .INR: return "₹"
        case .KRW: return "₩"
        case .KZT: return "₸"
        case .RUB: return "₽"
        case .UAH: return "₴"
        case .UZS: return "sum"
        case .BYN: return "Br"
        case .BRL: return "R$"
        case .TRY: return "₺"
        case .NGN: return "₦"
        case .THB: return "฿"
        case .BDT: return "৳"
        case .CAD: return "C$"
        case .ILS: return "₪"
        case .GEL: return "₾"
        case .VND: return "đ"
        case .ZAR: return "R‎"
        case .ARS: return "$"
        case .COP: return "$"
        case .ETB: return "ብር"
        case .KES: return "KSh"
        case .UGX: return "USh"
        case .VES: return "Bs"
        case .GRAM: return TonInfo.symbol
        case .BTC: return "₿"
        case .AUD: return "AU$"
        }
    }

    public var title: String {
        switch self {
        case .GRAM: return TKLocales.Currency.Items.ton
        case .USD: return TKLocales.Currency.Items.usd
        case .JPY: return TKLocales.Currency.Items.jpy
        case .AED: return TKLocales.Currency.Items.aed
        case .EUR: return TKLocales.Currency.Items.eur
        case .CHF: return TKLocales.Currency.Items.chf
        case .CNY: return TKLocales.Currency.Items.cny
        case .GBP: return TKLocales.Currency.Items.gbp
        case .IDR: return TKLocales.Currency.Items.idr
        case .INR: return TKLocales.Currency.Items.inr
        case .KRW: return TKLocales.Currency.Items.krw
        case .KZT: return TKLocales.Currency.Items.kzt
        case .RUB: return TKLocales.Currency.Items.rub
        case .UAH: return TKLocales.Currency.Items.uah
        case .UZS: return TKLocales.Currency.Items.uzs
        case .BYN: return TKLocales.Currency.Items.byn
        case .BRL: return TKLocales.Currency.Items.brl
        case .TRY: return TKLocales.Currency.Items.try
        case .NGN: return TKLocales.Currency.Items.ngn
        case .THB: return TKLocales.Currency.Items.thb
        case .BDT: return TKLocales.Currency.Items.bdt
        case .CAD: return TKLocales.Currency.Items.cad
        case .ILS: return TKLocales.Currency.Items.ils
        case .GEL: return TKLocales.Currency.Items.gel
        case .VND: return TKLocales.Currency.Items.vhd
        case .ZAR: return TKLocales.Currency.Items.zar
        case .ARS: return TKLocales.Currency.Items.ars
        case .COP: return TKLocales.Currency.Items.cop
        case .ETB: return TKLocales.Currency.Items.etb
        case .KES: return TKLocales.Currency.Items.kes
        case .UGX: return TKLocales.Currency.Items.ugx
        case .VES: return TKLocales.Currency.Items.ves
        case .BTC: return TKLocales.Currency.Items.btc
        case .AUD: return TKLocales.Currency.Items.aud
        }
    }

    public var symbolOnLeft: Bool {
        switch self {
        case .EUR, .USD, .GBP, .BDT, .CAD, .ILS, .AUD: return true
        default: return false
        }
    }

    public static var defaultCurrency: Currency {
        .USD
    }
}

extension Currency: CurrencyDisplayable {}

public extension Currency {
    var currencyDisplayType: CurrencyDisplayType {
        switch self {
        case .GRAM, .BTC:
            return .token
        default:
            return .fiat
        }
    }
}

public struct RemoteCurrency: Codable {
    public enum CurrencyType: String {
        case fiat
        case crypto
    }

    public let code: String
    public let name: String
    public let image: String
    public let type: String

    public var currencyType: CurrencyType {
        CurrencyType(rawValue: type) ?? .fiat
    }

    public static var `default`: RemoteCurrency {
        RemoteCurrency(
            code: "USD",
            name: "US Dollar",
            image: "https://tonkeeper.com/assets/currencies/USD.png",
            type: "fiat"
        )
    }

    public var legacyCurrency: Currency {
        Currency(code: code) ?? .USD
    }
}
