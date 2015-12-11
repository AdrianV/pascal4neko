package p4n;

import neko.NativeString;

abstract NekoString(NativeString) from NativeString to NativeString {
	public inline function new(s: String) {
		this = NativeString.ofString(s);
	}
	@:to public inline function toString(): String { return NativeString.toString(this); }
	@:from static public inline function fromString(s: String) { return new NekoString(s); }
}
