{**************************************************************************************************}
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is lazyBtree.inc.                                                           }
{                                                                                                  }
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             }
{ Created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                         }
{                                                                                                  }
{ Contributors:                                                                                    }
{   Adrian Veith                                                                                   }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ poor mans template of a lazyBtree                                                                }                                                                            
{                                                                                                  }
{**************************************************************************************************}

{$ifdef INC_INTERFACE}
const
  cMaxItems = 128;
  cCenter = cMaxItems div 2;

type
  PNode = ^RNode;
  PItem = ^RItem;
  RItem = record
    Key: TKeyType;
    Value: Pointer;
    Node: PNode;
  end;
  TItemArray = array[0..cMaxItems-1] of RItem;
  TKeyTypeArray = array of TKeyType;
  TValueTypeArray = array of TValueType;
  PItems = ^TItemArray;
  RNode = record
    Items: PItems;
    Left: PNode;
    Count: Integer;
  end;
  TVisitLeaveCall = procedure(Data: Pointer; const key: TKeyType; var value: TValueType);
  //TVisitLeaveClearCall = procedure(Data: Pointer; const key: TKeyType; var value: TValueType; var Clear: Boolean);
  TVisitLeaveClosure = record
    call: TVisitLeaveCall;
    //callClear: TVisitLeaveClearCall;
    data: Pointer;
  end;
  TReleaseProc = function(value: TValueType): TValueType;
  //TVisitLeave = procedure(const key: TKeyType; var value: TValueType; var Clear: Boolean) of object;
{$else}
type
  TItems1 = array[0..4] of RItem;
  TItems2 = array[0..31] of RItem;
  TItemsCenter = array[0..79] of RItem;
  TItems6 = array[0..95] of RItem;
  //TItems3 = array[0..16] of RItem;
  PItems1 = ^TItems1;
  PItems2 = ^TItems2;
  //PItems3 = ^TItems3;
  //PItems6 = ^TItems6;
  PItemsCenter = ^TItemsCenter;

  TVisitNode = function(n: PNode): PNode of object;

{$ifndef USE_OTHER_MEMMENAGER}
function MemAlloc(Size: Cardinal): Pointer; inline;
begin
  Result:= AllocMem(Size);
end;

procedure MemFree(Data:Pointer); inline;
begin
  FreeMemory(Data);
end;

function MemRealloc(Old: Pointer; Size: Cardinal): Pointer;// inline;
begin
  if Old = nil then
    Result:= AllocMem(Size)
  else
    Result:= ReallocMemory(Old, Size);
end;
{$endif}

function SearchItems(n: PNode; const AKey: TKeyType): Integer; inline;
var
	H, I: Integer;
{$ifndef lessAndEqual}
  SW: Integer;
{$endif}
	bFound: boolean;
begin
	bFound := False;
	result := 0;
  H:= n.Count -1;
	while result <= H do
	begin
		I := (result + H) shr 1;
{$ifndef lessAndEqual}
		SW:= Compare(n.Items[I].Key, AKey);
		if SW < 0 then
{$else}
    if n.Items[I].Key < AKey then
{$endif}
      result := I + 1
    else begin
			H := I - 1;
{$ifndef lessAndEqual}
			if SW = 0 then
{$endif}
        bFound := True;
		end;
	end;
	if bFound
    {$ifdef lessAndEqual} and (n.Items[result].Key = AKey) {$endif}
  then
		inc(result)
	else
		result:= - result;
end;

function InternalFind(n: PNode; const AKey: TKeyType): PItem; inline;
var
  x: Integer;
begin
  Result:= nil;
  while n <> nil do begin
    x:= SearchItems(n, AKey);
    if x <= 0 then begin
      if x = 0 then
        n:= n.Left
      else begin
        x:= (-x) -1;
        if x < n.Count then
          n:= n.Items[x].Node
        else
          n:= nil;
      end;
    end else begin
      Result:= @n.Items[x - 1];
      break;
    end;
  end;
end;

function DeleteItem(n: PNode; x: Integer): PNode; inline;
var
  cnt: Integer;
  it2: PItems;
