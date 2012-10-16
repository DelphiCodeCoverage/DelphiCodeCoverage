(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit CoverageStats;

interface

uses
  Classes,
  JclStringLists,
  I_CoverageStats;

type
  TCoverageStats = class(TInterfacedObject, ICoverageStats)
  private
    FName: string;
    FParent: Pointer;

    FLineCount: Integer;
    FPercentCovered: Integer;
    FCoveredLineCount: Integer;

    FCoverageLineCount: Integer;
    FCoverageLines: array of TCoverageLine;

    FCoverageStatsList: IJclStringList;
    procedure UpdateLineCapacity;
    procedure UpdatePercentCovered;
    function CoveredLineIndex(const ALineNumber: Integer): Integer;
  public
    constructor Create(
      const AName: string;
      const AParent: ICoverageStats
    );
    destructor Destroy; override;

    procedure Calculate;

    function CoveredLineCount: Integer;
    function LineCount: Integer;
    function PercentCovered: Integer;

    function Count: Integer;
    function GetCoverageReportByIndex(const AIndex: Integer): ICoverageStats;
    property CoverageReport[const AIndex: Integer]: ICoverageStats read GetCoverageReportByIndex; default;
    function GetCoverageReportByName(const AName: string) : ICoverageStats;
    property CoverageReportByName[const AName: string]: ICoverageStats read GetCoverageReportByName;

    function Name: string;
    function ReportFileName: string;
    function Parent: ICoverageStats;

    function GetCoverageLine(const AIndex: Integer): TCoverageLine;
    property CoverageLine[const AIndex: Integer]: TCoverageLine read GetCoverageLine;

    procedure AddLineCoverage(const ALineNumber: Integer; const AIsCovered: Boolean);
  end;

implementation

uses
  SysUtils;

constructor TCoverageStats.Create(
  const AName: string;
  const AParent: ICoverageStats);
begin
  inherited Create;

  FName := AName;

  FCoverageStatsList := TJclStringList.Create;
  FCoverageStatsList.Sorted := True;
  FCoverageStatsList.Duplicates := dupError;

  FCoverageLineCount := 0;
  SetLength(FCoverageLines, FCoverageLineCount);

  FParent := Pointer(AParent);
end;

destructor TCoverageStats.Destroy;
begin
  FCoverageStatsList := nil;

  inherited;
end;

procedure TCoverageStats.AddLineCoverage(
  const ALineNumber: Integer;
  const AIsCovered: Boolean);
var
  LineNumber: Integer;
  LineIndex: Integer;
begin
  LineIndex := CoveredLineIndex(ALineNumber);
  if LineIndex <> -1 then
  begin
    FCoverageLines[LineIndex].IsCovered := FCoverageLines[LineIndex].IsCovered
                                           or AIsCovered;
  end
  else
  begin
    UpdateLineCapacity;

    if (FCoverageLineCount > 0)
    and (ALineNumber < FCoverageLines[Pred(FCoverageLineCount)].LineNumber) then
    begin
      //We received a LineNumber that is out of order, sort it in
      LineNumber := FCoverageLineCount - 1;
      while (LineNumber > Low(FCoverageLines))
      and (FCoverageLines[LineNumber - 1].LineNumber > ALineNumber) do
        Dec(LineNumber);

      // Shift everything up to sort it in
      for LineIndex := FCoverageLineCount - 1 downto LineNumber do
        FCoverageLines[LineIndex + 1] := FCoverageLines[LineIndex];

      // And put in the new item sorted
      FCoverageLines[LineNumber].LineNumber := ALineNumber;
      FCoverageLines[LineNumber].IsCovered    := AIsCovered;
    end
    else
    begin
      //Append in the end
      FCoverageLines[FCoverageLineCount].LineNumber := ALineNumber;
      FCoverageLines[FCoverageLineCount].IsCovered    := AIsCovered;
    end;

    Inc(FCoverageLineCount);
  end;
end;

procedure TCoverageStats.Calculate;
var
  StatIndex: Integer;
  CurrentStatistics: ICoverageStats;
begin
  FLineCount := 0;
  FPercentCovered := 0;
  FCoveredLineCount := 0;

  if (FCoverageLineCount = 0) then
  begin
    for StatIndex := 0 to Pred(FCoverageStatsList.Count) do
    begin
      CurrentStatistics := ICoverageStats(Self.CoverageReport[StatIndex]);
      CurrentStatistics.Calculate;

      Inc(FLineCount, CurrentStatistics.LineCount);
      Inc(FCoveredLineCount, CurrentStatistics.CoveredLineCount);
    end;

    if FLineCount > 0 then
      UpdatePercentCovered;
  end
  else
  begin
    FLineCount := FCoverageLineCount;

    for StatIndex := 0 to Pred(FCoverageLineCount) do
    begin
      if FCoverageLines[StatIndex].IsCovered then
        Inc(FCoveredLineCount);
    end;

    if (FCoveredLineCount > 0) then
      UpdatePercentCovered;
  end;
end;

function TCoverageStats.Count: Integer;
begin
  Result := FCoverageStatsList.Count;
end;

function TCoverageStats.GetCoverageLine(const AIndex: Integer): TCoverageLine;
begin
  Result := FCoverageLines[AIndex];
end;

function TCoverageStats.GetCoverageReportByName(const AName: string): ICoverageStats;
begin
  Result := ICoverageStats(FCoverageStatsList.KeyInterface[AName]);

  if not Assigned(Result) then
  begin
    Result := TCoverageStats.Create(AName, Self);
    FCoverageStatsList.KeyInterface[AName] := Result;
  end;
end;

function TCoverageStats.GetCoverageReportByIndex(const AIndex: Integer): ICoverageStats;
begin
  Result := ICoverageStats(FCoverageStatsList.Interfaces[AIndex]);
end;

function TCoverageStats.Name: string;
begin
  Result := FName;
end;

function TCoverageStats.CoveredLineCount: Integer;
begin
  Result := FCoveredLineCount;
end;

function TCoverageStats.LineCount: Integer;
begin
  Result := FLineCount;
end;

function TCoverageStats.PercentCovered: Integer;
begin
  Result := FPercentCovered;
end;

function TCoverageStats.ReportFileName: string;
var
  tmp : string;
begin
  Result := ExtractFileName(Self.Name);

  if Self.Parent <> nil then
  begin
    tmp := Self.Parent.ReportFileName;
    if tmp <> '' then
      Result := tmp + '(' + Result + ')';
  end;
end;

function TCoverageStats.Parent: ICoverageStats;
begin
  Result := ICoverageStats(FParent);
end;

function TCoverageStats.CoveredLineIndex(const ALineNumber: Integer): Integer;
var
  Line: Integer;
begin
  Result := -1;
  for Line := 0 to Pred(FCoverageLineCount) do
  begin
    if CoverageLine[Line].LineNumber = ALineNumber then
      Exit(Line);
  end;
end;

procedure TCoverageStats.UpdatePercentCovered;
begin
  FPercentCovered := FCoveredLineCount * 100 div FLineCount;
end;

procedure TCoverageStats.UpdateLineCapacity;
begin
  if FCoverageLineCount = Length(FCoverageLines) then
    SetLength(FCoverageLines, FCoverageLineCount + 256);
end;

end.

