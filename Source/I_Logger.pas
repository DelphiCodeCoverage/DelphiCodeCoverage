(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_Logger;

interface

{$INCLUDE CodeCoverage.inc}

type
  ILogger = interface
    procedure Log(const AMessage: string);
  end;

implementation

end.
