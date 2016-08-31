/**************************************************************************************************
{                                                                                                  
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); 
{ you may not use this file except in compliance with the License. You may obtain a copy of the    
{ License at http://www.mozilla.org/MPL/                                                           
{                                                                                                  
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   
{ ANY KIND, either express or implied. See the License for the specific language governing rights  
{ and limitations under the License.                                                               
{                                                                                                  
{ The Original Code is SysUtils.hx.                                                                   
{                                                                                                  
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                
{                                                                                                  
{ Contributors:                                                                                    
{   Adrian Veith                                                                                   
{                                                                                                  
{**************************************************************************************************/

package p4n;
import p4n.DateTime;
import p4n.NekoString;

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
	public static dynamic function format(f: String, arg: Array < Dynamic > ): NekoString { return null; }
	public static dynamic function formatFloat(f: String, x: Float): NekoString { return null; }
	public static dynamic function formatDateTime(f: String, x: DateTime): NekoString { return null; }
	public static dynamic function setFormat(format: Dynamic): Void { return null; }
	public static dynamic function parseDate(s: String): DateTime { return null; }
	public static dynamic function parseDateTime(s: String): DateTime { return null; }
	public static dynamic function parseTime(s: String): DateTime { return null; }
	public static dynamic function parseFloat(s: String): Float { return null; }
}

class SysUtils {
	public inline static function parseDate(s: String): DateTime { return I.parseDate(s); }
	public inline static function parseDateTime(s: String): DateTime { return I.parseDateTime(s); }
	public inline static function parseTime(s: String): DateTime { return I.parseTime(s); }
	public inline static function parseFloat(s: String): Float { return I.parseFloat(s); }
	
	public inline static function format(f: String, arg: Array < Dynamic > ): String { return I.format(f, arg).toString(); }
	public inline static function formatFloat(f: String, x: Float): String { return I.formatFloat(f, x).toString(); }
	public inline static function formatDateTime(f: String, x: DateTime): String { return I.formatDateTime(f, x).toString(); }
	public inline static function setFormat(format: Dynamic): Void { I.setFormat(format); }

  public static function forceDir(APath: String): Bool {
		//trace(APath);
		try {
			var path = new haxe.io.Path(APath);
			if (! sys.FileSystem.exists(path.dir)) {
				//trace('check: ' + path.dir);
				if (forceDir(path.dir)) {
					//trace('create: ' + path.dir);
					sys.FileSystem.createDirectory(path.dir);
				} else return false;
			}
			return true;
		} catch (e: Dynamic) {
			trace(e);
			return false;
		}
	}

	static public function __init__() {
		neko.Lib.load('p4n_std.dll', '_init_std', 1) ('p4n_std') (I);
	}
	
}