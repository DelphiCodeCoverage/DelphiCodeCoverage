(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit I_CoverageStats;

interface

type
  TCoverageLine = record
    LineNumber: Integer;
    LineCount: Integer;
    function IsCovered: Boolean;
  end;

type
  ICoverageStats = interface
    // Statistics
    procedure Calculate;

    function CoveredLineCount: Integer;
    function LineCount: Integer;
    function PercentCovered: Integer;

    function Parent: ICoverageStats;
    function Count: Integer;
    function GetCoverageReportByIndex(const AIndex: Integer): ICoverageStats;
    property CoverageReport[const AIndex: Integer]: ICoverageStats read GetCoverageReportByIndex; default;

    function GetCoverageReportByName(const AName: string) : ICoverageStats;
    property CoverageReportByName[const AName: string]: ICoverageStats read GetCoverageReportByName;

    function ReportFileName: string;
    function Name: string;

    function GetCoverageLineCount: Integer;
    function GetCoverageLine(const AIndex: Integer): TCoverageLine;
    property CoverageLine[const AIndex: Integer]: TCoverageLine read GetCoverageLine;

    procedure AddLineCoverage(const ALineNumber: Integer; const ALineCount: Integer);
  end;

implementation

function TCoverageLine.IsCovered: Boolean;
begin
  Result := LineCount > 0;
end;

end.
