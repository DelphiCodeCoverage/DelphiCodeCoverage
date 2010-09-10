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
  Classes,
  I_CoverageStats;

type
  IReport = interface
    procedure Generate(const ACoverage: ICoverageStats;
                       const ASourceDirLst: TStrings;
                       const AOutputDir: string);
  end;

implementation

end.
