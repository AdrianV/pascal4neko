/**
 * ...
 * @author ...
 */

package p4n;

#if neko	

class DbgTraceOut 
{
	public static var trace_out(default, set): String->Dynamic->Void;
	
	static public var logFilepos = true;
	static public var logClass = false;
	static public var logMethod = false;
	
	static function set_trace_out(v: String->Dynamic->Void) {
		trace_out = v;
		return v;
	}
	public static dynamic function trace( v : Dynamic, ?infos : haxe.PosInfos ) : Void {
		var prefix = new StringBuf();
		if (infos != null) {
			if (logFilepos) prefix.add(infos.fileName + ":" + infos.lineNumber);
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
