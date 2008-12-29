object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 136
  ClientWidth = 264
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object vsHTTPServer1: TvsHTTPServer
    Active = False
    BaseDir = 'C:\Users\Adrian\Documents\FlashDevelop\'
    ListenPort = '1080'
    ThreadSafe = True
    LogFile = 'test.log'
    SSL = False
    AutoTLS = False
    OnGet = vsHTTPServer1Get
    OnPost = vsHTTPServer1Post
    DoVirtualHosts = False
    CaseSensitive = True
    SupportedProtocols = [hpHEAD, hpGET, hpPOST, hpTRACE, hpOPTIONS]
    AutomatedProtocols = [hpHEAD, hpGET, hpPOST, hpTRACE, hpOPTIONS, hpCONNECT]
    Left = 40
    Top = 32
  end
end
