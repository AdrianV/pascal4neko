unit uNekoDemo1;

interface
{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

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
  neko;

type
  TNekoObj2String = class
  private
    FBuffer: string;
    FVisited: array of value;
    procedure IterateObject(v: value; f: Tfield; data: Pointer);
    function Visit(v: value): Integer;
    function ValToString(xv: value): string;
  public
    constructor Create(o: value);
    destructor Destroy; override;
    class function toString(v: value): string; overload;
  end;


implementation

{ TNekoObj2String }

constructor TNekoObj2String.Create(o: value);
begin
  FBuffer:= '';
end;

destructor TNekoObj2String.Destroy;
begin

  inherited;
end;

procedure TNekoObj2String.IterateObject(v: value; f: Tfield; data: Pointer);
var
  s: string;
begin
  s:= val_string(val_field_name(f));
  if FBuffer <> '' then
    FBuffer := FBuffer + '; ';
  FBuffer:= FBuffer + Format('%s : %s', [s, ValToString(v)]);
end;

class function TNekoObj2String.toString(v: value): string;
begin
  with Create(v) do try
    Result:= ValToString(v);
  finally
    Free;
  end;
end;

function TNekoObj2String.ValToString(xv: value): string;
var
  av: TNekoArray;
  i, x: Integer;
  old, sarr: string;
  tv: value;
begin
  if val_is_int32(xv) then begin
    Result:= Format('Integer = %d', [val_int32(xv)]);
  end else if val_is_bool(xv) then begin
    if val_bool(xv) then
      Result:= 'Boolean = true'
    else
      Result:= 'Boolean = false'
  end else if val_is_float(xv) then begin
    Result:= Format('Double = %f', [val_float(xv)]);
  end else if val_is_string(xv) then begin
    Result:= Format('String = "%s"', [val_string(xv)]);
  end else if val_is_object(xv) then begin
    tv:= val_field(xv, id_string);
    if val_is_string(tv) then begin
      Result:= Format('String = "%s"', [val_string(tv)]);
    end else begin
      tv:= val_field(xv, id_array);
      if val_is_array(tv) then
        Result:= ValToString(tv)
      else begin
        x:= Visit(xv);
        if x = -1 then begin
          x:= High(FVisited);
          old:= FBuffer;
          FBuffer:= '';
          IterateFieldsMethod(xv, IterateObject, nil);
          Result:= Format('Object(%d) = (%s)', [x, FBuffer]);
          FBuffer:= old;
        end else
          Result:= Format('Object = (%d)', [x]);
      end;
    end;
  end else if val_is_array(xv) then begin
    av:= get_array(xv);
    sarr:= 'Array = [';
    for i := 0 to High(av) do begin
      if i > 0 then
        sarr:= sarr + ', ';
      sarr:= sarr + ValToString(av[i]);
    end;
    Result:= sarr + ']';
  end else if val_is_function(xv) then begin
    Result:= 'function';
  end else if val_is_abstract(xv) then begin
    Result:= '( abstract )';
  end else
    Result:= '( unknown )';
end;

function TNekoObj2String.Visit(v: value): Integer;
var
  i: Integer;
begin
  Result:= -1;
  for i := 0 to High(FVisited) do begin
    if FVisited[i] = v then begin
      Result:= i;
      exit;
    end;
  end;
  i:= Length(FVisited);
  SetLength(FVisited, i+1);
  FVisited[i]:= v;
end;

end.
