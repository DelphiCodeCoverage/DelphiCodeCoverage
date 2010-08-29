unit I_CoverageStats;

interface

type
  TCoverageLine = record
    LineNumber: Integer;
    Covered: Boolean;
  end;

type
  ICoverageStats = interface
    // Statistics
    procedure CalculateStatistics;

    function GetNumberOfCoveredLines(): Integer;
    function GetNumberOfLines(): Integer;
    function GetPercentCovered(): Integer;

    function GetCount: Integer;
    function GetCoverageReportByIndex(const AIndex: Integer): ICoverageStats;
    property CoverageReport[const AIndex: Integer]: ICoverageStats read GetCoverageReportByIndex;

    procedure AddLineCoverage(const ALineNumber: Integer; const ACovered: Boolean);
    function AlreadyCovered(const ALineNumber: Integer): boolean;

    function GetCoverageReport(const AName : string) : ICoverageStats;

    function Parent : ICoverageStats;

    function GetReportFileName : string;

    function GetCoverageLine(const AIndex: Integer): TCoverageLine;

    function GetName(): string;
  end;

implementation

end.
