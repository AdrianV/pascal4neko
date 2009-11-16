/**
 * ...
 * @author Adrian Veith
 */

package p4n;

#if neko
import neko.NativeString;

private class I {
	public static function getState(_p: Void): Int { return null; }
	public static function setHandler(_p: Void, onRead: NativeString->Bool->Void, onTerminate:Int->Void, onError: NativeString->Bool->Void): Void;
	public static function startProcess(_p: Void, cmd: String, ?args: Array<String>): Void;
	public static function terminate(_p: Void): Void;
	public static function write(_p: Void, s: String): Void;
	public static function writeln(_p: Void, s: String): Void;
	public static function createProcess(): Void;
}

class Process {

	private var _p: Void;
	public function new() {
		_p = I.createProcess();
	}
	public function free() {
		_p = null;
	}

	public function getState(): Int { 
		return I.getState(_p); 
	}

	public function setHandler(onRead: NativeString->Bool->Void, onTerminate:Int->Void, onError: NativeString->Bool->Void): Void 
	{ 
		I.setHandler(_p, onRead, onTerminate, onError);
	}
	public function startProcess(cmd: String, ?args: Array<String>): Void
	{
		I.startProcess(_p, cmd, args);
	}
	public function terminate(): Void
	{
		I.terminate(_p);
	}
	public function write(s: String): Void
	{
		I.write(_p, s);
	}
	public function writeln(s: String): Void
	{
		I.writeln(_p, s);
	}
	
	static public function __init__() {
		neko.Lib.load('p4n_process.dll', '_init', 1) (I);
	}
	
}
#end
