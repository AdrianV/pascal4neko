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
  neko, p4nHelper;

type
  TExportInfo = record
    Name: string;
    Func: Pointer;
    Args: Integer;
  end;
  TCustomConvert = function(const s: string): value;
  TArrayOfConst = array of TVarRec;

procedure AddExportTable(const ATable: array of TExportInfo; const LibName: string = '');
function AddToNekoTable(old: value; const data: array of value): value;
function AddValueArrays(const first, second: array of value): TNekoArray;
function ArrayToArrayOfConst(v: value): TArrayOfConst;
function ArrayToArrayOfString(v: value): TDynamicStringArray;
procedure ClearExportTable(const ATable: array of TExportInfo; const LibName: string);
function DeclareClass(cl, proto: value; const Name, Super: string; New: Pointer; NParams: Integer; Cons: Pointer = nil): value; //returns prototype
function EmbeddedLoader(argv: PPChar = nil; argc: Integer = 0): value;
function NewNekoInstance(out AInstance:Value): Value;
function ValueToVariant(v: value): Variant;
function VariantToValue(v: Variant): value;

var
  custom_convert1: TCustomConvert = nil;
  custom_convert2: TCustomConvert = nil;
  custom_convert3: TCustomConvert = nil;

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

function AddValueArrays(const first, second: array of value): TNekoArray;
var
  i, l1: Integer;
begin
  l1:= Length(first);
  SetLength(Result, l1 + Length(second));
  for i := 0 to l1 - 1 do
    Result[i]:= first[i];
  for i := 0 to High(second) do
    Result[l1 + i]:= second[i];
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
        if p.CFunc <> nil then 
          Result:= alloc_function(p.CFunc, p.NArgs, PChar(s))
        else
          Result:= val_null;
        exit;
      end;
    finally
      ExportProtect.Release;
    end;
    loader:= val_field(this, val_id('_loader'));
    Result:= val_ocall(loader, val_id('loadprim'), [prim, nargs], @exc);
  end else Result:= val_null;
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
      SetProto(proto, val_field(a, id_prototype)); //.proto;
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
    SetProto(Result , cl);
    AInstance:= Result;
  end;
end;

procedure AssignConst(var res: TVarRec; v: value);
var
  t: value;
begin
  res.VType:= vtAnsiString;
  res.VAnsiString:= nil;
  if not val_is_null(v) then begin
    if val_is_int(v) then begin
      res.VType:= vtInteger;
      res.VInteger:= val_int(v);
    end else begin
      case v^.t and 7 of
        cVAL_NULL: begin

        end;
        cVAL_FLOAT: begin
          res.VType:= vtExtended;
          New(res.VExtended);
          res.VExtended^:= val_float(v);
        end;
        cVAL_BOOL: begin
          res.VType:= vtBoolean;
          res.VBoolean:= v = val_true;
        end;
        cVAL_STRING: begin
          //res.VType:= vtAnsiString;
          //res.VAnsiString:= nil;
          AnsiString(res.VAnsiString):= val_string(v);
        end;
        cVAL_OBJECT: begin
          t:= val_field(v, id_string);
          if val_is_string(t) then begin
            AnsiString(res.VAnsiString):= val_string(t);
          end else begin
            AnsiString(res.VAnsiString):= ValueToString(v);
          end;
        end;
        cVAL_ARRAY: ;
        cVAL_FUNCTION: ;
        cVAL_ABSTRACT: ;
      end;
    end;
  end;
end;

function ArrayToArrayOfConst(v: value): TArrayOfConst;

  procedure BuildArray(a: value);
  var
    ai: TArrayInfo;
    i: Integer;
  begin
    ai.FromValue(a);
    SetLength(Result, ai.l);
    for i:= 0 to ai.l - 1 do
      AssignConst(Result[i], ai.Get(i, val_null))
  end;

  procedure FromValue(const val: array of const);
  begin
    SetLength(Result, 1);
    Result[0]:= val[0];
  end;

var
  t: value;
begin
  Result:= nil;
  if not val_is_null(v) then begin
    if val_is_int(v) then begin
      FromValue([val_int(v)]);
    end else begin
      case v^.t and 7 of
        cVAL_NULL: begin

        end;
        cVAL_FLOAT: FromValue([val_float(v)]);
        cVAL_BOOL: FromValue([v = val_true]);
        cVAL_STRING: FromValue([val_string(v)]);
        cVAL_OBJECT: begin
          t:= val_field(v, id_string);
          if val_is_string(t) then
            FromValue([val_string(t)])
          else begin
            t:= val_field(v, id_array);
            if val_is_array(t) then
              BuildArray(t)
            else
              FromValue([ValueToString(v)]);
          end;
        end;
        cVAL_ARRAY: BuildArray(v);
        cVAL_FUNCTION: ;
        cVAL_ABSTRACT: ;
      end;
    end;
  end;
end;

function ArrayToArrayOfString(v: value): TDynamicStringArray;
var
  arr: TArrayInfo;
  i: Integer;
begin
  Result:= nil;
  arr.FromValue(v);
  if arr.l > 0 then begin
    SetLength(Result, arr.l);
    for i := 0 to arr.l - 1 do
      Result[i]:= val_HaxeString(arr.Get(i, val_null));
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

function VariantToValue(v: Variant): value;
var
  pVar: PVarData;
begin
  pVar:= FindVarData(v);
  case pVar^.VType of
    varNull, varUnknown: Result:= val_null;
    varSmallint, varInteger, varShortInt, varWord:
        Result:= alloc_int(v);
    varSingle, varDouble, varCurrency, varDate:
        Result:= alloc_float(v);
    varBoolean: Result:= alloc_bool(v);
    varString: begin
      if (pVar^.VString = nil) then begin
        Result:= alloc_string('');
      end else begin
        case String(pVar^.VString)[1] of
          #1: if @custom_convert1 <> nil then
                Result:= custom_convert1(String(pVar^.VString))
              else Result:= alloc_string(String(pVar^.VString));
          #2: if @custom_convert2 <> nil then
                Result:= custom_convert2(String(pVar^.VString))
              else Result:= alloc_string(String(pVar^.VString));
          #3: if @custom_convert3 <> nil then
                Result:= custom_convert3(String(pVar^.VString))
              else Result:= alloc_string(String(pVar^.VString));
          else Result:= alloc_string(String(pVar^.VString));
        end;
      end;
    end;
    else
      Result:= alloc_string(v);
  end;
end;


initialization
  ExportProtect:= TCriticalSection.Create;

finalization
  CleanExport;
  FreeAndNil(ExportFunc);
  FreeAndNil(ExportProtect);

end.
