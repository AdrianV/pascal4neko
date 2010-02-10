unit WebIniFiles;

interface
uses
  SysUtils, Classes, IniFiles, Registry, blcksock, synautil, synacode, httpsend,
  p4nHelper, nekoHelper, //Helper,
{$IFDEF WIN32}
  //HelperWin,
{$ENDIF}
  JclSysInfo;

type
  PIniStack = ^TIniStack;
  ILoadStream = interface
    ['{2F4FF917-375F-4103-B147-BFCDCC29D15B}']
    function GetStream: TStream;
    property Stream: TStream read GetStream;
  end;
  IWebPath = interface
    ['{AC949B78-2697-4411-9B81-1A7C2C035D5D}']
    function GetPath: string;
    function GetFile: string;
    function GetParam: string;
    function GetDelim: Char;
    function GetIsLocal: Boolean;
    function PathOf(const AFileName: string = ''): string;

    property Path: string read GetPath;
    property FileName: string read GetFile;
    property Param: string read GetParam;
    property IsLocal: Boolean read GetIsLocal;
  end;
  IWebUpdate = interface
    ['{CEC2C3BF-F8AC-4CD5-B498-EFBEAE44EAC3}']
    function NeedUpdate(): Boolean;
    function DownloadUpdate: Boolean;
    function RunUpdate(const Param: string = ''): Boolean;
  end;
  TWebPath = class(TInterfacedObject, IWebPath)
  private
    FPath: string;
    FFile: string;
    FParam: string;
    FIsLocal: Boolean;
    FDelim: Char;
  protected
    function GetPath: string;
    function GetFile: string;
    function GetParam: string;
    function GetDelim: Char;
    function GetIsLocal: Boolean;
    function PathOf(const AFileName: string = ''): string;
  public
    class function FromString(APath: string): IWebPath;
  end;
  TWebIniFile = class(TMemIniFile)
  private
    inis: PIniStack;
    pIni: TWebIniFile;
  protected
    FIdent: string;
    function GetIni(const s: string): TWebIniFile;
    procedure LoadValues;
    procedure Rename(const FileName: string; Reload: Boolean);
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
    function Expand(const s: string): string;
    function ReadString(const Section, Ident, Default: string): string; override;
  end;
  TIniStack = record
    name: string;
    ini: TWebIniFile;
    next: PIniStack;
  end;

function OpenStream(const AFileName: string): ILoadStream;
function CheckUpdate(AppName: string = ''): IWebUpdate;

implementation

type
  TLoadStream = class (TInterfacedObject, ILoadStream)
  private
    FStream: TStream;
    FObject: TObject;
    function GetStream: TStream;
  protected
    destructor Destroy; override;
    constructor Create(const AFileName: string);
  end;
  TWebUpdate = class (TInterfacedObject, IWebUpdate)
  private
    FAppName: string;
    FIni: TWebIniFile;
  protected
    function NeedUpdate(): Boolean;
    function DownloadUpdate: Boolean;
    function RunUpdate(const Param: string = ''): Boolean;
  public
    destructor Destroy; override;
  end;

{ TWebIniFile }

constructor TWebIniFile.Create(const FileName: string);
begin
  inherited Create('');
  inherited Rename(FileName, False);
  LoadValues;
end;

type
  PExpandStack = ^TExpandStack;
  TExpandStack = record
    s: string;
    next: PExpandStack;
  end;

threadvar
  Flevel: Integer;

destructor TWebIniFile.Destroy;
var
  t: PIniStack;
begin
  while inis <> nil do begin
    t:= inis;
    inis:= inis.next;
    t.ini.Free;
    t.name:= '';
    Dispose(t);
  end;
  inherited;
end;

function TWebIniFile.Expand(const s: string): string;

