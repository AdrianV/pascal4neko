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
{ The Original Code is ModNeko.pas.                                                                }
{                                                                                                  }
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             }
{ Portions created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                }
{                                                                                                  }
{ Contributors:                                                                                    }
{   Adrian Veith                                                                                   }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ An Object Pascal implementation of the MOD_NEKO for use with the visualsynapse http-seerver.     }
{                                                                                                  }
{**************************************************************************************************}

unit ModNeko;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface
uses Classes, SysUtils, typinfo,
  {$IFDEF LINUX}Types, {$ELSE}Windows, {$ENDIF}
  {$IFNDEF FPC}{$IFNDEF LINUX}filectrl, {$ENDIF}{$ENDIF}
  blcksock, visualserverbase, inifiles, vstypedef, ExecCGI,
  synacode, synautil, mimemess, authentication, httpServer,
  neko, nekoHelper, p4nHelper, SyncObjs;

const
  daIdle = 0;
  daRunning = 1;
  daRunningAcc = 2;
  daFinished = 3;
  daError = 4;
  daShuttdown = 5;
  qsAccepting = 0;
  qsShutdown = -1;

type
  PIPInfo = ^TIPInfo;
  PSettings = ^TSettings;
  PCGIResult = ^TCGIResult;
  PHTTPRequest = ^THTTPRequest;
  TModeNekoParser = class;
  TRequestQueue = record
    req: PHTTPRequest;
    next: Integer;
    prior: Integer;
  end;
  TContext = record
	  r: PHTTPRequest;
	  main: value;
	  //post_data: value;
	  content_type: value;
	  headers_sent: Boolean;
    classes: value;
  end;
  PContext = ^TContext;
  TNekoRequestThread = class(TThread)
    FFileName: string;
    FHash: Integer;
    FTime: TDateTime;
    FLastTimeCheck: Cardinal;
    FReload: Integer;
    //Fvm: Pneko_vm;
    Fctx: TContext;
    //FRequestQueue: array of TRequestQueue;
    //FQueueFree: Integer;
    FFirst: PHTTPRequest;
    FLast: PHTTPRequest;
    FQueueState: Integer;
    FQueueLock: TCriticalSection;
    //FHasRequest: TEvent;
    FNekoParser: TModeNekoParser;
  protected
    procedure Execute; override;
    procedure PushRequest(req: PHTTPRequest);
    function PopRequest(): PHTTPRequest;
    procedure ShutDown;
  public
    constructor Create(AParent: TModeNekoParser; const AFileName: string; req: PHTTPRequest);
    destructor Destroy; override;
  end;
  TCacheMod = class
    main: Pvalue;
    FileName: string;
    Hits: Integer;
    Time: Integer;
    Lock: TCriticalSection;
    Hash: Integer;
    constructor Create(AMain: value; r: PHTTPRequest);
    destructor Destroy; override;
    procedure Cache(AMain: value; r: PHTTPRequest);
    function isCached(r: PHTTPRequest): Boolean;
  end;
  TModeNekoParser = class(TPreParser)
  private
    var FCache: TThreadList;
    var FModules: TThreadList;
    function ClearCache(Index: Integer): Boolean;
    function FindCache(r: PHTTPRequest): TCacheMod;
    function RunRequest(r: PHTTPRequest): TNekoRequestThread;
    procedure Kill(m: TNekoRequestThread);
    procedure RemoveModule(m: TNekoRequestThread);
    procedure ShutDown;
  protected
    function Execute(const FileName: string; Handler: TvsHTTPHandler): THttpConnectionMode; override;
  public
  	constructor Create(Server: TvsHTTPServer); override;
    destructor Destroy; override;
  end;
  TRequestResult = (rrOk, rrException, rrTimeout, rrShutdown);
  THTTPRequest = record
    H: TvsHTTPHandler;
    FileName: string;
    ModNeko: TModeNekoParser;
    //FTime: Integer;
    Hash: Integer;
    StartTick: Cardinal;
    DataAvailable: Integer;
    FNext, FPrior: PHTTPRequest;
    FHandle: THandle;
    procedure Create(AModNeko: TModeNekoParser; AHandler: TvsHTTPHandler; const AFileName: string);
    function DoRequest: Boolean; deprecated;
    function WaitForRequest: TRequestResult;
  end;

var
  __k_mod_neko: Tvkind;
  k_mod_neko: vkind = @ __k_mod_neko;

function CONTEXT: PContext; inline;

implementation
{$WRITEABLECONST ON}

