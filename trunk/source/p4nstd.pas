unit p4nstd;

interface
uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  SysConst,
  SysUtils,
  Classes,
  neko, nekoHelper, Helper,
  p4nInifiles;

  function _init_std__1: pointer; cdecl;
  function init_std(I: value): value; cdecl;

implementation

threadvar
  myFormat: TFormatSettings;

function setFormat(v: value): value; cdecl;
var
  s: string;

  function GetField(const Name: PChar): Boolean;
  var
    fv: value;
  begin
    Result:= False;
    fv:= val_field(v, val_id(Name));
    if val_is_HaxeString(fv) then begin
      s:= val_HaxeString(fv);
      Result:= s <> '';
    end;
  end;

  function GetFieldS(const Name: PChar): Boolean;
  var
    fv: value;
  begin
    Result:= False;
    fv:= val_field(v, val_id(Name));
    if val_is_HaxeString(fv) then begin
      s:= val_HaxeString(fv);
      Result:= True;
    end;
  end;

  procedure SetArray(var data: array of string;const Name: PChar);
  var
    fv: value;
    i: Integer;
    s1: string;
  begin
    fv:= val_field(v, val_id(Name));
    if val_is_HaxeString(fv) then begin
      s:= val_HaxeString(fv);
      for i := Low(data) to High(data) do begin
        s1:= SplitStringAt(s, ',');
        if s1 <> '' then
          data[i]:= s1;
      end;
    end;
  end;

begin
  Result:= val_null;
  if val_is_object(v) then begin
    if GetField('ThousandSeparator') then
      myFormat.ThousandSeparator:= s[1];
    if GetField('DecimalSeparator') then
      myFormat.DecimalSeparator:= s[1];
    if GetField('DateSeparator') then
      myFormat.DateSeparator:= s[1];
    if GetField('TimeSeparator') then
      myFormat.TimeSeparator:= s[1];
    if GetField('ListSeparator') then
      myFormat.ListSeparator:= s[1];

    if GetFieldS('CurrencyString') then
      myFormat.CurrencyString:= s;
    if GetFieldS('ShortDateFormat') then
      myFormat.ShortDateFormat:= s;
    if GetFieldS('LongDateFormat') then
      myFormat.LongDateFormat:= s;
    if GetFieldS('TimeAMString') then
      myFormat.TimeAMString:= s;
    if GetFieldS('TimePMString') then
      myFormat.TimePMString:= s;
    if GetFieldS('ShortTimeFormat') then
      myFormat.ShortTimeFormat:= s;
    if GetFieldS('LongTimeFormat') then
      myFormat.LongTimeFormat:= s;
    SetArray(myFormat.ShortMonthNames, 'ShortMonthNames');
    SetArray(myFormat.LongMonthNames, 'LongMonthNames');
    SetArray(myFormat.ShortDayNames, 'ShortDayNames');
    SetArray(myFormat.LongDayNames, 'LongDayNames');
  end;
end;

function parseDate(x: value): value; cdecl;
var
  rval: TDateTime;
begin
  Result:= val_null;
  if val_is_HaxeString(x) then
    if TryStrToDate(val_HaxeString(x), rval, myFormat) then
      Result:= alloc_float(rval);
end;

function parseDateTime(x: value): value; cdecl;
var
  rval: TDateTime;
begin
  Result:= val_null;
  if val_is_HaxeString(x) then
    if TryStrToDateTime(val_HaxeString(x), rval, myFormat) then
      Result:= alloc_float(rval);
end;

function parseTime(x: value): value; cdecl;
var
  rval: TDateTime;
begin
  Result:= val_null;
  if val_is_HaxeString(x) then
    if TryStrToTime(val_HaxeString(x), rval, myFormat) then
      Result:= alloc_float(rval);
end;

function parseFloat(x: value): value; cdecl;
var
  rval: Double;
begin
  Result:= val_null;
  if val_is_HaxeString(x) then
    if TryStrToFloat(val_HaxeString(x), rval, myFormat) then
      Result:= alloc_float(rval);
end;

function format(f, arg: value): value; cdecl;
begin
  Result:= val_null;
  if val_is_HaxeString(f) then begin
    Result:= alloc_string( SysUtils.Format(val_HaxeString(f), ArrayToArrayOfConst(arg), myFormat ));
  end;
end;

function formatFloat(f, x: value): value; cdecl;
begin
  Result:= val_null;
  if val_is_HaxeString(f) and val_is_number(x) then
    Result:= alloc_string(SysUtils.FormatFloat(val_HaxeString(f), val_number(x), myFormat));
end;

function formatDateTime(f, x: value): value; cdecl;
begin
  Result:= val_null;
  if val_is_HaxeString(f) and val_is_number(x) then
    Result:= alloc_string(SysUtils.FormatDateTime(val_HaxeString(f), val_number(x), myFormat));
end;

function init(I: value): value; cdecl;
begin
{$IFDEF MSWINDOWS}
  GetLocaleFormatSettings(GetThreadLocale, myFormat);
{$ENDIF}
  add_function(I, 'format', @format, 2);
  add_function(I, 'formatFloat', @formatFloat, 2);
  add_function(I, 'formatDateTime', @formatDateTime, 2);
  add_function(I, 'setFormat', @setFormat, 1);
  add_function(I, 'parseDate', @parseDate, 1);
  add_function(I, 'parseDateTime', @parseDateTime, 1);
  add_function(I, 'parseTime', @parseTime, 1);
  add_function(I, 'parseFloat', @parseFloat, 1);
end;

function init_std(I: value): value; cdecl;
var
  s: string;
begin
  Result:= val_null;
  if val_is_HaxeString(I) then begin
    s:= val_HaxeString(I);
    if s = 'p4n_inifiles' then begin
      Result:= alloc_function(@p4nInifiles.init, 1, 'init');
    end else if s = 'p4n_std' then begin
      Result:= alloc_function(@p4nstd.init, 1, 'p4nstd_init');
    end;
  end;
end;

function _init_std__1: pointer; cdecl;
begin
  result:= @init_std;
end;

end.
