unit p4nProcess;

interface
uses
  SysConst,
  SysUtils,
  Windows,
  JvComponent, JvCreateProcess,
  neko, nekoHelper, p4nHelper;


function _init__1: pointer; cdecl;

implementation

type
  TCallbackHandlers = record
    onErrorRead: value;
    onRead: value;
    onTerminate: value;
  end;
  PCallbackHandlers = ^TCallbackHandlers;
  TCreateProcessWrapper = class
    cp: TJvCreateProcess;
    handler: PCallbackHandlers;
    constructor Create;
    destructor Destroy; override;
    procedure cpRead(Sender: TObject; const S: string;
      const StartsOnNewLine: Boolean);
    procedure cpTerminate(Sender: TObject; ExitCode: Cardinal);
    procedure cpErrorRead(Sender: TObject; const S: string;
      const StartsOnNewLine: Boolean);
  end;
  TJvCreateProcessFriend = class(TJvCreateProcess) end;

function createProcess(): value; cdecl;
begin
  Result:= TObject_GC(TCreateProcessWrapper.Create);
end;

function GetState(cp: value): value; cdecl;
var
  self: TCreateProcessWrapper;
begin
  Result:= val_null;
  if CheckClass(TObject_(cp), TCreateProcessWrapper, self) then begin
    with TJvCreateProcessFriend(self.cp) do HandleReadEvent(InputReader);
    Result:= alloc_int(Ord(self.cp.State));
  end;
end;

function SetHandler(cp, onRead, onTerminate, onError: value): value; cdecl;
var
  self: TCreateProcessWrapper;
begin
  Result:= val_null;
  if CheckClass(TObject_(cp), TCreateProcessWrapper, self) then begin
    if self.handler = nil then
      self.handler:= PCallbackHandlers( alloc_root(3));
    if val_is_function(onError) then
      self.handler.onErrorRead:= onError;
    if val_is_function(onRead) then
      self.handler.onRead:= onRead;
    if val_is_function(onTerminate) then
      self.handler.onTerminate:= onTerminate;
    //self.cpRead(nil, 'Test', false);
  end;
end;

function StartProcess(cp, cmd, args: value): value; cdecl;
var
  self: TCreateProcessWrapper;
  sCmd, s: string;
  lArgs: TArrayInfo;
  i: Integer;
begin
  Result:= val_null;
  if CheckClass(TObject_(cp), TCreateProcessWrapper, self) then begin
    sCmd:= val_HaxeString(cmd);
    lArgs.FromValue(args);
    for i := 0 to lArgs.l -1 do begin
      s:= val_HaxeString( lArgs.Get(i, val_null));
      if s <> '' then
        sCmd:= sCmd + ' "' + s + '"';
    end;
    self.cp.CommandLine:= sCmd;
    self.cpRead(nil, sCmd, true);
    //self.cp.WaitForTerminate:= False;
    if Assigned(self.handler) and val_is_function(self.handler.onRead, 2) then begin
      self.cp.ConsoleOptions := self.cp.ConsoleOptions + [coRedirect];
      self.cp.StartupInfo.ShowWindow := swHide;
      self.cp.StartupInfo.DefaultWindowState := False;
      //if val_is_function(self.handler.onErrorRead, 2) then
      //  self.cp.ConsoleOptions:= self.cp.ConsoleOptions + [coSeparateError];
    end;
    self.cp.Run;

  end;
end;

function Terminate(cp: value): value; cdecl;
var
  self: TCreateProcessWrapper;
begin
  Result:= val_null;
  if CheckClass(TObject_(cp), TCreateProcessWrapper, self) then begin
    self.cp.Terminate;
  end;
end;

function pro_Write(cp, Line: value): value; cdecl;
var
  self: TCreateProcessWrapper;
begin
  Result:= val_null;
  if CheckClass(TObject_(cp), TCreateProcessWrapper, self) then begin
    self.cp.Write(val_HaxeString(Line));
  end;
end;

function pro_Writeln(cp, Line: value): value; cdecl;
var
  self: TCreateProcessWrapper;
begin
  Result:= val_null;
  if CheckClass(TObject_(cp), TCreateProcessWrapper, self) then begin
    //self.cpRead(nil, val_HaxeString(Line), true);
    self.cp.Writeln(val_HaxeString(Line));
  end;
end;

{ TCreateProcessWrapper }

procedure TCreateProcessWrapper.cpErrorRead(Sender: TObject; const S: string;
  const StartsOnNewLine: Boolean);
begin
  if Assigned(handler)
    and val_is_function(handler.onErrorRead, 2)
  then begin
    val_call2(handler.onErrorRead, alloc_string(s), alloc_bool(StartsOnNewLine));
  end;
end;

procedure TCreateProcessWrapper.cpRead(Sender: TObject; const S: string;
  const StartsOnNewLine: Boolean);
begin
  if Assigned(handler)
    and val_is_function(handler.onRead, 2)
  then begin
    val_call2(handler.onRead, alloc_string(s), alloc_bool(StartsOnNewLine));
  end;
end;

procedure TCreateProcessWrapper.cpTerminate(Sender: TObject;
  ExitCode: Cardinal);
begin
  if Assigned(handler)
    and val_is_function(handler.onTerminate, 1)
  then begin
    val_call1(handler.onTerminate, alloc_best_int(ExitCode));
  end;
end;

constructor TCreateProcessWrapper.Create;
begin
  cp:= TJvCreateProcess.Create(nil);
  cp.OnTerminate:= cpTerminate;
  cp.OnRead:= cpRead;
  cp.OnErrorRead:= cpErrorRead;
  handler:= nil;
end;

destructor TCreateProcessWrapper.Destroy;
begin
  cp.Free;
  if handler <> nil then free_root(pvalue(handler));
  
  inherited;
end;

function init(I: value): value; cdecl;
begin
  Result:= val_null;
  add_function(I, 'createProcess', @createProcess, 0);
  add_function(I, 'getState', @GetState, 1);
  add_function(I, 'setHandler', @SetHandler, 4);
  add_function(I, 'startProcess', @StartProcess, 3);
  add_function(I, 'terminate', @Terminate, 1);
  add_function(I, 'write', @pro_Write, 2);
  add_function(I, 'writeln', @pro_Writeln, 2);
end;

function _init__1: pointer; cdecl;
begin
  result:= @init;
end;

end.
