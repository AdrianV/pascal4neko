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

typedef TimeRec = {
	var hour: Int;
	var minute: Int;
	var sec: Float;	
}

typedef DateTimeRec = { > DateRec,
	> TimeRec,
}
	
//using p4n.DateTime;
#if js @:expose("p4n.DateTime") #end
abstract DateTime(Float) from Float to Float
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
	static public var ISOFirstWeekDay: Int = 0; // Montag
	static public var ISOFirstWeekMinDays: Int = 4; // 4. Januar liegt in erster Woche

	@:op(A + B) static public function add(lhs:DateTime, rhs:DateTime):DateTime;
	@:commutative @:op(A + B) static public function add1(lhs:DateTime, rhs:Float):DateTime;
	@:commutative @:op(A + B) static public function add2(lhs:DateTime, rhs:Int):DateTime;
	@:commutative @:op(A * B) static public function mul(lhs:DateTime, rhs:Float):DateTime;
	@:commutative @:op(A * B) static public function mul1(lhs:DateTime, rhs:Int):DateTime;
	@:op(A - B) static public function sub1(lhs:DateTime, rhs:Float):DateTime;
	@:op(A - B) static public function sub2(lhs:DateTime, rhs:DateTime):DateTime;
	@:op(A - B) static public function sub3(lhs:Float, rhs:DateTime):DateTime;
	@:op(A / B) static public function div1(lhs:DateTime, rhs:Float):Float;
	@:op(A < B) static public function lt(lhs:DateTime, rhs:DateTime):Bool;
	@:op(A <= B) static public function lte(lhs:DateTime, rhs:DateTime):Bool;
	@:op(A == B) static public function eq(lhs:DateTime, rhs:DateTime):Bool;
	@:op(A != B) static public function neq(lhs:DateTime, rhs:DateTime):Bool;
	@:op(A >= B) static public function gte(lhs:DateTime, rhs:DateTime):Bool;
	@:op(A > B) static public function gt(lhs:DateTime, rhs:DateTime):Bool;

	@:op(A < B) static public function lt1(lhs:DateTime, rhs:Float):Bool;
	@:op(A <= B) static public function lte1(lhs:DateTime, rhs:Float):Bool;
	@:op(A == B) static public function eq1(lhs:DateTime, rhs:Float):Bool;
	@:op(A != B) static public function neq1(lhs:DateTime, rhs:Float):Bool;
	@:op(A >= B) static public function gte1(lhs:DateTime, rhs:Float):Bool;
	@:op(A > B) static public function gt1(lhs:DateTime, rhs:Float):Bool;
	
	public inline function new(v: Float) {
		this = v;
	}
	
	public inline function isInitialized(): Bool {
		#if (neko || js)
			return this != null && this != 0.0;
		#else
			return this != 0.0;
		#end
	}
	public static function isLeapYear(year: Int): Bool {
		return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
	}
	
	public static function encode(year: Int, month: Int, day: Int): DateTime {
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
	
	public static inline function encodeTime(hour: Int, minute: Int, sec: Float): DateTime {
		return ((hour * HOURS) + minute * MINUTES + sec * SECONDS);
	}
	public static function encodeDateTime(year: Int, month: Int, day: Int, hour: Int, minute: Int, sec: Float): DateTime {
		return (encode(year, month, day) + (hour * HOURS) + minute * MINUTES + sec * SECONDS);
	}
	
	public inline function abs(): DateTime return Math.abs(this);
	
	public function decode(): DateRec {
		#if (neko || js)
		if (this == null) return { day:0, month: 0, year: 0 };
		#end
		if (Math.isNaN(this)) return { day:0, month: 0, year: 0 };
		var T: Int = toInt() + DateDelta;
		//if (Math.isNaN(T)) return { day:0, month: 0, year: 0 };
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
		
	public inline function year(): Int {
		return decode().year;
	}
	public inline function month(): Int {
		return decode().month;
	}
	public inline function day(): Int {
		return decode().day;
	}
	
	public function monthDelta(d2: DateTime): Int {
		var dd1 = decode();
		var dd2 = d2.decode();
		return (dd1.month - dd2.month) + 12 * (dd1.year - dd2.year);
	}
	public static function lastDayOf(Month: Int, Year: Int): Int {
		return if (isLeapYear(Year)) MD1[Month] else MD0[Month];
	}

	public function lastDayOfMonth(): Int {
		var dt: DateRec = decode();
		return if (isLeapYear(dt.year)) MD1[dt.month] else MD0[dt.month];
	}
	
	public function dayOfWeek(): Int {
		// Mo = 0; Sun= 6
		return (Math.floor(this) +5) % 7;
	}
	
	public function fixDay(day: Int): DateTime {
		var dt: DateRec = decode();
		return encode(dt.year, dt.month, day);
	}
	
	public function ISOWeekNumber() {
		//var YearOfWeekNumber, WeekDay: Integer): Integer;
		var WeekDay : Int = ((dayOfWeek() - ISOFirstWeekDay + 7) % 7) + 1;
		var day4: DateTime = this - WeekDay + 8 - ISOFirstWeekMinDays;
		var dt: DateRec = day4.decode();
		return { Week: Math.floor((day4 - encode(dt.year, 1, 1)) / 7.0) +1, Year: dt.year, WeekDay: WeekDay };
	}
	
	public inline function weekNumber(): Int {
		return ISOWeekNumber().Week;
	}

	public function decodeDateTime(): DateTimeRec {
		var dt: DateRec = decode();
		//trace(dt);
		var t = Math.min(1 - 0.00005 * SECONDS, timeValue() + 0.00005 * SECONDS) * 24;
		var h: Int = Math.floor(t);
		t = (t - h) * 60;
		var m = Math.floor(t);
		t = (t - m) * 60;
		return {year: dt.year, month: dt.month, day: dt.day, hour: h, minute: m, sec: MathX.round(t, 3) };
	}
	
	public function decodeTime(): TimeRec {
		var t = Math.min(1 - 0.00005 * SECONDS, timeValue() + 0.00005 * SECONDS) * 24;
		var h: Int = Math.floor(t);
		t = (t - h) * 60;
		var m = Math.floor(t);
		t = (t - m) * 60;
		return { hour: h, minute: m, sec: MathX.round(t, 3) };		
	}
	
	//public static function DecodeDateTime(dt: Float): DateTimeRec { return if (dt != null) TDateTime.fromFloat(dt).decodeDateTime() else null; }
	@:from public static inline function fromInt(v: Int): DateTime { return v; }
	@:to public inline function toInt(): Int { return Math.floor(this); }
	public function timeValue(): DateTime { return this - Math.floor(this); }
	public function dayValue(): DateTime return Math.floor(this);
	@:to public function toDate(): Date { 
		//trace(me);
		var dt: DateTimeRec = decodeDateTime();
		return new Date(dt.year, dt.month -1, dt.day, dt.hour, dt.minute, Math.floor(dt.sec));
	}
	
	public static function EasterSunday(year: Int): DateTime {
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
	
	@:from public static function fromDate(d: Date): DateTime {
		//var res: TDateTime = TDateTime.EncodeDateTime(1970, 1, 1, 1, 0, 0);
		//res.toFloat += d.getTime() / (1000 * 60 * 60 * 24); 
		return d != null ? DateTime.encodeDateTime(d.getFullYear(), d.getMonth() +1, d.getDate(), 
      d.getHours(), d.getMinutes(), d.getSeconds()): 0.0;
	}
		
	public static function fromTime(d: Date): DateTime {
		return d != null ? DateTime.encodeTime(d.getHours(), d.getMinutes(), d.getSeconds()) : 0.0;
	}

	public static function fromDay(d: Date): DateTime {
		return d != null ? DateTime.encode(d.getFullYear(), d.getMonth() + 1, d.getDate()) : 0.0;
	}
	
	/**
		Returns the actual day (without time).
	**/
	public static function date(): DateTime {
		return fromDate(Date.now()).toInt();
	}

	/**
		Returns the actual day and time.
	**/
	public static function now(): DateTime {
		return fromDate(Date.now());
	}
}

#if js
private class Init {
	private static function __init__() : Void untyped {
		function set() {
			var dummy = $hxClasses[DateTime.__name__.join(".")];
			__js__('p4n.DateTime = dummy');
			__js__('window.p4n.DateTime = dummy');
		}();
		
	}
}
#end