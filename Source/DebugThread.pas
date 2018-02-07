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

    function Handle: THandle; inline;
    function Id: DWORD; inline;
  end;

implementation

constructor TDebugThread.Create(
  const AThreadId: DWORD;
  const AThreadHandle: THandle);
begin
  inherited Create;

  FThreadId     := AThreadId;
  FThreadHandle := AThreadHandle;
end;

function TDebugThread.Handle: THandle;
begin
  Result := FThreadHandle;
end;

function TDebugThread.Id: DWORD;
begin
  Result := FThreadId;
end;

end.