begin
  with n.Items[x] do begin
    Value:= nil;
    if Node <> nil then begin
      Result:= n;
      exit;
    end;
    CleanKey(Key);
  end;
  cnt:= n.Count;
  case cnt of
    2 + High(TItems1): it2:= MemAlloc(sizeof(TItems1));
    //2 + High(TItems2): New(PItems3(it2));
    2 + High(TItems2): it2:= MemAlloc(sizeof(TItems2));
    2 + High(TItemsCenter): it2:= MemAlloc(sizeof(TItemsCenter));
    2 + High(TItems6): it2:= MemAlloc(sizeof(TItems6));
    else
      it2:= n.Items;
  end;
  dec(cnt);
  n.Count:= cnt;
  if cnt > 0 then begin
    if it2 <> n.Items then begin
      if x > 0 then
        Move(n.Items[0], it2[0], x * sizeof(RItem));
      if x < cnt then
        Move(n.Items[x + 1], it2[x], (cnt - x) * sizeof(RItem));
      MemFree(n.Items);
      n.Items:= it2;
    end else begin
      if x < cnt then begin
        Move(n.Items[x + 1], it2[x], (cnt - x) * sizeof(RItem));
      end;
      FillChar(it2[cnt], sizeof(RItem), 0);
    end;
    Result:= n;
  end else begin
    Result:= n.Left;
    MemFree(n.Items);
    MemFree(n);
  end;
end;

function InternalDelete(n: PNode; const AKey: TKeyType; out AValue: TValueType): PNode;
type
  RPath = record
    Xi: Integer;
    Nd: PNode;
  end;
var
  h, x: Integer;
  Path: array[0..20] of RPath;
  n2: PNode;

begin
  Result:= n;
  AValue:= nil;
  h:= 0;
  while n <> nil do begin
    x:= SearchItems(n, AKey);
    if x <= 0 then begin
      Path[h].Nd:= n;
      Path[h].Xi:= - x;
      inc(h);
      if x = 0 then
        n:= n.Left
      else begin
        x:= (-x) -1;
        if x < n.Count then
          n:= n.Items[x].Node
        else
          n:= nil;
      end;
    end else begin
      dec(x);
      AValue:= n.Items[x].Value;
      if AValue = nil then exit;
      n2:= DeleteItem(n, x);
      //if (n2 <> n) and (h = 0) then begin
      //  Result:= n2;
      //  exit;
      //end;
      dec(h);
      while (n2 <> n) and (h >=0) do begin
        n:= n2;
        with Path[h] do begin
          x:= Xi -1;
          if x >= 0 then begin
            if (n = nil) and (Nd.Items[x].Value = nil) then begin
              n:= Nd;
              n.Items[x].Node:= nil;
              n2:= DeleteItem(n, x);
            end else begin
              Nd.Items[x].Node:= n;
              exit;
            end;
          end else begin
            Nd.Left:= n;
            exit;
          end;
        end;
        dec(h);
      end;
      if h < 0 then
        Result:= n2;
      exit;
    end;
  end;
end;


function InsertItem(n: PNode; x: Integer; const AKey: TKeyType; AValue: TValueType): PItem;
var
  cntMin1: Integer;
  //it2: PItems;
