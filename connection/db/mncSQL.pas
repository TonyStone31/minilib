unit mncSQL;
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
  Classes, SysUtils, Contnrs,
  mncConnections, mncCommons, mncSchemas;

type
  TmncParseSQLOptions = set of (psoGenerateParams, psoAddParamsID, psoAddParamsNames);

  TmncSQLSession = class;
  TmncSQLCommand = class;
  TmncSQLGenerator = class;

  { TmncSQLConnection }

  TmncSQLConnection = class(TmncConnection)
  public
    function CreateSession: TmncSQLSession; virtual; abstract;
    procedure Execute(Command: string); virtual;
  end;

  { TmncSQLSchema }

  TmncSQLSchema = class(TmncSchema)
  end;

  { TmncSQLSession }

  TmncSQLSession = class(TmncSession)
  public
    function CreateCommand: TmncSQLCommand; virtual; abstract;
    function CreateSchema: TmncSchema; virtual; abstract;
  end;

  TmncSQLName = class(TObject)
  public
    ID: Integer;
    Name: string;
  end;

  { TmncSQLNames }

  TmncSQLProcessed = class(TObjectList)
  private
    function GetItem(Index: Integer): TmncSQLName;
  public
    SQL: string;
    procedure Clear; override;
    procedure Add(vID: Integer; vName:string);
    property Items[Index: Integer]: TmncSQLName read GetItem; default;
  end;

  { TmncSQLCommand }

  TmncSQLCommand = class(TmncCommand)
  private
    function GetSQL: TStrings;
  protected
    SQLProcessed: TmncSQLProcessed;
    {
      GetParamChar: Called to take the real param char depend on the sql engine to replace it with this new one.
                    by default it is ?
    }
    function GetParamChar: string; virtual;
    procedure DoParse; override;
    procedure DoUnparse; override;
    procedure ParseSQL(Options: TmncParseSQLOptions; ParamChar: string = '?');
  public
    constructor Create; override;
    destructor Destroy; override;
    property SQL: TStrings read GetSQL;//Alias of Request, autocomplete may add it in private becareful
  end;

  { TmncSQLGenerator }

  TmncSQLGenerator = class(TmncObject)
  public
    function Select(Table: string; Fields: array of string; Keys: array of string; ExtraFields: array of string): string; overload; virtual; abstract; 
    function Select(Table: string; Fields: array of string; Keys: array of string): string; overload;
    function Update(Table: string; Fields: array of string; Keys: array of string; ExtraFields: array of string): string; overload; virtual; abstract; 
    function Update(Table: string; Fields: array of string; Keys: array of string): string; overload;
    function Insert(Table: string; Fields: array of string; ExtraFields: array of string): string; overload; virtual; abstract;
    function Insert(Table: string; Fields: array of string): string; overload;
    function UpdateOrInsert(Updating, Returning:Boolean; Table: string; Fields: array of string; Keys: array of string): string; overload;
    function Delete(Table: string; Keys: array of string): string; overload;
  end;

implementation

{ TmncSQLConnection }

procedure TmncSQLConnection.Execute(Command: string);
begin
end;

{ TmncSQLProcessed }

function TmncSQLProcessed.GetItem(Index: Integer): TmncSQLName;
begin
  Result := inherited Items[Index] as TmncSQLName;
end;

procedure TmncSQLProcessed.Clear;
begin
  inherited Clear;
  SQL := '';
end;

procedure TmncSQLProcessed.Add(vID: Integer; vName: string);
var
  r: TmncSQLName;
begin
  r := TmncSQLName.Create;
  r.ID := vID;
  r.Name := vName;
  inherited Add(r);
end;

{ TmncSQLGenerator }

function TmncSQLGenerator.Select(Table: string; Fields: array of string;
  Keys: array of string): string;
begin

end;

function TmncSQLGenerator.Update(Table: string; Fields: array of string;
  Keys: array of string): string;
begin

end;

function TmncSQLGenerator.Insert(Table: string; Fields: array of string): string;
begin

end;

function TmncSQLGenerator.UpdateOrInsert(Updating, Returning: Boolean;
  Table: string; Fields: array of string; Keys: array of string): string;
begin

end;

function TmncSQLGenerator.Delete(Table: string; Keys: array of string): string;
begin

end;

function TmncSQLCommand.GetSQL: TStrings;
begin
  Result := FRequest;//just alias
end;

function TmncSQLCommand.GetParamChar: string;
begin
  Result := '?';
end;

procedure TmncSQLCommand.DoParse;
begin
  ParseSQL([]);
end;

procedure TmncSQLCommand.DoUnparse;
begin
  inherited;
  SQLProcessed.Clear;
  //maybe clear params, idk
end;

procedure TmncSQLCommand.ParseSQL(Options: TmncParseSQLOptions; ParamChar: string = '?');
var
  cCurChar, cNextChar, cQuoteChar: Char;
  sSQL, sParamName: string;
  i, LenSQL: Integer;
  iCurState, iCurParamState: Integer;
  iParam: Integer;
