unit WebIniFiles;

interface
uses
  SysUtils, Classes, IniFiles, Registry, blcksock, synautil, synacode, httpsend,
  p4nHelper , ProxySettings //, nekoHelper, //Helper,
{$IFDEF WIN32}
  //HelperWin,
{$ENDIF}
  //,JclSysInfo;
  ;

type
  PIniStack = ^TIniStack;
  TLoadProgressCallback = procedure(BytesLoaded, BytesTotal: Integer) of object;
  ILoadStream = interface
    ['{2F4FF917-375F-4103-B147-BFCDCC29D15B}']
    function GetIsLocal: Boolean;
    function GetFileName: String;
    function GetStream: TStream;
    property IsLocal: Boolean read GetIsLocal;
    property FileName: String read GetFileName;
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
    FSec: string;
    function GetIni(const s: string): TWebIniFile;
    procedure LoadValues;
    procedure Rename(const FileName: string; Reload: Boolean);
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
    function Expand(const s: string): string;
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure ReadExpandedSectionValues(const Section: string; Strings: TStrings); 
    procedure WriteSectionValues(const Section: string; Strings: TStrings); 
  end;
  TIniStack = record
    name: string;
    ini: TWebIniFile;
    next: PIniStack;
  end;

function OpenStream(const AFileName: string; ACallback: TLoadProgressCallback = nil): ILoadStream;
function CheckUpdate(const AppName: string = ''; const AParams: string = ''; ACallback: TLoadProgressCallback = nil): IWebUpdate;

implementation

type
  TLoadStream = class (TInterfacedObject, ILoadStream)
  private
  	FIsLocal: Boolean;
  	FFileName: String;
    FStream: TStream;
    FObject: TObject;
    FCallback: TLoadProgressCallback;
    function GetIsLocal: Boolean;
    function GetFileName: String;
    function GetStream: TStream;
    procedure HookSocket(Sender: TObject; Reason: THookSocketReason; const Value: String);
  protected
    destructor Destroy; override;
    constructor Create(const AFileName: string; ACallback: TLoadProgressCallback);
  end;
  TWebUpdate = class (TInterfacedObject, IWebUpdate)
  private
    FAppName: string;
    FIni: TWebIniFile;
    FParams: string;
    FCallback: TLoadProgressCallback;
  protected
    function NeedUpdate(): Boolean;
    function DownloadUpdate: Boolean;
    function RunUpdate(const Param: string = ''): Boolean;
  public
  	constructor Create(ACallback: TLoadProgressCallback);
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
	FIdent:= '';  
  FSec:= '';
	inherited;
end;

function TWebIniFile.Expand(const s: string): string;

var
  i, ls, x: Integer;
  stack: PExpandStack;


  function Convert(s: string): string;
  var
    s1, p1, p2, p3, sIdent, sSec: string;
    ini: TWebIniFile;
  begin
    sIdent:= FIdent;
    sSec:= FSec;
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
        if (p2 = '') and (s = '') then begin
          s:= FileName;
          if SameText(p3, 'Name') then
            s:= ExtractFileName(s)
          else if SameText(p3, 'Path') then
            s:= ExtractFilePathWeb(s)
          else if SameText(p3, 'Drive') then
            s:= ExtractFileDrive(s)
          else if SameText(p3, 'Extension') then
            s:= ExtractFileExt(s)
          else if SameText(p3, 'Dir') then
            s:= ExtractFileDir(s)
        end;
        Result:= ini.ReadString(p2, p3, s)
      end else
        Result:= '';
    finally
      dec(Flevel);
    end else if SameText(s1, 'env') then begin
      p1:= SplitString(s, '|');
      //p2:= SplitStringAt(s, '|');
      Result:= GetEnvironmentVariable(p1);
      //GetEnvironmentVar(p1, Result, True);
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
    end else if s1 = '^' then begin
      Result:='^';
    end else if s1 = '~' then begin
      Result:='~';
    end else if SameText(s1, 'key') then begin
      Result:=FIdent;
    end else if SameText(s1, 'sec') then begin
      Result:=FSec;
    end else
      Result:= s1;
    FIdent:= sIdent;
    FSec:= sSec;
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
  	if (ls > 0) then begin
    	case s[i] of
      	'^': begin
	      	Result:= s;
  		    exit;
        end;
      	'~': begin
	      	Result:= copy(s, 2, ls);
  		    exit;
        end;
      end;
    end;
    while i <= ls do begin
      case s[i] of
        '{': begin
          Result:= Result + copy(s, x, i - x);
          Push;
          x:= i + 1;
        end;
        '}': begin
        	if (Result <> '') and (Result[1]='#') then
          	Result:= Pop + Expand(copy(Result, 2, MaxInt) + copy(s, x, i - x))
          else
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

procedure TWebIniFile.ReadExpandedSectionValues(const Section: string;
  Strings: TStrings);
var
  i: Integer;
begin
  Strings.BeginUpdate;
  try
    ReadSectionValues(Section, Strings);
    for i := 0 to Strings.Count - 1 do
      Strings.Strings[i]:= Expand(Strings.Strings[i]);
  finally
    Strings.EndUpdate;
  end;
end;

//var
//	cnt_plan: Integer = 0;

function TWebIniFile.ReadString(const Section, Ident, Default: string): string;
var
  s: string;
  i, j: Integer;
