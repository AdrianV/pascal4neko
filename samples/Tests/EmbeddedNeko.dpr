// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
program EmbeddedNeko;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  neko,
  Helper,
  uNekoDemo1,
  Classes,
  nekoHelper,
  Forms;

type
  TObj1 = class
    FData: Integer;
    constructor Create(Data: Integer);
  end;
  TObj2 = class
    function DoSomething(A, B: TObj1): Integer;
  end;

function TObject_new(): value; cdecl;
var
  t: value;
begin
  TObject_NekoLink(NewNekoInstance(result), TObject.Create);
  t:= val_field(val_this, val_id('ClassName'));
end;

function TObject_cons(): value; cdecl;
var
  t: value;
begin
  TObject_NekoLink(NewNekoInstance(result), TObject.Create);
  t:= val_field(val_this, val_id('ClassName'));
end;

function TObject_ClassName(): value; cdecl;
var
  Self: TObject;
begin
  Self:= TObject_Self;
  if Self <> nil then
    Result:= alloc_string(Self.ClassName)
  else
    Result:= alloc_string('');
end;

function TComponent_new(AOwner: value): value; cdecl;
begin
  TObject_NekoLink(NewNekoInstance(Result), TComponent.Create(TComponent(TObject_Of(AOwner))));
end;

function TForm_new(AOwner: value): value; cdecl;
begin
  TObject_NekoLink(NewNekoInstance(Result), TForm.Create(TComponent(TObject_Of(AOwner))));
end;

function TForm_ShowModal(): value; cdecl;
begin
  Result:= alloc_int(TForm(TObject_Self).ShowModal);
  Result:= val_this;
  Result:= val_ocall0(val_this, val_id('ClassName'));
end;

function test(v: value): value; cdecl;
begin
  if val_is_function(v) then
    Result:= v //val_call0(v)
  else if val_is_object(v) then begin
    Result:= val_field(v, val_id('ClassName'));
    if val_is_function(Result) then
      Result:= val_ocall0(v, val_id('ClassName'))
    else
      Result:= v;
  end else
    Result:= v;
end;

function TObj1_getData(): value; cdecl;
var
  Self: TObject;
begin
  Self:= TObject_Self;
  if Self is TObj1 then
    Result:= alloc_int(TObj1(Self).FData)
  else
    Result:= alloc_int(0);
end;

function TObj1_setData(v: value): value; cdecl;
var
  ob: TObj1;
begin
  Result:= val_field(val_this, id_Self);
  if val_is_kind(Result, k_object) then begin
    ob:= TObj1(val_data(Result));
    ob.FData:= val_int(v);
    Result:= v;
  end else
    Result:= v;
end;

function TObj1_new(v: value): value; cdecl;
begin
  TObject_NekoLink(NewNekoInstance(Result), TObj1.Create(val_int(v)));
end;

function DeclareClass(cl, proto: value; const Name, Super: string; New: Pointer; NParams: Integer; Cons: Pointer = nil): value; //returns prototype
var
  a: value;
begin
  if Cons=nil then
    Cons:= New;
  Result:= alloc_object(nil);
  a:= alloc_array(1);
  val_array_ptr(a)^[0]:= alloc_string(Name);
  alloc_field(Result, id__name__, a);
  alloc_field(Result, id_new, alloc_function(New, NParams, 'new'));
  alloc_field(Result, id__construct__, alloc_function(Cons, NParams, '__construct__'));
  if Super <> '' then begin
    a:= val_field(cl, val_id(PChar(Super)));
    if val_is_object(a) then begin
      alloc_field(Result, id__super__, a);
      SetProto(proto, val_field(a, id_prototype)); //.proto;
      //Result:= val_field(a, id__super__);
    end;
  end;
  alloc_field(proto, id__class__, Result);
  alloc_field(Result, id_prototype, proto);
  alloc_field(cl, val_id(PChar(Name)), Result);
end;

function TObj1_init(t: value): value; cdecl;
var
  cl, p, a: value;
begin
  cl:= t;
  t:= val_field(cl, val_id('TObject'));
  if val_is_null(t) then begin
    p:= alloc_object(nil);
    alloc_field(p, val_id('ClassName'), alloc_function(@TObject_ClassName, 0, 'ClassName'));
    DeclareClass(cl, p, 'TObject', '', @TObject_new, 0);
    p:= alloc_object(nil);
    DeclareClass(cl, p, 'TComponent', 'TObject', @TComponent_new, 1);
    p:= alloc_object(nil);
    alloc_field(p, val_id('ShowModal'), alloc_function(@TForm_ShowModal, 0, 'ShowModal'));
    DeclareClass(cl, p, 'TForm', 'TComponent', @TForm_new, 1);
  end;

  t:= val_field(cl, val_id('TObj1'));
  if val_is_null(t) then exit;
  p:= val_field(t, id_prototype);
  alloc_field(p, val_id('get_Data'), alloc_function(@TObj1_getData, 0, 'get_Data'));
  alloc_field(p, val_id('set_Data'), alloc_function(@TObj1_setData, 1, 'set_Data'));
  alloc_field(t, id_new, alloc_function(@TObj1_new, 1, ''));
  //alloc_field(t, id__construct__, alloc_function(@TObj1_new, 1, ''));
  Result:= t;
end;

{function SetSuper(C, S: value): value; cdecl;
var
  a: value;
begin
  a:= val_field(C, val_id(PChar(Super)));
  if val_is_object(a) then begin
    alloc_field(t, id__super__, a);
    vobject(Result).proto:= vobject(val_field(a, id_prototype)); //.proto;
    //Result:= val_field(a, id__super__);
  end;
  Result:= val_null;
end;}

function LoadModule(const AFile: string): value;
var
  loader, exc: value;
  b: Pbuffer;
  FPUCW: Word;
begin
  loader:= EmbeddedLoader;
  exc:= nil;
  //loader:= val_field(loader, val_id('_loader'));
  FPUCW:= Get8087CW;
  Set8087CW($27F);
  Result:= val_ocall(loader, val_id('loadmodule'), [alloc_string(AFile), loader], @exc);
  Set8087CW(FPUCW);
  if (exc <> nil) then begin
    ReportException(neko.EmbeddedNeko, exc, True);
    raise ENekoException.Create(ReportException(neko.EmbeddedNeko, exc, True));
  end;
end;

procedure RunMe;
const
  CExport: array[0..4] of TExportInfo = (
    (Name: 'test'; Func: @test; Args: 1),
    (Name: 'TObj1_init'; Func: @TObj1_init; Args: 1),
    (Name: 'TObj1_new'; Func: @TObj1_new; Args: 1),
    (Name: 'TObj1_getData'; Func: @TObj1_getData; Args: 0),
    (Name: 'TObj1_setData'; Func: @TObj1_setData; Args: 1)
  );
var
  m: value;
  s: string;
begin
  if ParamCount >= 1 then
    s:= ParamStr(1)
  else
    s:= 'helloPascal.n';
  AddExportTable(CExport, '$$');
  m:= LoadModule(s);
  //writeln(TNekoObj2String.toString(neko.EmbeddedNeko.env));
  exit;
  writeln(TNekoObj2String.toString(m));
end;

{ TObj2 }

function TObj2.DoSomething(A, B: TObj1): Integer;
begin
  Result:= A.FData + B.FData;
end;

{ TObj1 }

constructor TObj1.Create(Data: Integer);
begin
  FData:= Data;
end;

begin
  try
    writeln('start');
    readln;
    RunMe;
    UnloadNeko;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
