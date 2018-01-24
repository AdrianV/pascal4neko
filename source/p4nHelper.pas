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
{ Some usefull (hopefully) routines for Object Pascal.                                             }
{                                                                                                  }
{**************************************************************************************************}
{$INCLUDE nekoDefs.inc}
unit p4nHelper;

interface
uses Sysutils
{$IFNDEF FPC}
  ,Forms
{$ENDIF}
{$IFDEF MSWINDOWS}
	,Windows, ShellApi
{$ENDIF}

;

type
{$IF not defined(IntPtr)}
{$IF sizeof(Pointer) = 4}
  IntPtr = LongInt;
{$ELSE}
  IntPtr = Int64;
{$IFEND}
{$IFEND}
{$IFDEF FPC}
  SmallSetInt = Byte;
{$ELSE}
  SmallSetInt = Byte;
{$ENDIF}
  TDynamicByteArray = array of byte;
	TDynamicStringArray = array of string;

function DSAFromConst(const A: array of string): TDynamicStringArray;  
function _Is_(AObject: TObject; AClass: TClass): Boolean;
function AddPath(const P1, P2: string): string;
function AddRelPath(const P1, P2: string): string;
function ApplicationPath: string;

function CheckClass(AObject: TObject; AClass: TClass; var ResObject{: TObject}): Boolean; {$ifdef COMPILER_INLINE} inline; {$endif}
function CheckPointer(APointer: Pointer; var ResPointer): Boolean; {$ifdef COMPILER_INLINE} inline; {$endif}
function Closure(Code: Pointer; Data: TObject): TMethod; {$ifdef COMPILER_INLINE} inline; {$endif}
procedure DbgTrace(const Msg: AnsiString); overload;
procedure DbgTrace(const Msg: WideString); overload;
procedure DbgTraceFmt(const Fmt: String; const Args: array of const); overload;
procedure DbgTraceFmt(const Fmt: WideString; const Args: array of const); overload;
function DecodeByteArray(const aStr:	string; const aCodeTable: string): TDynamicByteArray;
function EncodeByteArray(const aData: array of byte; const aCodeTable: string): string;

{$IFDEF LINUX}
function ExecuteFile(const FileName, Params, DefaultDir: string;
	ShowCmd: Integer = 0): THandle;
{$ELSE}
function ExecuteFile(const FileName, Params, DefaultDir: string;
	ShowCmd: Integer = SW_SHOWNORMAL): THandle;
{$ENDIF}
function ExtractFileNameOnly(const aFile: string): string;
function ExtractFileNameWeb(const FileName: string): string;
function ExtractFilePathWeb(const FileName: string): string;
function ProgramData: string;
function SplitString(var S: string; const limit: string):string;
function EndsWith(const sEnd, s: string): boolean;
function StartsWith(const sStart, s: string): boolean;

procedure DefaultDebugTrace(const Msg: AnsiString);
var
  HookDebugTrace : procedure(const Msg: AnsiString) = DefaultDebugTrace;

implementation

procedure DefaultDebugTrace(const Msg: AnsiString);
begin
{$IFDEF LINUX}
  writeln(Msg);
{$ELSE}
//{$IFDEF MSWINDOWS}
	OutputDebugStringA(PAnsiChar(Msg));
{$ENDIF}
end;

function DSAFromConst(const A: array of string): TDynamicStringArray;
var
	i, m: Integer;
begin
	m:= Length(A);
	SetLength(Result, m);
  for i := 0 to m - 1 do Result[i]:= A[i];
end;

function _Is_(AObject: TObject; AClass: TClass): Boolean;

  function ExtraTest: Boolean;
  var
    s: string;
    tc: TClass;
    x: Integer;
  begin
    s:= AClass.ClassName;
    x:= PInteger(Integer(AClass) + vmtInstanceSize)^; //AClass.InstanceSize;
    Pointer(tc) := PPointer(AObject)^; //AObject.ClassType;
    while (tc <> nil) do begin
      if (x = PInteger(Integer(tc) + vmtInstanceSize)^)
        and (tc.ClassName = s)
      then begin
        Result:= True;
        exit;
      end;
      Pointer(tc) := PPointer(Integer(tc) + vmtParent)^;
      if Pointer(tc) <> nil then
        Pointer(tc) := PPointer(tc)^;
    end;
    Result:= False;
  end;

