/**
 * ...
 * @author Adrian Veith
 */

package p4n;
import neko.NativeString;

typedef FormatSettings = {
	var ThousandSeparator: String;
	var DecimalSeparator: String;
	var DateSeparator: String;
	var TimeSeparator: String;
	var ListSeparator: String;
	var CurrencyString: String;
	var ShortDateFormat: String;
	var LongDateFormat: String;
	var TimeAMString: String;
	var TimePMString: String;
	var ShortTimeFormat: String;
	var LongTimeFormat: String;
	var ShortMonthNames: String;
	var LongMonthNames: String;
	var ShortDayNames: String;
	var LongDayNames: String;
}

private class I {
	public static function format(f: String, arg: Array < Dynamic > ): NativeString { return null; }
	public static function formatFloat(f: String, x: Float): NativeString { return null; }
	public static function formatDateTime(f: String, x: Float): NativeString { return null; }
	public static function setFormat(format: Dynamic): Void { return null; }
	public static function parseDate(s: String): Float { return null; }
	public static function parseDateTime(s: String): Float { return null; }
	public static function parseTime(s: String): Float { return null; }
	public static function parseFloat(s: String): Float { return null; }
}

class SysUtils {
	public inline static function parseDate(s: String): Float { return I.parseDate(s); }
	public inline static function parseDateTime(s: String): Float { return I.parseDateTime(s); }
	public inline static function parseTime(s: String): Float { return I.parseTime(s); }
	public inline static function parseFloat(s: String): Float { return I.parseFloat(s); }

	public static function parseTDate(s: String): TDateTime { return TDateTime.fromFloat(I.parseDate(s)); }
	public static function parseTDateTime(s: String): TDateTime { return TDateTime.fromFloat(I.parseDateTime(s)); }
	public static function parseTTime(s: String): TDateTime { return TDateTime.fromFloat( I.parseTime(s)); }
	
	public inline static function format(f: String, arg: Array < Dynamic > ): String { return NativeString.toString(I.format(f, arg)); }
	public inline static function formatFloat(f: String, x: Float): String { return NativeString.toString(I.formatFloat(f, x)); }
	public inline static function formatDateTime(f: String, x: Float): String { return NativeString.toString(I.formatDateTime(f, x)); }
	public inline static function formatTDateTime(f: String, x: TDateTime): String { return NativeString.toString(I.formatDateTime(f, x.toFloat)); }
	public inline static function setFormat(format: Dynamic): Void { I.setFormat(format); }

	static public function __init__() {
		neko.Lib.load('p4n_std.dll', '_init_std', 1) ('p4n_std') (I);
	}
	
}