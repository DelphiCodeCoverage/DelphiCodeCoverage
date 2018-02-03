(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit DebugProcess;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  Windows,
  I_DebugThread,
  I_DebugProcess,
  I_LogManager,
  I_DebugModule,
  Generics.Collections,
  JCLDebug;

type
  TDebugProcess = class(TInterfacedObject, IDebugProcess)
  private
    FProcessHandle: THandle;
    FProcessModule: HMODULE;
    FModuleList: TList<IDebugModule>;

    FDebugThreadLst: IInterfaceList;
    FLogManager: ILogManager;
    FName: string;
    FSize: Cardinal;
    FMapScanner: TJCLMapScanner;
  public
    constructor Create(
      const AProcessId: DWORD;
      const AProcessHandle: THandle;
      const AProcessModule: HMODULE;
      const AName: string;
      const ASize: Cardinal;
      const AMapScanner: TJCLMapScanner;
      const ALogManager: ILogManager);
    destructor Destroy; override;

    procedure AddThread(const ADebugThread: IDebugThread);
    procedure RemoveThread(const AThreadId: DWORD);

    procedure AddModule(const AModule: IDebugModule);
    procedure RemoveModule(const AModule: IDebugModule);
    function GetModule(const AName: string): IDebugModule;

    function Name: string; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
    function Base: HMODULE; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
    function Handle: THandle; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
    function Size: Cardinal;
    function MapScanner: TJCLMapScanner;
    function FindDebugModuleFromAddress(Addr: Pointer): IDebugModule;

    function GetThreadById(const AThreadId: DWORD): IDebugThread;
    function ReadProcessMemory(
      const AAddress, AData: Pointer;
      const ASize: Cardinal;
      const AChangeProtect: Boolean = False): Integer;
    function WriteProcessMemory(
      const AAddress, AData: Pointer;
      const ASize: Cardinal;
      const AChangeProtect: Boolean = False): Integer;
  end;

implementation

uses
  SysUtils,
  JwaWinBase;

constructor TDebugProcess.Create(
  const AProcessId: DWORD;
  const AProcessHandle: THandle;
  const AProcessModule: HMODULE;
  const AName: string;
  const ASize: Cardinal;
  const AMapScanner: TJCLMapScanner;
  const ALogManager: ILogManager);
begin
  inherited Create;

  FProcessHandle := AProcessHandle;
  FProcessModule := AProcessModule;
  FDebugThreadLst := TInterfaceList.Create;
  FModuleList := TList<IDebugModule>.Create;

  FName := AName;
  FLogManager := ALogManager;
  FMapScanner := AMapScanner;
  FSize := ASize;
end;

destructor TDebugProcess.Destroy;
begin
  FDebugThreadLst := nil;
  FLogManager := nil;
  FModuleList.Free;
  FModuleList := nil;

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
    FDebugThreadLst.Remove(DebugThread);
end;

function TDebugProcess.Name;
begin
  Result := FName;
end;

procedure TDebugProcess.AddModule(const AModule: IDebugModule);
begin
  FModuleList.Add(AModule);
end;

procedure TDebugProcess.RemoveModule(const AModule: IDebugModule);
begin
  FModuleList.Remove(AModule);
end;

function TDebugProcess.GetModule(const AName: string): IDebugModule;
var
  CurrentModule: IDebugModule;
begin
  result := nil;
  for CurrentModule in FModuleList do
  begin
    if CurrentModule.Name = AName then
      Exit(CurrentModule);
  end;
end;

function TDebugProcess.Handle: THandle;
begin
  Result := FProcessHandle;
end;

function TDebugProcess.Base: HMODULE;
begin
  Result := FProcessModule;
end;

function TDebugProcess.Size: Cardinal;
begin
  Result := FSize;
end;

function TDebugProcess.MapScanner;
begin
  Result := FMapScanner;
end;

function TDebugProcess.FindDebugModuleFromAddress(Addr: Pointer): IDebugModule;
var
  CurrentModule: IDebugModule;
  ModuleAddress: DWORD;

  function AddressBelongsToModule(const AModule: IDebugModule): Boolean;
  begin
    Result := ((ModuleAddress >= AModule.Base)
              and (ModuleAddress <= (AModule.Base + AModule.Size)));
  end;
begin
  Result := nil;
  ModuleAddress := DWORD(Addr);

  if AddressBelongsToModule(IDebugProcess(Self)) then
    Result := IDebugProcess(self)
  else
  begin
    for CurrentModule in FModuleList do
    begin
      if AddressBelongsToModule(CurrentModule) then
        Exit(CurrentModule);
    end;
  end;
end;

function TDebugProcess.GetThreadById(const AThreadId: DWORD): IDebugThread;
var
  ThreadIndex: Integer;
  CurrentThread: IInterface;
begin
  Result := nil;
  for ThreadIndex := 0 to FDebugThreadLst.Count - 1 do
  begin
    CurrentThread := FDebugThreadLst[ThreadIndex];
    if IDebugThread(CurrentThread).Id = AThreadId then
      Exit(IDebugThread(CurrentThread));
  end;
end;

function AddrToHex(const AAddress: Pointer): string;
begin
  Result := IntToHex(Integer(AAddress), 8);
end;

function TDebugProcess.ReadProcessMemory(
  const AAddress, AData: Pointer;
  const ASize: Cardinal;
  const AChangeProtect: Boolean = False): Integer;
var
  oldprot: UINT;
  numbytes: DWORD;
  changed: Boolean;
begin
  Changed := False;
  if not JwaWinBase.ReadProcessMemory(Handle, AAddress, AData, ASize, @numbytes) then
  begin
    // try changing protection
    if AChangeProtect
    and not VirtualProtectEx(Handle, AAddress, ASize, PAGE_EXECUTE_READ, @oldprot) then
    begin
      changed := true;
      if not JwaWinBase.ReadProcessMemory(Handle, AAddress, AData, ASize, @numbytes) then
      begin
        FLogManager.Log(
          'ReadProcessMemory failed reading address - ' + AddrToHex(AAddress) +
          ' Error:' + I_LogManager.LastErrorInfo);
        Result := -1;
        exit;
      end;
    end
    else
    begin
      FLogManager.Log(
        'ReadProcessMemory failed to change protection - ' + AddrToHex(AAddress) +
        ' Error:' + I_LogManager.LastErrorInfo);
    end;
  end;

  if numbytes <> ASize then
  begin
    FLogManager.Log(
      'ReadProcessMemory failed to read address - ' + AddrToHex(AAddress)
      + ' Wrong number of bytes - ' + IntToStr(numbytes)
      + ' Error:' + I_LogManager.LastErrorInfo);
    Result := -1;
    exit;
  end;

  if changed then
  begin
    if AChangeProtect
    and not VirtualProtectEx(Handle, AAddress, ASize, oldprot, @oldprot) then
    begin
      FLogManager.Log(
        'ReadProcessMemory Failed to restore access read address - ' + AddrToHex(AAddress)
        + ' Error:' + I_LogManager.LastErrorInfo);
      Result := 0;
      exit;
    end;
  end;

  Result := numbytes;
end;

function TDebugProcess.WriteProcessMemory(
  const AAddress, AData: Pointer;
  const ASize: Cardinal;
  const AChangeProtect: Boolean = False): Integer;
var
  oldprot: UINT;
  numbytes: DWORD;
  changed: Boolean;
begin
  changed := False; // keep track if we changed page protection

  if not JwaWinBase.WriteProcessMemory(Handle, AAddress, AData, ASize, @numbytes) then
  begin
    // Failed to write, thus we try to change the protection
    if AChangeProtect
    and not(VirtualProtectEx(Handle, AAddress, ASize, PAGE_EXECUTE_READWRITE, @oldprot)) then
    begin
      FLogManager.Log(
        'WriteProcessMemory failed to change protection to PAGE_EXECUTE_READWRITE address - ' + AddrToHex(AAddress) +
        ' Error:' + I_LogManager.LastErrorInfo);
      Result := -1;
      exit;
    end
    else
    begin
      changed := true;

      // Try again after changing protection
      if not JwaWinBase.WriteProcessMemory(Handle, AAddress, AData, ASize, @numbytes) then
      begin
        FLogManager.Log(
          'WriteProcessMemory failed writing address - ' + AddrToHex(AAddress) +
          ' Error:' + I_LogManager.LastErrorInfo);
        Result := -1;
        exit;
      end;
    end;
  end;

  if (numbytes <> ASize) then
  begin
    FLogManager.Log(
      'WriteProcessMemory failed to write address - ' + AddrToHex(AAddress) +
      ' Wrong number of bytes - ' + IntToStr(numbytes) +
      ' Error:' + I_LogManager.LastErrorInfo);
    Result := -1;
    exit;
  end;

  if changed
  and AChangeProtect
  and not VirtualProtectEx(Handle, AAddress, ASize, oldprot, @oldprot) then
  begin
    FLogManager.Log(
      'WriteProcessMemory: Failed to restore access read address - ' + AddrToHex(AAddress) +
      ' Error:' + I_LogManager.LastErrorInfo);
    Result := 0;
    exit;
  end;

  if not(FlushInstructionCache(Handle, AAddress, numbytes)) then
  begin
    FLogManager.Log(
      'WriteProcessMemory: FlushInstructionCache failed for address - ' + AddrToHex(AAddress) +
      ' Error:' + I_LogManager.LastErrorInfo);
  end;

  Result := numbytes;
end;

end.
