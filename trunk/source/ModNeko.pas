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
  neko, nekoHelper, SyncObjs;

type
  PIPInfo = ^TIPInfo;
  PSettings = ^TSettings;
  PCGIResult = ^TCGIResult;
  THTTPRequest = class;
  TCacheMod = class
    main: Pvalue;
    FileName: string;
    Hits: Integer;
    Time: Integer;
    Lock: TCriticalSection;
    constructor Create(AMain: value; AFileName: string; ATime: Integer);
    destructor Destroy; override;
  end;
  TModeNekoParser = class(TPreParser)
  private
    var FCache: TThreadList;
    function ClearCache(Index: Integer): Boolean;
    function FindCache(r: THTTPRequest): TCacheMod;
    procedure CacheModule(AModule: TCacheMod; r: THTTPRequest; main: value);
  protected
    function Execute(const FileName: string; Handler: TvsHTTPHandler): THttpConnectionMode; override;
  public
    destructor Destroy; override;
  end;
  THTTPRequest = class
    H: TvsHTTPHandler;
    FileName: string;
    ModNeko: TModeNekoParser;
    FTime: Integer;
    constructor Create(AModNeko: TModeNekoParser; AHandler: TvsHTTPHandler; const AFileName: string);
    function DoRequest: Boolean;
  end;
  TContext = record
	  r: THTTPRequest;
	  main: value;
	  post_data: value;
	  content_type: value;
	  headers_sent: Boolean;
    classes: value;
  end;
  PContext = ^TContext;

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
  //cache_root: mt_local = nil;
  config: RConfig = (hits: 0; use_stats: False; use_cache: True;
    use_prim_stats: False; gc_period: 10);

function CONTEXT: PContext; inline;
begin
	Result:= neko_vm_custom(neko_vm_current(),k_mod_neko);
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
	//neko_error();
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
  c: THTTPRequest;
begin
	c := THTTPRequest(param);
	if c = nil then c := CONTEXT().r;
	if (size = -1) then size := strlen(data);
  c.H.SendData(data, size);
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
  c:= CONTEXT();
  s:= c.r.H.FRequest.Header.Values['Cookie'];
  Result:= val_null;
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
end;

function set_cookie(name, v: value): value; cdecl;
var
  s: string;
  c: PContext;
begin
  c:= CONTEXT();
  s:= ValueToString(name) + '=' + ValueToString(v) + ';';
  c.r.H.FResponse.Header.Values['Set-Cookie']:= s;
  Result:= val_true;
end;

function get_host_name(): value; cdecl;
begin
  Result:= alloc_string(CONTEXT().r.H.FSettings.FServerName);
end;

function get_client_ip(): value; cdecl;
begin
  Result:= alloc_string(CONTEXT().r.H.FIPInfo.RemoteIP);
end;

function get_uri(): value; cdecl;
begin
  Result:= alloc_string(CONTEXT().r.H.FRequest.Parameter);
end;

function redirect(s: value): value; cdecl;
begin
  val_check_string(s);
  with CONTEXT().r.H do begin
    FResponse.Header.Values['Location']:= val_string(s);
    FResponse.ResponseCode:= 307;
  end;
  Result:= val_true;
end;

function set_return_code(i: value): value; cdecl;
begin
  if val_is_int(i) then begin
    CONTEXT().r.H.FResponse.ResponseCode:= val_int(i);
    Result:= val_true;
  end else
    Result:= nil;
end;

function set_header(s, v: value): value; cdecl;
var
  c: PContext;
begin
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
end;

function get_client_header(s: value): value; cdecl;
begin
  val_check_string(s);
  Result:= alloc_string( CONTEXT().r.H.FRequest.Header.Values[val_string(s)]);
end;

function get_client_headers(): value; cdecl;
var
  i: Integer;
  c: PContext;
begin
  c:= CONTEXT();
  Result:= val_null;
  with c.r.H.FRequest.Header do
  for i := 0 to Count - 1 do begin
    Result:= AddToTable(Result, Names[i], ValueFromIndex[i]);
  end;
end;

function RequestParams: string;
begin
  with CONTEXT().r.H do begin
    if FRequest.Command = 'POST' then
      Result:= DecodeURL( FPostData)
    else
      Result:= GetParams(FRequest.Parameter);
  end;
end;

function get_params_string(): value; cdecl;
begin
  Result:= alloc_string(RequestParams);
end;

function get_post_data(): value; cdecl;
begin
  Result:= CONTEXT().post_data;
end;

function parse_multipart_data(onpart, ondata: value): value; cdecl;
var
  c: PContext;
begin
  c:= CONTEXT();
  Result:= val_null; //not implemented
end;

function get_params(): value; cdecl;
var
  c: PContext;
  s, s1, n: string;
begin
  c:= CONTEXT();
  Result:= val_null; //not implemented
  s:= RequestParams;
  //SplitStringAt(s, '?');
  while s <> '' do begin
    s1:= SplitString(s,'&');
    n:= SplitString(s1, '=');
    Result:= AddToTable(Result, n, s1);
  end;
end;

function cgi_get_cwd(): value; cdecl;
var
  c: PContext;
begin
  c:= CONTEXT();
  Result:= alloc_string(ExtractFilePath(c.r.FileName));
end;

function cgi_set_main(f: value): value; cdecl;
var
  c: PContext;
begin
  c:= CONTEXT();
  if val_is_null(f) then begin
    c.main:= nil;
  end else begin
    val_check_function(f, 0);
    c.main:= f;
  end;
  Result:= val_true;
