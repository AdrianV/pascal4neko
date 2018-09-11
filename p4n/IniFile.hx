package p4n;
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
{ The Original Code is IniFile.hx.                                                                   
{                                                                                                  
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                
{                                                                                                  
{ Contributors:                                                                                    
{   Adrian Veith                                                                                   
{                                                                                                  
{**************************************************************************************************/

import haxe.Utf8;
import neko.Lib;
import p4n.TObject;
import p4n.NekoString;
import p4n.NekoArray;
import p4n.DateTime;

private class I {
	public static dynamic function getSections(_i: Object): NekoStringArray { return null; }
	public static dynamic function readString(_i: Object, Section: String, Key: String, Default: String): NekoString { return null; }
	public static dynamic function readInt(_i: Object, Section: String, Key: String, Default: Int): Int { return null; }
	public static dynamic function readBool(_i: Object, Section: String, Key: String, Default: Bool): Bool { return null; }
	public static dynamic function readDateTime(_i: Object, Section: String, Key: String, Default: DateTime): DateTime { return null; }
	public static dynamic function readFloat(_i: Object, Section: String, Key: String, Default: Float): Float { return null; }
	public static dynamic function readSection(_i: Object, Section: String): NekoStringArray { return null; }
	public static dynamic function readSectionKeys(_i: Object, Section: String): NekoStringArray { return null; }

	public static dynamic function writeString(_i: Object, Section: String, Key: String, val: String) { return null; }
	public static dynamic function writeInt(_i: Object, Section: String, Key: String, val: Int) { return null; }
	public static dynamic function writeBool(_i: Object, Section: String, Key: String, val: Bool) { return null; }
	public static dynamic function writeDateTime(_i: Object, Section: String, Key: String, val: DateTime) { return null; }
	public static dynamic function writeFloat(_i: Object, Section: String, Key: String, val: Float) { return null; }

	public static dynamic function KeyExists(_i: Object, Section: String, Key: String): Bool { return null; }
	public static dynamic function SectionExists(_i: Object, Section: String): Bool { return null; }
	public static dynamic function eraseKey(_i: Object, Section: String, Key: String) { return null; }
	public static dynamic function eraseSection(_i: Object, Section: String) { return null; }
	
	public static dynamic function updateFile(_i: Object) { return null; }
	
	public static dynamic function createIniFile(FileName: String): Object { return null; }
	public static dynamic function createMemIniFile(FileName: String): Object { return null; }
	public static dynamic function createRegIniFile(FileName: String): Object { return null; }
	public static dynamic function createWebIniFile(FileName: String): Object { return null; }

}

class CustomIniFile extends TObject 
{
	var _i: Object;
	public var FileName: String;
	
	public override function release () {
		_i.free();
	}
	
	public function new(i: Object, AFileName: String) {
		_i = i;
		FileName = AFileName;
	}

	public function getSections(): Array < String > { return I.getSections(_i).toArray(); }
	public function readString(Section: String, Key: String, Default: String): String { return I.readString(_i, Section, Key, Default).toString(); }
	public function readStringUtf8(Section: String, Key: String, Default: String): String { return Utf8.encode(I.readString(_i, Section, Key, Default).toString()); }
	public function readInt(Section: String, Key: String, Default: Int): Int { return I.readInt(_i, Section, Key, Default); }
	public function readBool(Section: String, Key: String, Default: Bool): Bool { return I.readBool(_i, Section, Key, Default); }
	public function readDateTime(Section: String, Key: String, Default: DateTime): DateTime { return I.readDateTime(_i, Section, Key, Default); }
	public function readFloat(Section: String, Key: String, Default: Float): Float { return I.readFloat(_i, Section, Key, Default); }
	public function readSection(Section: String): Array < String > { trace(Section); return I.readSection(_i, Section).toArray(); }

	public function readSectionKeys(Section: String): Array < String > { return I.readSectionKeys(_i, Section).toArray(); }

	public function writeString(Section: String, Key: String, val: String) { I.writeString(_i, Section, Key, val); }
	public function writeInt(Section: String, Key: String, val: Int) { I.writeInt(_i, Section, Key, val); }
	public function writeBool(Section: String, Key: String, val: Bool) { I.writeBool(_i, Section, Key, val); }
	public function writeDateTime(Section: String, Key: String, val: DateTime) { I.writeDateTime(_i, Section, Key, val); }
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
	
	#if ! macro
	static public function __init__() {
		var call = null;
		try {
		    var c1 = neko.Lib.load('p4n_std.dll', '_init_std', 1);
			call = c1('p4n_inifiles');
		} catch (e: Dynamic) {
			call = neko.Lib.load('p4n_inifiles.dll', '_init', 1);
		}
		if (call != null) call(I);
		TObject.boot();
	}
	#end
	
}