type
  PCache = ^TCache;
  TCache = record
    _file: value;
    main: value;
    hits: Integer;
    time: Integer;
    next: PCache;
  end;
  RConfig = record
    hits: Integer;
    use_stats: Boolean;
    use_cache: Boolean;
    use_prim_stats: Boolean;
    gc_period: Integer;
  end;

var
  config: RConfig = (hits: 0; use_stats: False; use_cache: True;
    use_prim_stats: False; gc_period: 10);

const
  trace_module_loading = false;


function CONTEXT: PContext; inline;
begin
	Result:= neko_vm_custom(neko_vm_current(),k_mod_neko);
end;

function TickDelta(tnow, tlast: Cardinal): Cardinal; inline;
begin
	if tnow >= tlast then
  	Result:= tnow - tlast
  else begin
    Result:= (High(Cardinal) - tlast) + tnow;
  end;
end;

function TCacheMod.isCached(r: PHTTPRequest): Boolean;
begin
  Result:= (main^ <> nil) and (time = FileAge(r.FileName));
end;

procedure gc_major();
begin
	if (config.gc_period <= 0) or (config.hits mod config.gc_period <>0) then exit;
	//if config.use_stats then neko_stats_measure(NULL,"gc",1);
	neko_gc_major();
	//if( config.use_stats ) neko_stats_measure(NULL,"gc",0);
end;

function cgi_command( v: value): value; cdecl;
var
  s: string;
  c: PContext;
  i: Integer;
begin
	try
    Result:= nil;
    val_check_string(v);
    s:= val_string(v);
    if s = 'stats' then begin
      result:= val_null; //return neko_stats_build(neko_vm_current());
      exit;
    end;
    if s = 'cache' then begin
      c:= CONTEXT();
      Result:= val_null;
      with c.r.ModNeko.FCache.LockList do try
        for i := 0 to Count - 1 do
          with TCacheMod(Items[i]) do
            Result:= AddToNekoTable(Result, [alloc_string(FileName), main^,  alloc_int(Hits)]);
      finally
        c.r.ModNeko.FCache.UnlockList;
      end;
      exit;
    end;
  except on e: Exception do val_rethrow(NekoSaveException(e)); end;
end;


procedure send_headers(c: PContext);
begin
  if not c.headers_sent then begin
    c.r.H.SendHeaders;
    c.headers_sent:= True;
  end;
end;

procedure request_print(const data: PChar; size: Integer; param: Pointer); cdecl;
var
  c: PHTTPRequest;
begin
	try
    //c := PHTTPRequest(param);
    //if c = nil then
    c := CONTEXT().r;
    if c <> param then 
      DbgTrace('print request is wonky');
    if (size = -1) then size := strlen(data);
    c.H.SendData(data, size);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

procedure null_print(const data: PChar; size: Integer; param: Pointer); cdecl;
begin
end;

{ cgi }

function AddToTable(old: value;const n,v: string): value;
var
  a: value;
begin
  a:= alloc_array(3);
  val_array_ptr(a)[0] := alloc_string(n);
  val_array_ptr(a)[1] := alloc_string(v);
  val_array_ptr(a)[2] := old;
  Result:= a;
end;

function get_cookies(): value; cdecl;
var
  s: string;
  c: PContext;
  start, i, x, ende, lens: Integer;

  procedure AddCookie;
  begin
    if x <= start then exit;
    Result:= AddToTable(Result, copy(s, start, x-start), copy(s, x +1, ende - x - 1));
  end;

begin
	try
    c:= CONTEXT();
    Result:= val_null;
    if c = nil then exit;
    s:= c.r.H.FRequest.Header.Values['Cookie'];
    x:= 0;
    start:= 1;
    lens:= Length(s);
    while true do begin
      for i := start to lens do begin
        if s[i] = '=' then begin
          x:= i;
          break;
        end;
      end;
      if x <= start then exit;
      for i:= x+1 to lens do begin
        case s[i] of
          #10, #13, ';': begin
            break;
          end;
        end;
      end;
      ende:= i;
      AddCookie;
      if (s[ende] <> ';') or (s[ende+1] <> ' ') then break;
      start:= ende + 2;
    end;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function set_cookie(name, v: value): value; cdecl;
var
  s: string;
  c: PContext;
begin
  try
    c:= CONTEXT();
    if c <> nil then begin
      s:= ValueToString(name) + '=' + ValueToString(v) + ';';
      c.r.H.FResponse.Header.Values['Set-Cookie']:= s;
      Result:= val_true;
    end else
      Result:= val_false;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_host_name(): value; cdecl;
begin
  try
    Result:= alloc_string(CONTEXT().r.H.FSettings.FServerName);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_client_ip(): value; cdecl;
