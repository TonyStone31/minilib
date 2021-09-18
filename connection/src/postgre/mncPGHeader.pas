unit mncPGHeader;
{ postgresql 13.x }
{$IFDEF FPC}
{$MODE delphi}
{$PACKRECORDS C}
{$ENDIF}

{$M+}{$H+}

{$MINENUMSIZE 4} //All enum must be sized as Integer
{$Z4}{$A8}

{**
 *  This file is part of the "Mini Connections"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher, zaherdirkey>
 * @author    Belal Hamed <belalhamed at gmail dot com>  
 *
 *}
 {
   Initially this file ported from Lazarus just to be compatiple in both Delphi and FPC
   But we updated it from postgresql 13.x

   src/interfaces/libpq/libpq-fe.h
 }

interface

uses
  mnLibraries,
  SysUtils;


const

  OIDNAMELEN = 36;

  INV_WRITE = $00020000;
  INV_READ = $00040000;

  BLOB_SEEK_SET = 0;
  BLOB_SEEK_CUR = 1;
  BLOB_SEEK_END = 2;

  OID_BOOL     = 16;
  OID_BYTEA    = 17;
  OID_TEXT     = 25;
  OID_OID      = 26;
  OID_NAME     = 19;
  OID_INT8     = 20;
  OID_INT2     = 21;
  OID_INT4     = 23;
  OID_FLOAT4   = 700;
  OID_MONEY    = 790;
  OID_FLOAT8   = 701;
  OID_UNKNOWN  = 705;
  OID_BPCHAR   = 1042;
  OID_VARCHAR  = 1043;
  OID_TIMESTAMP = 1114;
  OID_DATE      = 1082;
  OID_TIME      = 1083;
  OID_NUMERIC   = 1700;

  {
   * Option flags for PQcopyResult
  }
  PG_COPYRES_ATTRS		     = $01;
  PG_COPYRES_TUPLES		     = $02;	{ Implies PG_COPYRES_ATTRS }
  PG_COPYRES_EVENTS		     = $04;
  PG_COPYRES_NOTICEHOOKS	 = $08;


{ ****************** Plain API Types definition ***************** }

type

  OID = Integer;
  POID = ^OID;

