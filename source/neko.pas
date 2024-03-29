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
{ The Original Code is neko.pas.                                                                   }
{                                                                                                  }
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             }
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                }
{                                                                                                  }
{ Contributors:                                                                                    }
{   Adrian Veith                                                                                   }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ Translation of the Neko Virtual Machine Header for Object Pascal.                                }
{                                                                                                  }
{**************************************************************************************************}

unit neko;
{$MINSTACKSIZE $200000}

interface
{$IFDEF VER180}
  {$DEFINE COMPILER_INLINE}
	{$DEFINE COMPILER7}
	{$DEFINE COMPILER6_UP}
	{$DEFINE COMPILER5_UP}
  {$DEFINE COMPILER10_UP}
{$ENDIF}
{$IFDEF VER170}
  {$DEFINE COMPILER_INLINE}
	{$DEFINE COMPILER7}
	{$DEFINE COMPILER6_UP}
	{$DEFINE COMPILER5_UP}
{$ENDIF}

{$IFDEF VER160}
	{$DEFINE COMPILER7}
	{$DEFINE COMPILER6_UP}
	{$DEFINE COMPILER5_UP}
{$ENDIF}

{$IFDEF VER150}
	{$DEFINE COMPILER7}
	{$DEFINE COMPILER6_UP}
	{$DEFINE COMPILER5_UP}
{$ENDIF}

{$IFDEF VER140}
	{$DEFINE COMPILER6}
{$ENDIF}

{$IFDEF VER130}
	{$DEFINE COMPILER5}
{$ENDIF}

{$IFNDEF MSWINDOWS}
	{$IFDEF WIN32}
		{$DEFINE MSWINDOWS}
	{$ENDIF}
{$ENDIF}

{$IFDEF COMPILER6}
	{$DEFINE COMPILER6_UP}
	{$DEFINE COMPILER5_UP}
{$ENDIF}

{$IFDEF COMPILER5}
	{$DEFINE COMPILER5_UP}
{$ENDIF}

{$IFDEF FPC}
  {$ASMMODE intel}
  {$MODE delphi}
  {$DEFINE COMPILER_INLINE}
{$ENDIF}

{.$UNDEF COMPILER_INLINE}
{$IFDEF COMPILER_INLINE}
{$INLINE ON}
{$ENDIF}

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
  //Forms,
  p4nHelper,
  Classes;

{$IFDEF FPC}
{$PACKRECORDS C}
{$ELSE}
{$ALIGN 2} //????
{$ENDIF}

{$define neko_2_0}
{$define xNEKO_DEBUG}
const
{$IFDEF MSWINDOWS}
{$ifdef NEKO_DEBUG}
  neko_library = 'neko-debug.dll'; {Setup as you need}
{$else}
  neko_library = 'neko.dll'; {Setup as you need}
{$ENDIF}
{$ENDIF}
{$IFDEF LINUX}
  neko_library = 'libneko.so'; {Setup as you need}
{$ENDIF}

  cVAL_INT = $FF;
  cVAL_NULL = 0;
  cVAL_FLOAT = 1;
  cVAL_BOOL = 2;
  cVAL_STRING = 3;
  cVAL_OBJECT = 4;
  cVAL_ARRAY = 5;
  cVAL_FUNCTION = 6;
  cVAL_ABSTRACT = 7;
  cVAL_INT32 = 8;
  cVAL_PRIMITIVE = 6 or 16;
  cVAL_JITFUN = 6 or 32;
{$ifdef neko_very_old}
  cVAL_PRIMITIVE = 6 or 8;
  cVAL_JITFUN = 6 or 16;
{$endif}
  cVAL_32_BITS = $FFFFFFFF;
  VAR_ARGS = -1;
  max_array_size	=	((1 shl 29) - 1);
  max_string_size	=	((1 shl 29) - 1);
  invalid_comparison =	$FE;
  cTAG_BITS = 4;

type
  Tint_val = IntPtr; // !! not 64 bit compatible
  Pint_val = ^Tint_val;
  Tval_type =  Longword;
  Tfield = Longword;
  Tvalue = record
    t : Tval_type;
  end;
  value = ^Tvalue;
  Pvalue = ^value;

  Tobjcell = record
    id: Tfield;
    v: value;
  end;
  Pobjcell = ^Tobjcell;
  Tobjcells = array[0..1000] of Pobjcell;
  Pobjcells = ^Tobjcells;

  Tobjtable = record
    count: Longint;
    cells: Pobjcells;
  end;

  Tbuffer = record
  end;


  Tvkind = record
    __zero : longint;
  end;
  vkind = ^Tvkind;

  val_array = array [0..MaxInt div (sizeof(value)+1)] of value;
  Pval_array = ^val_array;
  TNekoArray = array of value;
  TArrayInfo = record
    a: Pval_array;
    l: Integer;
    function FromValue(v: value): Boolean;
    function Get(Index: Integer; Def: value): value; inline;
    function SetVal(Index: Integer; val: value): value; inline;
    function toArray(): TNekoArray; inline;
  end;
  Pobjtable = ^Tobjtable;

  Pbuffer = ^Tbuffer;

  Tfloat = double;
  ENekoException = class(Exception)
  public
    constructor CreateExc(Exc: value);
  end;




{$ALIGN 4}
type

  Tvfloat = record
    t : Tval_type;
    f : Tfloat;
  end;
  vfloat = ^Tvfloat;

{$IFDEF FPC}
{$PACKRECORDS C}
{$ELSE}
{$ALIGN 2} //????
{$ENDIF}