begin
  try
    Result:= alloc_string(CONTEXT().r.H.FIPInfo.RemoteIP);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_uri(): value; cdecl;
begin
  try
    Result:= alloc_string(CONTEXT().r.H.FRequest.ParamRaw);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function redirect(s: value): value; cdecl;
begin
  try
    val_check_string(s);
    with CONTEXT().r.H do begin
      FResponse.Header.Values['Location']:= val_string(s);
      FResponse.ResponseCode:= 307;
    end;
    Result:= val_true;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function set_return_code(i: value): value; cdecl;
begin
  try
    if val_is_int(i) then begin
      CONTEXT().r.H.FResponse.ResponseCode:= val_int(i);
      Result:= val_true;
    end else
      Result:= nil;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function set_header(s, v: value): value; cdecl;
var
  c: PContext;
begin
  try
    c:= CONTEXT();
    val_check_string(s);
    val_check_string(v);
    if SameStr(val_string(s), 'Content-Type') then begin
      c.r.H.FResponse.MimeType:= val_string(v);
      c.content_type:= alloc_string(c.r.H.FResponse.MimeType);
    end else begin
      c.r.H.FResponse.Header.Values[val_string(s)]:= val_string(v);
    end;
    Result:= val_true;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_client_header(s: value): value; cdecl;
begin
  try
    val_check_string(s);
    Result:= alloc_string( CONTEXT().r.H.FRequest.Header.Values[val_string(s)]);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_client_headers(): value; cdecl;
var
  i: Integer;
  c: PContext;
begin
  try
    c:= CONTEXT();
    Result:= val_null;
    with c.r.H.FRequest.Header do
      for i := 0 to Count - 1 do begin
        Result:= AddToTable(Result, Key[i], ValueAt[i]);
      end;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function RequestParams: string;
begin
  try
    with CONTEXT().r.H do begin
      if FRequest.Command = 'POST' then
        Result:= DecodeURL( FPostData)
      else
        Result:= FRequest.ParamQuery;
    end;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_params_string(): value; cdecl;
begin
  try
    Result:= alloc_string(RequestParams);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_post_data(): value; cdecl;
var
  c: PContext;

  function ReadPostData: String;
  var
    j, l: Integer;
    b: String;
    w: TvsHTTPHandler;
  begin
    w:= c.r.H;
    //Result := '';
    l := StrToIntDef (w.FRequest.Header.Values['Content-Length'], 0);
    if (l<=0) then begin
      w.FMode := cmClose;
      exit;
    end;
    while (length (Result) < l) and (w.FSock.LastError = 0) do
    begin
      j := l - length (Result);
      if j>2048 then
        j := 2048;
      b := w.FSock.RecvBufferStr (j, 30000);
      if b = '' then begin // timeout
        Result := '';
        break;
      end else
        Result := Result + b;
    end;
  end;

begin
  try
    c:= CONTEXT();
    if (c.r.H.FPostData = '') // and (c.r.H.FRequest.Header.Values['Content-Length'] <> '')
    then
      c.r.H.FPostData:= ReadPostData;
    Result:= alloc_string(c.r.H.FPostData);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function parse_multipart_data(onpart, ondata: value): value; cdecl;
var
  c: PContext;
  content_type, boundary, data: string;
  len: Integer;
begin
  try
    c:= CONTEXT();
    Result:= val_null; //not implemented
    boundary:= c.r.H.FRequest.Header.Values['Content-Type'];
    content_type:= SplitString(boundary, ';');
    if not SameStr(content_type, 'multipart/form-data') then begin
      DbgTrace(content_type);
      exit;
    end;
    val_check_function(onpart,2);
    val_check_function(ondata,3);
    len:= StrToIntDef (c.r.H.FRequest.Header.Values['Content-Length'], 0);
    if len = 0 then len := 8192;
    //data:= c.r.H.FSock.RecvBufferStr (len, 30000);
    //DbgTraceFmt('data: %d', [length(data)]);
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_params(): value; cdecl;
var
  c: PContext;
  s, s1, n: string;
begin
  try
    c:= CONTEXT();
    Result:= val_null;
    s:= RequestParams;
    //SplitStringAt(s, '?');
    while s <> '' do begin
      s1:= SplitString(s,'&');
      n:= SplitString(s1, '=');
      Result:= AddToTable(Result, n, s1);
    end;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function cgi_get_cwd(): value; cdecl;
var
  c: PContext;
begin
  try
    c:= CONTEXT();
    Result:= alloc_string(ExtractFilePath(c.r.FileName));
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function cgi_set_main(f: value): value; cdecl;
var
  c: PContext;