end;

function cgi_flush(): value; cdecl;
var
  c: PContext;
begin
  c:= CONTEXT();
  send_headers(c);
  Result:= val_null;
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
  CExport: array [0..20] of TExportInfo = (
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
    (Name: 'log_message'; Func: @log_message; Args: 1)
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

procedure TModeNekoParser.CacheModule(AModule: TCacheMod; r: THTTPRequest;
  main: value);
var
  i: Integer;
begin
  with FCache.LockList do try
    if AModule <> nil then
      AModule.Lock.Release
    else begin
      for i := 0 to Count - 1 do
        if TCacheMod(Items[i]).FileName = r.FileName then begin
          AModule:= TCacheMod(Items[i]);
          break;
        end;
    end;
    if (AModule <> nil) then begin
      //AModule.Lock.Release;
      if main = nil then begin
        Remove(AModule);
        AModule.Free;
        gc_major();
      end else begin
        AModule.main^:= main;
      end;
    end else begin
      AModule:= TCacheMod.Create(main, r.FileName, r.FTime);
      Add(AModule);
    end;
  finally
    FCache.UnlockList;
  end;
end;

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

destructor TModeNekoParser.Destroy;
begin
  if FCache <> nil then begin
    while ClearCache(0) do;
    FCache.Free;
  end;
  inherited;
end;

function TModeNekoParser.Execute(const FileName: string; Handler: TvsHTTPHandler): THttpConnectionMode;
begin
  //InitModNeko;
  if FCache = nil then
    FCache:= TThreadList.Create;
  Handler.FMode:= cmDONE;
  with THTTPRequest.Create(Self, Handler, FileName) do try
    H.FResponse.ResponseCode := 200;
    if not DoRequest then
      H.FResponse.ResponseCode := 503; //Service unavailable
  finally
    Free;
  end;
  if (Handler.FResponse.ResponseCode <> 200)
    or (Handler.FRequest.Command = 'POST')
  then
    Result := cmCLOSE
  else
    Result := cmDONE;
  Result := cmDONE
end;

function TModeNekoParser.FindCache(r: THTTPRequest): TCacheMod;
var
  i: Integer;
begin
  with FCache.LockList do try
    for i := 0 to Count - 1 do begin
      Result:= TCacheMod(Items[i]);
      if Result.FileName = r.FileName then begin
        if config.use_cache and (Result.Time = r.FTime) then begin
          Result.Lock.Enter;
          exit;
        end;
        Result.Lock.Enter;
        Result.Lock.Leave;
        Delete(i);
        Result.Free;
        gc_major();
      end;

    end;

  finally
    FCache.UnlockList;
  end;
  Result:= nil;
end;

{ THTTPRequest }

constructor THTTPRequest.Create(AModNeko: TModeNekoParser; AHandler: TvsHTTPHandler; const AFileName: string);
begin
  ModNeko:= AModNeko;
  H:= AHandler;
  FileName:= AFileName;
  FTime:= FileAge(AFileName);
end;

function THTTPRequest.DoRequest: Boolean;
var
  ctx: TContext;
  vm: Pneko_vm;
  sType: string;
  exc, old, mload: value;
  pUri: PChar;
  module: TCacheMod;
begin
  //H.Log('neko request start');
  Result:= True;
  exc:= nil;
  inc(config.hits);
  ctx.r:= Self;
  //ctx.main:= CacheFind(ctx.r);
  ctx.post_data:= nil;
  ctx.headers_sent:= False;
  H.FResponse.MimeType:='text/html';
  ctx.content_type:= alloc_string(H.FResponse.MimeType);
  sType:= H.FRequest.Header.Values['Content-Type'];
  vm:= neko_vm_alloc(nil);
  neko_vm_set_custom(vm, k_mod_neko, @ctx);
  neko_vm_jit(vm, 1);
  neko_vm_redirect(vm, @request_print, Self); //@ctx);
  neko_vm_select(vm);
  module:= ModNeko.FindCache(Self);
  if module <> nil then
    ctx.main:= module.main^
  else
    ctx.main:= nil;
  try
    try
      if ctx.main <> nil then begin
        old:= ctx.main;
        val_callEx(val_null, old, nil, 0, @exc);
        if (old <> ctx.main) and config.use_cache then begin
          ModNeko.CacheModule(module, Self, ctx.main);
          module:= nil;
        end;
      end else begin
        pUri:= PChar(H.FRequest.Parameter);
        mload:= EmbeddedLoader(@pUri, 1);
        val_ocall(mload, val_id('loadmodule'), [alloc_string(FileName), mload], @exc);
        if (ctx.main <> nil) and config.use_cache then begin
          ModNeko.CacheModule(module, Self, ctx.main);
          module:= nil;
        end;
      end;
    finally
      if module <> nil then
        module.Lock.Release;
    end;
  except
    on e: Exception do
      H.Log(e.Message);
  end;
  if exc <> nil then begin
    //send_headers(@ctx);
    H.SendData('Neko Exception');
  end;
  //H.Log('neko request done');
end;

{ TCacheMod }

constructor TCacheMod.Create(AMain: value; AFileName: string; ATime: Integer);
begin
  main:= alloc_root(1);
  main^:= AMain;
  FileName:= AFileName;
  Time:= ATime;
  Hits:= 0;
  Lock:= TCriticalSection.Create;
end;

destructor TCacheMod.Destroy;
begin
  free_root(main);
  FreeAndNil(Lock);
  inherited;
end;


initialization
  //Set8087CW($27F);
  InitModNeko;
end.
