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

@:coreType abstract Object { }

class TObject {

  public static dynamic function Release(AObject: Object): Bool {
    Release = neko.Lib.load('nekoHelper', 'release', 1); 
    return Release(AObject); 
  }
  
  
  public function release() {}	
}