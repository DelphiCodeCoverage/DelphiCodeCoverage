(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_DebugProcess;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Windows,
  I_DebugThread;

type
  IDebugProcess = interface
    procedure AddThread(const ADebugThread: IDebugThread);
    procedure RemoveThread(const AThreadId: DWORD);

    function GetHandle(): THandle;
    function GetModule(): HMODULE;
    function GetThreadById(const AThreadId: DWORD): IDebugThread;
    function ReadProcessMemory(const AAddress, AData: Pointer; const ASize:
        Cardinal; const AChangeProtect: Boolean = False): Integer;
    function WriteProcessMemory(const AAddress, AData: Pointer; const ASize:
        Cardinal; const AChangeProtect: Boolean = False): Integer;
  end;

implementation

end.
