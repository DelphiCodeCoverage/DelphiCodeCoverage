unit CoverageStatsMergeTests;

interface

uses
  TestFramework;

type
  TestCoverageStatsMerge = class(TTestCase)
  published
    procedure MergeMultipleOutputForSingleFile;
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

initialization
  RegisterTest(TestCoverageStatsMerge.Suite);
end.

