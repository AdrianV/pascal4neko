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


type
  PIPInfo = ^TIPInfo;
  PSettings = ^TSettings;
  PCGIResult = ^TCGIResult;
  PHTTPRequest = ^THTTPRequest;
  TModeNekoParser = class;
  TNekoRequestThread = class;
  TRequestQueue = record
    req: PHTTPRequest;
    next: Integer;
    prior: Integer;
  end;
  TGCedValue = record
	  main: value;
    bkg_task: value;
    module: value;
    cleanup: value;
    vm: Pneko_vm;
    exc: value;
  end;
  PGCedValue = ^TGCedValue;
  TContext = record
    gc: PGCedValue;
	  r: PHTTPRequest;
    bkg_intervall: Integer; // sec
     // function;
	  headers_sent: Boolean;
    runner: TNekoRequestThread;
	  //post_data: value;
	  //content_type: value;
    //classes: value;
  end;
  PContext = ^TContext;
  TNekoRequestThread = class(TThread)
    FFileName: string;
    FHash: Integer;
    FTime: TDateTime;
    FLastTimeCheck: Cardinal;
    FReload: Integer;
    Fctx: TContext;
    FFirst: PHTTPRequest;
    FLast: PHTTPRequest;
    FQueueState: Integer;
    FQueueLock: TCriticalSection;
    FHasRequest: THandle;
    FNekoParser: TModeNekoParser;
  protected
    procedure Execute; override;
    procedure PushRequest(req: PHTTPRequest);
    function PopFromQueue(): PHTTPRequest; inline;
    function PopRequest(): PHTTPRequest;
    procedure ShutDown;
    procedure ForcedKill;
  public
    constructor Create(AParent: TModeNekoParser; const AFileName: string; req: PHTTPRequest);
    destructor Destroy; override;
  end;
  TModeNekoParser = class(TPreParser)
  private
    //var FCache: TThreadList;
    var FModules: TThreadList;
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
    FHasData: THandle;
    FTimeout: Integer;
    procedure Create(AModNeko: TModeNekoParser; AHandler: TvsHTTPHandler; const AFileName: string);
    function WaitForRequest: TRequestResult;
  end;

var
  __k_mod_neko: Tvkind;
  k_mod_neko: vkind = @ __k_mod_neko;

function CONTEXT: PContext; inline;

implementation

const
  daIdle = 0;
  daRunning = 1;
  daRunningAcc = 2;
  daFinished = 3;
  daError = 4;
  daShuttdown = 5;
  qsAccepting = 0;
  qsShutdown = -1;
  qsInQueue = qsAccepting + 1;
  StandardRequestTimeout = 5 * 60;


{$WRITEABLECONST ON}

type
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
//      with c.r.ModNeko.FCache.LockList do try
//        for i := 0 to Count - 1 do
//          with TCacheMod(Items[i]) do
//            Result:= AddToNekoTable(Result, [alloc_string(FileName), main^,  alloc_int(Hits)]);
//      finally
//        c.r.ModNeko.FCache.UnlockList;
//      end;
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
  req: PHTTPRequest;
begin
  try
    c:= CONTEXT();
    val_check_string(s);
    val_check_string(v);
    req := c.r;
    if req <> nil then begin
      if SameStr(val_string(s), 'Content-Type') then begin
        req.H.FResponse.MimeType:= val_string(v);
        //req.H.FResponse.Header.Values['Content-Type']:= req.H.FResponse.MimeType;
      end else begin
        req.H.FResponse.Header.Values[val_string(s)]:= val_string(v);
      end;
      Result:= val_true;
    end else begin
      Result:= val_false;
    end;
  except on e: Exception do val_throw(NekoSaveException(e)); end;
end;

function get_client_raw_header(): value; cdecl;
begin
  Result:= alloc_string( CONTEXT().r.H.FRequest.Header.Text);
end;

function get_client_header(s: value): value; cdecl;
var
  res: string;
