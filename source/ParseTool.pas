unit ParseTool;

interface
  uses SysUtils;

{$INLINE ON}

type
  WeakSlice = object
  private
    data: PAnsiChar;
    last: Integer;
    //orig: PAnsiString;
    //function GetLength: Integer; inline;
    function GetValue: AnsiString; inline;
    function GetChar(i: Integer): AnsiChar; inline;
    //function GetContent: AnsiString; inline;
    //procedure Reset; inline;
    //property Content: AnsiString read GetContent;
  public
    procedure Assign(const s: AnsiString); overload; inline;
    procedure Assign(const s: AnsiString; len: Integer); overload; inline;
    procedure Assign(const s: AnsiString; start, len: Integer); overload;
    function Copy(start, len: Integer): WeakSlice;
    procedure Clear; inline;
    function Cmp(const s: WeakSlice): Integer;
    // reminder to myself - functions in while or until conditions are not inlined !!
    function IsValid: Boolean; inline;
    function Empty: Boolean; inline;
    function Equal(const s: AnsiString): Boolean; overload; inline;
    function Equal(const s: WeakSlice): Boolean; overload;
    function IEqual(const s: Ansistring): Boolean; overload; inline;
    function IEqual(const s: WeakSlice): Boolean; overload;
    function Less(const s: WeakSlice): Boolean;
    function ILess(const s: WeakSlice): Boolean;
    function ICmp(const s: WeakSlice): Integer;
    procedure SetEmpty; inline;
    procedure Shrink(len: Integer);
    function SplitAt(c: AnsiChar): WeakSlice;
    function StartsWith(const s: AnsiString): Boolean; overload; inline;
    function StartsWith(s: WeakSlice): Boolean; overload;
    function IStartsWith(const s: AnsiString): Boolean; overload; inline;
    function IStartsWith(s: WeakSlice): Boolean; overload;
    function Trim: WeakSlice;
    function TrimLeft: WeakSlice;
    function TrimRight: WeakSlice;

    property At[i: Integer]: AnsiChar read GetChar;
    property Length: Integer read Last;
    property Value: AnsiString read GetValue;
    property _Data: PAnsiChar read data;
    //class operator Explicit(const s: AnsiString): WeakSlice; inline;
  end;
  PartialString = record
  private
    slice: WeakSlice;
    _s: AnsiString;
    function GetChar(i: Integer): AnsiChar; inline;
    function GetValue: AnsiString; inline;
  public
    procedure Assign(const s: AnsiString); overload; inline;
    procedure Assign(const s: AnsiString; start, len: Integer); overload; inline;
    function Copy(start, len: Integer): WeakSlice; inline;
    procedure Clear; inline;
    function Cmp(const s: WeakSlice): Integer; inline;
    function Empty: Boolean; inline;
    function Equal(const s: AnsiString): Boolean; overload; inline;
    function Equal(const s: WeakSlice): Boolean; overload; inline;
    function IEqual(const s: Ansistring): Boolean; overload; inline;
    function IEqual(const s: WeakSlice): Boolean; overload; inline;
    function Less(const s: WeakSlice): Boolean; inline;
    function ILess(const s: WeakSlice): Boolean; inline;
    function ICmp(const s: WeakSlice): Integer; inline;
    procedure Reset; inline;
    procedure SetEmpty; inline;
    procedure Shrink(len: Integer); inline;
    function SplitAt(c: AnsiChar): WeakSlice; inline;

    property At[i: Integer]: AnsiChar read GetChar; default;
    property Content: AnsiString read _s;
    property Length: Integer read slice.Last;
    property Value: AnsiString read GetValue;

    //class operator Implicit(x: WeakSlice): PartialString; overload; inline;
    class operator Implicit(x: PartialString): WeakSlice; overload; inline;
  end;
  StringSplitter = record
  private
    _data: PartialString;
    _last: WeakSlice;
    _split: AnsiChar;
    //function GetCurrent: PartialString; //inline;
  public
    function MoveNext: Boolean; inline;
    property Current: WeakSlice read _last;
    function GetEnumerator: StringSplitter; inline;
  end;

function Split(s: string; at: AnsiChar): StringSplitter;

