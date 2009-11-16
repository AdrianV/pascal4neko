﻿/**
 * ...
 * @author Adrian Veith
 */

package p4n;
import neko.NativeString;
import neko.NativeArray;

private class I {
	public static function getSections(_i: Void): Array < String > { return null; }
	public static function readString(_i: Void, Section: String, Key: String, Default: String): NativeString { return null; }
	public static function readInt(_i: Void, Section: String, Key: String, Default: Int): Int { return null; }
	public static function readBool(_i: Void, Section: String, Key: String, Default: Bool): Bool { return null; }
	public static function readDateTime(_i: Void, Section: String, Key: String, Default: Float): Float { return null; }
	public static function readFloat(_i: Void, Section: String, Key: String, Default: Float): Float { return null; }
	public static function readSection(_i: Void, Section: String): NativeArray < NativeString > { return null; }
	public static function readSectionKeys(_i: Void, Section: String): NativeArray<NativeString> { return null; }

	public static function writeString(_i: Void, Section: String, Key: String, val: String);
	public static function writeInt(_i: Void, Section: String, Key: String, val: Int);
	public static function writeBool(_i: Void, Section: String, Key: String, val: Bool);
	public static function writeDateTime(_i: Void, Section: String, Key: String, val: Float);
	public static function writeFloat(_i: Void, Section: String, Key: String, val: Float);

	public static function KeyExists(_i: Void, Section: String, Key: String): Bool { return null; }
	public static function SectionExists(_i: Void, Section: String): Bool { return null; }
	public static function eraseKey(_i: Void, Section: String, Key: String);
	public static function eraseSection(_i: Void, Section: String);
	
	public static function updateFile(_i: Void);
	
	public static function createIniFile(FileName: String): Void;
	public static function createMemIniFile(FileName: String): Void;
	public static function createRegIniFile(FileName: String): Void;
	public static function createWebIniFile(FileName: String): Void;

}

class CustomIniFile 
{
	var _i: Void;
	public var FileName: String;
	public function new(i: Void, AFileName: String) {
		_i = i;
		FileName = AFileName;
	}

	public function getSections(): Array < String > { return I.getSections(_i); }
	public function readString(Section: String, Key: String, Default: String): String { return NativeString.toString( I.readString(_i, Section, Key, Default)); }
	public function readInt(Section: String, Key: String, Default: Int): Int { return I.readInt(_i, Section, Key, Default); }
	public function readBool(Section: String, Key: String, Default: Bool): Bool { return I.readBool(_i, Section, Key, Default); }
	public function readDateTime(Section: String, Key: String, Default: Float): Float { return I.readDateTime(_i, Section, Key, Default); }
	public function readFloat(Section: String, Key: String, Default: Float): Float { return I.readFloat(_i, Section, Key, Default); }
	public function readSection(Section: String): Array < String > { trace(Section); return cast p4n.Tools.toHaXe(I.readSection(_i, Section)); }

	public function readSectionKeys(Section: String): Array < String > { 
		var temp = I.readSectionKeys(_i, Section); 
		return cast p4n.Tools.toHaXe( temp); 
	}

	public function writeString(Section: String, Key: String, val: String) { I.writeString(_i, Section, Key, val); }
	public function writeInt(Section: String, Key: String, val: Int) { I.writeInt(_i, Section, Key, val); }
	public function writeBool(Section: String, Key: String, val: Bool) { I.writeBool(_i, Section, Key, val); }
	public function writeDateTime(Section: String, Key: String, val: Float) { I.writeDateTime(_i, Section, Key, val); }
	public function writeFloat(Section: String, Key: String, val: Float) { I.writeFloat(_i, Section, Key, val); }

	public function KeyExists(Section: String, Key: String): Bool { return I.KeyExists(_i, Section, Key); }
	public function SectionExists(Section: String): Bool { return I.SectionExists(_i, Section); }
	public function eraseKey(Section: String, Key: String) { I.eraseKey(_i, Section, Key); }
	public function eraseSection(Section: String) { I.eraseSection(_i, Section); }
	
	public function updateFile() { I.updateFile(_i); }
	
}

class RegIni extends CustomIniFile
{
	public function new(AFileName: String) {
		super(I.createRegIniFile(AFileName), AFileName);
	}	
}

class MemIni extends CustomIniFile
{
	public function new(AFileName: String) {
		super(I.createMemIniFile(AFileName), AFileName);
	}	
}

class WebIni extends CustomIniFile
{
	public function new(AFileName: String) {
		super(I.createWebIniFile(AFileName), AFileName);
	}	
}

class IniFile extends CustomIniFile
{
	public function new(AFileName: String) {
		super(I.createIniFile(AFileName), AFileName);
	}
	
	
	static public function __init__() {
		var call = null;
		try {
			call = neko.Lib.load('p4n_std.dll', '_init_std', 1) ('p4n_inifiles');
		} catch (e: Dynamic) {
			call = neko.Lib.load('p4n_inifiles.dll', '_init', 1);
		}
		if (call != null) call(I);
	}
	
}