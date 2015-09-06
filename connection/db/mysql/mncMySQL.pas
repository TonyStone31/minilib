unit mncMySQL;
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
  Classes, SysUtils, Variants,
  mncCommons, mncSchemas, mncMySql56dyn,
  mnUtils, mncConnections, mncSQL;

type
  { TmncMySQLConnection }

  TmncMySQLConnection = class(TmncSQLConnection)
  private
    FDBHandle: PMYSQL;
    FExclusive: Boolean;
    FReadCommited: Boolean;
    procedure SetExclusive(const AValue: Boolean);
    procedure SetReadCommited(const AValue: Boolean);
  protected
    procedure InitPragma; virtual;
    procedure DoConnect; override;
    procedure DoDisconnect; override;
    function GetConnected:Boolean; override;
    procedure RaiseError(Error: Integer; const Msg: string; const ExtraMsg: string = '');
    procedure CheckError(Error: Integer; const ExtraMsg: string = ''); overload;
    procedure CheckError(vMySQL: PMYSQL); overload;
    procedure DoInit; override;
  public
    constructor Create;
    class function Model: TmncConnectionModel; override;
    function CreateSession: TmncSQLSession; overload; override; 
    procedure Interrupt;
    function GetVersion: string;
    procedure Execute(Command: string); override;
    property Exclusive: Boolean read FExclusive write SetExclusive;
    property ReadCommited: Boolean read FReadCommited write SetReadCommited;
    property DBHandle: PMYSQL read FDBHandle;
  end;

  { TmncMySQLSession }

  TmncMySQLSession = class(TmncSQLSession)
  private
    function GetConnection: TmncMySQLConnection;
    procedure SetConnection(const AValue: TmncMySQLConnection);
  protected
    procedure DoInit; override;
    procedure DoStart; override;
    procedure DoStop(How: TmncSessionAction; Retaining: Boolean); override;
    function GetActive: Boolean; override;
  public
    constructor Create(vConnection: TmncConnection); override;
    destructor Destroy; override;
    function CreateCommand: TmncSQLCommand; override;
    function CreateSchema: TmncSchema; override;
    procedure Execute(SQL: string);
    function GetLastInsertID: Int64;
    function GetRowsChanged: Integer;
    property Connection: TmncMySQLConnection read GetConnection write SetConnection;
  end;

  { TmncMySQLField }

  TmncMySQLField = class(TmncField)
  private
    FValue: Variant;
  protected
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  end;

  { TmncMySQLParam }

  TmncMySQLParam = class(TmncParam)
  private
    FValue: Variant;
  protected
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  { TmncMySQLFields }

  TmncMySQLFields = class(TmncFields)
  protected
    function CreateField(vColumn: TmncColumn): TmncField; override;
  end;

  { TmncMySQLParams }

  TmncMySQLParams = class(TmncParams)
  protected
    function CreateParam: TmncParam; override;
  end;

  TMySQLBinds = array of MYSQL_BIND;

  { TmncMySQLBind }

  TmncMySQLBind = class(TmncBind)
  private
    FBuffer: Pointer;
    FBufferSize: Integer;
    function GetBufferAllocated: Boolean;
  protected
    function AllocBuffer(var P; Size: Integer): Pointer; virtual;
    procedure FreeBuffer;
    property Buffer: Pointer read FBuffer;
    property BufferSize: Integer read FBufferSize;
    property BufferAllocated: Boolean read GetBufferAllocated;
  public
    destructor Destroy; override;
  end;

  { TmncMySQLBinds }

  TmncMySQLBinds = class(TmncBinds)
  private
    function GetItem(Index: Integer): TmncMySQLBind;
  protected
    function CreateBind: TmncBind; override;
  public
    property Items[Index: Integer]: TmncMySQLBind read GetItem; default;
  end;

  { TmncMySQLCommand }

  TmncMySQLCommand = class(TmncSQLCommand)
  private
    FStatment: PMYSQL_STMT;
    FBOF: Boolean;
    FEOF: Boolean;
    function GetBinds: TmncMySQLBinds;
    function GetConnection: TmncMySQLConnection;
    procedure FetchColumns;
    procedure FetchValues;
    procedure ApplyParams;
    function GetSession: TmncMySQLSession;
    procedure SetSession(const AValue: TmncMySQLSession);
  protected
    procedure CheckError(Error:longint);
    procedure DoPrepare; override;
    procedure DoExecute; override;
    procedure DoNext; override;
    function GetEOF:Boolean; override;
    function GetActive:Boolean; override;
    procedure DoClose; override;
    procedure DoCommit; override;
    procedure DoRollback; override;
    function CreateFields(vColumns: TmncColumns): TmncFields; override;
    function CreateParams: TmncParams; override;
    function CreateBinds: TmncBinds; override;
    property Binds: TmncMySQLBinds read GetBinds;
  public
    property Connection: TmncMySQLConnection read GetConnection;
    property Session: TmncMySQLSession read GetSession write SetSession;
    procedure Clear; override;
    function GetRowsChanged: Integer; virtual;
    function GetLastInsertID: Int64;
    property Statment: PMYSQL_STMT read FStatment;
  end;

