unit CoverageStatsMergeTests;

interface

uses
  TestFramework;

type
  TestCoverageStatsMerge = class(TTestCase)
  published
    procedure MergeMultipleOutputForSingleFile;
    procedure OutOfOrderLineKeepsItsOwnCount;
  end;

implementation

uses
  CoverageStats, I_CoverageStats, XMLCoverageReport;

{ TestCoverageStats }

procedure TestCoverageStatsMerge.MergeMultipleOutputForSingleFile;
var
  LCoverageStats, ModuleStats, UnitStats: ICoverageStats;
  LNewCoverage: ICoverageStats;
begin
  LCoverageStats := TCoverageStats.Create('myFile', nil);

  ModuleStats := LCoverageStats.CoverageReportByName['Unit1'];
  UnitStats := ModuleStats.CoverageReportByName['Unit1.pas'];
  UnitStats.AddLineCoverage(1, 1);
  UnitStats := ModuleStats.CoverageReportByName['Unit3.pas'];
  UnitStats.AddLineCoverage(5, 1);

  ModuleStats := LCoverageStats.CoverageReportByName['Unit1'];
  UnitStats := ModuleStats.CoverageReportByName['Unit2.pas'];
  UnitStats.AddLineCoverage(4, 1);

  ModuleStats := LCoverageStats.CoverageReportByName['Unit2'];
  UnitStats := ModuleStats.CoverageReportByName['Unit2.pas'];
  UnitStats.AddLineCoverage(3, 1);

  ModuleStats := LCoverageStats.CoverageReportByName['Unit2'];
  UnitStats := ModuleStats.CoverageReportByName['Unit1.pas'];
  UnitStats.AddLineCoverage(2, 1);
  UnitStats.AddLineCoverage(3, 1);

  LCoverageStats.Calculate;

  LNewCoverage := TXMLCoverageReport.MergeCoverageStatsForGenerics(LCoverageStats);
  CheckEquals(3, LNewCoverage.Count);
  CheckEquals(1, LNewCoverage.CoverageReportByName['Unit1'].Count);
  CheckEquals(1, LNewCoverage.CoverageReportByName['Unit2'].Count);
  CheckEquals(1, LNewCoverage.CoverageReportByName['Unit3'].Count);
  CheckEquals(3, LNewCoverage.CoverageReportByName['Unit1'].CoverageReportByName['Unit1.pas'].GetCoverageLineCount);
  CheckEquals(2, LNewCoverage.CoverageReportByName['Unit2'].CoverageReportByName['Unit2.pas'].GetCoverageLineCount);
  CheckEquals(1, LNewCoverage.CoverageReportByName['Unit3'].CoverageReportByName['Unit3.pas'].GetCoverageLineCount);
end;

procedure TestCoverageStatsMerge.OutOfOrderLineKeepsItsOwnCount;
var
  LCoverageStats, UnitStats: ICoverageStats;
begin
  LCoverageStats := TCoverageStats.Create('myFile', nil);

  UnitStats := LCoverageStats.CoverageReportByName['Unit1'].CoverageReportByName['Unit1.pas'];
  UnitStats.AddLineCoverage(20, 5);
  UnitStats.AddLineCoverage(10, 3);

  CheckEquals(2, UnitStats.GetCoverageLineCount);
  CheckEquals(10, UnitStats.CoverageLine[0].LineNumber);
  CheckEquals(3, UnitStats.CoverageLine[0].LineCount, 'Line 10 keeps its own hits');
  CheckEquals(20, UnitStats.CoverageLine[1].LineNumber);
  CheckEquals(5, UnitStats.CoverageLine[1].LineCount, 'Line 20 keeps its hits');
end;

initialization
  RegisterTest(TestCoverageStatsMerge.Suite);
end.

