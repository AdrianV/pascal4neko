library testneko;
// the demo code is in the include file

uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Types,
  Libc,
  dynlibs,
{$ENDIF}
  SysUtils,
  Classes,
  neko,
  uNekoDemo1 in 'uNekoDemo1.pas';

{$include testneko.inc}

begin
end.