implementation

{ WeakSlice }

function WeakSlice.IsValid: Boolean;
begin
  Result:= Last > 0;
end;


function WeakSlice.GetChar(i: Integer): AnsiChar;
begin
  Result:= data[i - 1];
end;

//function WeakSlice.GetContent: AnsiString;
//begin
//  Result:= AnsiString(orig);
//end;

function WeakSlice.Empty: Boolean;
begin
  Result:= last <= 0;
end;

function WeakSlice.GetValue: AnsiString;
begin
  //if (Pointer(data) = orig) and (last = System.Length(AnsiString(orig))) then Result:= AnsiString(orig)
  //else Result:= System.copy(AnsiString(orig), data - PAnsiChar(orig) + 1, Length);
  if (data <> nil) and (Last > 0) then begin
    SetLength(Result, Last);
    Move(data^, Result[1], Last);
  end else Result:= '';
end;

procedure WeakSlice.Assign(const s: AnsiString);
begin
  //orig:= Pointer(s);
  data:= Pointer(s);
  last:= System.Length(s);
end;

procedure WeakSlice.Assign(const s: AnsiString; start, len: Integer);
var
  max: Integer;
begin
  data:= Pointer(s);
  if data <> nil then begin
    max:= System.Length(s);
    dec(start);
    if start >= 0 then begin
      if start < max then
        data:= @data[start]
      else
        data:= @data[max - 1]
    end;
    last := len;
    if last > max - start then
      last:= max - start;
  end else begin
    //data:= nil;
    last:= 0;
  end;
end;

procedure WeakSlice.Assign(const s: AnsiString; len: Integer);
var
  max: Integer;
begin
  //orig:= Pointer(s);
  data:= Pointer(s);
  if len > 0 then begin
    max:= System.Length(s);
    if len <= max then last:= len else last:= max;
  end else
    last:= 0;
end;

procedure WeakSlice.Clear;
begin
  //orig:= nil;
  data:= nil;
  last:= 0;
end;

function WeakSlice.Cmp(const s: WeakSlice): Integer;
var
  i, m: Integer;
begin
  m:= Length;
  i:= s.Length;
  if i < m then m:= i;
  for i := 0 to m - 1 do begin
    Result:= Ord(data[i]) - Ord(s.data[i]);
    if Result <> 0 then
      exit;
  end;
  Result:= Length - s.Length;
end;

function WeakSlice.Copy(start, len: Integer): WeakSlice;
begin
  if (len > 0) then begin
    dec(start);
    if start < 0 then start:= 0;
    if start < last then begin
      //Result.orig:= orig;
      Result.data:= data + start;
      len:= start + len;
      if Cardinal(len) > Cardinal(last) then len:= last;
      Result.last:= len - start;
      exit;
    end;
  end;
  Result.Clear;
end;

function WeakSlice.Equal(const s: AnsiString): Boolean;
var
  other: WeakSlice;
begin
  other.Assign(s);
  Result:= Equal(other);
end;

function WeakSlice.Equal(const s: WeakSlice): Boolean;
var
  i: Integer;
begin
  if Length = s.Length then begin
    for i := 0 to last - 1 do begin
      if s.data[i] <> data[i] then begin
        Result:= False;
        exit;
      end;
    end;
    Result:= True;
  end else
    Result:= False;
end;


//class operator WeakSlice.Explicit(const s: AnsiString): WeakSlice;
//begin
//  Result.Assign(s);
//end;

function WeakSlice.IEqual(const s: AnsiString): Boolean;
var
  other: WeakSlice;
begin
  other.Assign(s);
  Result:= IEqual(other);
end;

function WeakSlice.ICmp(const s: WeakSlice): Integer;
var
  i, m: Integer;
  c, cs: AnsiChar;
begin
  m:= Length;
  i:= s.Length;
  if i < m then m:= i;
  for i := 0 to m - 1 do begin
    c:= data[i];
    cs:= s.data[i];
    if c <> cs then begin
        if c in ['a'..'z'] then c:= AnsiChar(Ord(c) - Ord('a') + Ord('A'));
        if cs in ['a'..'z'] then cs:= AnsiChar(Ord(cs) - Ord('a') + Ord('A'));
        Result:= Ord(c) - Ord(cs);
        if Result <> 0 then
          exit;
    end;
  end;
  Result:= Length - s.Length;
