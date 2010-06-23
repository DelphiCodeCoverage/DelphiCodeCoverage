(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit DebugProcess;

interface

uses classes, windows, debugthread;

type

  TDebugProcess = class
  private
    processId: DWORD;
    handle: THandle;
    module: HMODULE;
    mThreadList: TList;
  public
    constructor Create(id: DWORD; processhandle: THandle;
      processmodule: HMODULE);
    procedure AddThread(thread: TDebugThread);
    procedure RemoveThread(threadid: DWORD);
    function GetThreadById(threadid: DWORD): TDebugThread;
    function GetHandle(): THandle;
    function GetModule(): HMODULE;
    function readProcessMemory(address: Pointer; data: Pointer; size: Cardinal;
      changeProtect: boolean = false): Integer;
    function writeProcessMemory(address: Pointer; data: Pointer;
      size: Cardinal; changeProtect: boolean = false): Integer;
  end;

implementation

uses sysutils, jwawindows, logger, disasm32;

constructor TDebugProcess.Create(id: DWORD; processhandle: THandle;
  processmodule: HMODULE);
begin
  processId := id;
  handle := processhandle;
  module := processmodule;
  mThreadList := TList.Create();
end;

procedure TDebugProcess.AddThread(thread: TDebugThread);
begin
  mThreadList.add(thread);
end;

procedure TDebugProcess.RemoveThread(threadid: DWORD);
var
  thread: TDebugThread;
begin
  thread := GetThreadById(threadid);
  if (thread <> nil) then
  begin
    mThreadList.remove(thread);
    thread.free;
  end;
end;

function TDebugProcess.GetHandle(): THandle;
begin
  result := handle;
end;

function TDebugProcess.GetModule(): HMODULE;
begin
  result := module;
end;

function TDebugProcess.GetThreadById(threadid: DWORD): TDebugThread;
var
  i: Integer;
begin
  for i := 0 to mThreadList.Count - 1 do
  begin
    if TDebugThread(mThreadList[i]).GetId() = threadid then
    begin
      result := TDebugThread(mThreadList[i]);
      break;
    end;
  end;
end;

function TDebugProcess.readProcessMemory(address: Pointer; data: Pointer;
  size: Cardinal; changeProtect: boolean = false): Integer;
var
  oldprot: uint;
  numbytes: DWORD;
begin
  if (changeProtect and not(VirtualProtectEx(GetHandle(), address, size,
        PAGE_READONLY, @oldprot))) then
  begin
    result := -1;
    exit;
  end;

  if (not(jwawindows.readProcessMemory(GetHandle(), address, data, size,
        @numbytes))) then
  begin
    log.log('ReadProcessMemory() returned false reading address' + inttohex
        (Integer(address), 8) + ' error:' + inttostr(getLastError()));
    result := -1;
    exit;
  end;
  if (numbytes <> size) then
  begin
    log.log
      ('ReadProcessMemory() failed to read address - wrong number of bytes' + inttohex(Integer(address), 8) + ' error:' + inttostr(getLastError()));
    result := -1;
    exit;
  end;
  if (changeProtect and not(VirtualProtectEx(GetHandle(), address, size,
        oldprot, @oldprot))) then
  begin
    log.log('ReadProcessMemory() Failed to restore access read address - ' +
        inttohex(Integer(address), 8) + ' error:' + inttostr(getLastError()));
    result := 0;
    exit;
  end;

  result := numbytes;
end;

function TDebugProcess.writeProcessMemory(address: Pointer; data: Pointer;
  size: Cardinal; changeProtect: boolean = false): Integer;
var
  oldprot: uint;
  numbytes: DWORD;
begin
  if (changeProtect and not(VirtualProtectEx(GetHandle(), address, size,
        PAGE_EXECUTE_READWRITE, @oldprot))) then
  begin
    result := -1;
    exit;
  end;

  if (not(jwawindows.writeProcessMemory(GetHandle(), address, data, size,
        @numbytes))) then
  begin
    log.log('ReadProcessMemory() returned false reading address' + inttohex
        (Integer(address), 8) + ' error:' + inttostr(getLastError()));
    result := -1;
    exit;
  end;
  if (numbytes <> size) then
  begin
    log.log(
      'ReadProcessMemory() failed to write address - wrong number of bytes' +
        inttohex(Integer(address), 8) + ' error:' + inttostr(getLastError()));
    result := -1;
    exit;
  end;
  if (changeProtect and not(VirtualProtectEx(GetHandle(), address, size,
        oldprot, @oldprot))) then
  begin
    log.log('WriteProcessMemory() Failed to restore access read address - ' +
        inttohex(Integer(address), 8) + ' error:' + inttostr(getLastError()));
    result := 0;
    exit;
  end;
  if (not(FlushInstructionCache(GetHandle(), address, numbytes))) then
  begin
    log.log('writeProcessMemory(): FlushInstructionCache failed for' + inttohex
        (Integer(address), 8) + ' error:' + inttostr(getLastError()));
  end;
  result := numbytes;
end;

end.
