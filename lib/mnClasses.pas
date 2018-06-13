unit mnClasses;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$IFDEF FPC}
{$MODE delphi}
{$ENDIF}
{$M+}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, Types,
  {$ifdef FPC}
  Contnrs
  {$else}
  System.Generics.Collections
  {$endif};

type
  {$ifdef FPC}

  { TmnObjectList }

  TmnObjectList<_Object_> = class(TObjectList)
  {$else}
  TmnObjectList<_Object_: class> = class(TObjectList<_Object_>)
  {$endif}
  private
    {$ifdef FPC}
    function GetItem(Index: Integer): _Object_;
    {$endif}
  protected
    type

      { TmnObjectEnumerator }

      TmnObjectEnumerator = class(TObject)
      private
        Index: Integer;
        List: TmnObjectList<_Object_>;
        function GetCurrent: _Object_;
      public
        function MoveNext: Boolean;
        procedure Reset;
        property Current: _Object_ read GetCurrent;
      end;

    function _AddRef: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
    function _Release: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};


  public
    function QueryInterface({$ifdef FPC}constref{$else}const{$endif} iid : TGuid; out Obj):HResult; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
    procedure AfterConstruction; override;
    procedure Created; virtual;
    procedure Added(Item: _Object_); virtual;
    function Add(Item: _Object_): Integer;
    function Extract(Item: _Object_): _Object_;
    function GetEnumerator: TmnObjectEnumerator;

    {$ifdef FPC}
    property Items[Index: Integer]: _Object_ read GetItem; default;
    function Last: _Object_;
    {$endif}
  end;


  {.$ifdef FPC}

  { TEnumerator }
{
  TEnumerator<_Object_> = object
  private
    FItems: _Object_;
    FCurrent: _Object_;
    FIndex: Integer;
  public
    constructor Create;
    function MoveNext: Boolean;
    property Current: Pointer read FCurrent;
  end;}

  { TmnNamedObjectList }

  {$ifdef FPC}
  TmnNamedObjectList<_Object_> = class(TmnObjectList<_Object_>)
  {$else}

  TmnNamedObject = class(TObject)
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  TmnNamedObjectList<_Object_: TmnNamedObject> = class(TmnObjectList<_Object_>)
  {$endif}
  private
  public
    function Find(const Name: string): _Object_;
    function IndexOfName(vName: string): Integer;
    //function GetEnumerator: specialize TEnumerator<_Object_>;
  end;
  {.$endif}
{
  FreePascal:

    TMyItems = class(specialize TmnObjectList<TMyObject>)

  Delphi:

    TMyItems = class(TmnObjectList<TMyObject>)
}
implementation

{$ifdef FPC}
function TmnObjectList<_Object_>.GetItem(Index: Integer): _Object_;
begin
  Result := _Object_(inherited Items[Index]);
end;

function TmnObjectList<_Object_>.Last: _Object_;
begin
  Result := _Object_(inherited Last);
end;
{$endif}

function TmnObjectList<_Object_>._AddRef: Integer;
begin
  Result := 0;
end;

function TmnObjectList<_Object_>._Release: Integer;
begin
  Result := 0;
end;

function TmnObjectList<_Object_>.GetEnumerator: TmnObjectEnumerator;
begin
  Result := TmnObjectEnumerator.Create;
  Result.List := Self;
end;

function TmnObjectList<_Object_>.QueryInterface({$ifdef FPC}constref{$else}const{$endif} iid : TGuid; out Obj):HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TmnObjectList<_Object_>.Added(Item: _Object_);
begin
end;

function TmnObjectList<_Object_>.Add(Item: _Object_): Integer;
begin
  Result := inherited Add(Item);
  Added(Item);
end;

function TmnObjectList<_Object_>.Extract(Item: _Object_): _Object_;
begin
  Result := _Object_(inherited Extract(Item));
end;

procedure TmnObjectList<_Object_>.Created;
begin
end;

procedure TmnObjectList<_Object_>.AfterConstruction;
begin
  inherited;
  Created;
end;

{ TmnNamedObjectList }

function  TmnNamedObjectList<_Object_>.Find(const Name: string): _Object_;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].Name, Name) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TmnNamedObjectList<_Object_>.IndexOfName(vName: string): Integer;
var
  i: integer;
begin
  Result := -1;
  if vName <> '' then
    for i := 0 to Count - 1 do
    begin
      if SameText(Items[i].Name, vName) then
      begin
        Result := i;
        break;
      end;
    end;
end;

{ TmnObjectList.TmnObjectEnumerator }

function TmnObjectList<_Object_>.TmnObjectEnumerator.GetCurrent: _Object_;
begin
  Result := List.Items[Index];
end;

function TmnObjectList<_Object_>.TmnObjectEnumerator.MoveNext: Boolean;
begin
  Inc(Index);
end;

procedure TmnObjectList<_Object_>.TmnObjectEnumerator.Reset;
begin
  Index := 0;
end;

{
function TmnNamedObjectList<_Object_>.GetEnumerator: specialize TEnumerator<_Object_>;
begin
  Result:=_Object_.Create;
  Result.FItems := Self;
end;}

{
operator enumerator (TmnNamedObjectList: TmnNamedObjectList<_Object_>): TEnumerator<_Object_>;
begin
  Result.Create;
end;}

{ TEnumerator }
{
constructor TEnumerator<_Object_>.Create;
begin
  inherited;
end;

function TEnumerator<_Object_>.MoveNext: Boolean;
begin
  Inc(FIndex);
  if FIndex > FItems then
    FCurrent := FItems[FIndex]
  else
    FCurrent := nil;
end;
 }

end.
