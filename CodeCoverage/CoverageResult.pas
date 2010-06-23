(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit CoverageResult;

interface

uses classes, Generics.Collections;

type

  TLineCoverage = record
    line: Integer;
    covered: boolean;
  end;

  TUnitCoverage = class
  private
    name: string;
    lineCoverage: array of TLineCoverage;
    numberOfLines: Integer;
    percentCovered: Integer;
    coveredLineCount: Integer;
  public
    constructor Create(unitname: string);
    procedure AddLineCoverage(line: Integer; covered: boolean);
    procedure ModifyLineCoverage(line: Integer; covered: boolean);
    function getLineCoverage(index: Integer): TLineCoverage;
    function AlreadyCovered(line: Integer): boolean;
    function GetName(): string;
    function GetPercentCovered: Integer;
    function GetNumberOfLines: Integer;
    function GetNumberOfCoveredLines: Integer;
    procedure CalculateStatistics;
  end;

  TCoverage = class
  private
    unitlist: TList<TUnitCoverage>;
    numberOfLines: Integer;
    percentCovered: Integer;
    coveredLineCount: Integer;
  public
    constructor Create();
    function getUnitCount: Integer;
    function getUnitByIndex(index: Integer): TUnitCoverage;
    function GetUnit(unitname: string): TUnitCoverage;
    property CoverageUnit[index: Integer]: TUnitCoverage read getUnitByIndex;
    procedure CalculateStatistics;
    function GetPercentCovered: Integer;
    function GetNumberOfLines: Integer;
    function GetNumberOfCoveredLines: Integer;
  end;

implementation

uses sysutils, logger;

constructor TUnitCoverage.Create(unitname: string);
begin
  name := unitname;
  numberOfLines := 0;
  SetLength(lineCoverage, numberOfLines + 256);
end;

function TUnitCoverage.GetName(): string;
begin
  result := name;
end;

function TUnitCoverage.AlreadyCovered(line: Integer): boolean;
var
  i: Integer;
begin
  result := false;
  for i := 0 to numberOfLines do
  begin
    if lineCoverage[i].line = line then
    begin
      result := true;
      break;
    end;
  end;
end;

function TUnitCoverage.getLineCoverage(index: Integer): TLineCoverage;
begin
  result := lineCoverage[index];
end;

procedure TUnitCoverage.AddLineCoverage(line: Integer; covered: boolean);
begin
  if numberOfLines mod 256 = 0 then
    SetLength(lineCoverage, numberOfLines + 256);
  lineCoverage[numberOfLines].line := line;
  lineCoverage[numberOfLines].covered := covered;
  inc(numberOfLines);
end;

procedure TUnitCoverage.ModifyLineCoverage(line: Integer; covered: boolean);
var
  i: Integer;
begin
  for i := 0 to numberOfLines do
  begin
    if lineCoverage[i].line = line then
      lineCoverage[i].covered := covered;
  end;
end;

procedure TUnitCoverage.CalculateStatistics;
var
  i: Integer;
begin
  coveredLineCount := 0;
  for i := 0 to numberOfLines - 1 do
  begin
    begin
      if lineCoverage[i].covered then
        inc(coveredLineCount);
    end;
  end;
  percentCovered := coveredLineCount * 100 div numberOfLines;
end;

function TUnitCoverage.GetPercentCovered: Integer;
begin
  result := percentCovered;
end;

function TUnitCoverage.GetNumberOfLines: Integer;
begin
  result := numberOfLines;
end;

function TUnitCoverage.GetNumberOfCoveredLines: Integer;
begin
  result := coveredLineCount;
end;

constructor TCoverage.Create;
begin
  unitlist := TList<TUnitCoverage>.Create;
end;

function TCoverage.getUnitCount: Integer;
begin
  result := unitlist.Count;
end;

function TCoverage.getUnitByIndex(index: Integer): TUnitCoverage;
begin
  result := unitlist[index];
end;

function TCoverage.GetPercentCovered: Integer;
begin
  result := percentCovered;
end;

function TCoverage.GetNumberOfLines: Integer;
begin
  result := numberOfLines;
end;

function TCoverage.GetNumberOfCoveredLines: Integer;
begin
  result := coveredLineCount;
end;
function TCoverage.GetUnit(unitname: string): TUnitCoverage;
var
  i: Integer;
begin
  result := nil;
  for i := 0 to unitlist.Count - 1 do
  begin
    if unitlist[i].name = unitname then
    begin
      result := TUnitCoverage(unitlist[i]);
      break;
    end;
  end;
  if result = nil then
  begin
    result := TUnitCoverage.Create(unitname);
    unitlist.add(result);
  end;
end;

procedure TCoverage.CalculateStatistics;
var
  i: Integer;
begin
  for i := 0 to unitlist.Count - 1 do
  begin
    unitlist[i].CalculateStatistics;
  end;
  numberOfLines := 0;
  coveredLineCount := 0;
  percentCovered := 0;
  for i := 0 to unitlist.Count - 1 do
  begin
    inc(numberOfLines, unitlist[i].GetNumberOfLines);
    inc(coveredLineCount, unitlist[i].GetNumberOfCoveredLines);
  end;
  percentCovered := coveredLineCount * 100 div numberOfLines;

end;

end.