implementation

uses
  mncDB, mncMySQLSchemas;

const
  MySQL_OK = 0;

var
  IsInitializeMySQL: Boolean = False;

{ TmncMySQLBind }

function TmncMySQLBind.GetBufferAllocated: Boolean;
begin
  Result := Buffer <> nil;
end;

function TmncMySQLBind.AllocBuffer(var P; Size: Integer): Pointer;
begin
  FreeBuffer;
  FBufferSize := Size;
  if Size > 0 then
  begin
    FBuffer := AllocMem(FBufferSize);
    Move(P, FBuffer^, Size);
  end;
  Result := FBuffer;
end;

procedure TmncMySQLBind.FreeBuffer;
begin
  if FBuffer <> nil then
    FreeMem(FBuffer);
  FBuffer := nil;
end;

destructor TmncMySQLBind.Destroy;
begin
  FreeBuffer;
  inherited;
end;

function SQLTypeToType(vType: enum_field_types; const SchemaType: string): TmncDataType;
begin
  case vType of
    MYSQL_TYPE_LONG:
      Result := dtInteger;
    MYSQL_TYPE_FLOAT:
      Result := dtFloat;
    MYSQL_TYPE_BLOB: Result := dtBlob;
    MYSQL_TYPE_NULL: Result := dtUnknown;
    MYSQL_TYPE_STRING:
    begin
      if SameText(SchemaType, 'Blob') then
        Result := dtBlob
      else
        Result := dtString;
    end
    else
      Result := dtUnknown;
  end;
end;

{ TmncMySQLBinds }

function TmncMySQLBinds.GetItem(Index: Integer): TmncMySQLBind;
begin
  Result := inherited Items[Index] as TmncMySQLBind;
end;

function TmncMySQLBinds.CreateBind: TmncBind;
begin
  Result := TmncMySQLBind.Create;
end;

function TmncMySQLParam.GetValue: Variant;
begin
  Result := FValue;
end;

procedure TmncMySQLParam.SetValue(const AValue: Variant);
begin
  FValue := AValue;
end;

constructor TmncMySQLParam.Create;
begin
  inherited;
end;

destructor TmncMySQLParam.Destroy;
begin
  inherited;
end;

function TmncMySQLField.GetValue: Variant;
begin
  Result := FValue;
end;

procedure TmncMySQLField.SetValue(const AValue: Variant);
begin
  FValue := AValue;
end;

{ TmncMySQLFields }

function TmncMySQLFields.CreateField(vColumn: TmncColumn): TmncField;
begin
  Result := TmncMySQLField.Create(vColumn);
end;

{ TmncMySQLParams }

function TmncMySQLParams.CreateParam: TmncParam;
begin
  Result := TmncMySQLParam.Create;
end;

procedure TmncMySQLConnection.CheckError(Error: Integer; const ExtraMsg: string);
var
  s : Utf8String;
begin
  if (Error <> MySQL_OK) then
  begin
    s := 'MySQL: ' + IntToStr(Error) + ', ' + mysql_error(FDBHandle);
    if ExtraMsg <> '' then
      s := s + ' - ' + ExtraMsg;
    raise EmncException.Create(s) {$ifdef fpc} at get_caller_frame(get_frame) {$endif};
  end;
end;

procedure TmncMySQLConnection.CheckError(vMySQL: PMYSQL);
begin
  if vMySQL = nil then
    RaiseError(mysql_errno(FDBHandle), mysql_error(FDBHandle));
end;

{ TmncMySQLConnection }

