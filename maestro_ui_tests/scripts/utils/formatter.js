/**
 * Mirrors KeeperCore `AmountFormatter` (default `.compact`) for integer minor-unit amounts.
 * Uses string math only (no `Number` scaling) so large nano-ton values stay exact.
 * Locale fixed to en-style: '.' decimal separator, ' ' (U+0020) thousands grouping — same as
 * `AmountFormatter.Configuration` grouping + en simulator in CI.
 * Thin space (U+2009) matches `FormattersAssembly` / `String.Symbol.shortSpace` between sign and
 * number and between number and currency symbol.
 */

var THIN_SPACE = '\u2009';
var PLUS_SIGN = '\u002b';
var MINUS_SIGN = '\u2212';
var GROUPING_SEPARATOR = ' ';
var DECIMAL_SEPARATOR = '.';

var COMPACT_MAX_FRACTION_DIGITS = 2;
var COMPACT_MAX_SIGNIFICANT_FRACTION_DIGITS = 3;

function digitString(amount) {
    if (amount === undefined || amount === null) return '0';
    if (typeof BigInt !== 'undefined' && typeof amount === 'bigint') {
        return amount < BigInt(0) ? (-amount).toString() : amount.toString();
    }
    var s = String(amount).trim();
    if (/^-?\d+$/.test(s)) return s.charAt(0) === '-' ? s.substring(1) : s;
    if (typeof amount === 'number' && Number.isFinite(amount)) {
        var rounded = Math.round(amount);
        if (Math.abs(amount - rounded) < 1e-9) {
            amount = rounded;
        }
        if (Number.isSafeInteger(amount)) {
            return String(Math.trunc(Math.abs(amount)));
        }
        // Loss of precision above 2^53-1: caller should pass balance as a string from JSON.
        var t = String(amount);
        if (/^-?\d+$/.test(t)) return t.charAt(0) === '-' ? t.substring(1) : t;
    }
    return '0';
}

function splitAmountParts(amount, fractionDigits) {
    var scale = Math.max(0, fractionDigits | 0);
    var amountString = digitString(amount);
    if (scale === 0) {
        return { integer: amountString === '' ? '0' : amountString, fraction: '' };
    }
    var needsPadding = amountString.length <= scale;
    var padded = needsPadding
        ? new Array(scale - amountString.length + 2).join('0') + amountString
        : amountString;
    var splitIndex = padded.length - scale;
    var integerPart = padded.substring(0, splitIndex);
    var fractionPart = padded.substring(splitIndex);
    return {
        integer: integerPart === '' ? '0' : integerPart,
        fraction: fractionPart
    };
}

function isZero(integer, fraction) {
    return integer === '0' && (fraction === '' || /^0+$/.test(fraction));
}

function trimTrailingZerosString(str) {
    var result = str;
    while (result.length > 0 && result.charAt(result.length - 1) === '0') {
        result = result.slice(0, -1);
    }
    return result;
}

function shouldRoundUp(ch) {
    return ch === '5' || ch === '6' || ch === '7' || ch === '8' || ch === '9';
}

function roundedDecimalDigits(digits, shouldRound) {
    if (!shouldRound) {
        return { digits: digits, overflow: false };
    }
    if (digits.length === 0) {
        return { digits: '', overflow: true };
    }
    var rounded = digits.split('');
    var index = rounded.length - 1;
    while (true) {
        if (rounded[index] === '9') {
            rounded[index] = '0';
            if (index === 0) {
                return { digits: '1' + rounded.join(''), overflow: true };
            }
            index--;
        } else {
            rounded[index] = String.fromCharCode(rounded[index].charCodeAt(0) + 1);
            return { digits: rounded.join(''), overflow: false };
        }
    }
}

function incrementInteger(integer) {
    var digits = integer.split('');
    var index = digits.length - 1;
    while (true) {
        if (digits[index] === '9') {
            digits[index] = '0';
            if (index === 0) {
                return '1' + digits.join('');
            }
            index--;
        } else {
            digits[index] = String.fromCharCode(digits[index].charCodeAt(0) + 1);
            return digits.join('');
        }
    }
}

function roundedParts(integer, fraction, maxFractionDigits) {
    var fractionEnd = Math.min(maxFractionDigits, fraction.length);
    var digits = fraction.substring(0, fractionEnd);
    var shouldRound = fractionEnd < fraction.length && shouldRoundUp(fraction.charAt(fractionEnd));
    var rounded = roundedDecimalDigits(digits, shouldRound);
    if (rounded.overflow) {
        return { integer: incrementInteger(integer), fraction: null };
    }
    var trimmed = trimTrailingZerosString(rounded.digits);
    return { integer: integer, fraction: trimmed === '' ? null : trimmed };
}

