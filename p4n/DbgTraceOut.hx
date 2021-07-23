/**
 * ...
 * @author ...
 */

package p4n;

#if neko	

@:keepInit
class DbgTraceOut 
{
	public static var trace_out(default, set): String->Dynamic->Void;
	
	static public var shortFilename = true;	
	static public var logModule = false;
	static public var logFilepos = true;
	static public var logClass = false;
	static public var logMethod = false;
	
	static var _moduleName: String = null;

	static function set_trace_out(v: String->Dynamic->Void) {
		trace_out = v;
		return v;
	}

	static inline function filePos(fileName: String, lineNumber: Int) {
		return if (shortFilename) {
			final fn = haxe.io.Path.withoutDirectory(fileName);
			'$fn.$lineNumber';
		} else 
			'$fileName.$lineNumber';
	}

	static function getModuleName() {
		final n = haxe.io.Path.withoutDirectory(neko.vm.Module.local().name) + ': ';
		_moduleName = n;
		return n;
	}

	static inline function moduleName() {
		return (_moduleName != null) ?	_moduleName : getModuleName();
	}

	public static dynamic function trace( v : Dynamic, ?infos : haxe.PosInfos ) : Void {
		var prefix = new StringBuf();
		if (infos != null) {
			if (logModule) prefix.add(getModuleName());
			if (logFilepos) prefix.add(filePos(infos.fileName, infos.lineNumber));
			if (logClass) prefix.add(":" + infos.className);
			if (logMethod) prefix.add("." + infos.methodName);
			prefix.add(": ");
		}
		trace_out(prefix.toString(), v);
	}
	static public function __init__() {
		try {	
			trace_out = neko.Lib.load('p4n', 'trace_out', 2);
		} catch (e: Dynamic) { trace_out = null; }
		if (trace_out != null) {
			haxe.Log.trace = trace;
		}
	}
	
}
#end