constructor TmncMySQLConnection.Create;
begin
  inherited Create;
end;

class function TmncMySQLConnection.Model: TmncConnectionModel;
begin
  Result.Name := 'MySQL';
  Result.Title := 'MySQL Database';
  Result.Capabilities := [ccDB, ccSQL, ccTransaction];
  //Result.SchemaClass := TmncMySQLSchema;//TOdo
end;

function TmncMySQLConnection.CreateSession: TmncSQLSession;
begin
  Result := TmncMySQLSession.Create(Self);
end;

procedure TmncMySQLConnection.Interrupt;
begin
  mysql_kill(DBHandle, 0); //TODO
  //https://dev.mysql.com/doc/refman/5.0/en/mysql-kill.html
end;

function TmncMySQLConnection.GetVersion: string;
var
  p: integer;
begin
  p := mysql_get_server_version(FDBHandle);
  Result := IntToStr(p);
end;

procedure TmncMySQLConnection.DoConnect;
var
  f: Integer;
  r: PMYSQL;
  aHost: string;
begin
  //TODO AutoCreate
  //* ref: https://dev.mysql.com/doc/refman/5.0/en/mysql-real-connect.html
  FDBHandle := mysql_init(FDBHandle);
  try
    //mysql_options(&mysql,MYSQL_READ_DEFAULT_GROUP,"your_prog_name");
    CheckError(mysql_real_connect(FDBHandle, PAnsiChar(Host), PChar(UserName), PChar(Password), nil, 0, nil, CLIENT_MULTI_RESULTS));
    CheckError(mysql_select_db(FDBHandle, PAnsiChar(Resource)));
  except
    on E:Exception do
    begin
      if FDBHandle <> nil then
        mysql_close(FDBHandle);
      FDBHandle := nil;
      raise;
    end;
  end;
  InitPragma;
end;

function TmncMySQLConnection.GetConnected: Boolean;
begin
  Result := FDBHandle <> nil;
end;

procedure TmncMySQLConnection.RaiseError(Error: Integer; const Msg: string; const ExtraMsg: string = '');
var
  s : string;
begin
  if (Error <> MySQL_OK) then
  begin
    s := 'MySQL: ' + IntToStr(Error) + ', ' + mysql_error(FDBHandle);
    if ExtraMsg <> '' then
      s := s + ' - ' + ExtraMsg;
    raise EmncException.Create(s) {$ifdef fpc} at get_caller_frame(get_frame) {$endif};
  end;
end;

procedure TmncMySQLConnection.DoDisconnect;
begin
  mysql_close(FDBHandle); //TODO check error
  FDBHandle := nil;
  {$ifdef FPC}
  ReleaseMySQL;
  {$endif}
end;

{ TmncMySQLSession }

destructor TmncMySQLSession.Destroy;
begin
  inherited;
end;

function TmncMySQLSession.CreateCommand: TmncSQLCommand;
begin
  Result := TmncMySQLCommand.Create;
  Result.Session := Self;
end;

function TmncMySQLSession.CreateSchema: TmncSchema;
begin
  //Result := TmncMySQLSchema.CreateBy(Self);
  Result := nil;
end;

procedure TmncMySQLSession.Execute(SQL: string);
begin
  Connection.Execute(SQL);
end;

procedure TmncMySQLSession.DoStart;
begin
  Execute('BEGIN');
end;

procedure TmncMySQLSession.DoStop(How: TmncSessionAction; Retaining: Boolean);
begin
  case How of
    sdaCommit: Execute('COMMIT');
    sdaRollback: Execute('ROLLBACK');
  end;
  if Retaining then
    Execute('BEGIN');
end;

procedure TmncMySQLConnection.Execute(Command: string);
var
 lMsg  : PChar;
 s : Utf8String;
 r  : integer;
begin
  if mysql_query(FDBHandle, PAnsiChar(Command)) <> 0 then
    RaiseError(-1, 'Query failed');
{  lMSg := nil;
  s := Command;
  r := mysql_exec(FDBHandle, PChar(s), nil, nil, @lMsg);
  if lMSg <> nil then
  begin
    s := lMsg;
    mysql_free(lMSg);
  end;
  CheckError(r, s);}
end;

function TmncMySQLSession.GetLastInsertID: Int64;
begin
  CheckActive;
  //Result := mysql_last_insert_rowid(Connection.DBHandle);
end;

