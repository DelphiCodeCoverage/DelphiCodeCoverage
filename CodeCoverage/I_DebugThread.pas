(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_DebugThread;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Windows;

type
  IDebugThread = interface
    function GetHandle(): THandle;
    function GetId(): DWORD;
  end;

implementation

end.
