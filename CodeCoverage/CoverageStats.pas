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
    FName                 : string;
    FParent               : Pointer;

    FStatNumberOfLines    : Integer;
    FStatPercentCovered   : Integer;
    FStatCoveredLineCount : Integer;

    FCoverageLineCount    : Integer;
    FCoverageLine         : array of TCoverageLine;

    FCRList               : IJclStringList;
    function GetCoverageReportByIndex(const AIndex: Integer): ICoverageStats;
  public
    constructor Create(const AName: string; const AParent: ICoverageStats);
    destructor Destroy; override;

    procedure CalculateStatistics;

    function GetNumberOfCoveredLines(): Integer;
    function GetNumberOfLines(): Integer;
    function GetPercentCovered(): Integer;

    function GetCount: Integer;
    property CoverageReport[const AIndex: Integer]: ICoverageStats read GetCoverageReportByIndex;

    function GetCoverageLine(const AIndex: Integer): TCoverageLine;
    procedure AddLineCoverage(const ALineNumber: Integer; const ACovered: Boolean);

    function AlreadyCovered(const ALineNumber: Integer): boolean;

    function GetCoverageReport(const AName : string) : ICoverageStats;

    function GetName(): string;

    function GetReportFileName : string;

    function Parent : ICoverageStats;
  end;


implementation

uses
  SysUtils;

{ TCoverageStats }

constructor TCoverageStats.Create(const AName: string; const AParent:
    ICoverageStats);
begin
  inherited Create;

  FName := AName;

  FCRList := TJclStringList.Create;
  FCRList.Sorted := True;
  FCRList.Duplicates := dupError;

  FCoverageLineCount := 0;
  SetLength(FCoverageLine, FCoverageLineCount);

  FParent := Pointer(AParent);
end;

destructor TCoverageStats.Destroy;
begin
  FCRList := nil;

  inherited;
end;

procedure TCoverageStats.AddLineCoverage(const ALineNumber: Integer;
  const ACovered: Boolean);
var
  LineNumber : Integer;
  lp         : Integer;
begin
  if FCoverageLineCount = Length(FCoverageLine) then
    SetLength(FCoverageLine, FCoverageLineCount + 256);

  if (FCoverageLineCount > 0) and
     (ALineNumber < FCoverageLine[FCoverageLineCount - 1].LineNumber) then
  begin
    //We received a LineNumber that is out of order, sort it in
    LineNumber := FCoverageLineCount - 1;
    while (LineNumber > Low(FCoverageLine)) and
          (FCoverageLine[LineNumber].LineNumber > ALineNumber) do
    begin
      dec(LineNumber);
    end;
    // Shift everything up to sort it in
    for lp := FCoverageLineCount - 1 downto LineNumber + 1 do
    begin
      FCoverageLine[lp + 1] := FCoverageLine[lp];
    end;
    // And put in the new item sorted
    FCoverageLine[LineNumber+1].LineNumber := ALineNumber;
    FCoverageLine[LineNumber+1].Covered    := ACovered;
  end
  else
  begin
    //Append in the end
    FCoverageLine[FCoverageLineCount].LineNumber := ALineNumber;
    FCoverageLine[FCoverageLineCount].Covered    := ACovered;
  end;

  Inc(FCoverageLineCount);
end;

procedure TCoverageStats.CalculateStatistics;
var
  lpCoverageStats : Integer;
  CoverageStats   : ICoverageStats;
begin
  FStatNumberOfLines    := 0;
  FStatPercentCovered   := 0;
  FStatCoveredLineCount := 0;

  if (FCoverageLineCount = 0) then
  begin
    for lpCoverageStats := 0 to Pred(FCRList.Count) do
    begin
      CoverageStats := ICoverageStats(Self.GetCoverageReportByIndex(lpCoverageStats));

      CoverageStats.CalculateStatistics;

      Inc(FStatNumberOfLines, CoverageStats.GetNumberOfLines);
      Inc(FStatCoveredLineCount, CoverageStats.GetNumberOfCoveredLines);
    end;

    if FStatNumberOfLines > 0 then
      FStatPercentCovered := FStatCoveredLineCount * 100 div FStatNumberOfLines;
  end
  else
  begin
    FStatNumberOfLines := FCoverageLineCount;

    for lpCoverageStats := 0 to Pred(FCoverageLineCount) do
    begin
      if FCoverageLine[lpCoverageStats].Covered then
        inc(FStatCoveredLineCount);
    end;

    if (FStatCoveredLineCount > 0) then
    begin
      FStatPercentCovered := FStatCoveredLineCount * 100 div FStatNumberOfLines;
    end;
  end;
end;

function TCoverageStats.GetCount: Integer;
begin
  Result := FCRList.Count;
end;

function TCoverageStats.GetCoverageLine(const AIndex: Integer): TCoverageLine;
begin
  Result := FCoverageLine[AIndex];
end;

function TCoverageStats.GetCoverageReport(const AName: string): ICoverageStats;
begin
  Result := ICoverageStats(FCRList.KeyInterface[AName]);

  if Result = nil then
  begin
    Result := TCoverageStats.Create(AName, Self);
    FCRList.KeyInterface[AName] :=  Result;
  end;
end;

function TCoverageStats.GetCoverageReportByIndex(const AIndex: Integer): ICoverageStats;
begin
  Result := ICoverageStats(FCRList.Interfaces[AIndex]);
end;

function TCoverageStats.GetName: string;
begin
  Result := FName;
end;

function TCoverageStats.GetNumberOfCoveredLines: Integer;
begin
  Result := FStatCoveredLineCount;
end;

function TCoverageStats.GetNumberOfLines: Integer;
begin
  Result := FStatNumberOfLines;
end;

function TCoverageStats.GetPercentCovered: Integer;
begin
  Result := FStatPercentCovered;
end;

function TCoverageStats.GetReportFileName: string;
var
  tmp : string;
begin
  Result := ExtractFileName(Self.GetName);

  if Self.Parent <> nil then
  begin
    tmp := Self.Parent.GetReportFileName;
    if tmp <> '' then
      Result := tmp + '(' + Result + ')';
  end;
end;

function TCoverageStats.Parent: ICoverageStats;
begin
  Result := ICoverageStats(FParent);
end;

function TCoverageStats.AlreadyCovered(
  const ALineNumber: Integer): boolean;
var
  lp: Integer;
begin
  Result := False;
  //log.log('Checking line:' + inttostr(line) + 'unit' + GetName());
  for lp := 0 to Pred(FCoverageLineCount) do
  begin
    if (GetCoverageLine(lp).LineNumber = ALineNumber) then
    begin
      Result := True;
      //log.log('Already covered:' + inttostr(lp) + ' unit ' + GetName());
      break;
    end;
  end;
end;

end.

