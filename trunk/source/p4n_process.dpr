// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
library p4n_process;

{ Wichtiger Hinweis zur DLL-Speicherverwaltung: ShareMem muss sich in der
  ersten Unit der unit-Klausel der Bibliothek und des Projekts befinden (Projekt-
  Quelltext anzeigen), falls die DLL Prozeduren oder Funktionen exportiert, die
  Strings als Parameter oder Funktionsergebnisse �bergeben. Das gilt f�r alle
  Strings, die von oder an die DLL �bergeben werden -- sogar f�r diejenigen, die
  sich in Records und Klassen befinden. Sharemem ist die Schnittstellen-Unit zur
  Verwaltungs-DLL f�r gemeinsame Speicherzugriffe, BORLNDMM.DLL.
  Um die Verwendung von BORLNDMM.DLL zu vermeiden, k�nnen Sie String-
  Informationen als PChar- oder ShortString-Parameter �bergeben. }
  

uses
  SysUtils,
  Classes,
  p4nProcess in 'p4nProcess.pas',
  p4nHelper in 'p4nHelper.pas';

{$LIBVERSION 'ndll'}

{$R *.res}

exports
  _init__1;

begin
end.
