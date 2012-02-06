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
{ The Original Code is Tools.hx.                                                                   
{                                                                                                  
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                
{                                                                                                  
{ Contributors:                                                                                    
{   Adrian Veith                                                                                   
{                                                                                                  
{**************************************************************************************************/

package p4n;

#if neko	
import neko.Lib;
import neko.NativeString;
import p4n.MathX;

class Globals implements Dynamic < Dynamic > {
	private var g: Dynamic;
	
	public function new(_g) {
		g = _g;
	}
	public function resolve( name: String): Dynamic {
		return if (g != null) return Reflect.field(g, name) else null;
	}
	public function set(name: String, value: Dynamic) {
		if (g != null) Reflect.setField(g, name, value);
	}
}
#end


class Tools 
{
#if neko	
	static var id__reference__: Int;
	public static function exportObject(o: Dynamic): Dynamic {
		if (o == null) return null;
		untyped {
			var f = __dollar__objfields(o);
			var i = 0;
			var l = __dollar__asize(f);
			while( i < l ) {
				var v = __dollar__objget(o, f[i]);
				switch (__dollar__typeof(v)) {
					case __dollar__tstring: {
						var s = neko.Utf8.encode(new String(v));
						__dollar__objset(o, f[i], s);
					}
					case __dollar__tabstract: __dollar__objset(o, f[i], null); 
					case __dollar__tobject: {
						if (v.__s != null)
							__dollar__objset(o, f[i], neko.Utf8.encode(v));
					}
					case __dollar__tarray: {
						var a = neko.NativeArray.toArray(o); 
						for (i in 0...a.length) exportObject(a[i]); 
						__dollar__objset(o, f[i], a);
					}
					default: {}
				}
				i = i + 1;
			}
		}
		return o;
	}
	public static function exportList<T>(AList: List<T>) 
	{
		
		if (AList == null) return null;
		for (x in AList) { 
			x = exportObject(x);
		}
		return AList;
	}
	

	static public function toHaXe(o: Dynamic): Dynamic {
		
		untyped switch (__dollar__typeof(o)) {
			case __dollar__tstring: return NativeString.toString(o);
			case __dollar__tobject: return NekoToHaxeObject(o);
			case __dollar__tarray: var a = neko.NativeArray.toArray(o); for (i in 0...a.length) a[i] = toHaXe(a[i]); return a;
			default: return o;
		}
	}
	static public function NekoToHaxeObject(o: Dynamic, ? proto: Dynamic, ? toUtf: Bool, ? stripAbstract: Bool): Dynamic {
		if (o == null) return null;
		untyped {
			var f = __dollar__objfields(o);
			//trace(f);
			var i = 0;
			var l = __dollar__asize(f);
			while ( i < l ) {
				var fx = f[i];
				if (stripAbstract && fx == id__reference__) {
					__dollar__objremove(o, fx);
					i++;
					continue;
				}
				var v = __dollar__objget(o, fx);
				switch (__dollar__typeof(v)) {
					case __dollar__tstring:
						if (toUtf == null || !toUtf)
							__dollar__objset(o, fx, new String(v));
						else {
							var s = neko.Utf8.encode(new String(v));
							__dollar__objset(o, fx, s);
						}
					case __dollar__tabstract: if (stripAbstract == true) {__dollar__objremove(o, fx); }
					default: {}
				}
				i++;
			}
		}
		if (proto != null) {
			untyped {
				__dollar__objsetproto(o, proto.prototype);
			}
		}		
		return o;
	}
	static var _app_terminated;
	static var _get_global;
	static var _app_path;
	static public function __init__() {
		untyped {
			var temp = { __reference__: 0 };
			var f = __dollar__objfields(temp);
			id__reference__ = f[0];
		}
		try {
			_app_terminated = Lib.load('p4n', 'app_terminated', 0);
			_app_path = Lib.load('p4n', 'app_path', 0);
		} 
		catch (e: Dynamic) {
			_app_terminated = null;
			_app_path = null;
		}
		try {
			_get_global = Lib.load('p4n', 'get_global', 0);
			global = new Globals(_get_global());
		} 
		catch (e: Dynamic) {
			_get_global = null;
			global = new Globals(null);
		}
	}
	public static var global: Globals;
	static public function AppTerminated(): Bool { return (_app_terminated != null && _app_terminated()); }
	static public function AppPath(): String { return if (_app_path != null) NativeString.toString(_app_path()) else ""; }

#end
	static public inline function frac(value: Float): Float { return MathX.frac(value); }
	static public inline function trunc(value: Float): Float { return MathX.trunc(value); }		
	static public inline function round(x: Float, n: Int): Float { return MathX.round(x, n); }

	static public inline function def < T > (Value: T, DefValue: T): T { return if (Value != null) Value else DefValue; }
	static public function IncludeTrailingPathDelimter(path: String): String {
		var c1 = path.lastIndexOf("/");
		var c2 = path.lastIndexOf("\\");
		if ( c1 < c2 ) {
			return if (c2 < path.length -1) path + '\\' else path;
		} else {
			return if (c1 < path.length -1) path + '/' else path;
		}
	}
}