begin
  try
    c:= CONTEXT();
    if val_is_null(f) then begin
      c.main:= nil;
    end else begin
      val_check_function(f, 0);
      c.main:= f;
    end;
    Result:= val_true;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function cgi_flush(): value; cdecl;
var
  c: PContext;
begin
  try
    c:= CONTEXT();
    //send_headers(c);
    c.headers_sent:= true;
    c.r.H.FlushData;
    Result:= val_null;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function cgi_get_config(): value; cdecl;
begin
  Result:= alloc_object(nil);
  alloc_field(Result, val_id('hits'), alloc_int(config.hits));
  alloc_field(Result, val_id('use_stats'), alloc_bool(config.use_stats));
  alloc_field(Result, val_id('use_cache'), alloc_bool(config.use_cache));
  alloc_field(Result, val_id('use_prim_stats'), alloc_bool(config.use_prim_stats));
  alloc_field(Result, val_id('gc_period'), alloc_int(config.gc_period));
end;

function cgi_set_config(v: value): value; cdecl;
begin
  config.hits:= val_int(val_field(v, val_id('hits')));
  config.use_stats:= val_bool(val_field(v, val_id('use_stats')));
  config.use_cache:= val_bool(val_field(v, val_id('use_cache')));
  config.use_prim_stats:= val_bool(val_field(v, val_id('use_prim_stats')));
  config.gc_period:= val_int(val_field(v, val_id('gc_period')));
end;

function get_http_method(): value; cdecl;
var
  c: PContext;
begin
  c:= CONTEXT();
  Result:= alloc_string( c.r.H.FRequest.Command);
end;

function log_message(m: value): value; cdecl;
var
  c: PContext;
begin
  c:= CONTEXT();
  c.r.H.Log(ValueToString(m));
  Result:= val_null;
end;

{ INIT }
procedure InitModNeko;
const
  InitDone: Boolean = False;
  CExport: array [0..21] of TExportInfo = (
    (Name: 'cgi_get_cwd'; Func: @cgi_get_cwd; Args: 0),
    (Name: 'cgi_set_main'; Func: @cgi_set_main; Args: 1),
    (Name: 'get_cookies'; Func: @get_cookies; Args: 0),
    (Name: 'set_cookie'; Func: @set_cookie; Args: 2),
    (Name: 'get_host_name'; Func: @get_host_name; Args: 0),
    (Name: 'get_client_ip'; Func: @get_client_ip; Args: 0),
    (Name: 'get_uri'; Func: @get_uri; Args: 0),
    (Name: 'redirect'; Func: @redirect; Args: 1),
    (Name: 'get_params'; Func: @get_params; Args: 0),
    (Name: 'get_params_string'; Func: @get_params_string; Args: 0),
    (Name: 'get_post_data'; Func: @get_post_data; Args: 0),
    (Name: 'set_header'; Func: @set_header; Args: 2),
    (Name: 'set_return_code'; Func: @set_return_code; Args: 1),
    (Name: 'get_client_header'; Func: @get_client_header; Args: 1),
    (Name: 'get_client_headers'; Func: @get_client_headers; Args: 0),
    (Name: 'parse_multipart_data'; Func: @parse_multipart_data; Args: 2),
    (Name: 'cgi_flush'; Func: @cgi_flush; Args: 0),
    (Name: 'cgi_get_config'; Func: @cgi_get_config; Args: 0),
    (Name: 'cgi_command'; Func: @cgi_command; Args: 1),
    (Name: 'get_http_method'; Func: @get_http_method; Args: 0),
    (Name: 'log_message'; Func: @log_message; Args: 1),
    (Name: 'tora_infos'; Func: nil; Args: 0)
  );

var
  loader, v: value;
begin
  if InitDone then exit;
  InitDone:= True;
  AddExportTable(CExport, 'mod_neko');
  LoadNeko;
  loader:= neko_default_loader(nil, 0);
  v:= val_ocall(loader, val_id('loadprim'), [alloc_string('std@put_env'), alloc_int(2)]);
  val_call2(v, alloc_string('MOD_NEKO'), alloc_string('1'));
  neko_vm_select(nil);
  Set8087CW($27F);
end;

{ TModeNekoParser }


function TModeNekoParser.ClearCache(Index: Integer): Boolean;
begin
  with FCache.LockList do try
    if (Index >= 0) and (Index < Count) then begin
      TObject(Items[Index]).Free;
      Delete(Index);
      Result:= True
    end else
      Result:= False;
  finally
    FCache.UnlockList;
  end;
