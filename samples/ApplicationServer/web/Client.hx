class Client {
  static function display(v) {
    trace(v);
  }
  static function test() {
    #if js
    var URL = "./remoting.n";
    #end
    #if neko
    var URL = "http://localhost:1080/remoting.n";
    #end
    var cnx = haxe.remoting.HttpAsyncConnection.urlConnect(URL);
    cnx.setErrorHandler( function(err) trace("Error : "+Std.string(err)) );
    cnx.Server.foo.call([[11,13,27,8]],display);    
    cnx.Server.foo.call([[11,13,27]],display);
    #if neko
    var cn2 = haxe.remoting.HttpConnection.urlConnect(URL);
    var i: Int;
    for( i in 0...100) {
      trace(cn2.Server.foo.call([[11,13,27,8, i]]));
      trace("blah: " + cn2.Server.blah.call([]));    
    }
    trace(cn2.Server.foo.call([[11,13,27]]));
    #end    
  }
  static function main() {
    #if js
    if (haxe.Firebug.detect()) haxe.Firebug.redirectTraces();
    #end
    #if neko
    test();
    #end
  }
}