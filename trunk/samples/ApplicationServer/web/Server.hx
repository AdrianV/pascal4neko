class Server {
  static var ctx;
  var hits: Int;
  function new() { hits = 0;}
  function foo(a: Array<Int>) {
    var r= 0;
    for (x in 0...a.length) {
      r += a[x];
    }
    return r; 
  }
  function blah(){
    hits += 1; 
    return hits; 
  }

  static function handleRequest() {
    var isNekoRequest = haxe.remoting.HttpConnection.handleRequest(ctx);
    if( isNekoRequest )
      return;
    // handle normal request
    neko.Lib.print("This is a remoting server !");
  }
  static function main() {
    ctx = new haxe.remoting.Context();
    ctx.addObject("Server",new Server());
    neko.Web.cacheModule(handleRequest);
    handleRequest();
  } 
}