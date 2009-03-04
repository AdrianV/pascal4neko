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
{$INCLUDE nekoDefs.inc}

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
{$IFDEF COMPILER6_UP}
  Variants,
{$ENDIF}
{$IFDEF FPC}
	Variants,
{$ENDIF}
  Classes,
  SyncObjs,
  neko;

type
  TExportInfo = record
    Name: string;
    Func: Pointer;
    Args: Integer;
  end;

procedure AddExportTable(const ATable: array of TExportInfo; const LibName: string = '');
function AddToNekoTable(old: value; const data: array of value): value;
procedure ClearExportTable(const ATable: array of TExportInfo; const LibName: string);
function DeclareClass(cl, proto: value; const Name, Super: string; New: Pointer; NParams: Integer; Cons: Pointer = nil): value; //returns prototype
function EmbeddedLoader(argv: PPChar = nil; argc: Integer = 0): value;
function NewNekoInstance(out AInstance:Value): Value;
function SplitString(var S: string; const limit: string):string;
function ValueToVariant(v: value): Variant;

implementation

type
  RExportInfo = record
    CFunc: Pointer;
    NArgs: Integer;
  end;
  PExportInfo = ^RExportInfo;

var
  ExportFunc: TStringList;
  ExportProtect: TCriticalSection;

function SplitString(var S: string; const limit: string):string;
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
  if ExportFunc = nil then exit;
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
  ExportProtect.Acquire;
  try
    if ExportFunc = nil then ExportFunc:= TStringList.Create;
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
  finally
    ExportProtect.Release;
  end;
end;

procedure ClearExportTable(const ATable: array of TExportInfo; const LibName: string);
var
  i, x: Integer;
  s: string;
begin
  if ExportFunc = nil then exit;
  ExportProtect.Acquire;
  try
    for i := Low(ATable) to High(ATable) do begin
      s:= ATable[i].Name;
      if LibName <> '' then
        s:= LibName + '@' + s;
      if ExportFunc.Find(s, x) then begin
        ExportFunc.Delete(x);
      end;
    end;
  finally
    ExportProtect.Release;
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
    ExportProtect.Acquire;
    try
      if Assigned(ExportFunc) and ExportFunc.Find(s, i) then begin
        SplitString(s, '@');
        p:= PExportInfo(ExportFunc.Objects[i]);
        Result:= alloc_function(p.CFunc, p.NArgs, PChar(s));
        exit;
      end;
    finally
      ExportProtect.Release;
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

function DeclareClass(cl, proto: value; const Name, Super: string; New: Pointer; NParams: Integer; Cons: Pointer = nil): value; //returns prototype
var
  a: value;
begin
  if Cons=nil then
    Cons:= New;
  Result:= alloc_object(nil);
  a:= alloc_array(1);
  val_array_ptr(a)^[0]:= alloc_string(Name);
  alloc_field(Result, id__name__, a);
  alloc_field(Result, id_new, alloc_function(New, NParams, 'new'));
  alloc_field(Result, id__construct__, alloc_function(Cons, NParams, '__construct__'));
  if Super <> '' then begin
    a:= val_field(cl, val_id(PChar(Super)));
    if val_is_object(a) then begin
      alloc_field(Result, id__super__, a);
      vobject(proto).proto:= vobject(val_field(a, id_prototype)); //.proto;
      //Result:= val_field(a, id__super__);
    end;
  end;
  alloc_field(proto, id__class__, Result);
  alloc_field(Result, id_prototype, proto);
  alloc_field(cl, val_id(PChar(Name)), Result);
end;

function NewNekoInstance(out AInstance:Value): Value;
var
  cl: value;
begin
  AInstance:= val_null;
  Result:= val_this;
  cl:= val_field(Result, id_prototype);
  if val_is_object(cl) then begin
    //Result:= alloc_object(cl);
    Result:= alloc_object(nil);
    vobject(Result).proto:= vobject(cl);
    AInstance:= Result;
  end;
end;

function ValueToVariant(v: value): Variant;

  function ArrayToVariant(a: value): Variant;
  var
    ai: TArrayInfo;
    i: Integer;
  begin
    ai.FromValue(a);
    Result:= VarArrayCreate([0, ai.l], varVariant);
    for i := 0 to ai.l - 1 do
      Result[i]:= ValueToVariant(ai.Get(i, val_null));
  end;

var
  t: value;
begin
  Result:= Null;
  if not val_is_null(v) then begin
    if val_is_int(v) then
      Result:= val_int(v)
    else begin
      case v^.t and 7 of
        cVAL_NULL: begin

        end;
        cVAL_FLOAT: Result:= val_float(v);
        cVAL_BOOL: Result:= v = val_true;
        cVAL_STRING: Result:= String(val_string(v));
        cVAL_OBJECT: begin
          t:= val_field(v, id_string);
          if val_is_string(t) then
            Result:= String(val_string(t))
          else begin
            t:= val_field(v, id_array);
            if val_is_array(t) then
              Result:= ArrayToVariant(t)
            else
              Result:= ValueToString(v);
          end;
        end;
        cVAL_ARRAY: Result:= ArrayToVariant(v);
        cVAL_FUNCTION: ;
        cVAL_ABSTRACT: ;
      end;
    end;
  end;
end;

initialization
  ExportProtect:= TCriticalSection.Create;

finalization
  CleanExport;
  FreeAndNil(ExportFunc);
  FreeAndNil(ExportProtect);

end.
