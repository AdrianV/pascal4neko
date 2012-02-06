/**
 * ...
 * @author ...
 */

package p4n;

#if neko	

class DbgTraceOut 
{
	public static var trace_out(default, setTraceOut): String->Dynamic->Void;
	
	static function setTraceOut(v: String->Dynamic->Void) {
		trace_out = v;
		return v;
	}
	public static dynamic function trace( v : Dynamic, ?infos : haxe.PosInfos ) : Void {
		trace_out(if (infos != null) infos.fileName + ":" + infos.lineNumber + ": " else "", v);
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