type
  vobject181 = ^Tvobject181;
  Tvobject181 = record
    t : Tval_type;
    table : Tobjtable;
    proto : vobject181;
  end;
  vobject180 = ^Tvobject180;
  Tvobject180 = record
    t : Tval_type;
    table : Pobjtable;
    proto : vobject180;
  end;
  Tneko_vm = record
    sp: Pint_val;
    csp: Pint_val;
    env: value;
    vthis: value;
    spmin: Pint_val;
    spmax: Pint_val;
    trap: Pint_val;
    jit_val: Pointer;
  end;
  Pneko_vm = ^Tneko_vm;

  Tvfunction = record
    t : Tval_type;
    nargs : longint;
    addr : pointer;
    env : value;
    module : pointer;
  end;
  vfunction = ^Tvfunction;

  Tvstring = record
    t : Tval_type;
    c : char;
  end;
  vstring = ^Tvstring;

  Tvarray = record
    t : Tval_type;
    ptr : value;
  end;
  varray = ^Tvarray;

  Tvabstract = record
    t : Tval_type;
    kind : vkind;
    data : pointer;
  end;
  vabstract = ^Tvabstract;
  
  Tvint32 = record
    t : Tval_type;
    i : longint;
  end;
  nvint32 = ^Tvint32;

  Phcell = ^Thcell;
  Thcell = record
    hkey : longint;
    key : value;
    val : value;
    next : Phcell;
  end;

  Tvhash = record
    cells : ^Phcell;
    ncells : longint;
    nitems : longint;
  end;
  vhash = ^Tvhash;

  Tneko_debug = record
  	base: Integer;
	  bits: UINT;
  end;
  neko_debug = ^Tneko_debug;

  Tneko_module = record
  	jit: Pointer;
	  nglobals: UINT;
	  nfields: UINT;
	  codesize: UINT;
	  name: value;
	  globals: Pvalue;
	  fields: Pvalue;
	  loader: value;
	  _exports: value;
	  dbgtbl: value;
	  dbgidxs: neko_debug;
	  code: Pint_val;
	  jit_gc: value;
  end;
  Pneko_module = ^Tneko_module;
  mt_local = type Pointer;
  mt_lock = type Pointer;

  readp = Pointer;

  Tfinalizer = procedure (v: value);cdecl;
  Tneko_printer = procedure (const data: PAnsiChar; size: Integer; param: Pointer); cdecl;
  Tthread_main_func = procedure (param: Pointer); cdecl;
  Tneko_stat_func = procedure(vm: Pneko_vm; const kind: PAnsiChar; start: Integer); cdecl;

  TFieldIterProc_c_prim = procedure ( v: value; f: Tfield; data: Pointer); cdecl;
  TFieldIterProc = procedure ( v: value; f: Tfield; data: Pointer);
  TFieldIterMethod = procedure ( v: value; f: Tfield; data: Pointer) of object;
  TReaderProc = function (p: readp; buf: Pointer; size: Integer): Integer; cdecl;


function alloc_bool(v: Boolean): value; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function alloc_best_int(i : longint) : value; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function alloc_int(v : longint) : value; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function need_32_bits(i : longint) : Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_kind(v: value): vkind; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_data(v: value): Pointer; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function get_val_int32(v: value): LongInt; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_fun_nargs(f: value): Integer; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}

