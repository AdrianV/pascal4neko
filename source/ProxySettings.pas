unit ProxySettings;

interface

uses
	httpsend;

type
  TSetProxyImpl = procedure (AHttp: THTTPSend; ADestination: string);

procedure SetProxy(AHttp: THTTPSend; ADestination: string);

var
  SetProxyImpl: TSetProxyImpl;

implementation

procedure SetProxy(AHttp: THTTPSend; ADestination: string);
begin
  if Assigned(SetProxyImpl) then SetProxyImpl(AHttp, ADestination);
end;


end.
