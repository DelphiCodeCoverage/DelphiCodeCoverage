(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit DebugThread;

interface

uses
  Winapi.Windows,
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

