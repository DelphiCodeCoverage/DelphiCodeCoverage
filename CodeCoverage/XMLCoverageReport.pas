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
    function FormatLinePercentage(const ACoverageStats : ICoverageStats) : string;
    procedure WriteStats(const ACoverageStats : ICoverageStats; const AOutFile: TextFile; const AIndentCount : Integer);
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
  lpModule        : Integer;
  lpUnit          : Integer;
  CoverageUnit    : ICoverageStats;
  CoverageModule  : ICoverageStats;
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
      for lpModule := 0 to Pred(ACoverage.GetCount) do
        SourceFileCount := SourceFileCount + ACoverage.CoverageReport[lpModule].GetCount;

      WriteLn(OutputFile, '  <srcfiles value="' + IntToStr(SourceFileCount) + '"/>');
      WriteLn(OutputFile, '  <srclines value="' + IntToStr(ACoverage.GetNumberOfLines()) + '"/>');
      WriteLn(OutputFile, '</stats>');

      WriteLn(OutputFile, '<data>');
      WriteLn(OutputFile, '  <all name="all classes">');

      WriteStats(ACoverage, OutputFile, 0);

      for lpModule := 0 to Pred(ACoverage.GetCount) do
      begin
        CoverageModule := ACoverage.CoverageReport[lpModule];
        WriteLn(OutputFile, '');
        WriteLn(OutputFile, '    <package name="' + CoverageModule.GetName + '">');
        WriteStats(CoverageModule, OutputFile, 1);

        for lpUnit := 0 to Pred(CoverageModule.GetCount) do
        begin
          CoverageUnit := CoverageModule.CoverageReport[lpUnit];
          WriteLn(OutputFile, '');
          WriteLn(OutputFile, '      <srcfile name="' + CoverageUnit.GetName() + '">');
          WriteStats(CoverageUnit, OutputFile, 2);
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

procedure TXMLCoverageReport.WriteStats(const ACoverageStats: ICoverageStats; 
                                        const AOutFile: TextFile;
                                        const AIndentCount: Integer);
var
  Padding : string;
begin
  Padding := '    ' + StringOfChar(' ', AIndentCount shl 1);
  WriteLn(AOutFile, Padding + '<coverage type="class, %" value="0%   (0/0)"/>');
  WriteLn(AOutFile, Padding + '<coverage type="method, %" value="0%   (0/0)"/>');
  WriteLn(AOutFile, Padding + '<coverage type="block, %" value="0%   (0/0)"/>');
  WriteLn(AOutFile, Padding + '<coverage type="line, %" value="' + FormatLinePercentage(ACoverageStats) + '"/>');
end;


procedure TXMLCoverageReport.AddPreAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '<report>');
end;

function TXMLCoverageReport.FormatLinePercentage(const ACoverageStats: ICoverageStats): string;
var
  PercentageStr : string;
begin
  PercentageStr := IntToStr(ACoverageStats.GetPercentCovered());

  Result := PercentageStr +
            '%' +
            StringOfChar(' ', 4 - Length(PercentageStr)) +
            '(' +
            IntToStr(ACoverageStats.GetNumberOfCoveredLines()) +
            '/' +
            IntToStr(ACoverageStats.GetNumberOfLines()) + ')';
end;

procedure TXMLCoverageReport.AddPostAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '</report>');
end;

end.

