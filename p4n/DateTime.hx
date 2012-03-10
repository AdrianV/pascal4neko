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
{ The Original Code is TDateTime.hx.                                                                   
{                                                                                                  
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                
{                                                                                                  
{ Contributors:                                                                                    
{   Adrian Veith                                                                                   
{                                                                                                  
{**************************************************************************************************/

package p4n;

typedef DateRec = {
	var day: Int;
	var month: Int;
	var year: Int;
}

typedef DateTimeRec = { > DateRec,
	var hour: Int;
	var minute: Int;
	var sec: Float;
}
	
//using p4n.DateTime;
class DateTime 
{
	static inline var DateDelta: Int = 693594;
	static inline var MD0 = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	static inline var MD1 = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	static inline var D1: Int = 365;
	static inline var D4: Int = D1 * 4 + 1;
	static inline var D100: Int = D4 * 25 - 1;
	static inline var D400: Int = D100 * 4 + 1;
	static public inline var HOURS: Float = 1 / 24;
	static public inline var MINUTES: Float = 1 / (24 * 60);
	static public inline var SECONDS: Float = 1 / (24 * 60 * 60);
	static public inline var ISOFirstWeekDay: Int = 0; // Montag
	static public inline var ISOFirstWeekMinDays: Int = 4; // 4. Januar liegt in erster Woche

		
	public static function isLeapYear(year: Int): Bool {
		return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
	}
	
	public static function encode(year: Int, month: Int, day: Int): Float {
		var DayTable = if (isLeapYear(year)) MD1 else MD0;
		  
		if ((year >= 1) && (year <= 9999) && (month >= 1) && (month <= 12) 
			&& (day >= 1) && (day <= DayTable[month]))
		{
			var I = 1;
			while (I < month) {
				day += DayTable[I++];
			}
			I = year - 1;
			return (I * 365 + Math.floor(I / 4) - Math.floor(I / 100) + Math.floor(I / 400) + day - DateDelta);
		} else
			return 0.0;
	}
	
	public static inline function encodeTime(hour: Int, minute: Int, sec: Float): Float {
		return ((hour * HOURS) + minute * MINUTES + sec * SECONDS);
	}
	public static function encodeDateTime(year: Int, month: Int, day: Int, hour: Int, minute: Int, sec: Float): Float {
		return (encode(year, month, day) + (hour * HOURS) + minute * MINUTES + sec * SECONDS);
	}
	
	public static function decode(me: Float): DateRec {
		if (me == null) return { day:0, month: 0, year: 0 };
		var T: Int = toInt(me) + DateDelta;
		if (T <= 0) {
			return { day: 0, year: 0, month: 0 };
		} else {
			T--;
			var Y: Int = 1;
			while (T >= D400) {
				T -= D400;
				Y += 400;
			}
			var I = Math.floor(T / D100);
			var D: Int = T % D100;
			if (I == 4) {
				I--;
				D += D100;
			}
			Y += I * 100;
			I = Math.floor(D / D4);
			D = D % D4;
			Y += I * 4;
			I = Math.floor(D / D1);
			D = D % D1;
			if (I == 4) {
				I--;
				D += D1;
			}
			Y += I;
			var DayTable = if (isLeapYear(Y)) MD1 else MD0;
			var M = 1;
			//trace(D);
			while (true) {
				I = DayTable[M];
				if (D < I) break;
				//trace({D:D, I:I, M:M});
				D -= I;
				M++;
			}
			var res: DateRec = { day: D + 1, month: M, year: Y };
			//trace(res);
			return res;
		}
	}
		
	public static inline function year(me: Float): Int {
		return decode(me).year;
	}
	public static inline function month(me: Float): Int {
		return decode(me).month;
	}
	public static inline function day(me: Float): Int {
		return decode(me).day;
	}
	
	public static function lastDayOf(Month: Int, Year: Int): Int {
		return if (isLeapYear(Year)) MD1[Month] else MD0[Month];
	}

	public static function lastDayOfMonth(me: Float): Int {
		var dt: DateRec = decode(me);
		return if (isLeapYear(dt.year)) MD1[dt.month] else MD0[dt.month];
	}
	
	public static function dayOfWeek(me: Float): Int {
		// Mo = 0; Sun= 6
		return (Math.floor(me) +5) % 7;
	}
	
	public static function fixDay(me: Float, day: Int): Float {
		var dt: DateRec = decode(me);
		return encode(dt.year, dt.month, day);
	}
	
	public static function ISOWeekNumber(me: Float) {
		//var YearOfWeekNumber, WeekDay: Integer): Integer;
		var WeekDay : Int = ((dayOfWeek(me) - ISOFirstWeekDay + 7) % 7) + 1;
		var day4: Float = me - WeekDay + 8 - ISOFirstWeekMinDays;
		var dt: DateRec = decode(day4);
		return { Week: Math.floor((day4 - encode(dt.year, 1, 1)) / 7) +1, Year: dt.year, WeekDay: WeekDay };
	}
	
	public static function weekNumber(me: Float): Int {
		return ISOWeekNumber(me).Week;
	}

	public static function decodeDateTime(me: Float): DateTimeRec {
		var dt: DateRec = decode(me);
		//trace(dt);
		var t = Math.min(1 - 0.00005 * SECONDS, timeValue(me) + 0.00005 * SECONDS) * 24;
		var h: Int = Math.floor(t);
		t = (t - h) * 60;
		var m = Math.floor(t);
		t = (t - m) * 60;
		return {year: dt.year, month: dt.month, day: dt.day, hour: h, minute: m, sec: Tools.round(t, 3) };
	}
	//public static function DecodeDateTime(dt: Float): DateTimeRec { return if (dt != null) TDateTime.fromFloat(dt).decodeDateTime() else null; }
	public static inline function toInt(me: Float): Int { return Math.floor(me); }
	public static inline function timeValue(me: Float): Float { return me - Math.floor(me); }
	public static function toDate(me: Float): Date { 
		//trace(me);
		var dt: DateTimeRec = decodeDateTime(me);
		return new Date(dt.year, dt.month -1, dt.day, dt.hour, dt.minute, Math.floor(dt.sec));
	}
	
	public static function EasterSunday(year: Int): Float {
		var a :Int = year % 19;
		var b : Int = (204-11*a) % 30;
		if (b == 28 || b == 29) 
			b--;
		var c: Int = (year + Math.floor(year / 4) + b - 13) % 7;
		var day : Int = 28 + b - c - 2;
		var month : Int = 3;
		if (day > 31) {
			day -= 31;
			month = 4;
		}
		return encode(year, month, day);
	}
	
	public static function fromDate(d: Date): Float {
		//var res: TDateTime = TDateTime.EncodeDateTime(1970, 1, 1, 1, 0, 0);
		//res.toFloat += d.getTime() / (1000 * 60 * 60 * 24); 
		return DateTime.encodeDateTime(d.getFullYear(), d.getMonth() +1, d.getDate(), 
      d.getHours(), d.getMinutes(), d.getSeconds());
	}
		
	public static inline function now(): Float {
		return fromDate(Date.now());
	}
}