end;

constructor TModeNekoParser.Create(Server: TvsHTTPServer);
begin
  inherited;
  FCache:= TThreadList.Create;
  FModules:= TThreadList.Create;
end;

destructor TModeNekoParser.Destroy;
begin
  ShutDown;
	while ClearCache(0) do;
  FreeAndNil(FCache);
  FreeAndNil(FModules);
  inherited;
end;

function TModeNekoParser.Execute(const FileName: string; Handler: TvsHTTPHandler): THttpConnectionMode;
var
  req: THTTPRequest;
  m: TNekoRequestThread;
begin
  if True then begin
    if FModules <> nil then begin
      req.Create(Self, Handler, FileName);
      Handler.FResponse.ResponseCode := 200;
      m:= RunRequest(@req);
      case req.WaitForRequest of
        rrOk: begin
          Result:= cmDONE;
        end;
        rrTimeout: begin
          Handler.FResponse.ResponseCode := 408;
          Result:= cmCLOSE;
          RemoveModule(m);
        end;
        rrException: begin
          Handler.FResponse.ResponseCode := 500;
          Result:= cmCLOSE;
        end;
        rrShutdown: begin
          Handler.FResponse.ResponseCode := 503;
          Result:= cmCLOSE;
        end;
      end;
    end;
  end else begin
    //InitModNeko;
    Handler.FMode:= cmDONE;
    //DbgTrace(FileName);
    if FCache <> nil then begin
      req.Create(Self, Handler, FileName);
      Handler.FResponse.ResponseCode := 200;
      if not req.DoRequest then
        Handler.FResponse.ResponseCode := 503; //Service unavailable
      if (Handler.FResponse.ResponseCode <> 200)
        or (Handler.FRequest.Command = 'POST')
      then
        Result := cmCLOSE
      else
        Result := cmDONE;
    end;
    Result := cmDONE
  end;
end;

function TModeNekoParser.FindCache(r: PHTTPRequest): TCacheMod;
var
  lockList: TList;
  i, h: Integer;
  cur: TCacheMod;
begin
  h:= r.Hash;
  Result:= nil;
  lockList:= FCache.LockList;
  try
    for i := 0 to lockList.Count - 1 do begin
      cur:= TCacheMod(lockList.Items[i]);
      if (h = cur.Hash) and SameFileName(cur.FileName, r.FileName) then begin
        Result:= cur;
        break;
      end;
    end;
    if Result = nil then begin
      if trace_module_loading then DbgTraceFmt('module %s not found in cache hash: %d', [r.FileName, h]);
      Result:= TCacheMod.Create(nil, r);
      lockList.Add(Result);
    end;
  finally
    //DbgTrace('want: ' + Result.FileName);
    if Result.Lock.TryEnter then begin
      FCache.UnlockList;
    end else begin
      FCache.UnlockList;
      Result.Lock.Acquire;
    end;
    //DbgTrace('locked: ' + Result.FileName);
  end;
end;


procedure TModeNekoParser.Kill(m: TNekoRequestThread);
begin

end;

procedure TModeNekoParser.RemoveModule(m: TNekoRequestThread);
var
  modules: TList;
  i: Integer;
begin
  modules:= FModules.LockList;
  try
    i:= modules.IndexOf(m);
    if i >= 0 then begin
      modules.Delete(i);
    end;
  finally
    FModules.UnlockList;
  end;
  m.Free;
end;

function TModeNekoParser.RunRequest(r: PHTTPRequest): TNekoRequestThread;
var
  modules: TList;
  i: Integer;
begin
  modules:= FModules.LockList;
  try
    Result:= nil;
    for i := 0 to modules.Count - 1 do begin
      Result:= TNekoRequestThread(modules.List^[i]);
      if (Result.FHash = r.Hash) and SameFileName(Result.FFileName, r.FileName) then
        break;
      Result:= nil;
    end;
    if Result = nil then begin
      Result:= TNekoRequestThread.Create(Self, r.FileName, r);
      modules.Add(Result);
    end else begin
      Result.PushRequest(r);
    end;
  finally
    FModules.UnlockList;
  end;
end;

procedure TModeNekoParser.ShutDown;
var
  modules: TList;
  i, x: Integer;