function val_is_null(v : value) : Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_tag(v: value): Tval_type; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_short_tag(v: value): Tval_type; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_int(v : value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_bool(v : value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_number(v : value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_float(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_string(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_function(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF} overload;
function val_is_function(v: value; n: Integer): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF} overload;
function val_is_object(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_array(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_abstract(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_kind(v: value; k: vkind): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_int32(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
procedure val_check_kind(v: value; k: vkind); {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
procedure val_check_function(f: value; n: Integer); //{$IFDEF COMPILER_INLINE} inline; {$ENDIF}
procedure val_check_object(v: value); {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
procedure val_check_string(v: value); {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_type(v: value): Tval_type; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_int(v: value): Integer;  {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_float(v: value): Double; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_bool(v: value): Boolean; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_int32(v: value): Integer; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_number(v: value): Double;
function val_hdata(v: value): vhash; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_string(v: value): PAnsiChar; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_strlen(v: value): Integer; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
procedure val_set_length(v: value; len: Integer);
function val_array_size(v: value): Integer; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_array_ptr(v: value): Pval_array; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function get_array(v: value): TNekoArray; overload;
function get_array(p: Pvalue; cnt: Integer): TNekoArray; overload;
function alloc_string(const S: string): value; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_call(f: value; const args: array of value; exc: Pvalue = nil): value; //{$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_ocall(o: value; f: Tfield; const args: array of value; exc: Pvalue = nil): value; //{$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function val_is_HaxeString(v: value): Boolean;
function val_HaxeString(v: value): string;
function val_HaxePChar(v: value): PAnsiChar;
function toId(const s: AnsiString): TField; inline;

var
  alloc_abstract: function (k: vkind; data: Pointer): value; cdecl;
  _alloc_string: function (const v: PAnsiChar): value; cdecl;
  alloc_float: function(v: Tfloat): value; cdecl;
  alloc_empty_string: function(size: Cardinal): value; cdecl;
  copy_string: function(const str: PAnsiChar; size: Tint_val): value; cdecl;
  val_this: function: value; cdecl;
  val_id: function(const name: PAnsiChar): Tfield; cdecl;
  val_field: function(o: value; f: Tfield): value; cdecl;
  alloc_object: function(o: value): value; cdecl;
  alloc_field: procedure(o: value; f: Tfield; v: value); cdecl;
  val_iter_fields: procedure(o: value; iter: TFieldIterProc_c_prim; data: Pointer); cdecl;
  val_field_name: function(f: Tfield): value; cdecl;
  alloc_array: function(n: Cardinal): value; cdecl;
  val_call0: function(f: value): value; cdecl;
  val_call1: function(f, arg: value): value; cdecl;
  val_call2: function(f, arg1, arg2: value): value; cdecl;
  val_call3: function(f, arg1, arg2, arg3: value): value; cdecl;
  val_callN: function(f: value; args: Pvalue; nargs: Integer): value; cdecl;
  val_ocall0: function(o: value; f: Tfield): value; cdecl;
  val_ocall1: function(o: value; f: Tfield; arg: value): value; cdecl;
  val_ocall2: function(o: value; f: Tfield; arg1, arg2: value): value; cdecl;
  val_ocallN: function(o: value; f: Tfield; args: Pvalue; nargs: Integer): value; cdecl;
  val_callEx: function(vthis: value; f: value; args: Pvalue; nargs: Integer; exc: Pvalue): value; cdecl;
  alloc_root: function(nvals: Cardinal): Pvalue; cdecl;
  free_root: procedure(r: Pvalue); cdecl;
  alloc: function(nbytes: Cardinal): Pointer; cdecl;
  alloc_private: function(nbytes: Cardinal): Pointer; cdecl;
  alloc_function: function(c_prim: Pointer; nargs: Cardinal; const name: PAnsiChar): value; cdecl;
  alloc_buffer: function(const init: PAnsiChar): Pbuffer; cdecl;
  buffer_append: procedure(b: Pbuffer; const s: PAnsiChar); cdecl;
  buffer_append_sub: procedure(b: Pbuffer; const s: PAnsiChar; len: Tint_val); cdecl;
  buffer_append_char: procedure(b: Pbuffer; c: Char); cdecl;
  buffer_to_string: function(b: Pbuffer): value; cdecl;
  val_buffer: procedure(b: Pbuffer; v: value); cdecl;
  val_compare: function(a, b: value): Integer; cdecl;
  val_print: procedure(s: value); cdecl;
  val_gc: procedure(v: value; f: Tfinalizer); cdecl;
  val_throw: procedure(v: value); cdecl;
  val_rethrow: procedure(v: value); cdecl;
  val_hash: function(v: value): Integer; cdecl;
  kind_export: procedure(k: vkind; const name: PAnsiChar); cdecl;
  kind_import: function(const name: PAnsiChar): vkind; cdecl;
  _neko_failure: procedure(msg: value; const AFile: PAnsiChar; line: Integer); cdecl;

  neko_global_init: procedure(s: Pointer); cdecl;
  neko_set_stack_base: procedure(s: Pointer); cdecl;
  neko_global_free: procedure; cdecl;
  neko_gc_major: procedure; cdecl;
  neko_gc_loop: procedure; cdecl;
  neko_gc_stats: procedure(var Aheap, Afree: Integer); cdecl;
  neko_thread_create: function(init, main: Tthread_main_func; param: Pointer; var handle: Pointer): Integer; cdecl;
  neko_thread_blocking: procedure(f: Tthread_main_func; p: Pointer); cdecl;
  neko_thread_register: function(t: Boolean): Boolean; cdecl;
  
  neko_vm_alloc: function(custom: Pointer): Pneko_vm; cdecl;
  neko_vm_current: function: Pneko_vm; cdecl;
  neko_exc_stack: function(vm: Pneko_vm): value; cdecl;
  neko_call_stack: function(vm: Pneko_vm): value; cdecl;
  neko_vm_custom: function(vm: Pneko_vm; k: vkind): Pointer; cdecl;
  neko_vm_set_custom: procedure(vm: Pneko_vm; k: vkind; v: Pointer); cdecl;
  neko_vm_execute: function(vm: Pneko_vm; module: Pointer): value; cdecl;
  neko_vm_select: procedure(vm: Pneko_vm); cdecl;
  neko_vm_jit: function(vm: Pneko_vm; enable_jit: Integer): Integer; cdecl;
  neko_vm_trusted: function(vm: Pneko_vm; trusted: Integer): Integer; cdecl;
  neko_default_loader: function (argv: PPChar; argc: Integer): value; cdecl;
  neko_vm_redirect: procedure(vm: Pneko_vm; print: Tneko_printer; param: Pointer); cdecl;
  neko_vm_set_stats: procedure(vm: Pneko_vm; fstats, pstats: Tneko_stat_func); cdecl;
  neko_vm_dump_stack: procedure(vm: Pneko_vm); cdecl;
  neko_is_big_endian: function: Integer; cdecl;
  neko_read_module: function (AReader: TReaderProc; p: readp; loader: value ): Pneko_module; cdecl;
  
  alloc_local: function(): mt_local; cdecl;
  local_get: function(l: mt_local): Pointer; cdecl;
  local_set: procedure(l: mt_local; v: Pointer); cdecl;
  free_local: procedure(l: mt_local); cdecl;

  alloc_lock: function(): mt_lock; cdecl;
  lock_acquire: procedure(l: mt_lock); cdecl;
  lock_try: function(l: mt_lock): Integer; cdecl;
  lock_release: procedure(l: mt_lock); cdecl;
  free_lock: procedure(l: mt_lock); cdecl;
	alloc_int32: function (v : longint) : value; cdecl;

{$ifndef neko_2_0}
  k_int32: vkind;
{$endif}  
  k_hash: vkind;
  neko_kind_module: vkind;

  val_null: value;
  val_true: value;
  val_false: value;
  neko_error: procedure;
  id_string: Tfield;
  id_length: Tfield;
  id_array: Tfield;
  id_Self: Tfield;
  id_interface: Tfield;
  id_object: Tfield;
  id_node: Tfield;
  id_prototype: Tfield;
  id_new: Tfield;
  id__construct__: Tfield;
  id__name__: Tfield;
  id__super__: Tfield;
  id__class__: Tfield;
  id_cache: Tfield;
  id_constructor: Tfield;

  __kind_k_object: Tvkind;
  k_object: vkind = @ __kind_k_object;
  __kind_k_objectgc: Tvkind;
  k_objectgc: vkind = @ __kind_k_objectgc;

  __kind_k_interface: Tvkind;
  k_interface: vkind = @ __kind_k_interface;
  __kind_k_node: Tvkind;
  k_node: vkind = @ __kind_k_node;
  object_is_181: Boolean;


procedure add_function(c: value; const Name: string; code: Pointer; Args: Integer);
function GetProto(v: value): value;
function IInterface_(v: value): IInterface;
procedure IInterface_free(v: value); cdecl;
function IInterface_GC(I: IInterface): value;
procedure IterateFields(o: value; iter: TFieldIterProc; data: Pointer);
procedure IterateFieldsMethod(o: value; iter: TFieldIterMethod; data: Pointer);
procedure LoadNeko;
procedure UnloadNeko;
function LoadModule(const AFile: string): value;
procedure ExecuteModuleMain(AModule: value);
function ReportException(vm: Pneko_vm; exc: value; isExc: BOOL ): string;
function NekoExceptionToString(exc: value): string;
procedure SetProto(var v: value; proto: value);
procedure TPointer_free(v: value); cdecl;
procedure TObject_free(v: value); cdecl;
function TObject_wrapper(Self: TObject): value; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function TObject_GC(Self: TObject): value;
function TObject_(v: value): TObject; //{$IFDEF COMPILER_INLINE} inline; {$ENDIF}
function TObject_Of(v: value): TObject;
function TObject_Release(v: value): value; cdecl;
function TObject_Self: TObject; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}
procedure StreamReader(p: readp; buf: Pointer; size: Integer); cdecl;
function ValueToString(v: value): string;
function NekoSaveException(e: Exception): value;
procedure NekoThrowException(v: value);
function NekoDLLIsLoaded: Boolean;
function valid_value(data: Pointer): value; {$IFDEF COMPILER_INLINE} inline; {$ENDIF}

var
  EmbeddedNeko: Pneko_vm;

implementation

type
  TCallFieldIterProc = record
    Proc: TFieldIterProc;
    Data: Pointer;
  end;
  PCallFieldIterProc = ^TCallFieldIterProc;
  TCallFieldIterMethod = record
    Method: TFieldIterMethod;
    Data: Pointer;
  end;
  PCallFieldIterMethod = ^TCallFieldIterMethod;

var
  HNEKO: HMODULE;

function valid_value(data: Pointer): value;
begin
  if data <> nil then Result:= value(data)
  else Result:= val_null;
end;

function NekoDLLIsLoaded: Boolean;
begin
	Result:= HNEKO <> 0;
end;

procedure add_function(c: value; const Name: string; code: Pointer; Args: Integer);
begin
  alloc_field(c, val_id(PAnsiChar(Name)), alloc_function(code, Args, PAnsiChar(Name)));
end;

function alloc_string(const S: string): value;
begin
  result:= alloc_empty_string(Length(s));
  if s <> '' then
    Move(s[1], val_string(result)^, Length(s));
end;

function val_data(v: value): Pointer;
begin
  Result:= vabstract(v).data;
end;

function get_val_int32(v: value): LongInt;
begin
	Result:= nvint32(v).i;
end;

procedure dummy_error;
begin
  raise ENekoException.Create('Error in neko');
end;

procedure UnloadNeko;
begin
  if HNEKO <> 0 then begin
    if EmbeddedNeko <> nil then begin
      neko_global_free();
      EmbeddedNeko:= nil;
    end;
    FreeLibrary(HNEKO);
    HNEKO:= 0;
  end;
end;

procedure StartNekoVM;
begin
  //writeln('StartNekoVM');
  if EmbeddedNeko <> nil then exit;
  neko_global_init(nil);
  EmbeddedNeko:= neko_vm_alloc(nil);
  neko_vm_select(EmbeddedNeko);
  neko_vm_jit(EmbeddedNeko, 1);
end;

function GetProto(v: value): value;
begin
  if val_is_object(v) then begin
    if object_is_181 then
      Result:= value(vobject181(v).proto)
    else
      Result:= value(vobject180(v).proto)
  end else
    Result:= nil;
end;
procedure SetProto(var v: value; proto: value);
begin
  val_check_object(v);
  val_check_object(proto);
  if object_is_181 then
    vobject181(v).proto:= vobject181(proto)
  else
    vobject180(v).proto:= vobject180(proto);
end;

procedure TestObjTable;
var
  v: value;
begin
  v:= alloc_object(nil);
  object_is_181:= (vobject181(v).table.count = 0) and (vobject181(v).table.cells = nil);
end;

procedure LoadNeko;
begin
  //writeln('LoadNeko', Get8087CW);
  if HNEKO <> 0 then exit;
  DbgTrace('load neko dll');
  HNEKO:= LoadLibrary(neko_library);
  if HNEKO <> 0 then try
    alloc_abstract:= GetProcAddress(HNEKO, 'neko_alloc_abstract');
    _alloc_string:= GetProcAddress(HNEKO, 'neko_alloc_string');
    alloc_float:= GetProcAddress(HNEKO, 'neko_alloc_float');
    alloc_empty_string:= GetProcAddress(HNEKO, 'neko_alloc_empty_string');
    copy_string:= GetProcAddress(HNEKO, 'neko_copy_string');
    val_this:= GetProcAddress(HNEKO, 'neko_val_this');
    val_id:= GetProcAddress(HNEKO, 'neko_val_id');
    val_field:= GetProcAddress(HNEKO, 'neko_val_field');
    alloc_object:= GetProcAddress(HNEKO, 'neko_alloc_object');
    alloc_field:= GetProcAddress(HNEKO, 'neko_alloc_field');
    val_iter_fields:= GetProcAddress(HNEKO, 'neko_val_iter_fields');
    val_field_name:= GetProcAddress(HNEKO, 'neko_val_field_name');
    alloc_array:= GetProcAddress(HNEKO, 'neko_alloc_array');
    val_call0 := GetProcAddress(HNEKO, 'neko_val_call0');
    val_call1 := GetProcAddress(HNEKO, 'neko_val_call1');
    val_call2 := GetProcAddress(HNEKO, 'neko_val_call2');
    val_call3 := GetProcAddress(HNEKO, 'val_call3');
    val_callN := GetProcAddress(HNEKO, 'neko_val_callN');
    val_ocall0 := GetProcAddress(HNEKO, 'neko_val_ocall0');
    val_ocall1 := GetProcAddress(HNEKO, 'neko_val_ocall1');
    val_ocall2 := GetProcAddress(HNEKO, 'val_ocall2');
    val_ocallN := GetProcAddress(HNEKO, 'neko_val_ocallN');
    val_callEx := GetProcAddress(HNEKO, 'neko_val_callEx');
    alloc_root := GetProcAddress(HNEKO, 'neko_alloc_root');
    free_root := GetProcAddress(HNEKO, 'neko_free_root');
    alloc := GetProcAddress(HNEKO, 'neko_alloc');
    alloc_private := GetProcAddress(HNEKO, 'neko_alloc_private');
    alloc_function := GetProcAddress(HNEKO, 'neko_alloc_function');
    alloc_buffer := GetProcAddress(HNEKO, 'neko_alloc_buffer');
    buffer_append := GetProcAddress(HNEKO, 'neko_buffer_append');
    buffer_append_sub := GetProcAddress(HNEKO, 'neko_buffer_append_sub');
    buffer_append_char := GetProcAddress(HNEKO, 'buffer_append_char');
    buffer_to_string := GetProcAddress(HNEKO, 'neko_buffer_to_string');
    val_buffer := GetProcAddress(HNEKO, 'neko_val_buffer');
    val_compare := GetProcAddress(HNEKO, 'neko_val_compare');
    val_print := GetProcAddress(HNEKO, 'val_print');
    val_gc := GetProcAddress(HNEKO, 'neko_val_gc');
    val_throw := GetProcAddress(HNEKO, 'neko_val_throw');
    val_rethrow := GetProcAddress(HNEKO, 'neko_val_rethrow');
    val_hash := GetProcAddress(HNEKO, 'neko_val_hash');
    kind_export := GetProcAddress(HNEKO, 'neko_kind_export');
    kind_import := GetProcAddress(HNEKO, 'neko_kind_import');
    _neko_failure := GetProcAddress(HNEKO, '_neko_failure');
		alloc_int32:= GetProcAddress(HNEKO, 'neko_alloc_int32');

{$ifndef neko_2_0}
    k_int32:= PPointer(GetProcAddress(HNEKO, 'neko_k_int32'))^;
{$endif}  
    k_hash:= PPointer(GetProcAddress(HNEKO, 'neko_k_hash'))^;
    neko_kind_module:= PPointer(GetProcAddress(HNEKO, 'neko_kind_module'))^;
    val_null:= Pvalue(GetProcAddress(HNEKO, 'val_null'))^;
    val_true:= Pvalue(GetProcAddress(HNEKO, 'val_true'))^;
    val_false:= Pvalue(GetProcAddress(HNEKO, 'val_false'))^;
    neko_error:= dummy_error;

    neko_global_init:= GetProcAddress(HNEKO, 'neko_global_init');
    neko_set_stack_base:= GetProcAddress(HNEKO, 'neko_set_stack_base');
    neko_global_free:= GetProcAddress(HNEKO, 'neko_global_free');
    neko_gc_major:= GetProcAddress(HNEKO, 'neko_gc_major');
    neko_gc_loop:= GetProcAddress(HNEKO, 'neko_gc_loop');
    neko_gc_stats:= GetProcAddress(HNEKO, 'neko_gc_stats');
    neko_thread_create:= GetProcAddress(HNEKO, 'neko_thread_create');
    neko_thread_blocking:= GetProcAddress(HNEKO, 'neko_thread_blocking');
    neko_thread_register:= GetProcAddress(HNEKO, 'neko_thread_register');
    neko_vm_alloc:= GetProcAddress(HNEKO, 'neko_vm_alloc');
    neko_vm_current:= GetProcAddress(HNEKO, 'neko_vm_current');
    neko_exc_stack:= GetProcAddress(HNEKO, 'neko_exc_stack');
    neko_call_stack:= GetProcAddress(HNEKO, 'neko_call_stack');
    neko_vm_custom:= GetProcAddress(HNEKO, 'neko_vm_custom');
    neko_vm_set_custom:= GetProcAddress(HNEKO, 'neko_vm_set_custom');
    neko_vm_execute:= GetProcAddress(HNEKO, 'neko_vm_execute');
    neko_vm_select:= GetProcAddress(HNEKO, 'neko_vm_select');
    neko_vm_jit:= GetProcAddress(HNEKO, 'neko_vm_jit');
    neko_vm_trusted:= GetProcAddress(HNEKO, 'neko_vm_trusted');
    neko_default_loader:= GetProcAddress(HNEKO, 'neko_default_loader');
    neko_vm_redirect:= GetProcAddress(HNEKO, 'neko_vm_redirect');
    neko_vm_set_stats:= GetProcAddress(HNEKO, 'neko_vm_set_stats');
    neko_vm_dump_stack:= GetProcAddress(HNEKO, 'neko_vm_dump_stack');
    neko_is_big_endian:= GetProcAddress(HNEKO, 'neko_is_big_endian');
    neko_read_module:= GetProcAddress(HNEKO, 'neko_read_module');

    alloc_local:= GetProcAddress(HNEKO, 'neko_alloc_local');
    local_get:= GetProcAddress(HNEKO, 'neko_local_get');
    local_set:= GetProcAddress(HNEKO, 'neko_local_set');
    free_local:= GetProcAddress(HNEKO, 'neko_free_local');

    alloc_lock:= GetProcAddress(HNEKO, 'neko_alloc_lock');
    lock_acquire:= GetProcAddress(HNEKO, 'neko_lock_acquire');
    lock_try:= GetProcAddress(HNEKO, 'neko_lock_try');
    lock_release:= GetProcAddress(HNEKO, 'neko_lock_release');
    free_lock:= GetProcAddress(HNEKO, 'neko_free_lock');

    if neko_vm_current = nil then
      StartNekoVM
    else
      Set8087CW($27F);
    id_string:= val_id('__s');
    id_length:= val_id('length');
    id_array:= val_id('__a');
    id_Self:= val_id('__self');
    id_interface:= val_id('__i');
    id_object:= val_id('__o');
    id_node:= val_id('__node');
    id_prototype:= val_id('prototype');
    id_new:= val_id('new');
    id__construct__:= val_id('__construct__');
    id__name__:= val_id('__name__');
    id__super__:= val_id('__super__');
    id__class__:= val_id('__class__');
    id_cache:= val_id('cache');
    id_constructor:= val_id('constructor');
    TestObjTable;
  except
    UnloadNeko;
  end else begin
    DbgTrace('cannot load '+ neko_library);
  end;
  //writeln(' ...done');
end;

function need_32_bits(i : longint) : Boolean;
begin
   //Result:=(dword(i)) and $C0000000 <> 0;
   Result:=(dword(i) + $40000000) and $80000000 <> 0;
end;

function alloc_int(v : longint) : value;
begin
//   Result:=value(Tint_val(((longint(v)) shl 1) or 1));
  Result:= value((v * 2) or 1);
end;

{$ifdef neko_very_old}
function alloc_int32(v : longint) : value;
begin
   Result:= alloc_abstract(k_int32, Pointer(v));
end;
{$endif}

function alloc_bool(v: Boolean): value;
begin
  if v then
    Result:= val_true
  else
    Result:= val_false;
end;

function alloc_best_int(i : longint) : value;
begin
   if need_32_bits(i) then
     Result:=alloc_int32(i)
   else
     Result:=alloc_int(i);
end;

function val_kind(v: value): vkind;
begin
  Result:= vabstract(v).kind;
end;

function val_fun_nargs(f: value): Integer;
begin
  Result:= vfunction(f).nargs;
end;

function val_is_null(v : value) : Boolean;
begin
   Result:= v = val_null;
end;

function val_tag(v: value): Tval_type;
begin
  Result:= v.t;
end;

function val_short_tag(v: value): Tval_type;
begin
  Result:= val_tag(v) and ( (1 shl cTAG_BITS) -1);
end;

function val_is_int(v : value): Boolean;
begin
  Result:=((Tint_val(v)) and 1) <> 0;
end;

function val_is_bool(v : value): Boolean;
begin
  Result:=(v = val_true) or (v = val_false);
end;

function val_is_float(v: value): Boolean;
begin
  Result:= not val_is_int(v) and (v.t = cVAL_FLOAT);
end;

function val_is_string(v: value): Boolean;
begin
  Result:= not val_is_int(v) and (v.t and 7 = cVAL_STRING);
end;

function val_is_function(v: value): Boolean;
begin
  Result:= not val_is_int(v) and (v.t and 7 = cVAL_FUNCTION);
end;

function val_is_function(v: value; n: Integer): Boolean;
begin
  Result:= val_is_function(v) and ((val_fun_nargs(v) = n) or (val_fun_nargs(v) = VAR_ARGS));
end;

function val_is_object(v: value): Boolean;
begin
  Result:= (not val_is_int(v)) and (v.t = cVAL_OBJECT);
end;

function val_is_array(v: value): Boolean;
begin
  Result:= not val_is_int(v) and (v.t and 7 = cVAL_ARRAY);
end;

function val_is_abstract(v: value): Boolean;
begin
  Result:= not val_is_int(v) and (v.t = cVAL_ABSTRACT);
end;


function val_is_kind(v: value; k: vkind): Boolean;
begin
  Result:= val_is_abstract(v) and (val_kind(v) = k);
end;

function val_is_int32(v: value): Boolean;
begin
  Result:= val_is_int(v) or (v.t = cVAL_INT32);
end;

function val_is_number(v : value): Boolean;
begin
  Result:= val_is_int(v) or (v.t = cVAL_INT32) or (v.t = cVAL_FLOAT);
end;

procedure val_check_kind(v: value; k: vkind);
begin
  if not val_is_kind(v, k) then neko_error;
end;

procedure val_check_function(f: value; n: Integer);
begin
  if not val_is_function(f) or ((val_fun_nargs(f) <> n) and (val_fun_nargs(f) <> VAR_ARGS))
  then
    neko_error;
end;
procedure val_check_object(v: value);
begin
  if not val_is_object(v) then
    neko_error;
end;

procedure val_check_string(v: value);
begin
  if not val_is_string(v) then
    neko_error;
end;

function val_type(v: value): Tval_type;
begin
  if val_is_int(v) then
    Result:= cVAL_INT
  else
    Result:= v.t and 7;
end;

function val_int(v: value): Integer;
begin
  Result:= Integer(Cardinal(v) and not 1) div 2;
  //Result:= Integer((Cardinal(v) shr 1) OR (Cardinal(v) and $80000000));
end;

function val_float(v: value): Double;
begin
  Result:= vfloat(v).f;
end;

function val_bool(v: value): Boolean;
begin
  Result:= v = val_true;
end;

function val_int32(v: value): Integer;
begin
  if val_is_int(v) then
    Result:= val_int(v)
  else
    Result:= nvint32(v).i;
end;

function val_number(v: value): Double;
begin
  if val_is_int(v) then
    Result:= val_int(v)
  else if val_is_float(v) then
    Result:= val_float(v)
  else
    Result:= nvint32(v).i;
end;

function val_hdata(v: value): vhash;
begin
  Result:= val_data(v);
end;

function val_string(v: value): PAnsiChar;
begin
  Result:= @vstring(v).c;
end;

function val_strlen(v: value): Integer;
begin
  Result:= val_tag(v) shr cTAG_BITS;
end;

procedure val_set_length(v: value; len: Integer);
begin
  v.t:= val_short_tag(v) or (Cardinal(len) shl cTAG_BITS);
end;

function val_array_size(v: value): Integer;
begin
  Result:= val_tag(v) shr cTAG_BITS;
end;

function val_array_ptr(v: value): Pval_array;
begin
  Result:= @varray(v).ptr;
end;

function val_is_HaxeString(v: value): Boolean;
begin
  Result:= (val_is_object(v) and val_is_string(val_field(v, id_string))) or val_is_string(v);
end;

function val_HaxeString(v: value): string;
begin
  Result:= '';
  if val_is_object(v) then
    v:= val_field(v, id_string);
  if val_is_string(v) then
    Result:= val_string(v);
end;

function val_HaxePChar(v: value): PAnsiChar;
begin
  Result:= nil;
  if val_is_object(v) then
    v:= val_field(v, id_string);
  if val_is_string(v) then
    Result:= val_string(v);
end;

function toId(const s: AnsiString): TField; inline;
begin
  result:= val_id(PAnsiChar(s));
end;

function val_call(f: value; const args: array of value; exc: Pvalue): value;
var
  n: Integer;
begin
  n:= Length(args);
  val_check_function(f, n);
  Result:= val_callEx(nil, f, @args[0], n, exc);
end;

function val_ocall(o: value; f: Tfield; const args: array of value; exc: Pvalue): value;
var
  vf: value;
  n: Integer;
begin
  vf:= val_field(o, f);
  n:= Length(args);
  val_check_function(vf, n);
  Result:= val_callEx(o, vf, @args[0], n, exc);
end;

procedure TPointer_free(v: value); cdecl;
begin
  //if val_is_abstract(v) and val_is_kind(v, k_object) then
  Dispose(vabstract(v).data);
  vabstract(v).data:= nil;
end;

procedure TObject_free(v: value); cdecl;
var
  o: TObject;
begin
  try
    //if val_is_abstract(v) and val_is_kind(v, k_object) then
    o:= TObject(vabstract(v).data);
    vabstract(v).data:= nil;
    if o is TInterfacedObject then begin
      if TInterfacedObject(o).RefCount = 0 then
        o.Free;
    end else
      o.Free;
  except
  end;
end;

procedure IInterface_free(v: value); cdecl;
begin
  IInterface(vabstract(v).data):= nil;
end;

function TObject_wrapper(Self: TObject): value;
begin
  Result:= alloc_abstract(k_object, Self);
end;

function TObject_Release(v: value): value; cdecl;
var
  o: TObject;
begin
	Result:= val_false;
  try
    if val_is_abstract(v) and val_is_kind(v, k_objectgc) then begin
      o:= TObject(vabstract(v).data);
      if o = nil then exit;
      vabstract(v).data:= nil;
      val_gc(v, nil);
      if o is TInterfacedObject then begin
        if TInterfacedObject(o).RefCount = 0 then
          o.Free;
      end else
        o.Free;
      Result:= val_true;
    end;
  except
  end;
end;


function TObject_(v: value): TObject;
begin
  if val_is_kind(v, k_object) or val_is_kind(v, k_objectgc) then
    Result:= TObject(val_data(v))
  else if not val_is_null(v) then Result:= TObject(v)
  else Result:= nil;
end;


function TObject_Of(v: value): TObject;
begin
  Result:= nil;
  if val_is_object(v) then
    v:= val_field(v, id_Self);
  if val_is_kind(v, k_object) or val_is_kind(v, k_objectgc) then
    Result:= TObject(val_data(v));
end;

function TObject_Self: TObject;
begin
  Result:= TObject_Of(val_this);
end;

function IInterface_(v: value): IInterface;
begin
  if val_is_kind(v, k_interface) then
    Result:= IInterface(val_data(v))
  else if not val_is_null(v) then Result:= IInterface(v)
  else Result:= nil;
  //if Result <> nil then ?????
  //  Result._AddRef;
end;

function IInterface_GC(I: IInterface): value;
begin
  I._AddRef;
  Result:= alloc_abstract(k_interface, Pointer(I));
  val_gc(Result, IInterface_free);
end;


function TObject_GC(Self: TObject): value;
begin
  Result:= alloc_abstract(k_objectgc, Self);
  val_gc(Result, TObject_free);
end;


function get_array(p: Pvalue; cnt: Integer): TNekoArray; overload;
begin
  SetLength(Result, cnt);
  Move(p^, Result[0], cnt * SizeOf(value));
end;

function get_array(v: value): TNekoArray;
var
  x: Integer;
begin
  x:= val_array_size(v);
  SetLength(Result, x);
  Move(val_array_ptr(v)^, Result[0], x * SizeOf(value));
end;

procedure IterPasProc( v: value; f: Tfield; data: Pointer); cdecl;
begin
  PCallFieldIterProc(data).Proc(v, f, PCallFieldIterProc(data).Data);
end;

procedure IterPasMethod( v: value; f: Tfield; data: Pointer); cdecl;
begin
  PCallFieldIterMethod(data).Method(v, f, PCallFieldIterMethod(data).Data);
end;

procedure IterateFields(o: value; iter: TFieldIterProc; data: Pointer);
var
  c: TCallFieldIterProc;
begin
  c.Proc:= iter;
  c.Data:= data;
  val_iter_fields(o, IterPasProc, @c);
end;

procedure IterateFieldsMethod(o: value; iter: TFieldIterMethod; data: Pointer);
var
  c: TCallFieldIterMethod;
begin
  c.Method:= iter;
  c.Data:= data;
  val_iter_fields(o, IterPasMethod, @c);
end;

function ReportException(vm: Pneko_vm; exc: value; isExc: BOOL ): string;
var
	i: Integer;
  b: Pbuffer;
  st, s: value;
begin
	b:= alloc_buffer(nil);
	st:= neko_exc_stack(vm);
  try for i := 0 to val_array_size(st) -1 do
    begin
      s := val_array_ptr(st)[i];
      buffer_append(b,'Called from ');
      if ( (s = nil) or val_is_null(s) ) then
        buffer_append(b,'a C (internal) function')
      else if( val_is_string(s) ) then begin
        buffer_append(b, val_string(s));
        buffer_append(b,' (no debug available)');
      end else if  val_is_array(s)
        and (val_array_size(s) = 2)
        and val_is_string(val_array_ptr(s)[0])
        and val_is_int(val_array_ptr(s)[1])
      then begin
        val_buffer(b, val_array_ptr(s)[0]);
        buffer_append(b, ' line ');
        val_buffer(b, val_array_ptr(s)[1]);
      end else
        val_buffer(b, s);
      buffer_append(b, #$0d#$0A);
    end;
  except
	end;
	if isexc then
    buffer_append(b, 'Uncaught exception - ');
	val_buffer(b, exc);
  Result:= val_string(buffer_to_string(b));
end;

function NekoExceptionToString(exc: value): string;
var
  b: Pbuffer;
begin
	b:= alloc_buffer(nil);
	val_buffer(b, exc);
  Result:= val_string(buffer_to_string(b));
end;

function LoadModule(const AFile: string): value;
var
  loader, exc, f: value;
  args: array[0..1] of value;
  FPUCW: Word;
begin
  loader:= neko_default_loader(nil, 0);
  args[0]:= alloc_string(AFile);
  args[1]:= loader;
  exc:= nil;
  f:= val_field(loader, val_id('loadmodule'));
  FPUCW:= Get8087CW;
  Set8087CW($27F);
  Result:= val_callEx(loader, f, @args[0], 2, @exc);
  Set8087CW(FPUCW);
  if (exc <> nil) then begin
    //ReportException(EmbeddedNeko, exc, True);
    raise ENekoException.Create(ReportException(EmbeddedNeko, exc, True) + ' while loading ' + AFile);
  end;
end;

procedure ExecuteModuleMain(AModule: value);
var
  main: value;
begin
  main:= val_field(AModule, val_id('main'));
  val_check_function(main, 0);
  val_call0(main);
end;

function ValueToString(v: value): string;
var
  b:Pbuffer;
begin
  b:= alloc_buffer(nil);
  val_buffer(b, v);
  Result:= val_string( buffer_to_string(b));
end;

procedure StreamReader(p: readp; buf: Pointer; size: Integer); cdecl;
var
  lStream: TStream;
begin
  lStream:= p;
  lStream.ReadBuffer(buf^, size);
end;

function NekoSaveException(e: Exception): value;
begin
	Result:= alloc_string(e.ClassName + ': ' + e.Message);
end;

procedure NekoThrowException(v: value);
begin
	if v <> nil then val_throw(v);
end;

{ TArrayInfo }

function TArrayInfo.FromValue(v: value): Boolean;
var
  vl: value;
begin
  l:= -1;
  if val_is_object(v) then begin
    vl:= val_field(v, id_length);
    if val_is_int(vl) then
      l:= val_int(vl);
    v:= val_field(v, id_array);
  end;
  if val_is_array(v) then begin
    a:= val_array_ptr(v);
    if l = -1 then
      l:= val_array_size(v);
    Result:= True
  end else begin
    Result:= False;
    a:= nil;
  end;
end;

function TArrayInfo.Get(Index: Integer; Def: value): value;
begin
  if (Index >= 0) and (Index < l) then
    Result:= a^[Index]
  else
    Result:= Def;
end;

function TArrayInfo.SetVal(Index: Integer; val: value): value;
begin
  Result:= val;
  if (Index >= 0) and (Index < l) then
    a^[Index]:= val;
end;

function TArrayInfo.toArray: TNekoArray;
begin
  SetLength(result, l);
  Move(a^, Result[0], l * SizeOf(value));
end;

{ ENekoException }

constructor ENekoException.CreateExc(Exc: value);
begin
  Create(ReportException(neko_vm_current(), Exc, True ));
end;

initialization
  LoadNeko;
  //assert(val_int(alloc_int(-1)) = -1);
  //assert(val_int(alloc_int(-MaxInt div 2)) = -MaxInt div 2);

finalization
  UnloadNeko;

end.
