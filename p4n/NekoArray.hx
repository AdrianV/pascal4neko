package p4n;

import neko.NativeString;
import neko.NativeArray;

abstract NekoStringArray(NativeArray<NativeString>) from NativeArray<NativeString> to NativeArray<NativeString> {
	public inline function new(a: NativeArray<NativeString>) {
		this = a;
	}
	/*@:to*/ public function toArray(): Array<String> { 
		untyped {
			var a = Array.new1(this, __dollar__asize(this));
			for( i in 0...a.length )
				a[i] = NativeString.toString(this[i]);
			return a;		
		}
	}
	@:from static public function fromArray(a: Array<String>) { 
		var r: NativeArray<NativeString> = NativeArray.alloc(a.length);
		for (i in 0 ... a.length) r[i] = NativeString.ofString(a[i]);
		return r; 
	}
}

abstract NekoArray<T>(NativeArray<T>) from NativeArray<T> to NativeArray<T> {
	public inline function new(a: NativeArray<T>) {
		this = a;
	}
	@:to public inline function toArray(): Array<T> { 
		return NativeArray.toArray(this); 
	}
	
	public function toArrayDeep(): Array<T> { 
		var x = toHaxeInplace(this);
		return x;
		//return deep ? (toHaxeInplace((this: Dynamic)): Array<T>) : NativeArray.toArray(this); 
		
	}
	
	@:from static inline public function fromArray<T>(a: Array<T>) { 
		return NativeArray.ofArrayCopy(a); 
	}
	
	public static function toHaxeInplace(o: Dynamic): Dynamic {
		if (o != null) untyped { 
			switch( __dollar__typeof(o) ) {
				case 0: return o;
				case 1: return o;
				case 2: return o;
				case 3: return o;
				case 4: 
					return new String(o);
				case 6:
					var l = __dollar__asize(o);
					var a = Array.new1(o, l);
					for ( i in 0...l ) {
						a[i] = toHaxeInplace(a[i]);
					}
					return a;
				case 5: 
					//trace("is object ", o);
					var f = __dollar__objfields(o);
					var i = 0;
					var l = __dollar__asize(f);
					while( i < l ) {
						var v: Dynamic = __dollar__objget(o, f[i]);
						var t = __dollar__typeof(v);
						if (t == __dollar__tstring) {
							__dollar__objset(o, f[i], new String(v));
						//} else if (t == __dollar__tabstract) { 
							//__dollar__objset(o, f[i], null); 
						} else if (t == __dollar__tobject) {
							__dollar__objset(o, f[i], toHaxeInplace(v));
						} else if (t== __dollar__tarray) {
							var a = neko.NativeArray.toArray(v); 
							for (i in 0...a.length) toHaxeInplace(a[i]); 
							__dollar__objset(o, f[i], a);
						}
						i = i + 1;
					}
					return o;
				default: 
					return o;
					//throw "Can't convert "+string(v);
			}
		}
		return null;
	}
	
}
