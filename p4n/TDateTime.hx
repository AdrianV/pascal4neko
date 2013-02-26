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

import p4n.DateTime;
	
class TDateTime 
{
	static inline var DateDelta: Int = 693594;
	static var MD0(default, null) = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	static var MD1(default, null) = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	static inline var D1: Int = 365;
  static inline var D4: Int = D1 * 4 + 1;
  static inline var D100: Int = D4 * 25 - 1;
  static inline var D400: Int = D100 * 4 + 1;
	static public inline var HOURS: Float = 1 / 24;
	static public inline var MINUTES: Float = 1 / (24 * 60);
	static public inline var SECONDS: Float = 1 / (24 * 60 * 60);
	static public inline var ISOFirstWeekDay: Int = 0; // Montag
  static public inline var ISOFirstWeekMinDays: Int = 4; // 4. Januar liegt in erster Woche

	
	public var toFloat: Float;
	public function new(? value: Float = 0) {
		toFloat = value;		
	}
	
	public static function IsLeapYear(year: Int): Bool {
		return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
	}
	
	public static function Encode(year: Int, month: Int, day: Int): TDateTime {
		var DayTable = if (IsLeapYear(year)) MD1 else MD0;
		  
		if ((year >= 1) && (year <= 9999) && (month >= 1) && (month <= 12) 
			&& (day >= 1) && (day <= DayTable[month]))
		{
			var I = 1;
			while (I < month) {
				day += DayTable[I++];
			}
			I = year - 1;
			return new TDateTime(I * 365 + Math.floor(I / 4) - Math.floor(I / 100) + Math.floor(I / 400) + day - DateDelta);
		} else
			return new TDateTime(0);
	}
	
	public static inline function EncodeTime(hour: Int, minute: Int, sec: Float): TDateTime {
		return new TDateTime((hour * HOURS) + minute * MINUTES + sec * SECONDS);
	}
	public static function EncodeDateTime(year: Int, month: Int, day: Int, hour: Int, minute: Int, sec: Float): TDateTime {
		return new TDateTime(Encode(year, month, day).toFloat + (hour * HOURS) + minute * MINUTES + sec * SECONDS);
	}
	
	public function decode(): DateRec {
		var T: Int = toInt() + DateDelta;
		if (T <= 0) {
			return { day: 0, year: 0, month: 0 };
		} else {
			T--;
			var Y = 1;
			while (T >= D400) {
				T -= D400;
				Y += 400;
			}
			var I = Math.floor(T / D100);
			var D = T % D100;
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
			var DayTable = if (IsLeapYear(Y)) MD1 else MD0;
			var M = 1;
			//trace(D);
			while (true) {
				I = DayTable[M];
				if (D < I) break;
				//trace({D:D, I:I, M:M});
				D -= I;
				M++;
			}
			return { day: D+1, month: M, year: Y };
		}
	}
	
	public static function Decode(dt: Float): DateRec {
		return if (dt != null) TDateTime.fromFloat(dt).decode() else null;
	}
	
	public inline function Year(): Int {
		return decode().year;
	}
	public inline function Month(): Int {
		return decode().month;
	}
	public inline function Day(): Int {
		return decode().day;
	}
	
	public static function LastDayOf(Month: Int, Year: Int): Int {
		return if (IsLeapYear(Year)) MD1[Month] else MD0[Month];
	}

	public function LastDayOfMonth(): Int {
		var dt: DateRec = decode();
		return if (IsLeapYear(dt.year)) MD1[dt.month] else MD0[dt.month];
	}
	
	public function DayOfWeek(): Int {
		// Mo = 0; Sun= 6
		return (Math.floor(toFloat) +5) % 7;
	}
	
	public function FixDay(day: Int): TDateTime {
		var dt: DateRec = decode();
		return Encode(dt.year, dt.month, day);
	}
	
	public function ISOWeekNumber() {
		//var YearOfWeekNumber, WeekDay: Integer): Integer;
		var WeekDay : Int = ((DayOfWeek() - ISOFirstWeekDay + 7) % 7) + 1;
		var day4: Float = toFloat - WeekDay + 8 - ISOFirstWeekMinDays;
		var dt: DateRec = Decode(day4);
		return { Week: Math.floor((day4 - Encode(dt.year, 1, 1).toFloat) / 7) +1, Year: dt.year, WeekDay: WeekDay };
	}
	
	public function WeekNumber(): Int {
		return ISOWeekNumber().Week;
	}

	public function decodeDateTime(): DateTimeRec {
		var dt: DateRec = decode();
		var t = Math.min(1 - 0.00005 * SECONDS, TimeValue() + 0.00005 * SECONDS) * 24;
		var h: Int = Math.floor(t);
		t = (t - h) * 60;
		var m = Math.floor(t);
		t = (t - m) * 60;
		return {year: dt.year, month: dt.month, day: dt.day, hour: h, minute: m, sec: MathX.round(t, 3) };
	}
	public static function DecodeDateTime(dt: Float): DateTimeRec { return if (dt != null) TDateTime.fromFloat(dt).decodeDateTime() else null; }
	public inline function toInt(): Int { return Math.floor(toFloat); }
	public inline function TimeValue(): Float { return toFloat - Math.floor(toFloat); }
	public inline function toDate(): Date { 
		var dt: DateTimeRec = decodeDateTime();
		return new Date(dt.year, dt.month -1, dt.day, dt.hour, dt.minute, Math.floor(dt.sec));
	}
  public static function FloatToDate(dt: Float): Date {
    if (dt != null) {
      return fromFloat(dt).toDate();
    } else
      return null;
  }
	public static function EasterSunday(year: Int): TDateTime {
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
		return Encode(year, month, day);
	}
	
	public static function fromDate(d: Date): TDateTime {
		//var res: TDateTime = TDateTime.EncodeDateTime(1970, 1, 1, 1, 0, 0);
		//res.toFloat += d.getTime() / (1000 * 60 * 60 * 24); 
		return TDateTime.EncodeDateTime(d.getFullYear(), d.getMonth() +1, d.getDate(), 
      d.getHours(), d.getMinutes(), d.getSeconds());
	}
	public static inline function fromFloat(f: Float): TDateTime {
		return new TDateTime(f);
	}
	
	public static inline function now(): TDateTime {
		return fromDate(Date.now());
	}
}