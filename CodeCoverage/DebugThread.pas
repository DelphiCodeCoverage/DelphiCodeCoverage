(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit DebugThread;

interface

uses classes, windows;

type

  TDebugThread = class
  private
    threadID: DWORD;
    handle: THandle;
  public
    constructor Create(id: DWORD; threadhandle: THandle);
    function GetHandle(): THandle;
    function GetId(): DWORD;
  end;

implementation

uses sysutils;

constructor TDebugThread.Create(id: DWORD; threadhandle: THandle);
begin
  threadID := id;
  handle := threadhandle;
end;

function TDebugThread.GetHandle(): THandle;
begin
  result := handle;
end;

function TDebugThread.GetId(): DWORD;
begin
  result := threadID;
end;

end.