var
  i, ls, x: Integer;
  stack: PExpandStack;


  function Convert(s: string): string;
  var
    s1, p1, p2, p3, sIdent: string;
    ini: TWebIniFile;
  begin
    sIdent:= FIdent;
    s1:= SplitString(s, ':');
    ini:= nil;
    if SameText(s1, 'ini') then try
      inc(Flevel);
      if Flevel < 30 then begin
        p1:= SplitString(s, ',');
        p2:= SplitString(s, ',');
        p3:= SplitString(s, '|');
        if p1 <> '' then
          ini:= GetIni(p1)
        else ini:= Self;
        Result:= ini.ReadString(p2, p3, s);
      end else
        Result:= '';
    finally
      dec(Flevel);
    end else if SameText(s1, 'env') then begin
      p1:= SplitString(s, '|');
      //p2:= SplitStringAt(s, '|');
      GetEnvironmentVar(p1, Result, True);
      if Result = '' then
        Result:= s;
      //if p2 <> '' then
      //  Result:= AddPath(Result, p2);
    end else if SameText(s1, 'cwd') then begin
      GetDir(0, Result);
      if s <> '' then
        Result:= AddPath(Result, s);
    end else if SameText(s1, 'appath') then begin
      Result:= AddPath(ApplicationPath, s);
    end else if SameText(s1, 'ProgramData') then begin
      Result:= AddPath(ProgramData, s);
    end else if SameText(s1, 'reg') then begin
      p1:= SplitString(s, ',');
      p2:= SplitString(s, ',');
      p3:= SplitString(s, '|');
      with TRegIniFile.Create(p1) do try
        Result:= ReadString(p2, p3, s);
      finally
        Free;
      end;
    end else if s1 = '<' then begin
      Result:='{';
    end else if s1 = '>' then begin
      Result:='}';
    end else if SameText(s1, 'key') then begin
      Result:=FIdent;
    end else
      Result:= s1;
    FIdent:= sIdent;
  end;

  function Pop: string;
  var
    it: PExpandStack;
  begin
    if stack <> nil then begin
      Result:= stack.s;
      it:= stack;
      stack:= stack.next;
      it.s:= '';
      Dispose(it);
    end else
      Result:= '';
  end;

  procedure Push;
  var
    it: PExpandStack;
  begin
    New(it);
    it.s:= Result;
    //it.x:= x;
    it.next:= stack;
    stack:= it;
    Result:= '';
  end;

begin
  stack:= nil;
  Result:= '';
  ls:= Length(s);
  i:= 1;
  x:= 1;
  try
    while i <= ls do begin
      case s[i] of
        '{': begin
          Result:= Result + copy(s, x, i - x);
          Push;
          x:= i + 1;
        end;
        '}': begin
          Result:= Pop + Convert(Result + copy(s, x, i - x));
          x:= i + 1;
          case s[x] of
            '\','/': if (Result <> '') and (Result[Length(Result)] = s[x]) then begin
              inc(x);
              inc(i);
            end;
          end;
        end;
      end;
      inc(i);
    end;
    Result:= Result + copy(s, x, i - x);
    while stack <> nil do
      Result:= Pop + Result;
  finally
    while stack <> nil do Pop;
  end;
end;

function TWebIniFile.GetIni(const s: string): TWebIniFile;
var
  t: PIniStack;
begin
  if SameText(s, FileName) then begin
    Result:= Self;
  end else if pIni <> nil then begin
    Result:= pIni.GetIni(s)
  end else begin
    t:= inis;
    while t <> nil do begin
      if SameText(s, t.name) then begin
        Result:= t.ini;
        exit;
      end;
      t:= t.next;
    end;
    Result:= TWebIniFile.Create(s);
    Result.pIni:= Self;
    New(t);
    t.next:= inis;
    inis:= t;
    t.name:= s;
    t.ini:= Result;
  end;
end;

procedure TWebIniFile.LoadValues;
var
  List: TStringList;
  stream: ILoadStream;
  t: PIniStack;
begin
  t:= inis;
  while t <> nil do begin
    t.ini.LoadValues;
    t:= t.next;
  end;
  List:= nil;
  stream:= OpenStream(FileName);
  try
    if stream.Stream <> nil then begin
      stream.Stream.Position:= 0;
      List:= TStringList.Create;
      //List.LineBreak:= #$a;
      List.LoadFromStream(stream.Stream);
      SetStrings(List);
    end else
      Clear;
  finally
    List.Free;
  end;
end;

function TWebIniFile.ReadString(const Section, Ident, Default: string): string;
var
  s: string;
begin
  FIdent:= Ident;
  s:= inherited ReadString(Section, Ident, Default);
  Result:= Expand(s);
  if (Result = '') and (s <> '') then
    Result:= Expand(Default);
end;

procedure TWebIniFile.Rename(const FileName: string; Reload: Boolean);
begin
  inherited Rename(FileName, False);
  if Reload then
    LoadValues;
end;

{ TLoadStream }

