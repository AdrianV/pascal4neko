/**
 * ...
 * @author ...
 */

import haxe.remoting.HttpConnection;

class CnxServer extends haxe.remoting.Proxy<Server> {}
class CnxServerAsync extends haxe.remoting.AsyncProxy<Server> {}

class Client 
{
  static function display(v) {
    trace(v);
  }
  static function test2() {
    var URL = "remoting.n";
    var cnx = HttpConnection.urlConnect(URL);
		var proxy = new CnxServer(cnx.Server);
		var res: Int = proxy.foo(1, 2);
    return res;
  }

  static function test() {
    var URL = "remoting.n";
    var cnx = haxe.remoting.HttpAsyncConnection.urlConnect(URL);
    cnx.setErrorHandler( function(err) trace("Error : " + Std.string(err)) );
		var proxy = new CnxServerAsync(cnx.Server);
		proxy.foo(1, 2, display);
    //cnx.Server.foo.call([1,2],display);
  }
	  
	static function main() {
    //if (haxe.Firebug.detect()) haxe.Firebug.redirectTraces();
  }

	
}