const
  DefaultState = 0;
  CommentState = 1;
  QuoteState = 2;
  ParamState = 3;
  ParamDefaultState = 0;
  ParamQuoteState = 1;

  procedure AddToSQL(s: string);
  begin
    SQLProcessed.SQL := SQLProcessed.SQL + s;
  end;
var
  aParam: TmncParam;
begin
  if (SQL.Text = '') then
    raise EmncException.Create('Empty SQL to parse!');
  //TODO stored procedures and trigger must not check param in budy procedure
  SQLProcessed.Clear;
  sParamName := '';
  try
    iParam := 1;
    cQuoteChar := '''';
    sSQL := Trim(SQL.Text) + ' ';//zaher that dummy
    i := 1;
    iCurState := DefaultState;
    iCurParamState := ParamDefaultState;
    { Now, traverse through the SQL string, character by character,
     picking out the parameters and formatting correctly for Firebird }
    LenSQL := Length(sSQL);
    while (i <= LenSQL) do
    begin
      { Get the current token and a look-ahead }
      cCurChar := sSQL[i];
      if i = LenSQL then
        cNextChar := #0
      else
        cNextChar := sSQL[i + 1];
      { Now act based on the current state }
      case iCurState of
        DefaultState:
          begin
            case cCurChar of
              '''', '"':
                begin
                  cQuoteChar := cCurChar;
                  iCurState := QuoteState;
                end;
              '?':
                begin
                  iCurState := ParamState;
                  AddToSQL(GetParamChar);//here we can replace it with new param char for example % for some sql engine
{                  if psoAddParamsID in Options then
                    AddToSQL();}
                end;
              '/': if (cNextChar = '*') then
                begin
                  AddToSQL(cCurChar);
                  Inc(i);
                  iCurState := CommentState;
                end;
            end;
          end;
        CommentState:
          begin
            if (cNextChar = #0) then
              raise EmncException.Create('EOF in comment detected: ' + IntToStr(i))
            else if (cCurChar = '*') then
            begin
              if (cNextChar = '/') then
                iCurState := DefaultState;
            end;
          end;
        QuoteState:
          begin
            if cNextChar = #0 then
              raise EmncException.Create('EOF in string detected: ' + IntToStr(i))
            else if (cCurChar = cQuoteChar) then
            begin
              if (cNextChar = cQuoteChar) then
              begin
                AddToSQL(cCurChar);
                Inc(i);
              end
              else
                iCurState := DefaultState;
            end;
          end;
        ParamState:
          begin
          { collect the name of the parameter }
            if iCurParamState = ParamDefaultState then
            begin
              if cCurChar = '"' then
                iCurParamState := ParamQuoteState
              else if (cCurChar in ['A'..'Z', 'a'..'z', '0'..'9', '_', ' ']) then //Quoted can include spaces
              begin
                sParamName := sParamName + cCurChar;
                if psoAddParamsNames in Options then
                  AddToSQL(cCurChar);
              end
              else if psoGenerateParams in Options then//if passed ? (ParamChar) without name of params
              begin
                sParamName := '_Param_' + IntToStr(iParam);
                Inc(iParam);
                iCurState := DefaultState;
                SQLProcessed.Add(iParam, sParamName);
                sParamName := '';
              end
              else
                raise EmncException.Create('Parameter name expected');
            end
            else
            begin
            { determine if Quoted parameter name is finished }
              if cCurChar = '"' then
              begin
                Inc(i);
                SQLProcessed.Add(iParam, sParamName);
                SParamName := '';
                iCurParamState := ParamDefaultState;
                iCurState := DefaultState;
              end
              else
                sParamName := sParamName + cCurChar
            end;
          { determine if the unquoted parameter name is finished }
            if (iCurParamState <> ParamQuoteState) and
              (iCurState <> DefaultState) then
            begin
              if not (cNextChar in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
              begin
                Inc(i);
                iCurState := DefaultState;
                if psoAddParamsID in Options then
                begin
                  AddToSQL(IntToStr(iParam));
                  Inc(iParam);
                end;
                //slNames.Add(UpperCase(sParamName));
                SQLProcessed.Add(iParam, sParamName);
                sParamName := '';
              end;
            end;
          end;
      end;
      if iCurState <> ParamState then
        AddToSQL(sSQL[i]);
      Inc(i);
    end;
    Params.Clear; 
    Binds.Clear;
    for i := 0 to SQLProcessed.Count - 1 do
    begin
      aParam := Params.Found(SQLProcessed[i].Name);//it will auto create it if not founded
      Binds.Add(aParam);
    end;
  finally
  end;
end;

constructor TmncSQLCommand.Create;
begin
  inherited Create;
  SQLProcessed := TmncSQLProcessed.Create(True);
end;

destructor TmncSQLCommand.Destroy;
begin
  inherited Destroy;
  FreeAndNil(SQLProcessed);
end;

end.

