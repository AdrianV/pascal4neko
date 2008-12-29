unit uTestServer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, visualserverbase, vstypedef, httpServer, neko, nekoHelper, ModNeko;

type
  TForm2 = class(TForm)
    vsHTTPServer1: TvsHTTPServer;
    procedure FormCreate(Sender: TObject);
    procedure vsHTTPServer1Get(Sender: TObject; Request: TRequest;
      var Response: TResponse; IPInfo: TIPInfo; var Handled: Boolean);
    procedure vsHTTPServer1Post(Sender: TObject; Request: TRequest;
      var Response: TResponse; IPInfo: TIPInfo; var Handled: Boolean);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.FormCreate(Sender: TObject);
begin
  vsHTTPServer1.Active:= False;
  vsHTTPServer1.LoadSettings('TestServer.ini');
  vsHTTPServer1.RegisterPreParser('', '.n', '', '', TModeNekoParser);
  vsHTTPServer1.RegisterDir(IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'web', '');
  vsHTTPServer1.ThreadSafe:= False;
  vsHTTPServer1.Active:= True;
  //vsHTTPServer1.RegisterPHP();
end;

procedure TForm2.vsHTTPServer1Get(Sender: TObject; Request: TRequest;
  var Response: TResponse; IPInfo: TIPInfo; var Handled: Boolean);
begin
      //
end;

procedure TForm2.vsHTTPServer1Post(Sender: TObject; Request: TRequest;
  var Response: TResponse; IPInfo: TIPInfo; var Handled: Boolean);
begin
    //
end;

end.