end;

function WeakSlice.IEqual(const s: WeakSlice): Boolean;
var
  i: Integer;
  ci, ck: AnsiChar;
begin
  if Length = s.Length then begin
    for i := 0 to last - 1 do begin
      ci:= data[i];
      ck:= s.data[i];
      if ck <> ci then begin
        case ci of
          'A'..'Z': Result:= AnsiChar(Ord(ci) + Ord('a') - Ord('A')) = ck;
          'a'..'z': Result:= AnsiChar(Ord(ci) - Ord('a') + Ord('A')) = ck;
          else Result:= False;
        end;
        if not Result then exit;
      end;
    end;
    Result:= True;
  end else
    Result:= False;
end;

function WeakSlice.ILess(const s: WeakSlice): Boolean;
var
  i, m: Integer;
  c, cs: AnsiChar;
begin
  m:= Length;
  i:= s.Length;
  if i < m then m:= i;
  for i := 0 to m - 1 do begin
    c:= data[i];
    cs:= s.data[i];
    if c <> cs then begin
        if c in ['a'..'z'] then c:= AnsiChar(Ord(c) - Ord('a') + Ord('A'));
        if cs in ['a'..'z'] then cs:= AnsiChar(Ord(cs) - Ord('a') + Ord('A'));
        if c >= cs then begin
          Result:= False;
          exit;
        end;
    end else begin
      Result:= False;
      exit;
    end;
  end;
  Result:= s.IsValid;
end;

function WeakSlice.IStartsWith(const s: AnsiString): Boolean;
var
  ws: WeakSlice;
begin
  ws.Assign(s);
  Result:= IStartsWith(ws);
end;

function WeakSlice.IStartsWith(s: WeakSlice): Boolean;
var
  x: Integer;
  c, cs: AnsiChar;
begin
  if Length >= s.Length then begin
    for x := 0 to s.Length -1 do begin
      c:= data[x];
      cs:= s.data[x];
      if c <> cs then begin
        case c of
          'A'..'Z': Result:= AnsiChar(Ord(c) + Ord('a') - Ord('A')) = cs;
          'a'..'z': Result:= AnsiChar(Ord(c) - Ord('a') + Ord('A')) = cs;
          else Result:= False;
        end;
        if not Result then
          exit;
      end;
    end;
    Result:= True;
  end else
    Result:= False;
end;

function WeakSlice.Less(const s: WeakSlice): Boolean;
var
  i, m: Integer;
begin
  m:= Length;
  i:= s.Length;
  if i < m then m:= i;
  for i := 0 to m - 1 do begin
    if data[i] >= s.data[i] then begin
      Result:= False;
      exit;
    end;
  end;
  Result:= s.IsValid;
end;

//procedure WeakSlice.Reset;
//begin
//  last:= System.Length(AnsiString(orig));
//  data:= Pointer(orig);
//end;

procedure WeakSlice.SetEmpty;
begin
  last:= 0;
end;

procedure WeakSlice.Shrink(len: Integer);
begin
  if len < Length then begin
    if len > 0 then begin
      last:= len;
    end else
      SetEmpty;
  end;
end;

function WeakSlice.SplitAt(c: AnsiChar): WeakSlice;
var
  i: Integer;
begin
  for i:= 0 to last - 1 do begin
    if data[i] = c then begin
      Result.data:= data;
      Result.last:= i;
      //Result.orig:= orig;
      data:= @data[i + 1];
      dec(last, i + 1);
      exit;
    end;
  end;
  Result:= Self;
  SetEmpty;
end;

function WeakSlice.StartsWith(const s: AnsiString): Boolean;
var
  ws: WeakSlice;
begin
  ws.Assign(s);
  Result:= StartsWith(ws);
end;

function WeakSlice.StartsWith(s: WeakSlice): Boolean;
var
  x: Integer;
begin
  if Length >= s.Length then begin
    for x := 0 to s.Length -1 do begin
      if data[x] <> s.data[x] then begin
        Result:= False;
        exit;
      end;
    end;
    Result:= True;
  end else
    Result:= False;
