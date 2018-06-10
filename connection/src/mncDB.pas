unit mncDB;
{**
 *  This file is part of the "Mini Connections"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$M+}
{$H+}
{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, Contnrs,
  mncCommons, mncConnections, mncMeta, mncORM;

type
  { TmncEngine }

  TmncEngine = class(TObject)
  public
    Name: string;
    Title: string;
    ConnectionClass: TmncConnectionClass;
    MataClass: TmncMetaClass;
  end;

{ TmncEngines }

  TmncEngines = class(TObjectList)
  private
    function GetItems(Index: Integer): TmncEngine;
  public
    function RegisterConnection(vName, vTitle: string; vConnectionClass: TmncConnectionClass): TmncEngine;
    function RegisterMeta(vName, vTitle: string; vMetaClass: TmncMetaClass): TmncEngine;
    function Find(vName: string): TmncEngine;
    function IndexOf(vName: string): Integer;
    function CreateConnection(vModel: string): TmncConnection;
    function CreateMeta(vModel: string): TmncMeta;
    property Items[Index:Integer]: TmncEngine read GetItems; default;
  end;

function DB: TmncEngines;

implementation

var
  FmncEngines: TmncEngines = nil;

function DB: TmncEngines;
begin
  if FmncEngines = nil then
    FmncEngines := TmncEngines.Create;
  Result := FmncEngines;
end;

{ TmncEngines }

function TmncEngines.GetItems(Index: Integer): TmncEngine;
begin
  Result := inherited Items[Index] as TmncEngine;
end;

function TmncEngines.RegisterConnection(vName, vTitle: string; vConnectionClass: TmncConnectionClass): TmncEngine;
begin
  Result := Find(vName);
  if Result = nil then
  begin
    Result := TmncEngine.Create;
    Result.Name := vName;
    Result.Title := vTitle;
    inherited Add(Result);
  end;
  Result.ConnectionClass := vConnectionClass;
end;

function TmncEngines.RegisterMeta(vName, vTitle: string; vMetaClass: TmncMetaClass): TmncEngine;
begin
  Result := Find(vName);
  if Result = nil then
  begin
    Result := TmncEngine.Create;
    Result.Name := vName;
    Result.Title := vTitle;
    inherited Add(Result);
  end;
  Result.MataClass := vMetaClass;
end;

function TmncEngines.Find(vName: string): TmncEngine;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count -1 do
  begin
    if SameText(vName, Items[i].Name) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TmncEngines.IndexOf(vName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to Count -1 do
  begin
    if SameText(vName, Items[i].Name) then
    begin
      Result := i;
      break;
    end;
  end;
end;

function TmncEngines.CreateConnection(vModel: string): TmncConnection;
var
  P: TmncEngine;
begin
  Result := nil;
  P := Find(vModel);
  if P <> nil then
    Result := P.ConnectionClass.Create
  else
    raise EmncException.Create('Model ' + vModel + ' not found');
end;

function TmncEngines.CreateMeta(vModel: string): TmncMeta;
var
  P: TmncEngine;
begin
  Result := nil;
  P := Find(vModel);
  if P <> nil then
    Result := P.MataClass.Create
  else
    raise EmncException.Create('Model ' + vModel + ' not found');
end;

initialization

finalization
  FreeAndNil(FmncEngines);
end.