begin
  cntMin1 := n.Count;
  inc(n.Count);
  case n.Count of
    2 + High(TItems1): begin
      n.Items:= MemReAlloc(n.Items, sizeof(TItems2));
      Fillchar(n.Items[High(TItems1)+1], sizeof(TItems2) - sizeof(TItems1), 0);
    end;
    //2 + High(TItems2): New(PItems3(it2));
    2 + High(TItems2): begin
      n.Items:= MemReAlloc(n.Items, sizeof(TItemsCenter));
      Fillchar(n.Items[High(TItems2)+1], sizeof(TItemsCenter) - sizeof(TItems2), 0);
    end;
    2 + High(TItemsCenter): begin
      n.Items:= MemReAlloc(n.Items, sizeof(TItems6));
      Fillchar(n.Items[High(TItemsCenter)+1], sizeof(TItems6) - sizeof(TItemsCenter), 0);
    end;
    2 + High(TItems6): begin
      n.Items:= MemReAlloc(n.Items, sizeof(TItemArray));
      Fillchar(n.Items[High(TItems6)+1], sizeof(TItemArray) - sizeof(TItems6), 0);
    end;
    //else
    //  it2:= n.Items;
  end;
  {if it2 <> n.Items then begin
    if x > 0 then begin
      Move(n.Items^, it2^, x * sizeof(RItem));
    end;
  end;}
  if x < cntMin1 then begin
    Move(n.Items[x], n.Items[x+1], (cntMin1 - x) * sizeof(RItem));
    FillChar(n.Items[x], sizeof(RItem), 0);
  end;
  //FillChar(n.Items[x], sizeof(RItem), 0);
  //for i := n.Count - 1 downto x + 1 do
  //  it2[i]:= n.Items[i-1];
  Result:= @n.Items[x];
  Result.Key:= AKey;
  Result.Value:= AValue;
  //if it2 <> n.Items then begin
    //MemFree(n.Items);
    //n.Items:= it2;
  //end;
end;

function InternalPut(n: PNode; AKey: TKeyType; AValue: TValueType; out OldValue: TValueType): PNode;
type
  RPath = record
    X: Integer;
    N: PNode;
  end;
var
  h, x: Integer;
  Path: array[0..30] of RPath;
  left: PNode;

  function SplitPage: PNode;
  var
    x: Integer;
    it1, it2: PItemsCenter;
  begin
    left:= Path[h].N;
    x:= - Path[h].X;
    it1:= MemAlloc(sizeof(TItemsCenter));
    it2:= MemAlloc(sizeof(TItemsCenter));
    Result:= MemAlloc(sizeof(RNode));
    Result.Items:= PItems(it2);
    Result.Count:= cCenter;
    if x = cCenter then begin
      Move(left.Items^, it1^, cCenter * sizeof(RItem));
      Move(left.Items[cCenter], it2^, cCenter * sizeof(RItem));
      Result.Left:= n;
    end else begin
      if x < cCenter then begin
        if x > 0 then
          Move(left.Items^, it1^, x * sizeof(RItem));
        it1[x].Key:= AKey;
        it1[x].Value:= AValue;
        it1[x].Node:= n;
        Move(left.Items[x], it1[x+1], (cCenter - x -1) * sizeof(RItem));
        with left.Items[cCenter - 1] do begin
          AKey:= Key;
          AValue:= Value;
          Result.Left:= Node;
          CleanKey(Key);
        end;
        Move(left.Items[cCenter], it2^, cCenter * SizeOf(RItem));
      end else begin
        Move(left.Items^, it1^, cCenter * SizeOf(RItem));
        x:= x - (cCenter + 1);
        if x > 0 then
          Move(left.Items[cCenter + 1], it2^, x * sizeof(RItem));
        it2[x].Key:= AKey;
        it2[x].Value:= AValue;
        it2[x].Node:= n;
        Move(left.Items[cCenter + 1 + x], it2[x+1], (cCenter - x -1) * sizeof(RItem));
        with left.Items[cCenter] do begin
          AKey:= Key;
          AValue:= Value;
          Result.Left:= Node;
          CleanKey(Key);
        end;
      end;
    end;
    left.Count:= cCenter;
    MemFree(left.Items);
    left.Items:= PItems(it1);
  end;

begin
  OldValue:= nil;
  Result:= n;
  h:= 0;
  while n <> nil do begin
    x:= SearchItems(n, AKey);
    if x <= 0 then begin
      Path[h].N:= n;
      Path[h].X:= x;
      inc(h);
      if x = 0 then
        n:= n.Left
      else begin
        x:= (-x) -1;
        if x < n.Count then
          n:= n.Items[x].Node
        else
          n:= nil;
      end;
    end else begin
      with n.Items[x - 1] do begin
        OldValue:= Value;
        Value:= AValue;
      end;
      exit;
    end;
  end;
  dec(h);
  left:= nil;
  while h >= 0 do begin
    if Path[h].N.Count < cMaxItems then begin
      InsertItem(Path[h].N, - Path[h].X, AKey, AValue).Node:= n;
      exit;
    end else begin
      n:= SplitPage;
    end;
    dec(h);
  end;
  Result:= MemAlloc(sizeof(RNode));
  Result.Items:= MemAlloc(sizeof(TItems1));
  //New(PItems1(Result.Items));
  Result.Count:= 1;
  Result.Left:= left;
  Result.Items[0].Key:= AKey;
  //UniqueString(Result.Items[0].Key);
  Result.Items[0].Value:= AValue;
  Result.Items[0].Node:= n;