constructor TLoadStream.Create(const AFileName: string);
begin
  if StartsWith('http://', AFileName)
    or StartsWith('https://', AFileName)
  then begin
    FObject:= THTTPSend.Create;
    if THTTPSend(FObject).HTTPMethod('GET', AFileName)
      and (THTTPSend(FObject).ResultCode = 200)
    then
      FStream:= THTTPSend(FObject).Document;
  end else begin
    if FileExists(AFileName) then begin
      FStream:= TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
      FObject:= FStream;
    end;
  end;
end;

destructor TLoadStream.Destroy;
begin
  //if FStream is TFileStream then
  //  DbgTraceFmt('close %s', [TFileStream(FStream).FileName]);
  FObject.Free;
  inherited;
end;

function TLoadStream.GetStream: TStream;
begin
  Result:= FStream;
end;

function OpenStream(const AFileName: string): ILoadStream;
begin
  Result:= TLoadStream.Create(AFileName);
end;

{ TWebPath }

class function TWebPath.FromString(APath: string): IWebPath;
var
  me: TWebPath;
  i: Integer;
begin
  me:= Create;
  Result:= me;
  if Pos('/', APath) > 0 then begin
    me.FDelim:= '/';
    me.FIsLocal:= APath[1] = '/'; // Pos(':', APath) < 2;
    me.FPath:= SplitString(APath, '?');
    me.FParam:= APath;
  end else begin
    me.FDelim:= '\';
    me.FIsLocal:= True;
    if Pos('\', APath) = 0 then begin
      me.FFile:= APath;
      exit;
    end;
    me.FPath:= APath;
  end;
  for i := Length(me.FPath) downto 1 do begin
    if me.FPath[i] = me.FDelim then begin
      me.FFile:= copy(me.FPath, i + 1, MaxInt);
      System.Delete(me.FPath, i, MaxInt);
      break;
    end;
  end;
end;

function TWebPath.GetDelim: Char;
begin
  Result:= FDelim;
end;

function TWebPath.GetFile: string;
begin
  Result:= FFile;
end;

function TWebPath.GetIsLocal: Boolean;
begin
  Result:= FIsLocal;
end;

function TWebPath.GetParam: string;
begin
  Result:= FParam;
end;

function TWebPath.GetPath: string;
begin
  Result:= FPath;
end;

function TWebPath.PathOf(const AFileName: string): string;
var
  s: string;
begin
  if AFileName <> '' then begin
    if not FIsLocal then
      s:= EncodeURL(AFileName)
    else
      s:= AFileName;
  end else
    s:= FFile;
  if FPath <> '' then
    Result:= FPath+ FDelim
  else
    Result:= '';
  Result:= Result + s;
  if FParam <> '' then
    Result:= Result + '?' + FParam;
end;

{ TWebUpdate }

function CheckUpdate(AppName: string = ''): IWebUpdate;
var
  me: TWebUpdate;
begin
  me:= TWebUpdate.Create;
  if AppName = '' then
    me.FAppName:= ExtractFileName(ParamStr(0))
  else
    me.FAppName:= AppName;
  me.FIni:= TWebIniFile.Create(ApplicationPath + 'Versions.ini');
  Result:= me;
end;

destructor TWebUpdate.Destroy;
begin
  FIni.Free;
  inherited;
end;

function TWebUpdate.DownloadUpdate: Boolean;

  function TestMD5(AStream: TStream; const sMD5: string): Boolean;
  var
    s: string;
  begin
    Result:= False;
    if AStream.Size <= 0 then
      exit;
    AStream.Position:= 0;
    SetLength(s, AStream.Size);
    SetLength(s, AStream.Read(s[1], Length(s)));

    Result:= EncodeByteArray(TDynamicByteArray(MD5(s)), '0123456789abcdef') = sMD5;
    AStream.Position:= 0;
  end;

var
  sDown, sWeb, sControl, sUpd, sMD5: string;
  load: ILoadStream;
begin
  Result:= False;
  sDown:= ExcludeTrailingPathDelimiter( FIni.ReadString(FAppName, 'DownloadPath', '{ini:,INIT,{key}|{env:TEMP}}'));
  ForceDirectories(sDown);
  sWeb:= FIni.ReadString(FAppName, 'UpdatePath', '{ini:,INIT,{key}}');
  sControl:= AddPath(sWeb, FIni.ReadString(FAppName, 'Control', '{ini:,INIT,{key}|current.ini}'));
  sUpd:= FIni.ReadString('-', '-', Format('{ini:%s,%s,Update}',[sControl, FAppName]));
  sMD5:= FIni.ReadString('-', '-', Format('{ini:%s,%s,MD5}',[sControl, FAppName]));
  sDown:= AddPath(sDown, sUpd);
  if FileExists(sDown) then begin
    load:= OpenStream(sDown);
    Result:= (load.Stream <> nil) and ((sMD5 = '') or TestMD5(load.Stream, sMD5));
    load:= nil;
    if Result then
      exit;
    DbgTraceFmt('file %s exists, md5 mismatch', [sDown]);
    if not DeleteFile(sDown) then begin
{$IFDEF WIN32}
      DbgTraceFmt('cannot delete file %s reason: %d', [sDown, GetLastError]);
      //DbgTraceFmt('cannot delete file %s reason: %s', [sDown, GetLastErrorString]);
{$ELSE}
      DbgTraceFmt('cannot delete file %s reason: %d', [sDown, GetLastError]);
{$ENDIF}
    end;
  end;
  DbgTraceFmt('download from %s to %s', [AddPath(sWeb, sUpd), sDown]);
  load:= OpenStream(AddPath(sWeb, sUpd));
  if (load.Stream <> nil) and (load.Stream.Size > 0) then begin
    try
      if (sMD5 = '') or TestMD5(load.Stream, sMD5) then begin
        with TFileStream.Create(sDown, fmCreate) do try
          Result:= CopyFrom(load.Stream, load.Stream.Size) = load.Stream.Size;
        finally
          Free;
        end;
        if not Result then begin
          DbgTraceFmt('cannot copy %s to %s', [AddPath(sWeb, sUpd), sDown]);
        end;
      end else begin
        DbgTraceFmt('md5 mismatch for %s', [AddPath(sWeb, sUpd)]);
      end;
    except
      Result:= False;
    end;
    if not Result then
      DeleteFile(sDown);
  end else begin
    DbgTraceFmt('download from %s failed', [AddPath(sWeb, sUpd)]);
  end;
end;

function TWebUpdate.NeedUpdate(): Boolean;
var
  sControl: string;
  iVersInst, iVersUpd: Integer;
begin
  with Fini do begin
    sControl:= AddPath(FIni.ReadString(FAppName, 'UpdatePath', '{ini:,INIT,{key}}'), FIni.ReadString(FAppName, 'Control', '{ini:,INIT,{key}|current.ini}'));
    Result:=(ReadString('INIT', 'Version', '0') = ReadString('-', '-', Format('{ini:%s,INIT,Version|0}',[sControl])));
    if Result then begin
      iVersInst:=ReadInteger('INSTALLED', FAppName, 0);
      iVersUpd:= StrToIntDef( ReadString('-', '-', Format('{ini:%s,%s,Revision|0}',[sControl, FAppName])), 0);
      Result:= (iVersInst < iVersUpd);
      DbgTraceFmt('Update control: %s - version installed: %d version in update: %d', [sControl, iVersInst, iVersUpd]);
    end else begin
      DbgTraceFmt('Update control: %s - no matching versions found', [sControl]);
    end;
  end;
end;

function TWebUpdate.RunUpdate(const Param: string): Boolean;
var
  sDown, sControl, sUpd, sParam: string;
begin
  Result:= False;
  sDown:= ExcludeTrailingPathDelimiter( FIni.ReadString(FAppName, 'DownloadPath', '{env:TEMP}'));
  sControl:= AddPath(FIni.ReadString(FAppName, 'UpdatePath', '{ini:,INIT,{key}}'), FIni.ReadString(FAppName, 'Control', '{ini:,INIT,{key}|current.ini}'));
  sUpd:= FIni.ReadString('-', '-', Format('{ini:%s,%s,Update}',[sControl, FAppName]));
  sParam:= FIni.ReadString('-', '-', Format('{ini:%s,%s,Parameter}',[sControl, FAppName]));
  sUpd:= AddPath(sDown, sUpd);
  if FileExists(sUpd) then begin
    if Param <> '' then
      sParam:= sParam + ' ' + Param;
    DbgTraceFmt('run %s %s in %s', [sUpd, sParam, sDown]);
    if p4nHelper.ExecuteFile(sUpd, sParam, sDown) > 32 then begin
      Result:= True;
    end;
  end else begin
    DbgTraceFmt('cannot find %s', [sUpd]);
  end;
end;

end.
