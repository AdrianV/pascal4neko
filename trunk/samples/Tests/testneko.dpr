library testneko;
// the demo code is in the include file

uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Types,
  Libc,
  dynlibs,
{$ENDIF}
  SysUtils,
  Classes,
  neko,
  uNekoDemo1 in 'uNekoDemo1.pas';
  
//{$include testneko.inc}
// The code for this demo is shared for use with delphi or lazarus
// since delphi uses .dpr and lazarus .lpr as an extension for projects
{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

{$IFNDEF FPC}
{$LIBVERSION 'ndll'}

{$ENDIF}


function hello: value; cdecl;
var
  o: value;
begin
  o:= alloc_object(nil);
  alloc_field(o, val_id('test'), alloc_string('Hallo Neko'));
  alloc_field(o, val_id('IntVal'), alloc_best_int(44));
  alloc_field(o, val_id('FloatVal'), alloc_float(79.5));
  Result:= o;
end;

function showMe(v: value): value; cdecl;
var
  s: string;
begin
  with TNekoObj2String.Create(v) do try
    s:= toString(v);
  finally
    Free;
  end;
  Result:= alloc_string(PChar(s));
end;

function doSomething(a, b: value): value; cdecl;
begin
  Result:= alloc_string(PChar(Format('a + b = %f', [val_int(a) + val_float(b)])));
end;

function _init: value; cdecl;

  procedure Exp(prim: Pointer; nargs: Integer; name: PChar);
  begin
    alloc_field(Result, val_id(name), alloc_function(prim, nargs, name));
  end;

begin
  Result:= alloc_object(nil);
  Exp(@hello, 0, 'hello');
  Exp(@showMe, 1, 'showMe');
  Exp(@doSomething, 2, 'doSomething');
end;

function _init__0: pointer; cdecl;
begin
  result:= @_init;
end;


exports
  _init__0;



begin
end.