begin
  modules:= FModules.LockList;
  try
    for i := 0 to modules.Count - 1 do begin
      TNekoRequestThread(modules.List^[i]).ShutDown;
    end;
    i:= modules.Count;
  finally
    FModules.UnlockList;
  end;
  x:= 0;
  while i > 0 do begin
    Sleep(10);
    modules:= FModules.LockList;
    try
      inc(x);
      if (x > 100) then begin
        while modules.Count > 0 do begin
          with TNekoRequestThread(modules.List^[0]) do begin
            DbgTrace('kill module: ' + FFileName);
            //Suspend;
            Free;
          end;
          modules.Delete(0);
        end;
      end;
      i:= modules.Count;
    except
    end;
    FModules.UnlockList;
  end;
end;

{ THTTPRequest }

procedure THTTPRequest.Create(AModNeko: TModeNekoParser; AHandler: TvsHTTPHandler; const AFileName: string);
begin
  ModNeko:= AModNeko;
  H:= AHandler;
  FileName:= AFileName;
  //FTime:= FileAge(AFileName);
  DataAvailable:= daIdle;
  Hash:= hashString(AFileName, False);
  FNext:= nil;
  FPrior:= nil;
  FHandle := CreateEvent(nil, False, False, nil);
end;

function THTTPRequest.DoRequest: Boolean;
var
  ctx: TContext;
  vm: Pneko_vm;
  //sType: string;
  exc, old, mload: value;
  pUri: PAnsiChar;
  module: TCacheMod;


begin
  //H.Log('neko request start');
  Result:= True;
  exc:= nil;
  inc(config.hits);
  ctx.r:= @Self;
  //ctx.main:= CacheFind(ctx.r);
  //ctx.post_data:= nil;
  ctx.headers_sent:= False;
  H.FResponse.MimeType:='text/html';
  ctx.content_type:= alloc_string(H.FResponse.MimeType);
  //sType:= H.FRequest.Header.Values['Content-Type'];
  vm:= neko_vm_alloc(nil);
  neko_vm_set_custom(vm, k_mod_neko, @ctx);
  neko_vm_jit(vm, 1);
  neko_vm_redirect(vm, @request_print, @Self); //@ctx);
  neko_vm_select(vm);

  if False then DbgTraceFmt('running module %s caching is %d - request: %s',
    [FileName, ord(config.use_cache), H.FPostData]);
  module:= ModNeko.FindCache(@Self); // Aquires the Lock
  //module.Lock.Enter;
  try
    if module.isCached(@Self)
    then begin
      if trace_module_loading then DbgTraceFmt('module %s is cached', [FileName]);
      ctx.main:= module.main^;
      old:= ctx.main;
      val_callEx(val_null, old, nil, 0, @exc);
      if config.use_cache then begin
        if (old <> ctx.main) then begin
          module.Cache(ctx.main, @Self);
        end;
      end else begin
        module.Cache(nil, @Self);
      end;
    end else if FileAge(FileName) > 0 then begin
      if trace_module_loading then DbgTraceFmt('load and run %s age: %d', [FileName, FileAge(FileName)]);
      ctx.main:= nil;
      pUri:= PAnsiChar(H.FRequest.ParamRaw);
      mload:= EmbeddedLoader(@pUri, 1);
      val_ocall(mload, val_id('loadmodule'), [alloc_string(FileName), mload], @exc);
      if (ctx.main <> nil) and config.use_cache then begin
        if trace_module_loading then DbgTraceFmt('cache %s', [FileName]);
        module.Cache(ctx.main, @Self);
      end else begin
        if true then DbgTraceFmt('%s does not want to be cached', [FileName]);
        module.Cache(nil, @Self);
      end;
    end else begin
      if trace_module_loading then DbgTraceFmt('not found %s', [FileName]);
      Result:= False;
    end;
    if trace_module_loading then DbgTraceFmt('completed %s module is cached: %d', [FileName, ord(module.isCached(@self))]);
  except
    on e: Exception do begin
      H.LogError(e.Message);
      p4nHelper.DbgTraceFmt('error %s in %s', [e.Message, FileName]);
    end;
  end;
  module.Lock.Release;
  //DbgTrace('unlock: ' + module.FileName);
  neko_vm_select(nil);
  if exc <> nil then begin
    //send_headers(@ctx);
    H.SendData('Neko Exception');
    p4nHelper.DbgTrace(neko.ReportException(vm, exc, true));
  end;
  //H.Log('neko request done');
end;

//function NtDelayExecution(aAlertable: BOOL; var aInterval: Int64): DWORD; stdcall; external 'ntdll.dll';

