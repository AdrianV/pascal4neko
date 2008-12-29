// JCL_DEBUG_EXPERT_INSERTJDBG OFF
program TestServer;

uses
  FastCode,
  RtlVclOptimize,
  Forms,
  uTestServer in 'uTestServer.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
