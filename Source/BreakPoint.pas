(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit BreakPoint;

interface

uses
  System.Classes,
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
    FBreakCount: integer;
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

    function BreakCount: integer;
    procedure IncBreakCount;

    function Activate: Boolean;
    function Address: Pointer;
    function Module: IDebugModule;

    function GetCovered: Boolean;
    property IsCovered: Boolean read GetCovered;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows;

constructor TBreakPoint.Create(const ADebugProcess: IDebugProcess;
                               const AAddress: Pointer;
                               const AModule: IDebugModule;
                               const ALogManager: ILogManager);
begin
  inherited Create;

  FAddress := AAddress;
  FProcess := ADebugProcess;
  FActive := False;
  FBreakCount := 0;
  FModule := AModule;

  FDetailsCount := 0;
  SetLength(FDetails, 2);

  FLogManager := ALogManager;
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
      FlushInstructionCache(FProcess.Handle, nil, 0);
      if BytesWritten = 1 then
      begin
        for DetailIndex := 0 to Pred(FDetailsCount) do
        begin
          FLogManager.Log(
            'Activate ' + FDetails[DetailIndex].UnitName +
            ' line ' + IntToStr(FDetails[DetailIndex].Line) +
            ' BreakPoint at:' + IntToHex(Integer(FAddress), 8)
          );
        end;

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
    FlushInstructionCache(FProcess.Handle,nil,0);

    for DetailIndex := 0 to Pred(FDetailsCount) do
    begin
      FLogManager.Log(
        'De-Activate ' + FDetails[DetailIndex].UnitName +
        ' line ' + IntToStr(FDetails[DetailIndex].Line) +
        ' BreakPoint at:' + IntToHex(Integer(FAddress), 8)
      );
    end;

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
  begin
    SetLength(FDetails, FDetailsCount + 5);
  end;

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
    begin
      FLogManager.Log('Failed setting thread context:' + I_LogManager.LastErrorInfo);
    end;
  end
  else
  begin
    FLogManager.Log('Failed to get thread context   ' + I_LogManager.LastErrorInfo);
  end;
end;

function TBreakPoint.IsActive: Boolean;
begin
  Result := FActive;
end;

function TBreakPoint.Address: Pointer;
begin
  Result := FAddress;
end;

function TBreakPoint.Module: IDebugModule;
begin
  Result := FModule;
end;

function TBreakPoint.BreakCount: Integer;
begin
  Result := FBreakCount;
end;

procedure TBreakPoint.IncBreakCount;
begin
  Inc(FBreakCount);
end;

function TBreakPoint.GetCovered: Boolean;
begin
  Result := FBreakCount > 0;
end;

end.