{ Application-visible enum types }

  TConnStatusType = (
    CONNECTION_OK,
    CONNECTION_BAD,

  	{ Non-blocking mode only below here }

  	{
  	 * The existence of these should never be relied upon - they should only
  	 * be used for user feedback or similar purposes.
  	 }
  	CONNECTION_STARTED,			{ Waiting for connection to be made.  }
  	CONNECTION_MADE,			{ Connection OK; waiting to send.     }
  	CONNECTION_AWAITING_RESPONSE,	{ Waiting for a response from the
  									 * postmaster.        }
  	CONNECTION_AUTH_OK,			{ Received authentication; waiting for
  								 * backend startup. }
  	CONNECTION_SETENV,			{ Negotiating environment. }
  	CONNECTION_SSL_STARTUP,		{ Negotiating SSL. }
  	CONNECTION_NEEDED,			{ Internal state: connect() needed }
  	CONNECTION_CHECK_WRITABLE,	{ Check if we could make a writable
  								 * connection. }
  	CONNECTION_CONSUME,			{ Wait for any pending message and consume
  								 * them. }
  	CONNECTION_GSS_STARTUP,		{ Negotiating GSSAPI. }
  	CONNECTION_CHECK_TARGET		{ Check if we have a proper target connection }
    );

  TPostgresPollingStatusType = (
  	PGRES_POLLING_FAILED = 0,
  	PGRES_POLLING_READING,		{ These two indicate that one may	  }
  	PGRES_POLLING_WRITING,		{ use select before polling again.   }
  	PGRES_POLLING_OK,
  	PGRES_POLLING_ACTIVE		{ unused; keep for awhile for backwards
  								 * compatibility }
  );

  TExecStatusType = (
    PGRES_EMPTY_QUERY = 0,		{ empty query string was executed }
    PGRES_COMMAND_OK,			{ a query command that doesn't return
                                 * anything was executed properly by the
                                 * backend }
    PGRES_TUPLES_OK,			{ a query command that returns tuples was
                                 * executed properly by the backend, PGresult
                                 * contains the result tuples }
    PGRES_COPY_OUT,				{ Copy Out data transfer in progress }
    PGRES_COPY_IN,				{ Copy In data transfer in progress }
    PGRES_BAD_RESPONSE,			{ an unexpected response was recv'd from the
                                 * backend }
    PGRES_NONFATAL_ERROR,		{ notice or warning message }
    PGRES_FATAL_ERROR,			{ query failed }
    PGRES_COPY_BOTH,			{ Copy In/Out data transfer in progress }
    PGRES_SINGLE_TUPLE			{ single tuple from larger resultset }
  );

  TPGTransactionStatusType = (
      PQTRANS_IDLE,				{ connection idle }
      PQTRANS_ACTIVE,				{ command in progress }
      PQTRANS_INTRANS,			{ idle, within transaction block }
      PQTRANS_INERROR,			{ idle, within failed transaction }
      PQTRANS_UNKNOWN				{ cannot determine status }
  );

  TPGVerbosity = (
      PQERRORS_TERSE,				{ single-line error messages }
      PQERRORS_DEFAULT,			{ recommended style }
      PQERRORS_VERBOSE,			{ all the facts, ma'am }
      PQERRORS_SQLSTATE			{ only error severity and SQLSTATE code }
  );

  TPGContextVisibility = (
      PQSHOW_CONTEXT_NEVER,		{ never show CONTEXT field }
      PQSHOW_CONTEXT_ERRORS,		{ show CONTEXT for errors only (default) }
      PQSHOW_CONTEXT_ALWAYS		{ always show CONTEXT field }
  );

  {
   * PGPing - The ordering of this enum should not be altered because the
   * values are exposed externally via pg_isready.
  }

  TPGPing = (
      PQPING_OK,					{ server is accepting connections }
      PQPING_REJECT,				{ server is alive but rejecting connections }
      PQPING_NO_RESPONSE,			{ could not establish connection }
      PQPING_NO_ATTEMPT			{ connection not attempted (bad params) }
  );

{
  PGconn encapsulates a connection to the backend.
  The contents of this struct are not supposed to be known to applications.
}
  TPGconn = type Pointer;
  PPGconn = ^TPGconn;

{
   PGresult encapsulates the result of a query (or more precisely, of a single
   SQL command --- a query string given to PQsendQuery can contain multiple
   commands and thus return multiple PGresult objects).
   The contents of this struct are not supposed to be known to applications.
}
  TPGresult = type Pointer;
  PPGresult = ^TPGresult;

{
  PGcancel encapsulates the information needed to cancel a running
  query on an existing connection.
  The contents of this struct are not supposed to be known to applications.
}
  TPGcancel = type Pointer;
  PPGcancel= ^TPGcancel;

{
  PGnotify represents the occurrence of a NOTIFY message.
  Ideally this would be an opaque typedef, but it's so simple that it's
  unlikely to change.
  NOTE: in Postgres 6.4 and later, the be_pid is the notifying backend's,
  whereas in earlier versions it was always your own backend's PID.
}
  PPGnotify = ^TPGnotify;
  TPGnotify = packed record
    relname: PAnsiChar; { notification condition name }
    be_pid: Integer;  { process ID of notifying server process }
    extra: PAnsiChar; { notification parameter }
    { Fields below here are private to libpq; apps should not use 'em }
    next: PPGnotify;		{ list link }
  end;

  { Function types for notice-handling callbacks }

  TPQnoticeReceiver = procedure(arg: Pointer; var res: TPGresult); cdecl;
  TPQnoticeProcessor = procedure(arg: Pointer; message: PAnsiChar); cdecl;

{ Print options for PQprint() }

  TPQBool = type byte;

  //PPChar = array[00..$FF] of PAnsiChar;

  TPQprintOpt = packed record
    header: Byte; { print output field headings and row count }
    align: Byte; { fill align the fields }
    standard: Byte; { old brain dead format }
    html3: Byte; { output html tables }
    expanded: Byte; { expand tables }
    pager: Byte; { use pager for output if needed }
    fieldSep: PAnsiChar; { field separator }
    tableOpt: PAnsiChar; { insert to HTML <table ...> }
    caption: PAnsiChar; { HTML <caption> }
    fieldName: array[00..$FF] of PAnsiChar; { null terminated array of repalcement field names }
  end;

  PPQprintOpt = ^TPQprintOpt;

  { ----------------
   * Structure for the conninfo parameter definitions returned by PQconndefaults
   * or PQconninfoParse.
   *
   * All fields except "val" point at static strings which must not be altered.
   * "val" is either NULL or a malloc'd current-value string.  PQconninfoFree()
   * will release both the val strings and the PQconninfoOption array itself.
   * ----------------
  }

  TPQconninfoOption = packed record
    Keyword: PAnsiChar; { The keyword of the option }
    EnvVar: PAnsiChar; { Fallback environment variable name }
    Compiled: PAnsiChar; { Fallback compiled in default value  }
    Val: PAnsiChar; { Options value	}
    Lab: PAnsiChar; { Label for field in connect dialog }
    Dispchar: PAnsiChar; { Character to display for this field
                           in a connect dialog. Values are:
                           ""	Display entered value as is
                           "*"	Password field - hide value
                           "D"	Debug options - don't
                           create a field by default }
    Dispsize: Integer; { Field size in characters for dialog }
  end;

  PPQConninfoOption = ^TPQconninfoOption;

  {
   ----------------
   * PQArgBlock -- structure for PQfn() arguments
   * ----------------
  }

  TPQArgBlock = packed record
    len: Integer;
    isint: Integer;
    case u: Boolean of
      True: (ptr: PInteger); { can't use void (dec compiler barfs)	 }
      False: (_int: Integer);
  end;

  PPQArgBlock = ^TPQArgBlock;

  {
   ----------------
    PGresAttDesc -- Data about a single attribute (column) of a query result
   ----------------
  }

  TPGresAttDesc = record
      name: PAnsiChar;			{ column name }
      TableId: Oid;     		{ source table, if known }
      ColumnId: Integer;		{ source column, if known }
      Format: Integer;			{ format code for value (text/binary) }
      TypId: Oid;			      { type id }
      Typlen: Integer;			{ type size }
      Atttypmod: Integer;		{ type-specific modifier info }
  end;

  {
    ----------------
    Exported functions of libpq
    ----------------
  }

  { ===	in fe-connect.c === }

  { make a new client connection to the backend }
  { Asynchronous (non-blocking) }

  TPQconnectStart = function(ConnInfo: PAnsiChar): PPGconn; cdecl;
  TPQconnectStartParams = function(Keywords: Pointer; Values: Pointer; expand_dbname: Integer): PPGconn; cdecl;
  TPQconnectPoll = function(conn: PPGconn): TPostgresPollingStatusType; cdecl;

  TPQconnectdb = function(ConnInfo: PAnsiChar): PPGconn; cdecl;
  TPQconnectdbParams = function(Keywords: Pointer; Values: Pointer; expand_dbname: Integer): PPGconn; cdecl;
  TPQsetdbLogin = function(Host, Port, Options, Tty, Db, User, Passwd: PAnsiChar): PPGconn; cdecl;

  { close the current connection and free the PGconn data structure }
  TPQfinish = procedure(conn: PPGconn); cdecl;

  { get info about connection options known to PQconnectdb }
  TPQconndefaults = function: PPQconninfoOption; cdecl;

  { parse connection options in same way as PQconnectdb }
  TPQconninfoParse = function(conninfo: PAnsiChar; errmsg: PPAnsiChar): PPQconninfoOption; cdecl;

  { return the connection options used by a live connection }
  TPQconninfo = function(conn: PPGconn): PPQconninfoOption; cdecl;

  { free the data structure returned by PQconndefaults() or PQconninfoParse() }
  TPQconninfoFree = procedure(connOptions: PPQconninfoOption); cdecl;

  {
   * close the current connection and reestablish a new one with the same
   * parameters
  }
  { Asynchronous (non-blocking) }
  TPQresetStart = function(conn: PPGconn): Integer; cdecl;
  TPQresetPoll = function(conn: PPGconn): TPostgresPollingStatusType; cdecl;

  { Synchronous (blocking) }
  TPQreset = procedure(conn: PPGconn); cdecl;

  { request a cancel structure }
  TPQgetCancel = function(conn: PPGconn): PPGcancel; cdecl;

  { free a cancel structure }
  TPQfreeCancel = procedure(cancel: PPGcancel); cdecl;

  { issue a cancel request }
  PQcancel = function(cancel: PPGcancel; errbuf: PPAnsiChar; errbufsize: Integer): Integer; cdecl;

  { backwards compatible version of PQcancel; not thread-safe }
  TPQrequestCancel = function(conn: PPGconn): Integer; cdecl; //deprecated;

  { Accessor functions for PGconn objects }
  TPQdb = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQuser = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQpass = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQhost = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQhostaddr = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQport = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQtty = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQoptions = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQstatus = function(conn: PPGconn): TConnStatusType; cdecl;
  TPQtransactionStatus = function(conn: PPGconn): TPGTransactionStatusType; cdecl;
  TPQparameterStatus = function(conn: PPGconn; paramName: PAnsiChar): PAnsiChar; cdecl; //or maybe PPAnsiChar
  TPQprotocolVersion = function(conn: PPGconn): Integer; cdecl;
  TPQserverVersion = function(conn: PPGconn): Integer; cdecl;
  TPQerrorMessage = function(conn: PPGconn): PAnsiChar; cdecl;
  TPQsocket = function(conn: PPGconn): Integer; cdecl;
  TPQbackendPID = function(conn: PPGconn): Integer; cdecl;

  { SSL information functions }

  TPQsslInUse = function(conn: PPGconn): Integer; cdecl;
  TPQsslStruct = procedure(conn: PPGconn; struct_name: PAnsiChar); cdecl;
  TPQsslAttribute = function(conn: PPGconn; attribute_name: PAnsiChar): PAnsiChar; cdecl;
  TPQsslAttributeNames = function(conn: PPGconn): PPAnsiChar; cdecl;

  { Get the OpenSSL structure associated with a connection. Returns NULL for
   * unencrypted connections or if any other TLS library is in use. }
  TPQgetssl = procedure(conn: PPGconn); cdecl;

  { Tell libpq whether it needs to initialize OpenSSL }
  TPQinitSSL = procedure(do_init: Integer); cdecl;

  { More detailed way to tell libpq whether it needs to initialize OpenSSL }
  TPQinitOpenSSL = procedure(do_ssl: Integer; do_crypto: Integer); cdecl;

  { Return true if GSSAPI encryption is in use }
  PQgssEncInUse = function(conn: PPGconn): Integer; cdecl;

  { Returns GSSAPI context if GSSAPI is in use }
  TPQgetgssctx = procedure(conn: PPGconn); cdecl;

  { Set verbosity for PQerrorMessage and PQresultErrorMessage }
  TPQsetErrorVerbosity = function(conn: PPGconn; verbosity: TPGVerbosity): TPGVerbosity; cdecl; //TODO check return

  { Set CONTEXT visibility for PQerrorMessage and PQresultErrorMessage }
  TPQsetErrorContextVisibility = function(conn: PPGconn; show_context: TPGContextVisibility): TPGContextVisibility; cdecl;

  TPQtrace = procedure(conn: PPGconn; DebugPort: Pointer); cdecl;
  TPQuntrace = procedure(conn: PPGconn); cdecl;

  { Override default notice handling routines }
  TPQsetNoticeReceiver = function(conn: PPGconn; proc: TPQnoticeReceiver; Arg: Pointer): TPQnoticeReceiver; cdecl;
  TPQsetNoticeProcessor = function(conn: PPGconn; proc: TPQnoticeProcessor; Arg: Pointer): TPQnoticeProcessor; cdecl;

  {
   *	   Used to set callback that prevents concurrent access to
   *	   non-thread safe functions that libpq needs.
   *	   The default implementation uses a libpq internal mutex.
   *	   Only required for multithreaded apps that use kerberos
   *	   both within their app and for postgresql connections.
  }
  TPGthreadlock = procedure(acquire: Integer); cdecl; //callback

  TPQregisterThreadLock = function(newhandler: TPGthreadlock): TPGthreadlock; cdecl;

  { Simple synchronous query }
  TPQexec = function(conn: PPGconn; query: PAnsiChar): PPGresult; cdecl;
  TPQexecParams = function(conn: PPGconn; command: PAnsiChar; nParams: Integer; paramTypes: POID; paramValues: PPAnsiChar; paramLengths, paramFormats: Pointer; resultFormat: Integer): PPGresult; cdecl; //todo check arg

  TPQPrepare = function(conn: PPGconn; stmtName, query: PAnsiChar; nParams: Integer; paramTypes: POid): PPGresult; cdecl;
  TPQExecPrepared = function(conn: PPGconn; stmtName: PAnsiChar; nParams: Integer; paramValues: PPAnsiChar; paramLengths, paramFormats: PInteger; resultFormat: Integer): PPGresult; cdecl;

  TPQsendQuery = function(conn: PPGconn; query: PAnsiChar): Integer; cdecl;
  TPQsendQueryParams = function(conn: PPGconn; command: PAnsiChar; nParams: Integer; paramTypes: POID; paramValues: PPAnsiChar; paramLengths, paramFormats: PInteger; resultFormat: Integer): Integer; cdecl;

  TPQsendPrepare = function(conn: PPGconn; stmtName, query: PAnsiChar; nParams: Integer; paramTypes: POid): Integer; cdecl;
  TPQsendQueryPrepared = function(conn: PPGconn; stmtName: PAnsiChar; nParams: Integer; paramValues: PPAnsiChar; paramLengths, paramFormats: PInteger; resultFormat: Integer): Integer; cdecl;

  TPQsetSingleRowMode = function(conn: PPGconn): Integer; cdecl;
  TPQgetResult = function(conn: PPGconn): PPGresult; cdecl;

  { Routines for managing an asynchronous query }

  TPQisBusy = function(conn: PPGconn): Integer; cdecl;
  TPQconsumeInput = function(conn: PPGconn): Integer; cdecl;

  { LISTEN/NOTIFY support }

  TPQnotifies = function(conn: PPGconn): PPGnotify; cdecl;

  { Routines for copy in/out }
  TPQputCopyData = function(conn: PPGconn; buffer: PAnsiChar; nbytes: Integer): Integer; cdecl;
  TPQputCopyEnd = function(conn: PPGconn; errormsg: PPAnsiChar): Integer; cdecl;
  TPQgetCopyData = function(conn: PPGconn; buffer: PPAnsiChar; async: Integer): Integer; cdecl;


  TPQfreeNotify = procedure(Handle: PPGnotify); cdecl;
  //TPQgetline = function(conn: PPGconn; Str: PAnsiChar; length: Integer): Integer; cdecl;
  //TPQputline = function(conn: PPGconn; Str: PAnsiChar): Integer; cdecl;
  //TPQgetlineAsync = function(conn: PPGconn; Buffer: PAnsiChar; BufSize: Integer): Integer; cdecl;
  //TPQputnbytes = function(conn: PPGconn; Buffer: PAnsiChar; NBytes: Integer): Integer; cdecl;
  //TPQendcopy = function(conn: PPGconn): Integer; cdecl;

  //* Set blocking/nonblocking connection to the backend }
  TPQsetnonblocking = function(conn: PPGconn; arg: Integer): Integer; cdecl;
  TPQisnonblocking = function(conn: PPGconn): Integer; cdecl;
  TPQisthreadsafe = function(): Integer; cdecl;
  TPQping = function(ConnInfo: PAnsiChar): TPGPing; cdecl;
  TPQpingParams = function(Keywords: Pointer; Values: Pointer; expand_dbname: Integer): TPGPing; cdecl;

  { Force the write buffer to be written (or at least try) }
  TPQflush = function(conn: PPGconn): Integer;

  TPQfn = function(conn: PPGconn; fnid: Integer; result_buf, result_len: PInteger; result_is_int: Integer; args: PPQArgBlock; nargs: Integer): PPGresult; cdecl;
  TPQresultStatus = function(Result: PPGresult): TExecStatusType; cdecl;
  TPQresultErrorMessage = function(Result: PPGresult): PAnsiChar; cdecl;

  TPQnparams  = function(Result: PPGresult): Integer; cdecl;
  TPQparamtype = function(Result: PPGresult; param_num: Integer): Integer; cdecl;

  //p = params
  //r = result

//new  char *PQresultErrorField(const PGresult *res, int fieldcode);
  TPQresultErrorField = function(result: PPGResult; fieldcode: integer): PAnsiChar; cdecl;

  TPQntuples = function(Result: PPGresult): Integer; cdecl;
  TPQnfields = function(Result: PPGresult): Integer; cdecl;
  TPQbinaryTuples = function(Result: PPGresult): Integer; cdecl;
  TPQfname = function(Result: PPGresult; field_num: Integer): PAnsiChar; cdecl;
  TPQfnumber = function(Result: PPGresult; field_name: PAnsiChar): Integer; cdecl;
  TPQftype = function(Result: PPGresult; field_num: Integer): OID; cdecl;
  TPQfsize = function(Result: PPGresult; field_num: Integer): Integer; cdecl;
  TPQfmod = function(Result: PPGresult; field_num: Integer): Integer; cdecl;
  TPQcmdStatus = function(Result: PPGresult): PAnsiChar; cdecl;
  TPQoidValue = function(Result: PPGresult): OID; cdecl;
  TPQoidStatus = function(Result: PPGresult): PAnsiChar; cdecl;
  TPQcmdTuples = function(Result: PPGresult): PAnsiChar; cdecl;
  TPQgetvalue = function(Result: PPGresult; tup_num, field_num: Integer): PAnsiChar; cdecl;
  TPQgetlength = function(Result: PPGresult; tup_num, field_num: Integer): Integer; cdecl;
  TPQgetisnull = function(Result: PPGresult; tup_num, field_num: Integer): Integer; cdecl;
  TPQclear = procedure(Result: PPGresult); cdecl;
  TPQmakeEmptyPGresult = function(conn: PPGconn; status: TExecStatusType): PPGresult; cdecl;

//FirmOS: New defines

  TPQescapeByteaConn = function(conn: PPGconn; const from: PAnsiChar; from_length: longword; to_lenght: PLongword): PAnsiChar; cdecl;
  TPQescapeBytea = function(const from: PByte; from_length: longword; to_lenght: PLongword): PByte; cdecl;

//TODO  TPQescapeString    =function(const from:PAnsiChar;from_length:longword;to_lenght:PLongword):PAnsiChar;cdecl;

//unsigned char *PQescapeByteaConn(conn: PPGconn,
//                                 const unsigned char *from,
//                                 size_t from_length,
//                                 size_t *to_length);
  TPQunescapeBytea = function(const from: PByte; to_lenght: PLongword): PByte; cdecl;
//unsigned char *PQunescapeBytea(const unsigned char *from, size_t *to_length);

  TPQFreemem = procedure(ptr: Pointer); cdecl;

{ === in fe-lobj.c === }
  Tlo_open = function(conn: PPGconn; lobjId: OID; mode: Integer): Integer; cdecl;
  Tlo_close = function(conn: PPGconn; fd: Integer): Integer; cdecl;
  Tlo_read = function(conn: PPGconn; fd: Integer; buf: PAnsiChar; len: Integer): Integer; cdecl;
  Tlo_write = function(conn: PPGconn; fd: Integer; buf: PAnsiChar; len: Integer): Integer; cdecl;
  Tlo_lseek = function(conn: PPGconn; fd, offset, whence: Integer): Integer; cdecl;
  Tlo_creat = function(conn: PPGconn; mode: Integer): OID; cdecl;
  Tlo_tell = function(conn: PPGconn; fd: Integer): Integer; cdecl;
  Tlo_unlink = function(conn: PPGconn; lobjId: OID): Integer; cdecl;
  Tlo_import = function(conn: PPGconn; filename: PAnsiChar): OID; cdecl;
  Tlo_export = function(conn: PPGconn; lobjId: OID; filename: PAnsiChar): Integer; cdecl;
  Tlo_truncate = function(conn: PPGconn; fd, len: Integer): Integer; cdecl;

var

  PQconnectStart: TPQconnectStart;
  PQconnectStartParams: TPQconnectStartParams;
  PQconnectPoll: TPQconnectPoll;

  PQconnectdb: TPQconnectdb;
  PQsetdbLogin: TPQsetdbLogin;
  PQfinish: TPQfinish;
  PQconndefaults: TPQconndefaults;
  PQconninfoParse: TPQconninfoParse;
  PQconninfo: TPQconninfo;
  PQconninfoFree: TPQconninfoFree;

  PQresetStart: TPQresetStart;
  PQresetPoll: TPQresetPoll;

  PQreset: TPQreset;
  PQgetCancel: TPQgetCancel;
  PQfreeCancel: TPQfreeCancel;
  PQrequestCancel: TPQrequestCancel;

  PQdb: TPQdb;
  PQuser: TPQuser;
  PQpass: TPQpass;
  PQhost: TPQhost;
  PQhostaddr: TPQhostaddr;
  PQport: TPQport;
  PQtty: TPQtty;
  PQoptions: TPQoptions;
  PQstatus: TPQstatus;
  PQtransactionStatus: TPQtransactionStatus;
  PQparameterStatus: TPQparameterStatus;
  PQprotocolVersion: TPQprotocolVersion;
  PQserverVersion: TPQserverVersion;
  PQerrorMessage: TPQerrorMessage;
  PQsocket: TPQsocket;
  PQbackendPID: TPQbackendPID;

  PQsslInUse: TPQsslInUse;
  PQsslStruct: TPQsslStruct;
  PQsslAttribute: TPQsslAttribute;
  PQsslAttributeNames: TPQsslAttributeNames;

  PQgetssl: TPQgetssl;
  PQinitSSL: TPQinitSSL;
  PQinitOpenSSL: TPQinitOpenSSL;
  QgssEncInUse: PQgssEncInUse;
  PQgetgssctx: TPQgetgssctx;
  PQsetErrorVerbosity: TPQsetErrorVerbosity;
  PQsetErrorContextVisibility: TPQsetErrorContextVisibility;

  PQtrace: TPQtrace;
  PQuntrace: TPQuntrace;

  PQsetNoticeReceiver: TPQsetNoticeReceiver;
  PQsetNoticeProcessor: TPQsetNoticeProcessor;

  PQexec: TPQexec;
  PQexecParams: TPQexecParams;
  PQPrepare: TPQPrepare;
  PQExecPrepared: TPQExecPrepared;
  PQsendQuery: TPQsendQuery;
  PQsendQueryParams: TPQsendQueryParams;
  PQsendPrepare: TPQsendPrepare;
  PQsendQueryPrepared: TPQsendQueryPrepared;
  PQsetSingleRowMode: TPQsetSingleRowMode;

  PQgetResult: TPQgetResult;

  PQisBusy: TPQisBusy;
  PQconsumeInput: TPQconsumeInput;

  PQnotifies: TPQnotifies;

  PQputCopyData: TPQputCopyData;
  PQputCopyEnd: TPQputCopyEnd;
  PQgetCopyData: TPQgetCopyData;

  PQfreeNotify: TPQfreeNotify;

  //PQgetline: TPQgetline;
  //PQputline: TPQputline;
  //PQgetlineAsync: TPQgetlineAsync;
  //PQputnbytes: TPQputnbytes;
  //PQendcopy: TPQendcopy;

  PQsetnonblocking: TPQsetnonblocking;
  PQisnonblocking: TPQisnonblocking;
  PQisthreadsafe: TPQisthreadsafe;
  PQping: TPQping;
  PQpingParams: TPQpingParams;

  PQflush: TPQflush;

  PQfn: TPQfn;
  PQresultStatus: TPQresultStatus;
  PQresultErrorMessage: TPQresultErrorMessage;
  PQresultErrorField: TPQresultErrorField; //Firmos
  PQntuples: TPQntuples;
  PQnfields: TPQnfields;
  PQbinaryTuples: TPQbinaryTuples;
  PQfname: TPQfname;
  PQfnumber: TPQfnumber;
  PQftype: TPQftype;
  PQfsize: TPQfsize;
  PQfmod: TPQfmod;
  PQcmdStatus: TPQcmdStatus;
  PQoidValue: TPQoidValue;
  PQoidStatus: TPQoidStatus;
  PQcmdTuples: TPQcmdTuples;
  PQgetvalue: TPQgetvalue;
  PQgetlength: TPQgetlength;
  PQgetisnull: TPQgetisnull;
  PQclear: TPQclear;
  PQmakeEmptyPGresult: TPQmakeEmptyPGresult;
  //belal
  PQnparams: TPQnparams;
  PQparamtype: TPQparamtype;

//FirmOS: New defines
  PQescapeByteaConn: TPQescapeByteaConn;
  PQescapeBytea: TPQescapeBytea;
  PQunescapeBytea: TPQunescapeBytea;

  PQFreemem: TPQFreemem;

{ === in fe-lobj.c === }
  lo_open: Tlo_open;
  lo_close: Tlo_close;
  lo_read: Tlo_read;
  lo_write: Tlo_write;
  lo_lseek: Tlo_lseek;
  lo_creat: Tlo_creat;
  lo_tell: Tlo_tell;
  lo_unlink: Tlo_unlink;
  lo_import: Tlo_import;
  lo_export: Tlo_export;
  lo_truncate: Tlo_truncate;

type

  { TmncPGLib }

  TmncPGLib = class(TmnLibrary)
  protected
    procedure Link; override;
  end;

var
  PGLib: TmncPGLib = nil;

function PQsetdb(Host, Port, Options, Tty, Db: PAnsiChar): PPGconn;

implementation

function PQsetdb(Host, Port, Options, Tty, Db: PAnsiChar): PPGconn;
begin
  Result := PQsetdbLogin(Host, Port, Options, Tty, Db, nil, nil);
end;

procedure TmncPGLib.Link;
begin

  PQfreemem := GetAddress('PQfreemem');
  PQescapeByteaConn := GetAddress('PQescapeByteaConn');
  PQescapeBytea := GetAddress('PQescapeBytea');
  PQunescapeBytea := GetAddress('PQunescapeBytea');

  PQconnectStart := GetAddress('PQconnectStart');
  PQconnectStartParams := GetAddress('PQconnectStartParams');
  PQconnectPoll := GetAddress('PQconnectPoll');

  PQconnectdb := GetAddress('PQconnectdb');
  PQsetdbLogin := GetAddress('PQsetdbLogin');
  PQfinish := GetAddress('PQfinish');
  PQconndefaults := GetAddress('PQconndefaults');
  PQconninfoParse := GetAddress('PQconninfoParse');
  PQconninfo := GetAddress('PQconninfo');
  PQconninfoFree := GetAddress('PQconninfoFree');

  PQresetStart := GetAddress('PQresetStart');
  PQresetPoll := GetAddress('PQresetPoll');

  PQreset := GetAddress('PQreset');
  PQgetCancel := GetAddress('PQgetCancel');
  PQfreeCancel := GetAddress('PQfreeCancel');

  PQrequestCancel := GetAddress('PQrequestCancel');
  PQdb := GetAddress('PQdb');
  PQuser := GetAddress('PQuser');
  PQpass := GetAddress('PQpass');
  PQhost := GetAddress('PQhost');
  PQhostaddr := GetAddress('PQhostaddr');
  PQport := GetAddress('PQport');
  PQtty := GetAddress('PQtty');
  PQoptions := GetAddress('PQoptions');
  PQstatus := GetAddress('PQstatus');
  PQtransactionStatus := GetAddress('PQtransactionStatus');
  PQparameterStatus := GetAddress('PQparameterStatus');
  PQprotocolVersion := GetAddress('PQprotocolVersion');
  PQserverVersion := GetAddress('PQserverVersion');

  PQerrorMessage := GetAddress('PQerrorMessage');
  PQsocket := GetAddress('PQsocket');
  PQbackendPID := GetAddress('PQbackendPID');

  PQsslInUse := GetAddress('PQsslInUse');
  PQsslStruct := GetAddress('PQsslStruct');
  PQsslAttribute := GetAddress('PQsslAttribute');
  PQsslAttributeNames := GetAddress('PQsslAttributeNames');

  PQgetssl := GetAddress('PQgetssl');
  PQinitSSL := GetAddress('PQinitSSL');
  PQinitOpenSSL := GetAddress('PQinitOpenSSL');
  QgssEncInUse := GetAddress('QgssEncInUse');
  PQgetgssctx := GetAddress('PQgetgssctx');
  PQsetErrorVerbosity := GetAddress('PQsetErrorVerbosity');
  PQsetErrorContextVisibility := GetAddress('PQsetErrorContextVisibility');

  { Enable/disable tracing }
  PQtrace := GetAddress('PQtrace');
  PQuntrace := GetAddress('PQuntrace');

  { Override default notice handling routines }
  PQsetNoticeReceiver := GetAddress('PQsetNoticeReceiver');
  PQsetNoticeProcessor := GetAddress('PQsetNoticeProcessor');

{ === in fe-exec.c === }
  PQexec := GetAddress('PQexec');
  PQexecParams := GetAddress('PQexecParams');

  PQsendQuery := GetAddress('PQsendQuery');
  PQsendQueryParams := GetAddress('PQsendQueryParams');

  PQPrepare := GetAddress('PQprepare');
  PQExecPrepared := GetAddress('PQexecPrepared');

  PQsendPrepare := GetAddress('PQsendPrepare');
  PQsendQueryPrepared := GetAddress('PQsendQueryPrepared');

  PQsetSingleRowMode := GetAddress('PQsetSingleRowMode');
  PQgetResult := GetAddress('PQgetResult');

  PQisBusy := GetAddress('PQisBusy');
  PQconsumeInput := GetAddress('PQconsumeInput');

  PQnotifies := GetAddress('PQnotifies');

  PQputCopyData:= GetAddress('PQputCopyData');
  PQputCopyEnd := GetAddress('PQputCopyEnd');
  PQgetCopyData := GetAddress('PQgetCopyData');

  //  PQgetline := GetAddress('PQgetline');
  //  PQputline := GetAddress('PQputline');
  //  PQgetlineAsync := GetAddress('PQgetlineAsync');
  //  PQputnbytes := GetAddress('PQputnbytes');
  //  PQendcopy := GetAddress('PQendcopy');

  PQsetnonblocking := GetAddress('PQsetnonblocking');
  PQisnonblocking := GetAddress('PQisnonblocking');
  PQisthreadsafe := GetAddress('PQisthreadsafe');
  PQping := GetAddress('PQping');
  PQpingParams := GetAddress('PQpingParams');
  PQflush := GetAddress('PQflush');

  PQfreeNotify := GetAddress('PQfreeNotify');

  PQfn := GetAddress('PQfn');
  PQresultStatus := GetAddress('PQresultStatus');
  PQresultErrorMessage := GetAddress('PQresultErrorMessage');
  PQresultErrorField := GetAddress('PQresultErrorField');
  PQntuples := GetAddress('PQntuples');
  PQnfields := GetAddress('PQnfields');
  PQbinaryTuples := GetAddress('PQbinaryTuples');
  PQfname := GetAddress('PQfname');
  PQfnumber := GetAddress('PQfnumber');
  PQftype := GetAddress('PQftype');
  PQfsize := GetAddress('PQfsize');
  PQfmod := GetAddress('PQfmod');
  PQcmdStatus := GetAddress('PQcmdStatus');
  PQoidValue := GetAddress('PQoidValue');
  PQoidStatus := GetAddress('PQoidStatus');
  PQcmdTuples := GetAddress('PQcmdTuples');
  PQgetvalue := GetAddress('PQgetvalue');
  PQgetlength := GetAddress('PQgetlength');
  PQgetisnull := GetAddress('PQgetisnull');
  PQclear := GetAddress('PQclear');
  PQmakeEmptyPGresult := GetAddress('PQmakeEmptyPGresult');

  PQnparams := GetAddress('PQnparams');
  PQparamtype := GetAddress('PQparamtype');

{ === in fe-lobj.c === }
  lo_open := GetAddress('lo_open');
  lo_close := GetAddress('lo_close');
  lo_read := GetAddress('lo_read');
  lo_write := GetAddress('lo_write');
  lo_lseek := GetAddress('lo_lseek');
  lo_creat := GetAddress('lo_creat');
  lo_tell := GetAddress('lo_tell');
  lo_unlink := GetAddress('lo_unlink');
  lo_import := GetAddress('lo_import');
  lo_export := GetAddress('lo_export');
  lo_truncate := GetAddress('lo_truncate');
end;

initialization
  PGLib := TmncPGLib.Create('libpq');
finalization
  FreeAndNil(PGLib);
end.

