(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit DebugProcess;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  Windows,
  I_DebugThread,
  I_DebugProcess,
  I_LogManager;

type
  TDebugProcess = class(TInterfacedObject, IDebugProcess)
  private
    //FProcessId      : DWORD;
    FProcessHandle  : THandle;
    FProcessModule  : HMODULE;
    FDebugThreadLst : IInterfaceList;
    FLogManager     : ILogManager;

  public
    constructor Create(const AProcessId: DWORD; const AProcessHandle: THandle;
        AProcessModule: HMODULE; const ALogManager : ILogManager);
    destructor Destroy; override;

    procedure AddThread(const ADebugThread: IDebugThread);
    procedure RemoveThread(const AThreadId: DWORD);

    function GetHandle(): THandle;{$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
    function GetModule(): HMODULE;{$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}

    function GetThreadById(const AThreadId: DWORD): IDebugThread;
    function ReadProcessMemory(const AAddress, AData: Pointer; const ASize:
        Cardinal; const AChangeProtect: Boolean = False): Integer;
    function WriteProcessMemory(const AAddress, AData: Pointer; const ASize:
        Cardinal; const AChangeProtect: Boolean = False): Integer;
  end;

implementation

uses
  SysUtils,
  JwaWinBase;

constructor TDebugProcess.Create(const AProcessId: DWORD; const AProcessHandle:
    THandle; AProcessModule: HMODULE; const ALogManager : ILogManager);
begin
  inherited Create;

  //FProcessId      := AProcessId;
  FProcessHandle  := AProcessHandle;
  FProcessModule  := AProcessModule;
  FDebugThreadLst := TInterfaceList.Create();
  FLogManager     := ALogManager
end;

destructor TDebugProcess.Destroy;
begin
  FDebugThreadLst := nil;
  FLogManager     := nil;

  inherited;
end;

procedure TDebugProcess.AddThread(const ADebugThread: IDebugThread);
begin
  FDebugThreadLst.Add(ADebugThread);
end;

procedure TDebugProcess.RemoveThread(const AThreadId: DWORD);
var
  DebugThread: IDebugThread;
begin
  DebugThread := GetThreadById(AThreadId);
  if (DebugThread <> nil) then
  begin
    FDebugThreadLst.Remove(DebugThread);
  end;
end;

function TDebugProcess.GetHandle(): THandle;
begin
  Result := FProcessHandle;
end;

function TDebugProcess.GetModule(): HMODULE;
begin
  Result := FProcessModule;
end;

function TDebugProcess.GetThreadById(const AThreadId: DWORD): IDebugThread;
var
  lp: Integer;
begin
  Result := nil;
  for lp := 0 to FDebugThreadLst.Count - 1 do
  begin
    if IDebugThread(FDebugThreadLst[lp]).GetId() = AThreadId then
    begin
      Result := IDebugThread(FDebugThreadLst[lp]);
      break;
    end;
  end;
end;

function TDebugProcess.ReadProcessMemory(const AAddress, AData: Pointer; const
    ASize: Cardinal; const AChangeProtect: Boolean = False): Integer;
var
  oldprot: uint;
  numbytes: DWORD;
begin
  if (AChangeProtect and
     (not VirtualProtectEx(GetHandle(), AAddress, ASize, PAGE_READONLY, @oldprot))) then
  begin
    Result := -1;
    exit;
  end;

  if (not JwaWinBase.ReadProcessMemory(GetHandle(), AAddress, AData, ASize,
        @numbytes)) then
  begin
    FLogManager.Log('ReadProcessMemory() failed reading address - ' +
                    IntToHex(Integer(AAddress), 8) +
                    ' Error:' +
                    I_LogManager.GetLastErrorInfo());
    Result := -1;
    exit;
  end;
  if (numbytes <> ASize) then
  begin
    FLogManager.Log('ReadProcessMemory() failed to read address - ' +
                    IntToHex(Integer(AAddress), 8) +
                    ' Wrong number of bytes - ' +
                    IntToStr(numbytes) +
                    ' Error:' +
                    I_LogManager.GetLastErrorInfo());
    Result := -1;
    exit;
  end;
  if (AChangeProtect and
     (not VirtualProtectEx(GetHandle(), AAddress, ASize, oldprot, @oldprot))) then
  begin
    FLogManager.Log('ReadProcessMemory() Failed to restore access read address - ' +
                    IntToHex(Integer(AAddress), 8) +
                    ' Error:' +
                    I_LogManager.GetLastErrorInfo());
    Result := 0;
    exit;
  end;

  Result := numbytes;
end;

function TDebugProcess.WriteProcessMemory(const AAddress, AData: Pointer; const
    ASize: Cardinal; const AChangeProtect: Boolean = False): Integer;
var
  oldprot: uint;
  numbytes: DWORD;
begin
  if (AChangeProtect and not(VirtualProtectEx(GetHandle(), AAddress, ASize,
        PAGE_EXECUTE_READWRITE, @oldprot))) then
  begin
    Result := -1;
    exit;
  end;

  if (not JwaWinBase.WriteProcessMemory(GetHandle(), AAddress, AData, ASize,
        @numbytes)) then
  begin
    FLogManager.Log('WriteProcessMemory() failed writing address - ' +
                    IntToHex(Integer(AAddress), 8) +
                    ' Error:' +
                    I_LogManager.GetLastErrorInfo());
    Result := -1;
    exit;
  end;
  if (numbytes <> ASize) then
  begin
    FLogManager.Log('ReadProcessMemory() failed to write address - ' +
                    IntToHex(Integer(AAddress), 8) +
                    ' Wrong number of bytes - ' +
                    IntToStr(numbytes) +
                    ' Error:' +
                    I_LogManager.GetLastErrorInfo());
    Result := -1;
    exit;
  end;
  if (AChangeProtect and
     (not VirtualProtectEx(GetHandle(), AAddress, ASize, oldprot, @oldprot))) then
  begin
    FLogManager.Log('WriteProcessMemory(): Failed to restore access read address - ' +
                    IntToHex(Integer(AAddress), 8) +
                    ' Error:' +
                    I_LogManager.GetLastErrorInfo());
    Result := 0;
    exit;
  end;
  if (not(FlushInstructionCache(GetHandle(), AAddress, numbytes))) then
  begin
    FLogManager.Log('WriteProcessMemory(): FlushInstructionCache failed for address - ' +
                    IntToHex(Integer(AAddress), 8) +
                    ' Error:' +
                    I_LogManager.GetLastErrorInfo());
  end;
  Result := numbytes;
end;

end.

