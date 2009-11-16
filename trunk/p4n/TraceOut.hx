/**
 * ...
 * @author ...
 */

package p4n;

#if neko	

class TraceOut 
{
	static var trace_out;
	public static dynamic function trace( v : Dynamic, ?infos : haxe.PosInfos ) : Void {
		trace_out(infos.fileName + ":" + infos.lineNumber + ": ", v);
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
