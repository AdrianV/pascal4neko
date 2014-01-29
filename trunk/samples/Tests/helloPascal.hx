import neko.Boot;

typedef THello = {
  var test: String;
  var IntVal: Int;
  var FloatVal: Float ;
}

class XObject {
  public function ClassName(): String {return 'XObject';}
  public function new(): Void {}
  public static function StaticFunction() {return 1;}
}

class XComponent extends XObject {
  private function get_Owner(): XComponent {return null;}
  public var Owner(get, null): XComponent;
  public function new(AOwner: TComponent): Void { super();}
}

class XForm extends XComponent {
  public function ShowModal(): Int {return 124;}
} 

extern class TObject {
  public function ClassName(): String;
  public function new(): Void;
}

class InitObject extends TObject {
//  private static var doinit = neko.Lib.load('$', 'TObj1_init', 1);
//  private static var doinit2 = {
//	  untyped {
//	    var cl = Boot.__classes;
//	    neko.Lib.load('$', 'TObj1_init', 1) (cl);
//	    TObject = Reflect.field(cl, 'TObject');
//	    TComponent = Reflect.field(cl, 'TComponent');
//	    TForm = Reflect.field(cl, 'TForm');
//    }    
//    return true;
//  }
}

extern class TBlahBlah {
  public function oops(): Int;  
}

extern class TComponent extends TObject {
  private function get_Owner(): TComponent;
  public var Owner(get, null): TComponent;
  public function new(AOwner: TComponent): Void;
}

extern class TForm extends TComponent {
  public function ShowModal(): Int;
} 

class Test2 extends TObject {
  public function new() {
    super();
  }
}

class Xest2 extends XObject {
  public function new() {
    super();
  }
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
    if (true)
	  untyped {
	    neko.Lib.load('$', 'TObj1_init', 1) (neko.Boot.__classes);
	    TObject = neko.Boot.__classes.TObject;
	    TComponent = neko.Boot.__classes.TComponent;
	    TForm = neko.Boot.__classes.TForm;
	    Test2.__super__ = TObject;
	    untyped __dollar__objsetproto(Test2.prototype, TObject.prototype);
    }
    trace(TObj1);    
	//main();
  }
	static function main() {
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
		var ot2 = new XObject();
		trace(XObject);
		trace(ot2);
		untyped trace(Test2.__super__.prototype.__class__ == TObject);
		untyped trace(Xest2.__super__ == XObject);
		untyped trace(Xest2.__super__.prototype.__class__ == XObject);
		untyped trace(Xest2);
		var ot = new Test2();
		trace(ot);
		untyped trace(ot.__class__);
		untyped trace(__dollar__call(ot.__class__.__super__.prototype.ClassName, ot, __dollar__array()));
		trace(ot.ClassName());
		trace(test(new XForm(null)));
		trace(XForm);
		trace(TForm);
		
    var ob2: TObject = new TObject();
    trace('Halle');
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
    var ob2: TObject = new TObject();
    trace('Halle');
    trace(ob2.ClassName());
    trace(TForm);
    trace(TObject);
    var f: TForm = new TForm(null);
    trace(f.ShowModal());
    trace(f.ClassName());
    trace(TObj2);
    trace(new TObj2(24).Test());
    trace('The END!');
	}
}