begin
  try
    val_check_string(s);
    if CONTEXT().r.H.FRequest.Header.GetValue(val_string(s), res)
    then
      Result:= alloc_string(res)
    else
      Result:= val_null;
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
const MAX_POST_DATA_SIZE = $80000; // 512K
var
  c: PContext;

  {$define IN_ONE_STEP}
  function ReadPostData: String;
  const CHUNK_SIZE = 8 * 1024;
  var
    l, lenr : Integer;
  {$ifndef IN_ONE_STEP}
    j, lenb: Integer;
    b: String;
  {$endif}
    w: TvsHTTPHandler;
  begin
    w:= c.r.H;
    Result := '';
    l := StrToIntDef (w.FRequest.Header.Values['Content-Length'], 0);
    if (l<=0) or (l > MAX_POST_DATA_SIZE) then begin
      DbgTraceFmt('invalid Content-Length: %d', [l]);
      Result := '';
      w.FMode := cmClose;
      exit;
    end;
  {$ifdef IN_ONE_STEP}
    Result:= w.FSock.RecvBufferStr (l, 30000);
    lenr:= Length(Result);
    if (lenr <> l) then DbgTraceFmt('expected %d, received %d bytes', [l, lenr]);
    if (w.FSock.LastError <> 0) then begin
      DbgTrace('after ' + IntToStr(lenr) + ' bytes socket error: ' + w.FSock.LastErrorDesc);
      //raise Exception.Create(w.FSock.LastErrorDesc);
    end;
  {$else}
    lenr:= 0;
    SetLength(Result, l);
    j := l - lenr;
    while (j > 0) and (w.FSock.LastError = 0) do
    begin
      if j > CHUNK_SIZE then
        j := CHUNK_SIZE;
      b := w.FSock.RecvBufferStr (j, 30000);
      lenb:= Length(b);
      if (lenb = 0) or (w.FSock.LastError <> 0) then begin // timeout
        Result := '';
        DbgTrace(w.FRequest.Header.Text);
        if (w.FSock.LastError <> 0) then begin
          DbgTrace('after ' + IntToStr(lenr) + ' bytes socket error: ' + w.FSock.LastErrorDesc);
          raise Exception.Create(w.FSock.LastErrorDesc);
        end else begin
          DbgTrace('after ' + IntToStr(lenr) + ' bytes zero size packet');
          raise Exception.Create('zero size packet');
        end;
        //break;
      end else begin
        Move(b[1], Result[lenr + 1], lenb);
        lenr := lenr + lenb;
        j := l - lenr;
      end;
    end;
  {$endif}
  end;

begin
  try
    c:= CONTEXT();
    if (c.r.H.FPostData = '') //and (c.r.H.FMode in [cmPUT, cmPOST]) // and (c.r.H.FRequest.Header.Values['Content-Length'] <> '')
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
    if (f = nil) or val_is_null(f) or not val_is_function(f,0) then begin
      if c.r <> nil then
        DbgTrace('want to unload ' + c.r.FileName)
      else DbgTrace('unload from background ' + c.runner.FFileName);
      //DbgTrace('unload ' + c.
      c.gc.main:= nil;
      c.gc.bkg_task:= nil;
      c.bkg_intervall:= 0;
    end else begin
      val_check_function(f, 0);
      c.gc.main:= f;
    end;
    Result:= val_true;
  except on e: Exception do
    begin
      DbgTraceFmt('cgi_set_main problem %s', [e.Message]);
      Result:= val_false;
    end;
  end;
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

function set_timeout(v: value): value; cdecl;
var
  c: PContext;
  vi: Integer;
begin
  if val_is_int(v) then
    vi:= val_int(v)
  else vi:= 0;
  if vi > 0 then begin
    c:= CONTEXT();
    if c.r <> nil then
      InterlockedExchange(c.r.FTimeout, vi * 1000);
  end;
  Result:= val_null;
end;

function set_background_task(callb: value; intervall: value): value; cdecl;
var
  c: PContext;
  vi: Integer;
begin
  if val_is_null(callb) then callb:= nil;
  if val_is_int(intervall) and (callb <> nil) then
    vi:= val_int(intervall)
  else vi:= 0;
  if (vi >= 0) and ((callb = nil) or val_is_function(callb, 0)) then begin
    c:= CONTEXT();
    c.gc.bkg_task:= callb;
    c.bkg_intervall:= vi;
    Result:= val_true;
  end else
    Result:= val_false;
end;

function set_cleanup(callb: value): value; cdecl;
var
  c: PContext;
begin
  if val_is_null(callb) then callb:= nil;
  if (callb = nil) or val_is_function(callb, 0) then begin
    c:= CONTEXT();
    c.gc.cleanup:= callb;
    Result:= val_true;
  end else
    Result:= val_false;
end;

