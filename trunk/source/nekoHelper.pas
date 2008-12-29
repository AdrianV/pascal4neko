{**************************************************************************************************}
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is nekoHelper.pas.                                                             }
{                                                                                                  }
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             }
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                }
{                                                                                                  }
{ Contributors:                                                                                    }
{   Adrian Veith                                                                                   }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ Some usefull (hopefully) routines for the use of the Neko Virtual Machine with Object Pascal.    }
{                                                                                                  }
{**************************************************************************************************}

unit nekoHelper;

interface
uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Types,
  Libc,
  dynlibs,
{$ENDIF}
  SysConst,
  SysUtils,
  Classes,
  neko;

type
  TExportInfo = record
    Name: string;
    Func: Pointer;
    Args: Integer;
  end;

procedure AddExportTable(const ATable: array of TExportInfo; const LibName: string = '');
function AddToNekoTable(old: value; const data: array of value): value;
function EmbeddedLoader(argv: PPChar = nil; argc: Integer = 0): value;
function SplitStringAt(var S: string; const limit: string):string;

implementation

type
  RExportInfo = record
    CFunc: Pointer;
    NArgs: Integer;
  end;
  PExportInfo = ^RExportInfo;

var
  ExportFunc: TStringList;

function SplitStringAt(var S: string; const limit: string):string;
var
	i: integer;
begin
  i:= Pos(limit, s);
  if i > 0 then begin
    Result:= copy(S, 1, i -1);
    s:= copy(S, i + Length(limit), MaxInt);
	end else begin
		result:= S;
		S:= '';
	end;
end;

procedure CleanExport;
var
  i: Integer;
  p: PExportInfo;
begin
  for i := 0 to ExportFunc.Count - 1 do begin
    p:= PExportInfo(ExportFunc.Objects[i]);
    Dispose(p);
  end;
  ExportFunc.Clear;
end;

function AddToNekoTable(old: value; const data: array of value): value;
var
  a: value;
  i, l: Integer;
begin
  l:= Length(data);
  a:= alloc_array(l);
  for i := 0 to l - 1 do
    val_array_ptr(a)[i] := data[i];
  val_array_ptr(a)[l] := old;
  Result:= a;
end;

procedure AddExportTable(const ATable: array of TExportInfo; const LibName: string);
var
  i, x: Integer;
  p: PExportInfo;
  s: string;
begin
  for i := Low(ATable) to High(ATable) do begin
    s:= ATable[i].Name;
    if LibName <> '' then
      s:= LibName + '@' + s;
    if not ExportFunc.Find(s, x) then begin
      New(p);
      ExportFunc.InsertObject(x, s, TObject(p));
    end else begin
      p:= PExportInfo(ExportFunc.Objects[x]);
    end;
    p.CFunc:= ATable[i].Func;
    p.NArgs:= ATable[i].Args;
  end;
end;

function myLoadPrim(prim, nargs: value): value; cdecl;
var
  loader, exc, this: value;
  s: string;
  p: PExportInfo;
  i: Integer;
begin
  this:= val_this;
  if val_is_string(prim) then begin
    s:= val_string(prim); //, 0, '@');
    if ExportFunc.Find(s, i) then begin
      SplitStringAt(s, '@');
      p:= PExportInfo(ExportFunc.Objects[i]);
      Result:= alloc_function(p.CFunc, p.NArgs, PChar(s));
      exit;
    end;
    loader:= val_field(this, val_id('_loader'));
    Result:= val_ocall(loader, val_id('loadprim'), [prim, nargs], @exc);
  end;
end;

function myLoadModule(mname, vthis: value): value; cdecl;
var
  loader, exc, f, this: value;
  args: array [0..1] of value;
begin
  this:= vthis;
  args[0]:= mname;
  args[1]:= vthis;
  loader:= val_field(this, val_id('_loader'));
  f:= val_field(loader, val_id('loadmodule'));
  Result:= val_callEx(loader, f, @args[0], 2, @exc);
end;

function EmbeddedLoader(argv: PPChar; argc: Integer): value;
var
  ol: value;
begin
  ol:= neko_default_loader(argv, argc);
  Result:= alloc_object(ol);
  alloc_field(Result, val_id('_loader'), ol);
	alloc_field(Result, val_id('loadprim'), alloc_function(@myLoadPrim, 2, 'loadprim'));
	alloc_field(Result, val_id('loadmodule'), alloc_function(@myLoadModule, 2, 'loadmodule'));
end;

initialization
  ExportFunc:= TStringList.Create;

finalization
  CleanExport;
  ExportFunc.Free;

end.
