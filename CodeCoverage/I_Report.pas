(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_Report;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_CoverageStats,
  ClassInfoUnit;

type
  IReport = interface
    procedure Generate(const ACoverage: ICoverageStats;const AModuleInfoList: TModuleList);
  end;

implementation

end.
