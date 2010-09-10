(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit DebugThread;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Windows,
  I_DebugThread;

type
  TDebugThread = class(TInterfacedObject, IDebugThread)
  private
    FThreadId: DWORD;
    FThreadHandle: THandle;
  public
    constructor Create(const AThreadId: DWORD; const AThreadHandle: THandle);

    function GetHandle(): THandle;{$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
    function GetId(): DWORD;{$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
  end;

implementation

constructor TDebugThread.Create(const AThreadId: DWORD; const AThreadHandle:
    THandle);
begin
  inherited Create;

  FThreadId     := AThreadId;
  FThreadHandle := AThreadHandle;
end;

function TDebugThread.GetHandle(): THandle;
begin
  Result := FThreadHandle;
end;

function TDebugThread.GetId(): DWORD;
begin
  Result := FThreadId;
end;

end.

