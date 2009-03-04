import haxe.remoting.HttpConnection;

#if neko
import haxe.remoting.Context;
import neko.Web;
#end

class Server 
{
  function new() { }

  public function foo(x: Int, y: Int): Int { return x + y; }

  static var inst: Server;
	
	static function main() {
    var ctx = new haxe.remoting.Context();
		inst = new Server();
    ctx.addObject("Server", inst);
    if( haxe.remoting.HttpConnection.handleRequest(ctx) )
      return;
    // handle normal request
    neko.Lib.print("This is a remoting server !");
  } 
	
}