(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit BreakPoint;

interface

uses classes, debugthread, debugprocess;

type

  TBreakpoint = class
  private
    old_opcode: byte;
    active: boolean;
    address: Pointer;
    process: TDebugProcess;
    line: Integer;
    unitname: string;
  public
    function GetAddress(): Pointer;
    function Activate: boolean;
    function DeActivate: boolean;
    procedure clear(thread: TDebugThread);
    function GetUnitName(): string;
    function GetLineNumber(): Integer;
    constructor Create(proc: TDebugProcess; iaddress: Pointer; lineno: Integer; unitname: string);
  end;

  TBreakpointList = class
  private
    mList: TList;
  public
    constructor Create;
    procedure AddBreakpoint(bp: TBreakpoint);
    function GetBreakPointByAddress(address: Pointer): TBreakpoint;
    destructor Destroy; override;
  end;

implementation

uses sysutils, windows, logger;

constructor TBreakpointList.Create;
begin
  mList := TList.Create;
end;

destructor TBreakpointList.Destroy;
var
  I: Integer;
begin
  for I := 0 to mList.Count - 1 do
    TBreakpoint(mList[I]).free;
  mList.free();
end;

procedure TBreakpointList.AddBreakpoint(bp: TBreakpoint);
begin
  mList.add(bp);
end;

function TBreakpointList.GetBreakPointByAddress(address: Pointer): TBreakpoint;
var
  I: Integer;
begin
  result := nil;
  for I := 0 to mList.Count - 1 do
    if TBreakpoint(mList[I]).GetAddress = address then
    begin
      result := TBreakpoint(mList[I]);
      break;
    end;
end;

constructor TBreakpoint.Create(proc: TDebugProcess; iaddress: Pointer; lineno: Integer; unitname: string);
begin
  address := iaddress;
  process := proc;
  active := false;
  self.line := lineno;
  self.unitname := unitname;
end;

function TBreakpoint.Activate: boolean;
var
  opcode: byte;
  bytesread, byteswritten: DWORD;

begin
  log.log('TBreakpoint.Activate:');
  result := false;
  if active then
    result := true
  else
  begin
    bytesread := process.readProcessMemory(address, @old_opcode, 1);
    if bytesread = 1 then
    begin
      opcode := $CC;
      byteswritten := process.writeProcessMemory(address, @opcode, 1);
      if byteswritten = 1 then
      begin
        log.log('Activate ' + GetUnitName() + ' line ' + inttostr(GetLineNumber()) + ' setting bp at:' + inttohex
            (Integer(address), 8));
        active := true;
        result := true;
      end;
    end;
  end;

end;

function TBreakpoint.DeActivate: boolean;
var
  byteswritten: DWORD;
  flush, writeresult: BOOL;
begin
  if (active <> true) then
  begin
    result := true;
  end
  else
  begin
    byteswritten := process.writeProcessMemory(address, @old_opcode, 1);
    log.log('DE-Activate ' + GetUnitName() + ' line ' + inttostr(GetLineNumber()) + ' setting bp at:' + inttohex
        (Integer(address), 8));
    if (byteswritten = 1) then
      result := true
    else
      result := false;
    active := false;
    log.log('De-activate');
  end;
end;

procedure TBreakpoint.clear(thread: TDebugThread);
var
  ctx: CONTEXT;
  result: BOOL;
begin
  log.log('Clearing breakpoint at ' + inttohex(Integer(address), 8));
  ctx.contextflags := CONTEXT_CONTROL;
  result := GetThreadContext(thread.gethandle(), ctx);
  if (result <> false) then
  begin
    DeActivate;
    dec(ctx.Eip);
    ctx.contextflags := CONTEXT_CONTROL;
    result := SetThreadContext(thread.gethandle(), ctx);
    if (result <> true) then
      log.log('failed setting threadcontext:' + inttohex(getlasterror(), 8));
  end
  else
    log.log('Failed to get thread context   ' + inttohex(getlasterror(), 8));
end;

function TBreakpoint.GetAddress: Pointer;
begin
  result := address;
end;

function TBreakpoint.GetUnitName(): string;
begin
  result := unitname;
end;

function TBreakpoint.GetLineNumber(): Integer;
begin
  result := line;
end;

end.
