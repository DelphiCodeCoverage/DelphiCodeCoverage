(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_Report;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_CoverageStats;

type
  IReport = interface
    procedure Generate(const ACoverage: ICoverageStats; const ASourceDir, AOutputDir: string);
  end;

implementation

end.