function THTTPRequest.WaitForRequest: TRequestResult;
var
  delta: Cardinal;
  FLastError: Integer;

  function ShortWait(TimeOut: LongWord): TWaitResult;
  begin
    case WaitForSingleObject(FHandle, Timeout) of
      WAIT_ABANDONED: Result := wrAbandoned;
      WAIT_OBJECT_0: Result := wrSignaled;
      WAIT_TIMEOUT: Result := wrTimeout;
      WAIT_FAILED:
        begin
          Result := wrError;
          FLastError := GetLastError;
        end;
    else
      Result := wrError;
    end;
  end;

var
  delay: Int64;
begin
  delay:= -1;
  while true do begin
    case InterlockedCompareExchange(DataAvailable, -1, -1) of
      daIdle: ShortWait(2);
      daRunning: begin
        if InterlockedCompareExchange(DataAvailable, daRunningAcc, daRunning) = daRunning
        then begin
          StartTick:= GetTickCount;
        end;
      end;
      daRunningAcc: begin
        delta:= TickDelta(GetTickCount, StartTick);
        if delta > 5 * 60 * 1000 then begin // TODO flexibel timeout
          Result:= rrTimeout;
          break;
        end else if delta > 5 then begin
          ShortWait(100);
        end else begin
          ShortWait(5);
          //NtDelayExecution(True, delay);
        end;
      end;
      daFinished: begin
        Result:= rrOk;
        break;
      end;
      daError: begin
        Result:= rrException;
        break;
      end;
      daShuttdown: begin
        Result:= rrShutdown;
        break;
      end;
    end;
  end;
  CloseHandle(FHandle);
end;

{ TCacheMod }

procedure TCacheMod.Cache(AMain: value; r: PHTTPRequest);
var
  ft: Integer;
begin
  if AMain = nil then begin
    main^:= nil;
    Time:= 0;
    gc_major();
  end else begin
    main^:= AMain;
    ft:= FileAge(r.FileName);
    if ft > 0 then
      Time:= ft;
  end;
end;

constructor TCacheMod.Create(AMain: value; r: PHTTPRequest);
begin
  main:= alloc_root(1);
  main^:= AMain;
  FileName:= r.FileName;
  Time:= FileAge(r.FileName);
  Hits:= 0;
  Lock:= TCriticalSection.Create;
  Hash:= r.Hash;
end;

destructor TCacheMod.Destroy;
begin
  free_root(main);
  FreeAndNil(Lock);
  inherited;
end;



{ TNekoRequestThread }

constructor TNekoRequestThread.Create(AParent: TModeNekoParser; const AFileName: string; req: PHTTPRequest);
var
  i: Integer;
begin
  FFileName:= AFileName;
  FHash:= hashString(AFileName, False);
  if not FileAge(AFileName, FTime) then FTime:= 0.0; 
  FLastTimeCheck:= GetTickCount;
  //SetLength(FRequestQueue, 1);
  //FRequestQueue[0].req:= req;
  //FRequestQueue[0].next:= -1;
  //FRequestQueue[0].prior:= -1;
  //FQueueFree:= -1;
  FFirst:= req;
  FLast:= req;
  FQueueLock:= TCriticalSection.Create;
  //FHasRequest:= TEvent.Create(nil, False, False, '', False);
  FNekoParser:= AParent;
  FQueueState:= qsAccepting + 1;
  inherited Create(False);
end;

destructor TNekoRequestThread.Destroy;
begin
  ShutDown;
  //FreeAndNil(FHasRequest);
  FreeAndNil(FQueueLock);
  inherited;
end;

procedure TNekoRequestThread.Execute;
type
  PPneko_vm = ^Pneko_vm;
var
  //req: PHTTPRequest;
  exc, mload: value;
  pUri: PAnsiChar;
  main: Pvalue;
  vm: PPneko_vm;


  procedure SendException;
  begin
    Fctx.r.H.SendData('Neko Exception');
    p4nHelper.DbgTrace(neko.ReportException(vm^, exc, true));
    InterlockedExchange(Fctx.r.DataAvailable, daError);
  end;