function applyCompactLessThanOneRules(fraction) {
    var i;
    for (i = 0; i < fraction.length; i++) {
        if (fraction.charAt(i) !== '0') break;
    }
    if (i >= fraction.length) {
        return { integer: '0', fraction: null, isZero: true };
    }
    var firstSignificantOffset = i;
    var maximumEndOffset = firstSignificantOffset + COMPACT_MAX_SIGNIFICANT_FRACTION_DIGITS;
    var endIndex = Math.min(maximumEndOffset, fraction.length);
    var slice = fraction.substring(0, endIndex);
    var shouldRound = endIndex < fraction.length && shouldRoundUp(fraction.charAt(endIndex));
    var rounded = roundedDecimalDigits(slice, shouldRound);
    if (rounded.overflow) {
        return { integer: '1', fraction: null, isZero: false };
    }
    var trimmed = trimTrailingZerosString(rounded.digits);
    if (trimmed === '') {
        return { integer: '0', fraction: null, isZero: true };
    }
    return { integer: '0', fraction: trimmed, isZero: false };
}

function applyCompactRules(integer, fraction) {
    if (isZero(integer, fraction)) {
        return { integer: '0', fraction: null, isZero: true };
    }
    if (integer === '0') {
        return applyCompactLessThanOneRules(fraction);
    }
    var rp = roundedParts(integer, fraction, COMPACT_MAX_FRACTION_DIGITS);
    return {
        integer: rp.integer,
        fraction: rp.fraction,
        isZero: false
    };
}

function applyGrouping(integer) {
    if (integer.length <= 3) return integer;
    var parts = [];
    var index = integer.length;
    while (index > 0) {
        var start = Math.max(0, index - 3);
        parts.push(integer.substring(start, index));
        index = start;
    }
    parts.reverse();
    return parts.join(GROUPING_SEPARATOR);
}

/**
 * @param {string} signPolicy 'none' | 'always'
 * @param {boolean} isNegative
 * @param {boolean} isZero
 */
function buildFormattedNumber(parts, signPolicy, isNegative, isZero) {
    var groupedInteger = applyGrouping(parts.integer);
    var numberString;
    if (parts.fraction !== null && parts.fraction !== '') {
        numberString = groupedInteger + DECIMAL_SEPARATOR + parts.fraction;
    } else {
        numberString = groupedInteger;
    }
    if (isZero) {
        return numberString;
    }
    if (signPolicy === 'always') {
        var signChar = isNegative ? MINUS_SIGN : PLUS_SIGN;
        return signChar + THIN_SPACE + numberString;
    }
    return numberString;
}

/**
 * Format integer minor-unit amount with KeeperCore compact rules.
 * @param {*} amount raw balance (string digits preferred)
 * @param {number} fractionDigits
 * @param {object} [opts]
 * @param {string} [opts.symbol] trailing symbol (e.g. USD₮)
 * @param {'none'|'always'} [opts.signPolicy]
 * @param {boolean} [opts.isNegative]
 */
function formatCompactMinorUnits(amount, fractionDigits, opts) {
    opts = opts || {};
    var signPolicy = opts.signPolicy || 'none';
    var isNegative = !!opts.isNegative;
    var parts = splitAmountParts(amount, fractionDigits);
    var compact = applyCompactRules(parts.integer, parts.fraction);
    var isZero = !!compact.isZero;
    var num = buildFormattedNumber(compact, signPolicy, isNegative, isZero);
    if (opts.symbol) {
        return num + THIN_SPACE + opts.symbol;
    }
    return num;
}

/**
 * TonAPI `balance` is nanotons (integer). Compact display matches KeeperCore `AmountFormatter`
 * default `.compact` (NOT legacy `Math.floor(amount/1e9 * 100) / 100`, which yields 2.26 for
 * 2265256703 while the app shows 2.27).
 */
function formatTon(amount) {
    return formatCompactMinorUnits(amount, 9, {});
}

function formatJetton(amount, decimals) {
    var d = decimals === undefined || decimals === null ? 9 : Number(decimals);
    return formatCompactMinorUnits(amount, d, {});
}

var USDT_DECIMALS = 6;

function formatUsdt(amount) {
    return formatCompactMinorUnits(amount, USDT_DECIMALS, {});
}

/**
 * Same as `SignedAccountEventAmountMapper` + `AmountFormatter` (`.compact`, `signPolicy` `.always`)
 * for jetton swap "received" line (`AccountEventMapper.mapJettonSwapAction` out / income).
 */
function formatHistoryJettonIncomeLine(amount, fractionDigits, symbol) {
    var sym = symbol || 'USD₮';
    var num = formatCompactMinorUnits(amount, fractionDigits, {
        signPolicy: 'always',
        isNegative: false
    });
    if (num === '0') {
        return '0' + THIN_SPACE + sym;
    }
    return num + THIN_SPACE + sym;
}

output.formatter = {
    formatJetton: formatJetton,
    formatTon: formatTon,
    formatUsdt: formatUsdt,
    formatHistoryJettonIncomeLine: formatHistoryJettonIncomeLine
};

(function maestroFormatterSanityCheck() {
    var ton = output.formatter.formatTon(2265256703);
    if (ton !== '2.27') {
        throw new Error(
            'formatter.js: formatTon(2265256703) expected "2.27" (Swift compact), got "' +
                ton +
                '". Legacy float+floor would show 2.26; refresh script / engine.'
        );
    }
})();
