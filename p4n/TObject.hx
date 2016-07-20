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
{ The Original Code is TObject.hx.                                                                   
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

@:coreType abstract Object { 
	static dynamic function _className(self: Object): NekoString {
		_className = neko.Lib.load('nekoHelper', 'classname', 1); 
		return _className(self); 	  
	}
	static dynamic function _free(self: Object): Bool {
		_free = neko.Lib.load('nekoHelper', 'release', 1); 
		return _free(self); 
	}
	
	public inline function free() return _free(this);
	public var className(get, never): String;
	private inline function get_className() return _className(this).toString();
}


class TObject {

	public static var _classes: Dynamic;
      
	public function release() { }	
	
	#if !macro
	static public function __init__() {
		untyped _classes = neko.Boot.__classes;
		var _init = neko.Lib.load('nekoHelper', '_init', 1);
		if (_init != null) _init(TObject);
	}
	#end
}

#end