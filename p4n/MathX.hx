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
{ The Original Code is MathX.hx.                                                                   
{                                                                                                  
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                
{                                                                                                  
{ Contributors:                                                                                    
{   Adrian Veith                                                                                   
{                                                                                                  
{**************************************************************************************************/

package p4n;

@:expose class MathX 
{
	static public inline function frac(value: Float): Float {
		return if (value >= 0) value - Math.floor(value) else value - Math.ceil(value);
	}

	static public inline function trunc(value: Float): Float {
		return if (value >= 0) Math.floor(value) else Math.ceil(value);
	}
	
	static var stellen = [0.00000001,0.0000001,0.000001,0.00001,0.0001,0.001,0.01,0.1,
		1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0];
		
	static public function round(x: Float, n: Int): Float {
		if ((n > 8) || (n < -8)) {
			return x;
		} else {
			var sf = stellen[n + 8];
			var xx = x * sf;
			return (trunc(xx) + trunc(frac(xx) * 2)) / sf;
		}
	}
	
	static public function roundUp(x: Float, n: Int): Float {
		if ((n > 8) || (n < -8)) {
			return x;
		} else {
			var sf = stellen[n + 8];
			var xx = x * sf;
			if (frac(xx) > 0) xx += 1;
			return trunc(xx) / sf;
		}
	}

	static public function roundDown(x: Float, n: Int): Float {
		if ((n > 8) || (n < -8)) {
			return x;
		} else {
			var sf = stellen[n + 8];
			var xx = x * sf;
			return trunc(xx) / sf;
		}
	}
	
}