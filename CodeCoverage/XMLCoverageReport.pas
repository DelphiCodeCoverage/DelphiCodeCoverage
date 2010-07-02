unit XMLCoverageReport;

interface

uses CoverageResult;

type
  TXMLCoverageReport = class
  public
    procedure generate(coverage: TCoverage; sourcedir: string; outputdir: string);
    procedure generateSummaryReport(coverage: TCoverage; outputdir: string);
  private
    procedure AddPreAmble(var outfile: TextFile);
    procedure AddPostAmble(var outfile: TextFile);
  end;

implementation

uses sysutils, strutils, jclfileutils;

procedure TXMLCoverageReport.generate(coverage: TCoverage; sourcedir: string; outputdir: string);
begin
  generateSummaryReport(coverage, outputdir);
end;

procedure TXMLCoverageReport.generateSummaryReport(coverage: TCoverage; outputdir: string);
var
  OutputFile: TextFile;
  i: Integer;
  outputFileName: string;
begin
  try
    outputFileName := 'CodeCoverage_summary.xml';
    if (outputdir <> '') then
      outputFileName := PathAppend(outputdir, outputFileName);
    AssignFile(OutputFile, outputFileName);
    rewrite(OutputFile);
    AddPreAmble(OutputFile);

    writeln(OutputFile, '<stats>');
    writeln(OutputFile, '  <packages value="' + inttostr(coverage.getUnitCount()) + '"/>');
    writeln(OutputFile, '  <classes value="0"/>');
    writeln(OutputFile, '  <methods value="0"/>');
    writeln(OutputFile, '  <srcfiles value="' + inttostr(coverage.getUnitCount()) + '"/>');
    writeln(OutputFile, '  <srclines value="' + inttostr(coverage.GetNumberOfLines()) + '"/>');
    writeln(OutputFile, '</stats>');

    writeln(OutputFile, '<data>');
    writeln(OutputFile, '  <all name="all classes">');

    for i := 0 to coverage.getUnitCount - 1 do
    begin
      writeln(OutputFile, '    <package name="' + coverage.CoverageUnit[i].GetName + '">');
      writeln(OutputFile, '      <coverage type="class, %" value="0% (0/0)"/>');
      writeln(OutputFile, '      <coverage type="method, %" value="0% (0/0)"/>');
      writeln(OutputFile, '      <coverage type="block, %" value="0% (0/0)"/>');
      writeln(OutputFile, '      <coverage type="line, %" value="' + inttostr(coverage.CoverageUnit[i].GetPercentCovered())
          + '% (' + inttostr(coverage.CoverageUnit[i].GetNumberOfCoveredLines()) + '/' + inttostr
          (coverage.CoverageUnit[i].GetNumberOfLines()) + ')"/>');

      writeln(OutputFile, '      <srcfile name="' + coverage.CoverageUnit[i].GetName + '.pas">');
      writeln(OutputFile, '        <coverage type="class, %" value="0% (0/0)"/>');
      writeln(OutputFile, '        <coverage type="method, %" value="0% (0/0)"/>');
      writeln(OutputFile, '        <coverage type="block, %" value="0% (0/0)"/>');
      writeln(OutputFile, '        <coverage type="line, %" value="' + inttostr(coverage.CoverageUnit[i].GetPercentCovered())
          + '% (' + inttostr(coverage.CoverageUnit[i].GetNumberOfCoveredLines()) + '/' + inttostr
          (coverage.CoverageUnit[i].GetNumberOfLines()) + ')"/>');
      writeln(OutputFile, '      </srcfile>');
      writeln(OutputFile, '    </package>');
    end;
    writeln(OutputFile, '  </all>');
    writeln(OutputFile, '</data>');
    AddPostAmble(OutputFile);
    CloseFile(OutputFile);
  except
    on E: EInOutError do
      writeln('Exception during generation of xml report - exception:' + E.message);
  end;
end;

procedure TXMLCoverageReport.AddPreAmble(var outfile: TextFile);
begin
  writeln(outfile, '<report>');
end;

procedure TXMLCoverageReport.AddPostAmble(var outfile: TextFile);
begin
  writeln(outfile, '</report>');
end;

end.
