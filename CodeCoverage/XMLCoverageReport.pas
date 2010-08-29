(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit XMLCoverageReport;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_Report,
  I_CoverageStats;

type
  TXMLCoverageReport = class(TInterfacedObject, IReport)
  private
    procedure AddPreAmble(const AOutFile: TextFile);
    procedure AddPostAmble(const AOutFile: TextFile);
    function FormatPercentage(const ACoverageBase : ICoverageStats) : string;
    //procedure GenerateSummaryReport(const ACoverage: ICoverage; const AOutputDir: string);
  public
    procedure Generate(const ACoverage: ICoverageStats; const ASourceDir, AOutputDir: string);
  end;

implementation

uses
  SysUtils,
  JclFileUtils;

procedure TXMLCoverageReport.Generate(const ACoverage: ICoverageStats; const
    ASourceDir, AOutputDir: string);
var
  OutputFileName  : string;
  OutputFile      : TextFile;
  lpUnit          : Integer;
  lpModule        : Integer;
  CoverageModule  : ICoverageStats;
  CoverageUnit    : ICoverageStats;
  SourceFileCount : Integer;
begin
  //GenerateSummaryReport(ACoverage, AOutputDir);
  OutputFileName := 'CodeCoverage_summary.xml';
  OutputFileName := PathAppend(AOutputDir, OutputFileName);

  try
    AssignFile(OutputFile, OutputFileName);
    try
      System.FileMode := fmOpenReadWrite;
      ReWrite(OutputFile);
      AddPreAmble(OutputFile);

      WriteLn(OutputFile, '<stats>');
      WriteLn(OutputFile, '  <packages value="' + IntToStr(ACoverage.GetCount()) + '"/>');
      WriteLn(OutputFile, '  <classes value="0"/>');
      WriteLn(OutputFile, '  <methods value="0"/>');

      SourceFileCount     := 0;
      for lpUnit := 0 to Pred(ACoverage.GetCount) do
        SourceFileCount := SourceFileCount + ACoverage.CoverageReport[lpUnit].GetCount;

      WriteLn(OutputFile, '  <srcfiles value="' + IntToStr(SourceFileCount) + '"/>');
      WriteLn(OutputFile, '  <srclines value="' + IntToStr(ACoverage.GetNumberOfLines()) + '"/>');
      WriteLn(OutputFile, '</stats>');

      WriteLn(OutputFile, '<data>');
      WriteLn(OutputFile, '  <all name="all classes">');

      for lpUnit := 0 to Pred(ACoverage.GetCount) do
      begin
        CoverageUnit := ACoverage.CoverageReport[lpUnit];
        WriteLn(OutputFile, '');
        WriteLn(OutputFile, '    <package name="' + CoverageUnit.GetName + '">');
        WriteLn(OutputFile, '      <coverage type="class, %" value="0%   (0/0)"/>');
        WriteLn(OutputFile, '      <coverage type="method, %" value="0%   (0/0)"/>');
        WriteLn(OutputFile, '      <coverage type="block, %" value="0%   (0/0)"/>');
        WriteLn(OutputFile, '      <coverage type="line, %" value="' + FormatPercentage(CoverageUnit) + '"/>');

        for lpModule := 0 to Pred(CoverageUnit.GetCount) do
        begin
          CoverageModule := CoverageUnit.CoverageReport[lpModule];
          WriteLn(OutputFile, '');
          WriteLn(OutputFile, '      <srcfile name="' + CoverageModule.GetName() + '">');
          WriteLn(OutputFile, '        <coverage type="class, %" value="0%   (0/0)"/>');
          WriteLn(OutputFile, '        <coverage type="method, %" value="0%   (0/0)"/>');
          WriteLn(OutputFile, '        <coverage type="block, %" value="0%   (0/0)"/>');
          WriteLn(OutputFile, '        <coverage type="line, %" value="' + FormatPercentage(CoverageModule) + '"/>');
          WriteLn(OutputFile, '      </srcfile>');
        end;
        WriteLn(OutputFile, '    </package>');
      end;
      WriteLn(OutputFile, '  </all>');
      WriteLn(OutputFile, '</data>');
      AddPostAmble(OutputFile);
    finally
      CloseFile(OutputFile);
    end;
  except
    on E: EInOutError do
      WriteLn('Exception during generation of xml report - exception:' + E.message);
  end;
end;

//procedure TXMLCoverageReport.GenerateSummaryReport(const ACoverage: ICoverage;
//    const AOutputDir: string);
//var
//  OutputFile: TextFile;
//  lp: Integer;
//  OutputFileName: string;
//begin
//  try
//    OutputFileName := 'CodeCoverage_summary.xml';
//    if (AOutputDir <> '') then
//      OutputFileName := PathAppend(AOutputDir, OutputFileName);
//    AssignFile(OutputFile, OutputFileName);
//    rewrite(OutputFile);
//    AddPreAmble(OutputFile);
//
//    WriteLn(OutputFile, '<stats>');
//    WriteLn(OutputFile, '  <packages value="' + IntToStr(ACoverage.getUnitCount()) + '"/>');
//    WriteLn(OutputFile, '  <classes value="0"/>');
//    WriteLn(OutputFile, '  <methods value="0"/>');
//    WriteLn(OutputFile, '  <srcfiles value="' + IntToStr(ACoverage.getUnitCount()) + '"/>');
//    WriteLn(OutputFile, '  <srclines value="' + IntToStr(ACoverage.GetNumberOfLines()) + '"/>');
//    WriteLn(OutputFile, '</stats>');
//
//    WriteLn(OutputFile, '<data>');
//    WriteLn(OutputFile, '  <all name="all classes">');
//
//    for lp := 0 to ACoverage.getUnitCount - 1 do
//    begin
//      WriteLn(OutputFile, '    <package name="' + ACoverage.CoverageModule[lp].GetModuleName + '">');
//      WriteLn(OutputFile, '      <coverage type="class, %" value="0% (0/0)"/>');
//      WriteLn(OutputFile, '      <coverage type="method, %" value="0% (0/0)"/>');
//      WriteLn(OutputFile, '      <coverage type="block, %" value="0% (0/0)"/>');
//      WriteLn(OutputFile, '      <coverage type="line, %" value="' + IntToStr(ACoverage.CoverageModule[lp].GetPercentCovered())
//          + '% (' + IntToStr(ACoverage.CoverageModule[lp].GetNumberOfCoveredLines()) + '/' + IntToStr
//          (ACoverage.CoverageModule[lp].GetNumberOfLines()) + ')"/>');
//
//      WriteLn(OutputFile, '      <srcfile name="' + ACoverage.CoverageModule[lp].GetModuleName + '.pas">');
//      WriteLn(OutputFile, '        <coverage type="class, %" value="0% (0/0)"/>');
//      WriteLn(OutputFile, '        <coverage type="method, %" value="0% (0/0)"/>');
//      WriteLn(OutputFile, '        <coverage type="block, %" value="0% (0/0)"/>');
//      WriteLn(OutputFile, '        <coverage type="line, %" value="' + IntToStr(ACoverage.CoverageModule[lp].GetPercentCovered())
//          + '% (' + IntToStr(ACoverage.CoverageModule[lp].GetNumberOfCoveredLines()) + '/' + IntToStr
//          (ACoverage.CoverageModule[lp].GetNumberOfLines()) + ')"/>');
//      WriteLn(OutputFile, '      </srcfile>');
//      WriteLn(OutputFile, '    </package>');
//    end;
//    WriteLn(OutputFile, '  </all>');
//    WriteLn(OutputFile, '</data>');
//    AddPostAmble(OutputFile);
//    CloseFile(OutputFile);
//  except
//    on E: EInOutError do
//      WriteLn('Exception during generation of xml report - exception:' + E.message);
//  end;
//end;

procedure TXMLCoverageReport.AddPreAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '<report>');
end;

function TXMLCoverageReport.FormatPercentage(
  const ACoverageBase: ICoverageStats): string;
var
  PercentageStr : string;
begin
  PercentageStr := IntToStr(ACoverageBase.GetPercentCovered());

  Result := PercentageStr +
            '%' +
            StringOfChar(' ', 4 - Length(PercentageStr)) +
            '(' +
            IntToStr(ACoverageBase.GetNumberOfCoveredLines()) +
            '/' +
            IntToStr(ACoverageBase.GetNumberOfLines()) + ')';
end;

procedure TXMLCoverageReport.AddPostAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '</report>');
end;

end.

