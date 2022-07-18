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
{ The Original Code is lazyBtreeInt.pas.                                                           }
{                                                                                                  }
{ The Initial Developer of the Original Code is Adrian Veith <adrian@veith-system.de>.             }
{ Created by Adrian Veith Copyright (C) Adrian Veith. All Rights Reserved.                         }
{                                                                                                  }
{ Contributors:                                                                                    }
{   Adrian Veith                                                                                   }
{                                                                                                  }
{**************************************************************************************************}
{                                                                                                  }
{ Integer variant of the lazyBtree template                                                        }
{                                                                                                  }
{**************************************************************************************************}

unit lazyBtreeInt;
interface
uses SysUtils, Variants;

type
  TValueType = Pointer;
  TKeyType = Integer;
{$define INC_INTERFACE}
{$I tplbtree.inc}
type
  //TVisitLeave = procedure(const key: Integer; var value: Pointer) of object;
  TBTreeInt = class
  protected
    FRoot: PNode;
    FCleanUp: TReleaseProc;
  public
    destructor Destroy; override;
    procedure Clear;
    function Delete(AKey: Integer): TValueType;
    function GetAllKeys(): TKeyTypeArray;
    function GetAllValues(): TValueTypeArray;
    function GetInline(AKey: Integer): TValueType; inline;
    function Get(AKey: Integer): TValueType;
    function IsEmpty: Boolean; inline;
    procedure ForAll(visit: TVisitLeaveClosure);
    function Put(AKey: Integer; AValue: TValueType): TValueType;
    property ReleaseData: TReleaseProc read FCleanUp write FCleanUp;
  end;
  TBTreeIntValue = class(TBTreeInt)
  private
    function getValue(Index: Integer): Variant; inline;
    procedure setValue(Index: Integer; const Value: Variant);
  public
    constructor Create;
    property Value[Index: Integer]: Variant read getValue write setValue; default;
  end;

implementation

{$define lessAndEqual}

//function Compare(A, B: TKeyType): Integer; inline;
//begin
//  if A > B then Result:= 1
//  else if A = B then Result:= 0
//  else Result:= -1;
//end;

procedure CleanKey(var k: TKeyType); inline;
begin
  k:= 0;
end;

{$undef INC_INTERFACE}
{$I tplbtree.inc}


{ TLazyBTree }

function TBTreeInt.GetInline(AKey: Integer): TValueType;
var
  it: PItem;
begin
  it:= InternalFind(FRoot, AKey);
  if it <> nil then
    Result:= it.Value
  else
    Result:= nil;
end;

function TBTreeInt.IsEmpty: Boolean;
begin
  Result:= FRoot = nil;
end;

procedure TBTreeInt.Clear;
begin
  if FRoot <> nil then begin
    if Assigned(FCleanUp) then
      FRoot:= ModifyAllValues(FRoot, FCleanUp);
    FRoot:= CleanTree(FRoot);
  end;
end;

function TBTreeInt.Delete(AKey: Integer): TValueType;
begin
  Result:= nil;
  FRoot:= InternalDelete(FRoot, AKey, Result);
  if Assigned(FCleanUp) and (Result <> nil) then
    Result:= FCleanUp(Result);
end;

destructor TBTreeInt.Destroy;
begin
  Clear;
  inherited;
end;

procedure TBTreeInt.ForAll(visit: TVisitLeaveClosure);
begin
  FRoot:= VisitAllLeaves(FRoot, visit);
end;

function TBTreeInt.Get(AKey: Integer): TValueType;
begin
  Result:= GetInline(AKey);
end;

procedure CollectKey(Data: Pointer; const key: TKeyType; var value: TValueType);
var
  len: Integer;
begin
  len:= Length(TKeyTypeArray(Data^));
  SetLength(TKeyTypeArray(Data^), len + 1);
  TKeyTypeArray(Data^)[len]:= key;
end;

function TBTreeInt.GetAllKeys: TKeyTypeArray;
var visit: TVisitLeaveClosure;
begin
  visit.data:= @Result;
  visit.call:= CollectKey;
  VisitAllLeaves(FRoot, visit);
end;

procedure CollectValue(Data: Pointer; const key: TKeyType; var value: TValueType);
var
  len: Integer;
  arr: ^TValueTypeArray absolute Data;
begin
  len:= Length(arr^);
  SetLength(arr^, len + 1);
  arr^[len]:= value;
end;

function TBTreeInt.GetAllValues: TValueTypeArray;
var visit: TVisitLeaveClosure;
begin
  visit.data:= @Result;
  visit.call:= CollectValue;
  VisitAllLeaves(FRoot, visit);
end;

function TBTreeInt.Put(AKey: Integer; AValue: TValueType): TValueType;
begin
  FRoot:= InternalPut(FRoot, AKey, AValue, Result);
  if Assigned(FCleanUp) and (AValue = nil) and (Result <> nil) then
    Result:= FCleanUp(Result);
end;

{ TBTreeIntValue }


function cleanVariant(value: TValueType): TValueType;
begin
  PVariant(value)^:= Unassigned;
  dispose(value);
  Result:= nil;
end;

constructor TBTreeIntValue.Create;
begin
  FCleanUp:= cleanVariant;
end;

function TBTreeIntValue.getValue(Index: Integer): Variant;
var
  v: PVariant;
begin
  v:= get(Index);
  if v <> nil then Result:= v^;
end;

procedure TBTreeIntValue.setValue(Index: Integer; const Value: Variant);
var
  old, v: PVariant;
begin
  if not VarIsNull(Value) then begin
    new(v);
    v^:= Value;
    old:= put(Index, v);
  end else begin
    old:= put(Index, nil);
  end;
  if old <> nil then begin
    old^:= Unassigned;
    dispose(old);
  end;
end;

end.
