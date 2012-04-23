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
  private
    FOld_Opcode : Byte;
    FActive     : Boolean;
    FAddress    : Pointer;
    FCovered    : Boolean;
    FProcess    : IDebugProcess;
    FModule     : IDebugModule;

    FDetailsCount : Integer;
    FDetails : array of TBreakPointDetail;

    FLogManager : ILogManager;

    function DeActivate: Boolean;

    function GetCovered : Boolean;
    procedure SetCovered(const ACovered : Boolean);
  public
    constructor Create(const ADebugProcess: IDebugProcess;
                       const AAddress: Pointer;
                       const Module : IDebugModule;
                       const ALogManager : ILogManager);

    procedure Clear(const AThread: IDebugThread);

    procedure AddDetails(const AModuleName, AUnitName: string; const ALineNumber: Integer);
    function DetailCount() : Integer;
    function DetailByIndex(const AIndex : Integer) : TBreakPointDetail;

    function IsActive : Boolean;

    function Activate: Boolean;
    function GetAddress(): Pointer;
    function GetModule():IDebugModule;

    property Covered : Boolean read GetCovered write SetCovered;
  end;

implementation

uses
  SysUtils,
  Windows;

constructor TBreakPoint.Create(const ADebugProcess: IDebugProcess;
                               const AAddress: Pointer;
                               const Module : IDebugModule;
                               const ALogManager : ILogManager);
begin
  inherited Create;

  FAddress    := AAddress;
  FProcess    := ADebugProcess;
  FActive     := False;
  FCovered    := False;
  FModule     := Module;

  FDetailsCount := 0;
  SetLength(FDetails, 2);

  FLogManager := ALogManager
end;

function TBreakPoint.Activate: Boolean;
var
  OpCode       : byte;
  BytesRead    : DWORD;
  BytesWritten : DWORD;
  lp : Integer;
begin
  FLogManager.Log('TBreakPoint.Activate:');
  Result := False;
  if FActive then
    Result := True
  else
  begin
    BytesRead := FProcess.ReadProcessMemory(FAddress, @FOld_Opcode, 1, true);
    if BytesRead = 1 then
    begin
      OpCode := $CC;
      BytesWritten := FProcess.WriteProcessMemory(FAddress, @OpCode, 1, true);
      if BytesWritten = 1 then
      begin
        for lp := 0 to Pred(FDetailsCount) do
          FLogManager.Log('Activate ' +
                          FDetails[lp].UnitName +
                          ' line ' +
                          IntToStr(FDetails[lp].Line) +
                          ' BreakPoint at:' +
                          IntToHex(Integer(FAddress), 8));

        FActive := True;
        Result  := True;
      end;
    end
    else
    begin

    end;
  end;
end;

function TBreakPoint.DeActivate: Boolean;
var
  BytesWritten: DWORD;
  lp : Integer;
begin
  if (not FActive) then
  begin
    Result := True;
  end
  else
  begin
    BytesWritten := FProcess.writeProcessMemory(FAddress, @FOld_Opcode, 1,true);
    for lp := 0 to Pred(FDetailsCount) do
      FLogManager.Log('De-Activate ' +
                      FDetails[lp].UnitName +
                      ' line ' +
                      IntToStr(FDetails[lp].Line) +
                      ' BreakPoint at:' +
                      IntToHex(Integer(FAddress), 8));

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

procedure TBreakPoint.AddDetails(const AModuleName, AUnitName: string; const
    ALineNumber: Integer);
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
  Result := GetThreadContext(AThread.GetHandle(), ContextRecord);
  if (Result {<> False}) then
  begin
    DeActivate;
    {$IFDEF CPU64}
    Dec(ContextRecord.Rip);
    {$ELSE}
    Dec(ContextRecord.Eip);
    {$ENDIF}
    ContextRecord.contextflags := CONTEXT_CONTROL;
    Result := SetThreadContext(AThread.GetHandle(), ContextRecord);
    if (not Result) then
      FLogManager.Log('Failed setting thread context:' + I_LogManager.GetLastErrorInfo());
  end
  else
    FLogManager.Log('Failed to get thread context   ' + I_LogManager.GetLastErrorInfo());
end;

function TBreakPoint.IsActive: Boolean;
begin
  Result := FActive;
end;

function TBreakPoint.GetAddress: Pointer;
begin
  Result := FAddress;
end;

function TBreakPoint.GetModule;
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
