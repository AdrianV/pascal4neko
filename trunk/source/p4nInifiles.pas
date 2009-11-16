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
{ Ini files for neko.                                                                              }
{                                                                                                  }
{**************************************************************************************************}
unit p4nInifiles;

interface
uses
  SysConst,
  SysUtils,
  Classes,
  IniFiles, Registry, WebIniFiles,
  neko, nekoHelper, p4nHelper;

function init(I: value): value; cdecl;

implementation

function getSections(I: value): value; cdecl;
var
  ini: TCustomIniFile;
  sl: TStringList;
  arr: TArrayInfo;
  x: Integer;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    sl:= TStringList.Create;
    try
      ini.ReadSections(sl);
      Result:= alloc_array(sl.Count);
      arr.FromValue(Result);
      for x := 0 to sl.Count - 1 do
        arr.SetVal(x, alloc_string(sl.Strings[x]));
    finally
      sl.Free;
    end;
  end;
end;

function readString(I, Section, Key, Default: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    result:= alloc_string(ini.ReadString(val_HaxeString(Section), val_HaxeString(Key), val_HaxeString(Default)));
  end;
end;

function readInt(I, Section, Key, Default: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    result:= alloc_int(ini.ReadInteger(val_HaxeString(Section), val_HaxeString(Key), val_int(Default)));
  end;
end;

function readBool(I, Section, Key, Default: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    result:= alloc_bool(ini.ReadBool(val_HaxeString(Section), val_HaxeString(Key), val_bool(Default)));
  end;
end;

function readDateTime(I, Section, Key, Default: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    result:= alloc_float(ini.ReadDateTime(val_HaxeString(Section), val_HaxeString(Key), val_number(Default)));
  end;
end;

function readFloat(I, Section, Key, Default: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    result:= alloc_float(ini.ReadFloat(val_HaxeString(Section), val_HaxeString(Key), val_number(Default)));
  end;
end;

function readSection(I, Section: value): value; cdecl;
var
  ini: TCustomIniFile;
  sl: TStringList;
  arr: TArrayInfo;
  x: Integer;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    sl:= TStringList.Create;
    try
      ini.ReadSectionValues(val_HaxeString(Section), sl);
      Result:= alloc_array(sl.Count);
      arr.FromValue(Result);
      for x := 0 to sl.Count - 1 do
        arr.SetVal(x, alloc_string(sl.Strings[x]));
    finally
      sl.Free;
    end;
  end;
end;

function readSectionKeys(I, Section: value): value; cdecl;
var
  ini: TCustomIniFile;
  sl: TStringList;
  arr: TArrayInfo;
  x: Integer;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    sl:= TStringList.Create;
    try
      ini.ReadSection(val_HaxeString(Section), sl);
      //writeln(sl.Text);
      Result:= alloc_array(sl.Count);
      arr.FromValue(Result);
      for x := 0 to sl.Count - 1 do
        arr.SetVal(x, alloc_string(sl.Strings[x]));
    finally
      sl.Free;
    end;
  end;
end;

function writeString(I, Section, Key, val: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.WriteString(val_HaxeString(Section), val_HaxeString(Key), val_HaxeString(val));
  end;
end;


function writeInt(I, Section, Key, val: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.WriteInteger(val_HaxeString(Section), val_HaxeString(Key), val_int(val));
  end;
end;

function writeBool(I, Section, Key, val: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.WriteBool(val_HaxeString(Section), val_HaxeString(Key), val_bool(val));
  end;
end;

function writeDateTime(I, Section, Key, val: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.WriteDateTime(val_HaxeString(Section), val_HaxeString(Key), val_number(val));
  end;
end;

function writeFloat(I, Section, Key, val: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.WriteFloat(val_HaxeString(Section), val_HaxeString(Key), val_number(val));
  end;
end;

function KeyExists(I, Section, Key: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    Result:= alloc_bool(ini.ValueExists(val_HaxeString(Section), val_HaxeString(Key)));
  end;
end;

function SectionExists(I, Section: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    Result:= alloc_bool(ini.SectionExists(val_HaxeString(Section)));
  end;
end;

function eraseKey(I, Section, Key: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.DeleteKey(val_HaxeString(Section), val_HaxeString(Key));
  end;
end;

function eraseSection(I, Section: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.EraseSection(val_HaxeString(Section));
  end;
end;

function updateFile(I: value): value; cdecl;
var
  ini: TCustomIniFile;
begin
  Result:= val_null;
  if CheckClass(TObject_(I), TCustomIniFile, ini) then begin
    ini.UpdateFile();
  end;
end;

function createIniFile(Name: value): value; cdecl;
begin
  Result:= TObject_GC(TIniFile.Create(val_HaxeString(Name)));
end;

function createMemIniFile(Name: value): value; cdecl;
begin
  Result:= TObject_GC(TMemIniFile.Create(val_HaxeString(Name)));
end;

function createRegIniFile(Name: value): value; cdecl;
begin
  Result:= TObject_GC(TRegIniFile.Create(val_HaxeString(Name)));
end;

function createWebIniFile(Name: value): value; cdecl;
begin
  Result:= TObject_GC(TWebIniFile.Create(val_HaxeString(Name)));
end;

function init(I: value): value; cdecl;
begin
  Result:= val_null;
  add_function(I, 'getSections', @getSections, 1);
  add_function(I, 'readString', @readString, 4);
  add_function(I, 'readInt', @readInt, 4);
  add_function(I, 'readBool', @readBool, 4);
  add_function(I, 'readDateTime', @readDateTime, 4);
  add_function(I, 'readFloat', @readFloat, 4);
  add_function(I, 'readSection', @readSection, 2);
  add_function(I, 'readSectionKeys', @readSectionKeys, 2);
  add_function(I, 'writeString', @writeString, 4);
  add_function(I, 'writeInt', @writeInt, 4);
  add_function(I, 'writeBool', @writeBool, 4);
  add_function(I, 'writeDateTime', @writeDateTime, 4);
  add_function(I, 'writeFloat', @writeFloat, 4);

  add_function(I, 'KeyExists', @KeyExists, 3);
  add_function(I, 'SectionExists', @SectionExists, 2);
  add_function(I, 'eraseKey', @eraseKey, 3);
  add_function(I, 'eraseSection', @eraseSection, 2);
  add_function(I, 'updateFile', @updateFile, 1);

  add_function(I, 'createIniFile', @createIniFile, 1);
  add_function(I, 'createMemIniFile', @createMemIniFile, 1);
  add_function(I, 'createRegIniFile', @createRegIniFile, 1);
  add_function(I, 'createWebIniFile', @createWebIniFile, 1);

end;


end.