begin
	FSec:= Section;
  FIdent:= Ident;
  s:= inherited ReadString(Section, Ident, Default);
  Result:= Expand(s);
  if (Result = '') and (s <> '') then
    Result:= Expand(Default);
  {if Result = 'D:\Borland\Delphi5\Projects\Planung\TIM.ini' then begin
    Result:= LowerCase(Result);
    j:= 0;
    for i := 0 to Length(Result) do
    	case Result[i] of
      	'a'..'z': begin  
           Result[i]:= Char(Ord(Result[i]) - (Ord('a') - Ord('A')));	
        	 if j = cnt_plan then break;
           inc(j);
        end;  
      end;
    inc(cnt_plan);  
  end;}
end;

procedure TWebIniFile.Rename(const FileName: string; Reload: Boolean);
begin
  inherited Rename(FileName, False);
  if Reload then
    LoadValues;
end;

procedure TWebIniFile.WriteSectionValues(const Section: string;
  Strings: TStrings);
var
  I: Integer;
  Sto: TStrings;
  All: TStringList;
begin
  All:= TStringList.Create;
  All.BeginUpdate;
  try
    All.CaseSensitive:= False;
    GetStrings(All);
    I := All.IndexOf('[' + Section + ']');
    if I >= 0 then begin
      All.Delete(I);
      while (I < All.Count)
        and ( (All[I] = '') or (All[I][1] <> '['))
      do
        All.Delete(I);
    end;
    All.Add('[' + Section + ']');
    for I := 0 to Strings.Count - 1 do
      All.Add(Strings[I]);
    SetStrings(All);
  finally
    All.EndUpdate;
    All.Free;
  end;
end;

{ TLoadStream }

constructor TLoadStream.Create(const AFileName: string; ACallback: TLoadProgressCallback);
var
	fs: TFileStream;
begin
	FFileName:= AFileName;
  if StartsWith('http://', AFileName)
    or StartsWith('https://', AFileName)
  then begin
    FObject:= THTTPSend.Create;
    if Assigned(ACallback) then begin
      FCallback:= ACallback;
      THTTPSend(FObject).Sock.OnStatus:= HookSocket;
    end;
    SetProxy(THTTPSend(FObject), AFileName);
    if THTTPSend(FObject).HTTPMethod('GET', AFileName)
      and (THTTPSend(FObject).ResultCode = 200)
    then
      FStream:= THTTPSend(FObject).Document
    else if THTTPSend(FObject).ProxyHost <> '' then begin
    	FObject.Free;
      FObject:= THTTPSend.Create;
    	THTTPSend(FObject).ProxyHost:= '';
	    if THTTPSend(FObject).HTTPMethod('GET', AFileName)
  	    and (THTTPSend(FObject).ResultCode = 200)
    	then
      	FStream:= THTTPSend(FObject).Document
    end;
  end else begin
    if FileExists(AFileName) then begin
    	FIsLocal:= True;
      fs:= TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
      try
	      FStream:= TMemoryStream.Create;
	      FObject:= FStream;
  	    FStream.CopyFrom(fs, 0);
        FStream.Position:= 0;
      finally
      	fs.Free;
      end;
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

function TLoadStream.GetFileName: String;
begin
	Result:= FFileName;
end;

function TLoadStream.GetIsLocal: Boolean;
begin
	Result:= FIsLocal;
end;

function TLoadStream.GetStream: TStream;
begin
  Result:= FStream;
end;

procedure TLoadStream.HookSocket(Sender: TObject; Reason: THookSocketReason;
  const Value: String);
begin
	if Reason = HR_ReadCount then
  	FCallback(THTTPSend(FObject).sock.RecvCounter , THTTPSend(FObject).DownloadSize);
end;

function OpenStream(const AFileName: string; ACallback: TLoadProgressCallback): ILoadStream;
begin
  Result:= TLoadStream.Create(AFileName, ACallback);
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

function CheckUpdate(const AppName: string; const AParams: string; ACallback: TLoadProgressCallback): IWebUpdate;
var
  me: TWebUpdate;
begin
  me:= TWebUpdate.Create(ACallback);
  if AppName = '' then
    me.FAppName:= ExtractFileName(ParamStr(0))
  else
    me.FAppName:= AppName;
  me.FParams:= AParams;
  me.FIni:= TWebIniFile.Create(ApplicationPath + 'Versions.ini');
  Result:= me;
end;

constructor TWebUpdate.Create(ACallback: TLoadProgressCallback);
begin
	FCallback:= ACallback;
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
    load:= OpenStream(sDown, FCallback);
    Result:= (load.Stream <> nil) and ((sMD5 = '') or TestMD5(load.Stream, sMD5));
    load:= nil;
    if Result then
      exit;
    DbgTraceFmt('file %s exists, md5 mismatch', [sDown]);
    if not DeleteFile(sDown) then begin
{$IFNDEF FPC}
{$IFDEF WIN32}
      DbgTraceFmt('cannot delete file %s reason: %d', [sDown, GetLastError]);
      //DbgTraceFmt('cannot delete file %s reason: %s', [sDown, GetLastErrorString]);
{$ELSE}
      DbgTraceFmt('cannot delete file %s reason: %d', [sDown, GetLastError]);
{$ENDIF WIN32}
{$ENDIF FPC}
    end;
  end;
  DbgTraceFmt('download from %s to %s', [AddPath(sWeb, sUpd), sDown]);
  load:= OpenStream(AddPath(sWeb, sUpd), FCallback);
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
		if (FParams <> '') and (Pos('\', sControl) = 0) then begin
			sControl:= sControl + '?' + FParams;    
    end;
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
  sDown:= ExcludeTrailingPathDelimiter( FIni.ReadString(FAppName, 'DownloadPath', '{ini:,INIT,DownloadPath|{env:TEMP}}'));
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
