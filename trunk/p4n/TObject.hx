/**
 * ...
 * @author Adrian Veith
 */

package p4n;

class TObject {

  public static dynamic function Release(AObject: Void): Bool {
    Release = neko.Lib.load('nekoHelper', 'release', 1); 
    return Release(AObject); 
  }
  
  
  public function release() {}	
}