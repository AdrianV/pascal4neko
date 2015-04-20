import neko.Boot;
import p4n.TObject;
import p4n.vcl.TForm;
import p4n.vcl.TButton;
import p4n.vcl.TComponent;

typedef THello = {
  var test: String;
  var IntVal: Int;
  var FloatVal: Float ;
}



class TObj0 {
  public var Data(dynamic, dynamic): Int;
  public function new(AData: Int) { 
    trace('here');
    this.Data = AData;
  }
  static var test: Int;
  private function get_Data() { return test;}
  private function set_Data(x) { test = x; return x;}
}

class TObj1 {
  public var Data(dynamic, dynamic): Int;
  public function new(AData: Int) { 
    trace('here');
	trace(this);
    this.Data = AData;
  }
}

class TObj2 extends TObj1 {
  public function Test() {return Data; }
  public function new(Data: Int) { super(Data);}
}

class HelloPascal {
  static var MyLib : {
    function hello(): THello;
    function showMe(v: Dynamic): String;
    function doSomething(a: Int, b: Float): String; 
  } = neko.Lib.load('testneko.dll','_init', 0)();
  static var test: Dynamic -> Dynamic = neko.Lib.load('$', 'test', 1);  
  static var testInt: Dynamic -> Void = neko.Lib.load('$', 'testInt', 1);  
  //static var test2 = test(neko.Boot);
  static function __init__() {
    trace(TObj0);
    var o = new TObj0(123);
    trace(TObj1);
    trace(o);
    if (false)
    untyped {
      trace(neko.Boot.__classes);
	    Test2.__super__ = TObject;
	    __dollar__objsetproto(Test2.prototype, TObject.prototype);
	  }
    if (false)
	  untyped {
	    neko.Lib.load('$', 'TObj1_init', 1) (neko.Boot.__classes);
	    TObject = neko.Boot.__classes.TObject;
	    TComponent = neko.Boot.__classes.TComponent;
	    TForm = neko.Boot.__classes.TForm;
	    Test2.__super__ = TObject;
	    untyped __dollar__objsetproto(Test2.prototype, TObject.prototype);
    }
	untyped neko.Lib.load('$', 'TObj1_init', 1) (neko.Boot.__classes);
    trace(TObj1);    
	//main();
  }
	static function main() {
		try {
			trace("main");
			testInt( -1);
			testInt( -1.1);
			testInt( -2);
			testInt(0x7FFFFFFF);
			testInt(-0x7FFFFFFF);
			trace('calling hello() in .dll written in pascal');
			var o: THello = MyLib.hello();
			trace(o);
			var o2 = MyLib.showMe(o);
			var i;
			trace(neko.vm.Module.local().globalsCount());
			trace(untyped Reflect.fields(__dollar__exports.__module));
			trace(o2);
			//trace(MyLib.showMe({a: 1, b: 2.2, c: [1,2, [4,5,6], "Hallo Welt", {e:3, f: 4.5 }], d:{e:3, f: 4.5 }}));
			trace(MyLib.showMe(o2));
			trace(MyLib.doSomething(1, 3.1415));
			var x = 12, y = 23;
			trace(test(function(){return x + y;}));
			
		trace('Hallo');
		var ob2 = new TComponent(null);
		trace(MyLib.showMe(ob2));
		//trace(ob2.ClassName());
			
			
			//trace(test(Test2));
			var ob1: TObj1 = new TObj1(123);
			//trace(123);
			//trace(ob1);
			trace(ob1.Data);
			ob1.Data += 127;
			trace(ob1.Data);
			//trace(Reflect);
			var i: Int;
			//for (i in 0...100000) {
			//  ob1 = new TObj1(ob1.Data + i); 
		//}
		//trace(ob1.Data);
		var ob2: TObject = new TForm(null);
		trace('Hallo');
		trace(ob2.className());
		//trace(TForm);
		//trace(TObject);
		var f: TForm = new TForm(null);
		trace(f.showModal());
		//trace(f.ClassName());
		trace(p4n.TObject.ClassName(cast f));
		var com = new TComponent(f);
		trace(TObj2);
		//trace(new TObj2(24).Test());
		trace("wtf");
		trace(p4n.vcl.TComponent.createPascalComponent);
		var xxx = new p4n.vcl.TComponent(null);
		xxx = new TButton(null);
		trace(xxx == null);
		trace(p4n.TObject.ClassName(cast xxx));
		trace('The END!');
		} catch (e: Dynamic) {
			trace(e);
		}
	}
}