function TmncMySQLSession.GetRowsChanged: Integer;
begin
  CheckActive;
  //Result := mysql_changes(Connection.DBHandle);
end;

function TmncMySQLSession.GetActive: Boolean;
begin
  Result:= inherited GetActive;
end;

constructor TmncMySQLSession.Create(vConnection: TmncConnection);
begin
  inherited;
end;

function TmncMySQLSession.GetConnection: TmncMySQLConnection;
begin
  Result := inherited Connection as TmncMySQLConnection;
end;

procedure TmncMySQLConnection.DoInit;
begin
  if not IsInitializeMySQL then
  begin
    InitialiseMysql(mysqllib);
    IsInitializeMySQL := True;
  end;
end;

procedure TmncMySQLSession.SetConnection(const AValue: TmncMySQLConnection);
begin
  inherited Connection := AValue;
end;

procedure TmncMySQLConnection.SetExclusive(const AValue: Boolean);
begin
  if FExclusive <> AValue then
  begin
    if Active then
      raise EmncException.Create('You can not set Exclusive when session active');
    FExclusive := AValue;
  end;
end;

procedure TmncMySQLConnection.SetReadCommited(const AValue: Boolean);
begin
  if FReadCommited <> AValue then
  begin
    if Active then
      raise EmncException.Create('You can not set ReadCommited when session active');
    FReadCommited := AValue;
  end;
end;

procedure TmncMySQLConnection.InitPragma;
begin
end;

procedure TmncMySQLSession.DoInit;
begin
end;

{ TmncMySQLCommand }

procedure TmncMySQLCommand.CheckError(Error: longint);
var
  s : Utf8String;
  ExtraMsg: string;
  r: Integer;
begin
  if (Error <> MySQL_OK) then
  begin
    s := 'MySQL: ' + IntToStr(Error) + ', ' + mysql_stmt_error(FStatment) ;
    if Active then
    begin
{      r := mysql_finalize(FStatment);//without check error prevent the loop
      if (r <> MySQL_OK) then
        ExtraMsg := mysql_errmsg(Connection.DBHandle)
      else
        ExtraMsg := '';
      if ExtraMsg <> '' then
        s := s + ' - ' + ExtraMsg;
      FStatment := nil;}
    end;
    raise EmncException.Create(s) {$ifdef fpc} at get_caller_frame(get_frame) {$endif};
  end;
end;

function TmncMySQLCommand.GetSession: TmncMySQLSession;
begin
  Result := inherited Session as TmncMySQLSession;
end;

procedure TmncMySQLCommand.SetSession(const AValue: TmncMySQLSession);
begin
  inherited Session := AValue;
end;

procedure TmncMySQLCommand.Clear;
begin
  inherited;
  FBOF := True;
end;

function TmncMySQLCommand.GetEOF: Boolean;
begin
  Result := (FStatment = nil) or FEOF; 
end;

function TmncMySQLCommand.GetRowsChanged: Integer;
begin
  Result := Session.GetRowsChanged;
end;

function TmncMySQLCommand.GetLastInsertID: Int64;
begin
  Result := Session.GetLastInsertID;
end;

procedure DateTimeToMySQLDateTime(DateTime: TDateTime; out ATime: MYSQL_TIME);
var
  st: TSystemTime;
begin
  DateTimeToSystemTime(DateTime, st);
  ATime.Year := st.Year;
  ATime.Month := st.Month;
  ATime.Day := st.Day;
  ATime.Hour := st.Hour;
  ATime.Minute := st.Minute;
  ATime.Second := st.Second;
  ATime.second_part := st.Millisecond;
  ATime.neg := 0;
  ATime.time_type := MYSQL_TIMESTAMP_DATETIME;
end ;

procedure DateTimeToMySQLTime(DateTime: TDateTime; out ATime: MYSQL_TIME);
var
  st: TSystemTime;
begin
  DateTimeToMySQLDateTime(DateTime, ATime);
  ATime.time_type := MYSQL_TIMESTAMP_TIME;
end ;

procedure DateTimeToMySQLDate(DateTime: TDateTime; out ATime: MYSQL_TIME);
var
  st: TSystemTime;
begin
  DateTimeToMySQLDateTime(DateTime, ATime);
  ATime.time_type := MYSQL_TIMESTAMP_DATE;
end ;

