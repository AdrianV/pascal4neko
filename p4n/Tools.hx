/**
 * ...
 * @author ...
 */

package p4n;

#if neko	
import neko.Lib;
import neko.NativeString;

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
			var i = 0;
			var l = __dollar__asize(f);
			while( i < l ) {
				var v = __dollar__objget(o, f[i]);
				switch (__dollar__typeof(v)) {
					case __dollar__tstring:
						if (toUtf == null || !toUtf)
							__dollar__objset(o, f[i], new String(v));
						else {
							var s = neko.Utf8.encode(new String(v));
							__dollar__objset(o, f[i], s);
						}
					case __dollar__tabstract: if (stripAbstract == true) {__dollar__objset(o, f[i], null); }
					default: {}
				}
				i = i + 1;
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
	static public inline function frac(value: Float): Float {
		return if (value >= 0) value - Math.floor(value) else value - Math.ceil(value);
	}
	static public inline function trunc(value: Float): Float {
		return if (value >= 0) Math.floor(value) else Math.ceil(value);
	}
	
	static var stellen = [0.00000001,0.0000001,0.000001,0.00001,0.0001,0.001,0.01,0.1,
		1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0];
		
	static public function round(x: Float, n: Int): Float {
		if ((n > 8) || (n < -8)) {
			return x;
		} else {
			var sf = stellen[n + 8];
			var xx = x * sf;
			return (trunc(xx) + trunc(frac(xx) * 2)) / sf;
		}
	}
	
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