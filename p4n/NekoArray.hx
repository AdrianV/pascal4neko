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
	@:to public inline function toArray(): Array<T> { return NativeArray.toArray(this); }
	@:from static inline public function fromArray(a: Array<T>) { 
		return NativeArray.ofArrayCopy(a); 
	}
}