procedure TmncMySQLCommand.ApplyParams;
var
  s: UTF8String;
  b: my_bool;
  dt: MYSQL_TIME;
  tiny: smallint;

  i: Integer;
  d: Double;
  c: Currency;
  n: Integer;
  t64: Int64;
  Values: TMySQLBinds;
begin
  //* ref: https://dev.mysql.com/doc/refman/5.0/en/mysql-stmt-bind-param.html
  //* ref: https://dev.mysql.com/doc/refman/5.0/en/mysql-stmt-execute.html
  //* https://dev.mysql.com/doc/refman/5.0/en/c-api-prepared-statement-type-codes.html

  SetLength(Values, Binds.Count);

  for i := 0 to Binds.Count - 1 do
  begin
    if Binds[i].Param.IsEmpty then
    begin
      n := 1;
      Values[i].is_null := Binds[i].AllocBuffer(n, SizeOf(n));
    end
    else
    begin
      case VarType(Binds[i].Param.Value) of
        varDate:
        begin
          DateTimeToMySQLDateTime(Binds[i].Param.Value, dt);
          Values[i].buffer := Binds[i].AllocBuffer(dt, SizeOf(dt));
          Values[i].buffer_length := SizeOf(dt);
          Values[i].buffer_type := MYSQL_TYPE_DATETIME;
        end;
        varBoolean:
        begin
          tiny := Ord(Boolean(Binds[i].Param.Value));
          Values[i].buffer := Binds[i].AllocBuffer(tiny, SizeOf(tiny));
          Values[i].buffer_length := SizeOf(tiny);
          Values[i].buffer_type := MYSQL_TYPE_TINY;
        end;
        varInteger:
        begin
          n := Ord(Integer(Binds[i].Param.Value));
          Values[i].buffer := Binds[i].AllocBuffer(n, SizeOf(n));
          Values[i].buffer_length := 0;
          Values[i].buffer_type := MYSQL_TYPE_LONG;
        end;
        varint64:
        begin
          t64 := Binds[i].Param.Value;
          Values[i].buffer := Binds[i].AllocBuffer(t64, SizeOf(t64));
          Values[i].buffer_length := 0;
          Values[i].buffer_type := MYSQL_TYPE_LONGLONG;
        end;
        varCurrency:
        begin
          t64 := Binds[i].Param.Value;
          Values[i].buffer := Binds[i].AllocBuffer(t64, SizeOf(t64));
          Values[i].buffer_length := 0;
          Values[i].buffer_type := MYSQL_TYPE_NEWDECIMAL;
        end;
        varDouble:
        begin
          d := Binds[i].Param.Value;
          Values[i].buffer := Binds[i].AllocBuffer(d, SizeOf(d));
          Values[i].buffer_length := 0;
          Values[i].buffer_type := MYSQL_TYPE_DOUBLE;
        end;
        else //String type
        begin
          s := VarToStrDef(Binds[i].Param.Value, '');
          Values[i].buffer := Binds[i].AllocBuffer(PChar(s)^, Length(s));
          Values[i].buffer_length := 0;
          Values[i].buffer_type := MYSQL_TYPE_VAR_STRING;
        end;
      end;
    end;
  end;
end;

procedure TmncMySQLCommand.DoExecute;
begin
  FBOF := True;
  CheckError(mysql_stmt_reset(FStatment));
  ApplyParams;
  CheckError(mysql_stmt_execute(FStatment));
end;

procedure TmncMySQLCommand.DoNext;
var
  r: Integer;
  b: Boolean;
begin
//  CheckError(mysql_step(@FStatment));
  b := mysql_stmt_fetch(FStatment) in [0, MYSQL_DATA_TRUNCATED];
  //r := mysql_fetch_row(FStatment);
  if (b) then
  begin
    if FBOF then
      FetchColumns;
    FetchValues;
    FEOF := False;
  end
  else //if (r = MySQL_DONE) then
  begin
    FEOF := True;
    //CheckError(mysql_reset(FStatment));
  end;
//  else if error
//    CheckError(r);
  FBOF := False;
end;

procedure TmncMySQLCommand.DoPrepare;
var
  r: Integer;
begin
  //* ref: https://dev.mysql.com/doc/refman/5.0/en/mysql-stmt-prepare.html
  FBOF := True;
