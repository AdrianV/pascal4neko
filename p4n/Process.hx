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
{ The Original Code is Process.hx.                                                                   
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
import neko.NativeString;
import p4n.TObject;

private class I {
	public static dynamic function getState(_p: Object): CPSState { return null; }
	public static dynamic function setHandler(_p: Object, onRead: NativeString->Bool->Void, onTerminate:Int->Void, onError: NativeString->Bool->Void): Void {}
	public static dynamic function startProcess(_p: Object, cmd: String, ?args: Array<String>): Void {}
	public static dynamic function terminate(_p: Object): Void {}
	public static dynamic function write(_p: Object, s: String): Void {}
	public static dynamic function writeln(_p: Object, s: String): Void {}
	public static dynamic function createProcess(): Object { return null; }
}

@:enum abstract CPSState(Int) to Int {
	var psReady = 0;
	var psRunning = 1;
	var psWaiting = 2;
}

class Process {

	private var _p: Object;
	public function new() {
		_p = I.createProcess();
	}
	public function free() {
		_p = null;
	}

	public function getState(): CPSState { 
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
