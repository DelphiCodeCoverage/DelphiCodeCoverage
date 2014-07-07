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

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  I_BreakPoint,
  I_DebugThread,
  I_DebugProcess,
  I_DebugModule,
  I_LogManager;

type
  TBreakPoint = class(TInterfacedObject, IBreakPoint)
  strict private
    FOld_Opcode: Byte;
    FActive: Boolean;
    FAddress: Pointer;
    FCovered: Boolean;
    FProcess: IDebugProcess;
    FModule: IDebugModule;

    FDetailsCount: Integer;
    FDetails: array of TBreakPointDetail;

    FLogManager: ILogManager;

    function DeActivate: Boolean;
  public
    constructor Create(const ADebugProcess: IDebugProcess;
                       const AAddress: Pointer;
                       const AModule: IDebugModule;
                       const ALogManager: ILogManager);

    procedure Clear(const AThread: IDebugThread);

    procedure AddDetails(const AModuleName: string;
                         const AUnitName: string;
                         const ALineNumber: Integer);
    function DetailCount: Integer;
    function DetailByIndex(const AIndex: Integer): TBreakPointDetail;

    function IsActive: Boolean;

    function Activate: Boolean;
    function Address: Pointer;
    function Module: IDebugModule;

    function GetCovered: Boolean;
    procedure SetCovered(const ACovered: Boolean);
    property IsCovered: Boolean read GetCovered write SetCovered;
  end;

implementation

uses
  SysUtils,
  Windows;

constructor TBreakPoint.Create(const ADebugProcess: IDebugProcess;
                               const AAddress: Pointer;
                               const AModule: IDebugModule;
                               const ALogManager: ILogManager);
begin
  inherited Create;

  FAddress := AAddress;
  FProcess := ADebugProcess;
  FActive := False;
  FCovered := False;
  FModule := AModule;

  FDetailsCount := 0;
  SetLength(FDetails, 2);

  FLogManager := ALogManager
end;

function TBreakPoint.Activate: Boolean;
var
  OpCode : Byte;
  BytesRead: DWORD;
  BytesWritten: DWORD;
  DetailIndex: Integer;
begin
  FLogManager.Log('TBreakPoint.Activate:');

  Result := FActive;

  if not Result then
  begin
    BytesRead := FProcess.ReadProcessMemory(FAddress, @FOld_Opcode, 1, true);
    if BytesRead = 1 then
    begin
      OpCode := $CC;
      BytesWritten := FProcess.WriteProcessMemory(FAddress, @OpCode, 1, true);
      if BytesWritten = 1 then
      begin
        for DetailIndex := 0 to Pred(FDetailsCount) do
          FLogManager.Log(
            'Activate ' + FDetails[DetailIndex].UnitName +
            ' line ' + IntToStr(FDetails[DetailIndex].Line) +
            ' BreakPoint at:' + IntToHex(Integer(FAddress), 8)
          );

        FActive := True;
        Result  := True;
      end;
    end;
  end;
end;

function TBreakPoint.DeActivate: Boolean;
var
  BytesWritten: DWORD;
  DetailIndex: Integer;
begin
  Result := not FActive;

  if not Result then
  begin
    BytesWritten := FProcess.writeProcessMemory(FAddress, @FOld_Opcode, 1,true);

    for DetailIndex := 0 to Pred(FDetailsCount) do
      FLogManager.Log(
        'De-Activate ' + FDetails[DetailIndex].UnitName +
        ' line ' + IntToStr(FDetails[DetailIndex].Line) +
        ' BreakPoint at:' + IntToHex(Integer(FAddress), 8)
      );

    Result  := (BytesWritten = 1);
    FActive := False;
  end;
end;

function TBreakPoint.DetailByIndex(const AIndex: Integer): TBreakPointDetail;
begin
  Result := FDetails[AIndex];
end;

function TBreakPoint.DetailCount: Integer;
begin
  Result := FDetailsCount;
end;

procedure TBreakPoint.AddDetails(const AModuleName: string;
                                 const AUnitName: string;
                                 const ALineNumber: Integer);
begin
  if (FDetailsCount = Length(FDetails)) then
    SetLength(FDetails, FDetailsCount + 5);

  FDetails[FDetailsCount].ModuleName := AModuleName;
  FDetails[FDetailsCount].UnitName   := AUnitName;
  FDetails[FDetailsCount].Line       := ALineNumber;

  Inc(FDetailsCount);
end;

procedure TBreakPoint.Clear(const AThread: IDebugThread);
var
  ContextRecord: CONTEXT;
  Result: BOOL;
begin
  FLogManager.Log('Clearing BreakPoint at ' + IntToHex(Integer(FAddress), 8));

  ContextRecord.ContextFlags := CONTEXT_CONTROL;

  Result := GetThreadContext(AThread.Handle, ContextRecord);
  if Result then
  begin
    DeActivate;
    {$IFDEF CPUX64}
    Dec(ContextRecord.Rip);
    {$ELSE}
    Dec(ContextRecord.Eip);
    {$ENDIF}
    ContextRecord.ContextFlags := CONTEXT_CONTROL;
    Result := SetThreadContext(AThread.Handle, ContextRecord);
    if (not Result) then
      FLogManager.Log('Failed setting thread context:' + I_LogManager.LastErrorInfo);
  end
  else
    FLogManager.Log('Failed to get thread context   ' + I_LogManager.LastErrorInfo);
end;

function TBreakPoint.IsActive: Boolean;
begin
  Result := FActive;
end;

function TBreakPoint.Address: Pointer;
begin
  Result := FAddress;
end;

function TBreakPoint.Module;
begin
  Result := FModule;
end;

procedure TBreakPoint.SetCovered(const ACovered: Boolean);
begin
  FCovered := ACovered;
end;

function TBreakPoint.GetCovered: Boolean;
begin
  Result := FCovered;
end;

end.