{ INIT }
procedure InitModNeko;
const
  InitDone: Boolean = False;
  CExport: array [0..25] of TExportInfo = (
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
    (Name: 'tora_infos'; Func: nil; Args: 0),
    (Name: 'get_client_raw_header'; Func: @get_client_raw_header; Args: 0),
    (Name: 'set_timeout'; Func: @set_timeout; Args: 1),
    (Name: 'set_background_task'; Func: @set_background_task; Args: 2),
    (Name: 'set_cleanup'; Func: @set_cleanup; Args: 1)
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



constructor TModeNekoParser.Create(Server: TvsHTTPServer);
begin
  inherited;
  FModules:= TThreadList.Create;
end;

destructor TModeNekoParser.Destroy;
begin
  ShutDown;
  FreeAndNil(FModules);
  inherited;
end;

function TModeNekoParser.Execute(const FileName: string; Handler: TvsHTTPHandler): THttpConnectionMode;
var
  req: THTTPRequest;
  m: TNekoRequestThread;

  procedure DoTimeout;
  begin
    Handler.FResponse.ResponseCode := 408;
    Result:= cmCLOSE;
    if m <> nil then begin
      DbgTraceFmt('timeout for %s - state: %d - available: %d', [FileName,
        InterlockedCompareExchange(m.FQueueState, 0, 0),
        InterlockedCompareExchange(req.DataAvailable, 0, 0)
      ]);
      m.ShutDown;

      if req.WaitForRequest = rrTimeout  then
        Kill(m);
      //RemoveModule(m);
    end;
  end;

begin
  if FModules <> nil then try
    req.Create(Self, Handler, FileName);
    Handler.FResponse.ResponseCode := 200;
    m:= RunRequest(@req);
    case req.WaitForRequest of
      rrOk: begin
        Result:= cmDONE;
      end;
      rrTimeout: DoTimeout;
      rrException: begin
        Handler.FResponse.ResponseCode := 500;
        Result:= cmCLOSE;
      end;
      rrShutdown: begin
        Handler.FResponse.ResponseCode := 503;
        Result:= cmCLOSE;
      end;
    end;
  except
    Result:= cmCLOSE;
  end;
end;


procedure TModeNekoParser.Kill(m: TNekoRequestThread);
begin
  m.ForcedKill;
  RemoveModule(m);
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
            ForcedKill;
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
  FTimeout:= StandardRequestTimeout * 1000;
  FHasData := CreateEvent(nil, False, False, nil);
end;

//function NtDelayExecution(aAlertable: BOOL; var aInterval: Int64): DWORD; stdcall; external 'ntdll.dll';

function THTTPRequest.WaitForRequest: TRequestResult;
var
  delta: Cardinal;
  FLastError: Integer;

  function ShortWait(TimeOut: LongWord): TWaitResult;
  begin
    case WaitForSingleObject(FHasData, Timeout) of
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
  timeout: Integer;
begin
  delay:= -1;
  while true do begin
    case InterlockedCompareExchange(DataAvailable, -1, -1) of
      daIdle: ShortWait(1000);
      daRunning: begin
        Windows.ResetEvent(FHasData);
        if InterlockedCompareExchange(DataAvailable, daRunningAcc, daRunning) = daRunning
        then begin
          StartTick:= GetTickCount;
        end;
      end;
      daRunningAcc: begin
        delta:= TickDelta(GetTickCount, StartTick);
        timeout:= InterlockedCompareExchange(FTimeout, 0, 0);
        if delta > timeout then begin // TODO flexibel timeout
          Result:= rrTimeout;
          break;
        end else if delta > 1 then begin
          ShortWait(1000);
        end else begin
          //ShortWait(5);
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
  CloseHandle(FHasData);
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
  FFirst:= req;
  FLast:= req;
  FQueueLock:= TCriticalSection.Create;
  FHasRequest:= CreateEvent(nil, False, False, nil);
  FNekoParser:= AParent;
  FQueueState:= qsInQueue;
  inherited Create(False);
end;

destructor TNekoRequestThread.Destroy;
var req: PHTTPRequest;
begin
  ShutDown;
  FreeAndNil(FQueueLock);
  while true do begin
    req:= PopFromQueue;
    if req = nil then break;
    InterlockedExchange(req.DataAvailable, daShuttdown);
    Windows.SetEvent(req.FHasData);
  end;
  CloseHandle(FHasRequest);
  inherited;
end;

procedure TNekoRequestThread.Execute;
type
  PPneko_vm = ^Pneko_vm;
var
  //exc, mload: value;
  pUri: PAnsiChar;
  //main: value;
  //vm: PPneko_vm;
  req: PHTTPRequest;


  procedure SendException;
  begin
    DbgTraceFmt('neko exception: %s in: %s',[NekoExceptionToString(FCtx.gc.exc), FFileName]);
    //p4nHelper.DbgTrace(neko.ReportException(vm^, exc, true));
    InterlockedExchange(req.DataAvailable, daError);
    //InterlockedExchange(FQueueState, qsShutdown);
  end;

  function LoadModule: Boolean;
  begin
    FCtx.gc.bkg_task:= nil;
    FCtx.bkg_intervall:= 0;
    FCtx.gc.vm:= neko_vm_alloc(nil);
    neko_vm_set_custom(FCtx.gc.vm, k_mod_neko, @Fctx);
    neko_vm_jit(FCtx.gc.vm, 1);
    neko_vm_redirect(FCtx.gc.vm, @request_print, req);
    neko_vm_select(FCtx.gc.vm);
    pUri:= PAnsiChar(req.H.FRequest.ParamRaw);
    FCtx.gc.module:= EmbeddedLoader(@pUri, 1);
    FCtx.gc.exc:= nil;
    val_ocall(FCtx.gc.module, val_id('loadmodule'), [alloc_string(FFileName), FCtx.gc.module], @FCtx.gc.exc);
    if (FCtx.gc.exc = nil) and (Fctx.gc.main <> nil) and config.use_cache then begin
      if trace_module_loading then DbgTraceFmt('cache %s', [FFileName]);
      //main^:= Fctx.main;
      InterlockedExchange(req.DataAvailable, daFinished);
      Result:= True;
    end else begin
      Result:= FCtx.gc.main <> nil;
      if not Result then DbgTraceFmt('%s does not want to be cached', [FFileName]);
      if FCtx.gc.exc <> nil then begin
        SendException;
      end else begin
        InterlockedExchange(req.DataAvailable, daFinished);
      end;
    end;
    Windows.SetEvent(req.FHasData);
  end;
var
  lastBkg, delta: Cardinal;
begin
  FCtx.runner:= Self;
  lastBkg:= 0;
  if FTime > 0 then begin
    neko_thread_register(true);
    FCtx.gc:= Pointer(alloc_root(sizeof(FCtx.gc^) div sizeof(Pointer)));
    //main:= nil;
    //vm:= nil;
    try
      InterlockedExchange(FReload, 1);
      while true do begin
        case InterlockedCompareExchange(FQueueState, qsShutdown, qsShutdown) of
          qsInQueue .. MaxInt: begin
            req:= PopRequest;
            if (req <> nil) then begin
              Fctx.r:= req;
              InterlockedExchange(req.DataAvailable, daRunning);
              Windows.SetEvent(req.FHasData);
              if (InterlockedCompareExchange(FReload, 0, 1) = 1) then begin
                if not LoadModule then break;
              end else begin
                neko_vm_select(FCtx.gc.vm);
                neko_vm_redirect(FCtx.gc.vm, @request_print, req);
                FCtx.gc.exc:= nil;
                val_callEx(val_null, Fctx.gc.main, nil, 0, @FCtx.gc.exc);
                if FCtx.gc.exc <> nil then begin
                  SendException;
                  if FCtx.gc.main <> nil then begin
                    InterlockedExchange(FReload, 1);
                  end else
                    break;
                end else begin
                  InterlockedExchange(req.DataAvailable, daFinished);
                end;
                Windows.SetEvent(req.FHasData);
                if not config.use_cache then begin
                  Fctx.gc.main:= nil;
                end else begin
                  //main^ := Fctx.main;
                end;
              end;
              Fctx.r:= nil;
              if Fctx.gc.main = nil then begin
                DbgTrace('unload ' + FFileName);
                break;
              end;
            end;
          end;
          qsAccepting: begin
            if (Fctx.gc.main = nil) then begin
              break;
            end;
            if (FCtx.bkg_intervall > 0) then begin
              delta:= TickDelta(GetTickCount, lastBkg);
              if delta > FCtx.bkg_intervall * 1000 then begin
                FCtx.gc.exc:= nil;
                neko_vm_select(FCtx.gc.vm);
                val_callEx(val_null, Fctx.gc.bkg_task, nil, 0, @FCtx.gc.exc);
                if FCtx.gc.exc <> nil then begin
                  DbgTraceFmt('neko exception in background: %s in: %s',[NekoExceptionToString(FCtx.gc.exc), FFileName]);
                  InterlockedExchange(FReload, 1);
                  FCtx.gc.bkg_task:= nil;
                  FCtx.bkg_intervall:= 0;
                  try
                    DbgTrace(ReportException(FCtx.gc.vm, FCtx.gc.exc, true));
                  except
                  end;
                end else begin
                  lastBkg:= GetTickCount;
                end;
              end;
            end;
            WaitForSingleObject(FHasRequest, 1000);
            //Sleep(1);
          end;
          else begin
            // qsShutdown
            break;
          end;
        end;
      end;
    except
      on e: Exception do DbgTrace(e.Message);
    end;
    try
      InterlockedExchange(FQueueState, qsShutdown);
      DbgTrace('leaving ' + FFileName);
      FCtx.gc.bkg_task:= nil;
      FCtx.bkg_intervall:= 0;
      //free_root(FCtx.bkg_task);
      if FCtx.gc.cleanup <> nil then try
        FCtx.gc.exc:= nil;
        DbgTrace('call cleanup');
        val_callEx(val_null, Fctx.gc.cleanup, nil, 0, @FCtx.gc.exc);
      except
        on e: Exception do DbgTrace(e.Message);
      end;
      //main^ := nil;
      //vm^:= nil;
      free_root(Pointer(FCtx.gc));
      //free_root(Pvalue(vm));
      if FCtx.gc.exc = nil then gc_major();
      neko_thread_register(false);
      DbgTrace('leaving');
      if Fctx.r <> nil then begin
        InterlockedExchange(Fctx.r.DataAvailable, daShuttdown);
        Windows.SetEvent(Fctx.r.FHasData);
      end;
    except
      on e: Exception do DbgTrace(e.Message);
    end;
  end else begin
    if trace_module_loading then DbgTraceFmt('not found %s', [FFileName]);
  end;
  FNekoParser.RemoveModule(Self);
end;

procedure TNekoRequestThread.ForcedKill;
var
  pData: PHandle;
  i: Integer;
begin
  pData:= Pointer(Self);
  i:= 0;
  for i := 0 to 4 do begin
    if pData^ = ThreadID then try
      DbgTrace('try to forced terminate');
      TerminateThread(Handle, 501);
      DbgTrace('done forced terminate');
      pData^:= 0;
      dec(pData);
      if pData^ = Handle then pData^:= 0;
      DbgTrace('free thread');
      Free;
      DbgTrace('done');
      exit;
    except
      DbgTrace('kill aborted');
      exit;
    end;
    inc(pData);
  end;
  DbgTrace('Thread ID not found - kill aborted');
end;

function TNekoRequestThread.PopFromQueue: PHTTPRequest;
begin
  Result:= FFirst;
  if Result <> nil then begin
    FFirst:= FFirst.FNext;
    if FFirst = nil then
      FLast:= nil
    else
      FFirst.FPrior:= nil;
  end;
end;

function TNekoRequestThread.PopRequest: PHTTPRequest;
var
  i: Integer;
begin
  if InterlockedCompareExchange(FQueueState, qsShutdown, qsShutdown) > qsAccepting then begin
    FQueueLock.Acquire;
    Result:= PopFromQueue();
    Windows.ResetEvent(FHasRequest);
    if Result <> nil then Dec(FQueueState); // inside Lock InterlockedDecrement
    FQueueLock.Release;
  end else begin
    Result:= nil;
    Fctx.gc.main:= nil;
  end;
end;

procedure TNekoRequestThread.PushRequest(req: PHTTPRequest);
var
  fa: TDateTime;
  t: Cardinal;
begin
  if InterlockedCompareExchange(FQueueState, qsShutdown, qsShutdown) > qsShutdown then begin
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
    Inc(FQueueState); //inside Lock InterlockedIncrement
    Windows.SetEvent(FHasRequest);
    FQueueLock.Release;
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
  Fctx.gc.main:= nil;
  FQueueLock.Release;
  Windows.SetEvent(FHasRequest);
end;

initialization
  //Set8087CW($27F);
  InitModNeko;
end.