//  mysql_prepare_v2
//TODO: apply value of params if using injection mode
  FStatment := mysql_stmt_init(Connection.DBHandle);
  try
    CheckError(mysql_stmt_prepare(FStatment, PChar(SQLProcessed.SQL), Length(SQLProcessed.SQL)));
  except
    on E: Exception do
    begin
      //FStatment := nil;
      raise;
    end;
  end;
end;

procedure TmncMySQLCommand.DoRollback;
begin
  Session.Rollback;
end;

function TmncMySQLCommand.CreateFields(vColumns: TmncColumns): TmncFields;
begin
  Result := TmncMySQLFields.Create(vColumns);
end;

function TmncMySQLCommand.CreateParams: TmncParams;
begin
  Result := TmncMySQLParams.Create;
end;

function TmncMySQLCommand.CreateBinds: TmncBinds;
begin
  Result := TmncMySQLBinds.Create;
end;

procedure TmncMySQLCommand.DoClose;
begin
  mysql_stmt_free_result(FStatment);
  mysql_stmt_close(FStatment);
  FStatment := nil;
end;

procedure TmncMySQLCommand.DoCommit;
begin
  Session.Commit;
end;

procedure TmncMySQLCommand.FetchColumns;
var
  i: Integer;
  c: Integer;
  aName: string;
  aType: Integer;
  pType: PChar;
  aColumn: TmncColumn;
  //aSize: Integer;
begin
  Columns.Clear;
  c := mysql_stmt_field_count(FStatment);
  {for i := 0 to c -1 do
  begin
    aName :=  DequoteStr(mysql_column_name(FStatment, i));
    aType := mysql_column_type(FStatment, i);
    pType := mysql_column_decltype(FStatment, i);
    aColumn := Columns.Add(aName, SQLTypeToType(aType, pType));
    aColumn.SchemaType := pType;
  end;}
end;

procedure TmncMySQLCommand.FetchValues;
var
  i: Integer;
  c: Integer;
  int:Int64;
{$ifdef fpc}
  str: string;
{$else}
  str: utf8string;
{$endif}
  flt: Double;
  aCurrent: TmncFields;
  aType: Integer;
  aColumn: TmncColumn;
  //aSize: Integer;
begin
  //belal why not use Columns ????
  //c := Columns.Count;
(*  c := mysql_column_count(FStatment);
  if c > 0 then
  begin
    aCurrent := CreateFields(Columns);
    for i := 0 to c - 1 do
    begin
//    TStorageType = (stNone, stInteger, stFloat, stText, stBlob, stNull);
      //aSize := mysql_column_bytes(FStatment, i);
      aColumn := Columns[i];
      aType := mysql_column_type(FStatment, i);
      //aType := Columns[i].DataType;
      case aType of
        MySQL_NULL:
        begin
          aCurrent.Add(i, Null);
        end;
        MySQL_INTEGER:
        begin
          int := mysql_column_int(FStatment, i);
{          if aColumn.DataType = ftDate then //todo
            int := int - 1;}
          aCurrent.Add(i, int);
        end;
        MySQL_FLOAT:
        begin
          flt := mysql_column_double(FStatment, i);
          aCurrent.Add(i, flt);
        end;
        MySQL_BLOB:
        begin
          int := mysql_column_bytes(FStatment, i);
          SetString(str, PChar(mysql_column_blob(FStatment, i)), int);
          aCurrent.Add(i, str);
        end;
        MySQL_TEXT:
        begin
          if SameText(aColumn.SchemaType, 'Blob') then
          begin
            int := mysql_column_bytes(FStatment, i);
            SetString(str, PChar(mysql_column_blob(FStatment, i)), int);
          end
          else
            str := mysql_column_text(FStatment, i);
          aCurrent.Add(i, str);
        end
        else
        begin
          str := mysql_column_text(FStatment, i);
          aCurrent.Add(i, str);
        end;
      end;
    end;
    Fields := aCurrent;
  end;*)
end;

function TmncMySQLCommand.GetActive: Boolean;
begin
  Result := FStatment <> nil; 
end;

function TmncMySQLCommand.GetConnection: TmncMySQLConnection;
begin
  Result := Session.Connection as TmncMySQLConnection;
end;

function TmncMySQLCommand.GetBinds: TmncMySQLBinds;
begin
  Result := inherited Binds as TmncMySQLBinds;
end;

initialization
  mncDB.Engines.Add(TmncMySQLConnection);
end.
