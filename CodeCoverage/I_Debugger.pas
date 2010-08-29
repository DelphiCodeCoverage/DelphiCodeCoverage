(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_Debugger;

interface

{$INCLUDE CodeCoverage.inc}

type
  IDebugger = interface
    procedure Start();
  end;

implementation

end.