begin
  if FTime > 0 then begin
    neko_thread_register(true);
    main:= nil;
    vm:= nil;
    try
      vm:= Pointer(alloc_root(1));
      vm^:= neko_vm_alloc(nil);
      neko_vm_set_custom(vm^, k_mod_neko, @Fctx);
      neko_vm_jit(vm^, 1);
      main:= alloc_root(1);
      Fctx.r:= PopRequest;
      if Fctx.r <> nil then begin
        //Fctx.r.StartTick:= GetTickCount;
        InterlockedExchange(Fctx.r.DataAvailable, daRunning);
        neko_vm_redirect(vm^, @request_print, Fctx.r); //@ctx);
        neko_vm_select(vm^);
        Fctx.main:= nil;
        pUri:= PAnsiChar(Fctx.r^.H.FRequest.ParamRaw);
        mload:= EmbeddedLoader(@pUri, 1);
        exc:= nil;
        val_ocall(mload, val_id('loadmodule'), [alloc_string(FFileName), mload], @exc);
        if (exc = nil) and (Fctx.main <> nil) and config.use_cache then begin
          if trace_module_loading then DbgTraceFmt('cache %s', [FFileName]);
          main^:= Fctx.main;
          InterlockedExchange(Fctx.r.DataAvailable, daFinished);
        end else begin
          if true then DbgTraceFmt('%s does not want to be cached', [FFileName]);
          if exc <> nil then SendException;
          Fctx.main:= nil;
        end;
        Windows.SetEvent(Fctx.r.FHandle);
        while Fctx.main <> nil do begin
          if InterlockedCompareExchange(FQueueState, -1, -1) <> qsAccepting then begin
            Fctx.r:= PopRequest;
            if Fctx.r <> nil then begin
              //Fctx.r.StartTick:= GetTickCount;
              if InterlockedCompareExchange(Fctx.r.DataAvailable, daRunning, daIdle) <> daIdle then begin
                DbgTrace('unexpected DataState');
                InterlockedExchange(Fctx.r.DataAvailable, daRunning);
              end;
              neko_vm_redirect(vm^, @request_print, Fctx.r); //@ctx);
              neko_vm_select(vm^);
              exc:= nil;
              if InterlockedCompareExchange(FReload, 0, 1) = 1 then begin
                val_ocall(mload, val_id('loadmodule'), [alloc_string(FFileName), mload], @exc);
                if exc <> nil then begin
                  Fctx.main:= nil;
                end;
              end else begin
                val_callEx(val_null, Fctx.main, nil, 0, @exc);
              end;
              if exc <> nil then begin
                SendException;
              end else begin
                InterlockedExchange(Fctx.r.DataAvailable, daFinished);
              end;
              Windows.SetEvent(Fctx.r.FHandle);
              if not config.use_cache then begin
                Fctx.main:= nil;
              end else
                main^ := Fctx.main;
            end;
          end else
            Sleep(1);
        end;
      end;
    except
    end;
    main^ := nil;
    vm^:= nil;
    free_root(main);
    free_root(Pvalue(vm));
    gc_major();
    neko_thread_register(false);
  end else begin
    if trace_module_loading then DbgTraceFmt('not found %s', [FFileName]);
  end;
  FNekoParser.RemoveModule(Self);
end;

function TNekoRequestThread.PopRequest: PHTTPRequest;
var
  i: Integer;
begin
  if InterlockedCompareExchange(FQueueState, -1, -1) >= qsAccepting then begin
    FQueueLock.Acquire;
    Result:= FFirst;
    if Result <> nil then begin
      FFirst:= FFirst.FNext;
      if FFirst = nil then
        FLast:= nil
      else
        FFirst.FPrior:= nil;
    end;
    FQueueLock.Release;
    InterlockedDecrement(FQueueState);
  end else begin
    Result:= nil;
    Fctx.main:= nil;
  end;
end;

procedure TNekoRequestThread.PushRequest(req: PHTTPRequest);
var
  fa: TDateTime;
  t: Cardinal;
begin
  if InterlockedCompareExchange(FQueueState, -1, -1) >= qsAccepting then begin
    FQueueLock.Acquire;
    if FFirst = nil then begin
      FFirst:= req;
      FLast:= req;
    end else begin
      req.FPrior:= FLast;
      FLast.FNext:= req;
      FLast:= req;
    end;
    t:= GetTickCount;
    if TickDelta(t, FLastTimeCheck) > 10000 then begin
      if FileAge(FFileName, fa)
        and (abs(fa - FTime) > 1 / (24.0 * 60))
      then begin
        FTime:= fa;
        InterlockedExchange(FReload, 1);
      end;
      FLastTimeCheck:= t;
    end;
    FQueueLock.Release;
    //FHasRequest.SetEvent;
    InterlockedIncrement(FQueueState);
  end else begin
    InterlockedExchange(req.DataAvailable, daShuttdown);
  end;
end;

procedure TNekoRequestThread.ShutDown;
begin
  if InterlockedCompareExchange(FQueueState, qsShutdown, qsShutdown) <= qsShutdown
  then exit;
  InterlockedExchange(FQueueState, qsShutdown);
  FQueueLock.Acquire;
  Fctx.main:= nil;
  FQueueLock.Release;
  //FHasRequest.SetEvent;
end;

initialization
  //Set8087CW($27F);
  InitModNeko;
end.