end;

function WeakSlice.Trim: WeakSlice;
var
  i, r: Integer;
begin
  for i := 0 to Last - 1 do begin
    if data[i] > ' ' then begin
      for r := last - 1 downto i do begin
        if data[r] > ' ' then begin
          //Result.orig:= orig;
          Result.data:= @data[i];
          Result.last:= r - i + 1;
          exit;
        end;
      end;
    end;
  end;
  Result.Clear;
end;

function WeakSlice.TrimLeft: WeakSlice;
var
  i: Integer;
begin
  for i := 0 to Last - 1 do begin
    if data[i] > ' ' then begin
      //Result.orig:= orig;
      Result.data:= @data[i];
      Result.last:= last - i;
      exit;
    end;
  end;
  Result.Clear;
end;

function WeakSlice.TrimRight: WeakSlice;
var
  i: Integer;
begin
  for i := Last - 1 downto 0 do begin
    if data[i] > ' ' then begin
      //Result.orig:= orig;
      Result.data:= data;
      Result.last:= i + 1;
      exit;
    end;
  end;
  Result.Clear;
end;

{ StringSplitter }

function Split(s: string; at: AnsiChar): StringSplitter;
begin
  Result._data.Assign(s);
  Result._last.Clear;
  Result._split:= at;
end;

//function StringSplitter.GetCurrent: PartialString;
//begin
//  Result:= last;
//end;

function StringSplitter.GetEnumerator: StringSplitter;
begin
  Result:= Self;
end;

function StringSplitter.MoveNext: Boolean;
begin
  _last:= _data.SplitAt(_split);
  Result:= not (_data.Empty and _last.Empty);
end;

{ PartialString }

procedure PartialString.Assign(const s: AnsiString; start, len: Integer);
begin
  _s:= s;
  slice.Assign(s, start, len);
end;

procedure PartialString.Assign(const s: AnsiString);
begin
  _s:= s;
  slice.Assign(s);
end;

procedure PartialString.Clear;
begin
  _s:= '';
  slice.Clear;
end;

function PartialString.Cmp(const s: WeakSlice): Integer;
begin
  Result:= slice.Cmp(s);
end;

function PartialString.Copy(start, len: Integer): WeakSlice;
begin
  Result:= slice.Copy(start, len);
end;

function PartialString.Equal(const s: WeakSlice): Boolean;
begin
  Result:= slice.Equal(s);
end;

function PartialString.GetChar(i: Integer): AnsiChar;
begin
  Result:= slice.GetChar(i);
end;

function PartialString.Empty: Boolean;
begin
  Result:= slice.Empty;
end;

function PartialString.GetValue: AnsiString;
begin
  Result:= slice.Value;
end;

function PartialString.Equal(const s: AnsiString): Boolean;
begin
  Result:= slice.Equal(s);
end;

function PartialString.ICmp(const s: WeakSlice): Integer;
begin
  Result:= slice.ICmp(s);
end;

function PartialString.IEqual(const s: Ansistring): Boolean;
begin
  Result:= slice.IEqual(s);
end;

function PartialString.IEqual(const s: WeakSlice): Boolean;
begin
  Result:= slice.IEqual(s);
end;

function PartialString.ILess(const s: WeakSlice): Boolean;
begin
  Result:= slice.ILess(s);
end;

//class operator PartialString.Implicit(x: WeakSlice): PartialString;
//begin
//  Result._s:= x.Content;
//  Result.slice:= x;
//end;

class operator PartialString.Implicit(x: PartialString): WeakSlice;
begin
  Result:= x.slice;
end;

function PartialString.Less(const s: WeakSlice): Boolean;
begin
  Result:= slice.Less(s);
end;

procedure PartialString.Reset;
begin
  slice.Assign(_s);
end;

procedure PartialString.SetEmpty;
begin
  slice.SetEmpty;
end;

procedure PartialString.Shrink(len: Integer);
begin
  slice.Shrink(len);
end;

function PartialString.SplitAt(c: AnsiChar): WeakSlice;
begin
  Result:= slice.SplitAt(c);
end;

end.
