// The code for this demo is shared for use with delphi or lazarus
// since delphi uses .dpr and lazarus .lpr as an extension for projects
{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

{$IFNDEF FPC}
{$LIBVERSION 'ndll'}
{$ENDIF}

function hello2(v: value): value; cdecl; forward;

function method(v: value): value; cdecl;
begin
  Result:= hello2(v);
end;

function hello: value; cdecl;
var
  o: value;
begin
  o:= alloc_object(nil);
  alloc_field(o, val_id('test'), alloc_string('Hallo Neko'));
  alloc_field(o, val_id('IntVal'), alloc_best_int(44));
  alloc_field(o, val_id('FloatVal'), alloc_float(79.5));
  alloc_field(o, val_id('callMe'), alloc_function(@method, 0, 'method'));
  Result:= o;
end;

function hello2(v: value): value; cdecl;
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

function hello__0: pointer; cdecl;
begin
  result:= @hello;
end;

function hello2__1: pointer; cdecl;
begin
  result:= @hello2;
end;


exports
  hello__0,
  hello2__1;