begin
  Result:= AObject.InheritsFrom(AClass);
  if not Result and Assigned(AObject) and Assigned(AClass) then begin
    //Result:= AObject.ClassNameIs(AClass.ClassName);
    Result:= ExtraTest;
  end;
end;

function AddPath(const P1, P2: string): string;
var
  delim: Char;
begin
  if (Pos('\', P1) > 0)
    or (Pos('\', P2) > 0)
  then
    delim:= '\'
  else
    delim:= '/';
  Result:= '';
  if (P1 <> '') then begin
    if P1[Length(P1)] = delim then
      Result:= P1
    else
      Result:= P1 + delim;
  end;
  if P2 <> '' then begin
    if (P2[1] <> delim) or (P1 = '') then
      Result:= Result + P2
    else
      Result:= Result + copy(P2, 2, MaxInt);
  end;
  if (Result <> '') and (Result[Length(Result)] = delim) then
    Delete(Result, Length(Result), 1);
end;

function AddRelPath(const P1, P2: string): string;
begin
  if Pos(':', P2) <= 0 then result:= AddPath(P1,P2)
  else result:= P2;
end;

function ApplicationPath: string;
begin
	Result:= ExtractFilePath(ParamStr(0));
end;

function CheckClass(AObject: TObject; AClass: TClass; var ResObject): Boolean; {$ifdef COMPILER_INLINE} inline; {$endif}
begin
  Result:= (AObject <> nil) and AObject.InheritsFrom(AClass);
  if Result then
    TObject(ResObject):= AObject
  else
    TObject(ResObject):= nil;
end;

function CheckPointer(APointer: Pointer; var ResPointer): Boolean; {$ifdef COMPILER_INLINE} inline; {$endif}
begin
  Result:= (APointer <> nil);
  if Result then
    Pointer(ResPointer):= APointer
  else
    Pointer(ResPointer):= nil;
end;

function Closure(Code: Pointer; Data: TObject): TMethod;
begin
  Result.Code:= Code;
  Result.Data:= Data;
end;

procedure DbgTrace(const Msg: AnsiString);
begin
  if Assigned(HookDebugTrace) then HookDebugTrace(Msg);
end;

procedure DbgTrace(const Msg: WideString);
begin
  if Assigned(HookDebugTrace) then HookDebugTrace(Msg);
end;

procedure DbgTraceFmt(const Fmt: String; const Args: array of const);
begin
	if Assigned(HookDebugTrace) then
    HookDebugTrace(Format(Fmt, Args));
end;

procedure DbgTraceFmt(const Fmt: WideString; const Args: array of const);
begin
	if Assigned(HookDebugTrace) then
    HookDebugTrace(Format(Fmt, Args));
end;

function EncodeByteArray(const aData: array of byte;
	const aCodeTable: string): string;
var
	codebits, usedbits, i, highA: Integer;
	code, temp, mask: Cardinal;
begin
  highA:= High(aData);
	code := Length(aCodeTable); //highA + 1;
	codebits:= 0;
	mask:= 0;
	while code >= 2 do begin
		code:= code shr 1;
		mask:= (mask shl 1) or 1;
		inc(codebits);
	end;
	Result:= '';
	i:= 0;
	usedbits:= 0;
	code:= 0;
	while true do begin
		while usedbits < codebits do begin
			if i <= HighA then begin
				inc(usedbits, 8);
				code:= (code shl 8) or aData[i];
				inc(i);
			end else begin
				if usedbits > 0 then begin
					//mask:= mask shr (codebits - usedbits);
					code:= code shl (codebits - usedbits);
					temp:= code and mask;
					Result:= Result + aCodeTable[temp + 1];
				end;
				exit;
			end;
		end;
		dec(usedbits, codebits);
		temp:= (code shr (usedbits)) and mask;
		Result:= Result + aCodeTable[temp + 1];
	end;
end;

function DecodeByteArray(const aStr:	string;
	const aCodeTable: string): TDynamicByteArray;
var
	codebits, usedbits, i, ir: Integer;
	code, temp, mask: Cardinal;
	ReverseCode: array [char] of Smallint;
begin
	code := Length(aCodeTable);
	codebits:= 0;
	mask:= $ff;
	while code >= 2 do begin
		code:= code shr 1;
		inc(codebits);
	end;
	FillChar(ReverseCode, 2 * (Ord(High(ReverseCode)) + 1), $FF);
	for i:= 1 to Length(aCodeTable) do begin
		ReverseCode[aCodeTable[i]] := i-1;
	end;
	Result:= nil;
	ir:= 0;
	i:= 1;
	usedbits:= 0;
	code:= 0;
	while true do begin
		while usedbits < 8 do begin
			if i <= Length(aStr) then begin
				if ReverseCode[aStr[i]] >= 0 then begin
					inc(usedbits, codebits);
					code:= (code shl codebits) or Word(ReverseCode[aStr[i]]);
				end;
				inc(i);
			end else begin
				if usedbits > 0 then begin
					mask:= mask shr (8 - usedbits);
					temp:= code and mask;
					exit;
					SetLength(Result, ir +1);
					Result[ir]:= temp;
					//inc(ir);
				end;
				exit;
			end;
		end;
		dec(usedbits, 8);
		temp:= (code shr (usedbits)) and mask;
		SetLength(Result, ir +1);
		Result[ir]:= temp;
		inc(ir);
	end;
end;

function ExecuteFile(const FileName, Params, DefaultDir: string;
	ShowCmd: Integer): THandle;
var
	aHandle: THandle;
begin
  result:= 0;
{$ifndef Linux}
{$IFNDEF FPC}
	if Application.MainForm = nil then
		aHandle := Application.Handle
	else
		aHandle := Application.MainForm.Handle;
{$ELSE}
  aHandle:= 0;
{$ENDIF}
  {$IFDEF Win32}
	Result := ShellExecute(aHandle, PChar('open'),
		PChar('"'+FileName+'"'), PChar(Params),	PChar('"'+DefaultDir+'"'), ShowCmd);
  {$ENDIF}
{$else}
	// not implemented yet
{$endif}
end;

function ExtractFileNameOnly(const aFile: string): string;
var
	i:	integer;
begin
	result := ExtractFileNameWeb(aFile);
	for i:= length(result) downto 1 do
		if result[i]='.' then break;
	if i > 1 then
		SetLength(result, i-1);
end;

function ExtractFileNameWeb(const FileName: string): string;
var
  delim: Char;
  I: Integer;
begin
  if (Pos('\', FileName) > 0)
  then
    delim:= '\'
  else
    delim:= '/';
  I := LastDelimiter(delim + DriveDelim, FileName);
  Result := Copy(FileName, I + 1, MaxInt);
end;

function ExtractFilePathWeb(const FileName: string): string;
var
  delim: Char;
  I: Integer;
begin
  if (Pos('\', FileName) > 0)
  then
    delim:= '\'
  else
    delim:= '/';
  I := LastDelimiter(delim + DriveDelim, FileName);
  Result := Copy(FileName, 1, I);
end;

function ProgramData: string;
var
  s: string;
begin
  Result:= Sysutils.GetEnvironmentVariable('ProgramData');
  if Result = '' then begin
    Result:= IncludeTrailingPathDelimiter(Sysutils.GetEnvironmentVariable('ALLUSERSPROFILE'));
    s:= ExtractFileName(ExcludeTrailingPathDelimiter(Sysutils.GetEnvironmentVariable('APPDATA')));
    if s = '' then begin
      s:= 'Anwendungsdaten';
      if not DirectoryExists(Result + s) then
        s:= 'Application Data';
    end;
    Result:= Result + s;
  end;
end;

function EndsWith(const sEnd, s: string): boolean;
begin
	result := LowerCase(sEnd) = LowerCase(copy(s, 1 + Length(s) - length(sEnd), MaxInt));
end;

function StartsWith(const sStart, s: string): boolean;
begin
	result := LowerCase(sStart) = LowerCase(copy(s,1,length(sStart)));
end;

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


end.