end;

function CleanTree(n: PNode): PNode;
var
  i: Integer;
begin
  if n <> nil then begin
    if n.Left <> nil then
      n.Left:= CleanTree(n.Left);
    for i := 0 to n.Count - 1 do
      with n.Items[i] do begin
        if Node <> nil then
          Node:= CleanTree(Node);
        CleanKey(Key);
        Value:= nil;
      end;
    MemFree(n.Items);
    MemFree(n);
  end;
  Result:= nil;
end;

function VisitAllNodes(n: PNode; visit: TVisitNode): PNode;
var
  i: Integer;
begin
  if n.Left <> nil then
    n.Left:= VisitAllNodes(n.Left, visit);
  for i := 0 to n.Count - 1 do
    with n.Items[i] do begin
      if Node <> nil then
        Node:= VisitAllNodes(Node, visit);
    end;
  Result:= visit(n);
end;

function VisitAllLeaves(n: PNode; visit: TVisitLeaveClosure): PNode;
var
  i: Integer;
  n1, n2: Pnode;
  cleanups: set of 0 .. cMaxItems-1;
  needClean: Boolean;
begin
  if n <> nil then begin
    if n.Left <> nil then begin
      n1:= n.Left;
      n2:= VisitAllLeaves(n1, visit);
      if n1 <> n2 then
        n.Left:= n2;
    end;
    i:= 0;
    cleanups:= [];
    needClean:= False;
    while i < n.Count do begin
      with n.Items[i] do begin
        n1:= Node;
        if Value <> nil then begin
          visit.call(visit.data, Key, TValueType(Value));
          if Value = nil then begin
            Include(cleanups, i);
            needClean:= True;
          end;
        end;
      end;
      if n1 <> nil then begin
        n2:= VisitAllLeaves(n1, visit);
        if n1 <> n2 then begin
          n.Items[i].Node:= n2
        end;
      end;
      inc(i);
    end;
    if needClean then begin
      for i := n.Count - 1 downto 0 do begin
        if i in cleanups then begin
          Result:= DeleteItem(n, i);
          if Result = nil then exit;
        end;
      end;
    end;
  end;
  Result:= n;
end;

function ModifyAllValues(n: PNode; visit: TReleaseProc): PNode;
var
  i: Integer;
  n1, n2: Pnode;
  cleanups: set of 0 .. cMaxItems-1;
  needClean: Boolean;
begin
  if n <> nil then begin
    if n.Left <> nil then begin
      n1:= n.Left;
      n2:= ModifyAllValues(n1, visit);
      if n1 <> n2 then
        n.Left:= n2;
    end;
    i:= 0;
    cleanups:= [];
    needClean:= False;
    while i < n.Count do begin
      with n.Items[i] do begin
        n1:= Node;
        if Value <> nil then begin
          TValueType(Value):= visit(TValueType(Value));
          if Value = nil then begin
            Include(cleanups, i);
            needClean:= True;
          end;
        end;
      end;
      if n1 <> nil then begin
        n2:= ModifyAllValues(n1, visit);
        if n1 <> n2 then begin
          n.Items[i].Node:= n2
        end;
      end;
      inc(i);
    end;
    if needClean then begin
      for i := n.Count - 1 downto 0 do begin
        if i in cleanups then begin
          Result:= DeleteItem(n, i);
          if Result = nil then exit;
        end;
      end;
    end;
  end;
  Result:= n;
end;

{$endif}

