(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit CoverageReport;

interface

uses CoverageResult;

type
  TCoverageReport = class
  public
    procedure generate(coverage: TCoverage; sourcedir: string; outputdir: string);
    procedure generateUnitReport(unitcoverage: TUnitCoverage; sourcedir: string; outputdir: string);
    procedure generateSummaryReport(coverage: TCoverage; outputdir: string);
  private
    procedure AddPreAmble(var outfile: TextFile);
    procedure AddPostAmble(var outfile: TextFile);
    procedure AddStatistics(var outfile: TextFile; unitcoverage: TUnitCoverage);
    procedure GenerateCoverageTable(var OutputFile: TextFile; unitcoverage: TUnitCoverage; var InputFile: TextFile);
  end;

implementation

uses sysutils, strutils, jclfileutils;

procedure TCoverageReport.generate(coverage: TCoverage; sourcedir: string; outputdir: string);
var
  i: Integer;
begin
  for i := 0 to coverage.getUnitCount - 1 do
  begin
    generateUnitReport(coverage.CoverageUnit[i], sourcedir, outputdir);
  end;
  generateSummaryReport(coverage, outputdir);
end;

procedure TCoverageReport.generateSummaryReport(coverage: TCoverage; outputdir: string);
var
  InputFile: TextFile;
  OutputFile: TextFile;
  i: Integer;
  outputFileName: string;
begin
  outputFileName := 'CodeCoverage_summary.html';
  if (outputdir <> '') then
    outputFileName := PathAppend(outputdir, outputFileName);
  AssignFile(OutputFile, outputFileName);
  rewrite(OutputFile);
  AddPreAmble(OutputFile);
  writeln(OutputFile, '<h1> Summary Coverage report</h1>');
  writeln(OutputFile, '<p> Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
      ' by DelphiCodeCoverage - an open source tool for Delphi Code Coverage.</p>');

  writeln(OutputFile, '<p> Aggregate statistics for all units</p>');
  writeln(OutputFile, '<table>');
  writeln(OutputFile, '  <tr>');
  writeln(OutputFile, '    <td >Unit Name</td>');
  writeln(OutputFile, '    <td >Number of lines (which generated code)</td>');
  writeln(OutputFile, '    <td >Number of covered lines</td>');
  writeln(OutputFile, '    <td >Percent covered</td>');
  writeln(OutputFile, '  </tr>');
  for i := 0 to coverage.getUnitCount - 1 do
  begin
    writeln(OutputFile, '  <tr>');
    writeln(OutputFile, '    <td ><a href ="' + coverage.CoverageUnit[i].GetName + '.html">' + coverage.CoverageUnit[i]
        .GetName + '</A></td>');
    writeln(OutputFile, '    <td >' + IntTostr(coverage.CoverageUnit[i].GetNumberOfLines()) + '</td>');
    writeln(OutputFile, '    <td >' + IntTostr(coverage.CoverageUnit[i].GetNumberOfCoveredLines()) + '</td>');
    writeln(OutputFile, '    <td >' + IntTostr(coverage.CoverageUnit[i].GetPercentCovered()) + '</td>');
    writeln(OutputFile, '  </tr>');
  end;
  writeln(OutputFile, '  <tr>');
  writeln(OutputFile, '  <tr>');
  writeln(OutputFile, '    <td class="h" >Aggregated for all units</td>');
  writeln(OutputFile, '    <td class="h">' + IntTostr(coverage.GetNumberOfLines()) + '</td>');
  writeln(OutputFile, '    <td class="h">' + IntTostr(coverage.GetNumberOfCoveredLines()) + '</td>');
  writeln(OutputFile, '    <td class="h">' + IntTostr(coverage.GetPercentCovered()) + '</td>');
  writeln(OutputFile, '  </tr>');
  writeln(OutputFile, '</table>');
  AddPostAmble(OutputFile);
  CloseFile(OutputFile);
end;

procedure TCoverageReport.generateUnitReport(unitcoverage: TUnitCoverage; sourcedir: string; outputdir: string);
var
  InputFile: TextFile;
  OutputFile: TextFile;
  sourceFilename: string;
  outputFileName: string;
begin
  sourceFilename := unitcoverage.GetName + '.pas';
  if sourcedir <> '' then
    sourceFilename := PathAppend(sourcedir, sourceFilename);
  AssignFile(InputFile, sourceFilename);

  outputFileName := unitcoverage.GetName + '.html';
  if (outputdir <> '') then
    outputFileName := PathAppend(outputdir, outputFileName);

  AssignFile(OutputFile, outputFileName);
  Reset(InputFile);
  rewrite(OutputFile);
  AddPreAmble(OutputFile);
  writeln(OutputFile, '<p> Coverage report for <strong>' + unitcoverage.GetName + '</strong>.</p>');
  writeln(OutputFile, '<p> Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
      ' by DelphiCodeCoverage - an open source tool for Delphi Code Coverage.</p>');
  AddStatistics(OutputFile, unitcoverage);
  GenerateCoverageTable(OutputFile, unitcoverage, InputFile);
  AddPostAmble(OutputFile);
  CloseFile(InputFile);
  CloseFile(OutputFile);
end;

procedure TCoverageReport.AddPreAmble(var outfile: TextFile);
begin
  writeln(outfile, '<html><head><meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />');
  writeln(outfile,
    '<title>Delphi CodeCoverage Coverage Report</title> <style type="text/css"> TABLE, TD, TH {border-style: solid;border-color: black;}');
  writeln(outfile,
    'TD, TH { background: white; margin: 0; line-height: 100%; padding-left: 0.5em; padding-right: 0.5em;}');
  writeln(outfile, 'TD { border-width: 0 1px 0 0;} TH { border-width: 1px 1px 1px 0; }');
  writeln(outfile, 'P, H1, H2, H3, TH { font-family: verdana,arial,sans-serif; font-size: 10pt;}');
  writeln(outfile, 'TD { font-family: courier,monospace; font-size: 10pt;}');
  writeln(outfile, 'TABLE.s TD {padding-left: 0.25em; padding-right: 0.25em; }');
  writeln(outfile, 'TABLE.s TR.notcovered TD { background: #FF9999; }');
  writeln(outfile, 'TABLE.s TR.nocodegen TD { background: #FFFFEE; }');
  writeln(outfile, 'TABLE.s TR.covered TD { background: #CCFFCC; }');
  writeln(outfile, 'TABLE.s {border-width: 1px 0 1px 1px; }');
  writeln(outfile, '    </style></head>');
  writeln(outfile, '<body>');

end;

procedure TCoverageReport.AddPostAmble(var outfile: TextFile);
begin
  writeln(outfile, '</body></html>');
end;

procedure TCoverageReport.AddStatistics(var outfile: Text; unitcoverage: TUnitCoverage);
begin
  writeln(outfile, '<p> Statistics for ' + unitcoverage.GetName + ' </p>');

  writeln(outfile, '<table class="s" cellspacing="0">');
  writeln(outfile, '  <tr>');
  writeln(outfile, '    <td >Number of lines with code gen</td');
  writeln(outfile, '    <td>' + IntTostr(unitcoverage.GetNumberOfLines()) + '</td');
  writeln(outfile, '  </tr>');

  writeln(outfile, '  <tr>');
  writeln(outfile, '    <td >Number of lines covered</td');
  writeln(outfile, '    <td>' + IntTostr(unitcoverage.GetNumberOfCoveredLines()) + '</td');
  writeln(outfile, '  </tr>');
  writeln(outfile, '  <tr>');
  writeln(outfile, '    <td >Line coverage in percent</td');
  writeln(outfile, '    <td>' + IntTostr(unitcoverage.GetPercentCovered()) + '</td');
  writeln(outfile, '  </tr>');
  writeln(outfile, '</table>');

  writeln(outfile, '<br><br>');

end;

procedure TCoverageReport.GenerateCoverageTable(var OutputFile: TextFile; unitcoverage: TUnitCoverage;
  var InputFile: TextFile);
var
  linecoverage: TLineCoverage;
  inputline: string;
  linecoverageiter: Integer;
  linecount: Integer;
begin
  linecoverageiter := 0;
  linecount := 0;
  writeln(OutputFile, '   <table class="s" width="100%" cellspacing="0">');
  linecount := 1;
  while (not(eof(InputFile))) do
  begin
    ReadLn(InputFile, inputline);
    linecoverage := unitcoverage.GetLinecoverage(linecoverageiter);
    if (linecount = linecoverage.line) then
    begin
      if (linecoverage.covered) then
      begin
        writeln(OutputFile, '  <tr class="covered">');
        writeln(OutputFile, '    <td class="1">' + IntTostr(linecount) + '</td>');
        writeln(OutputFile, '    <td><pre>' + TrimRight(inputline) + '</pre></td>');
        writeln(OutputFile, '  </tr>');
      end
      else
      begin
        writeln(OutputFile, '  <tr class="notcovered">');
        writeln(OutputFile, '    <td class="1">' + IntTostr(linecount) + '</td>');
        writeln(OutputFile, '    <td><pre>' + TrimRight(inputline) + '</pre></td>');
        writeln(OutputFile, '  </tr>');
      end;
      inc(linecoverageiter);
    end
    else
    begin
      writeln(OutputFile, '  <tr class="nocodegen">');
      writeln(OutputFile, '    <td class="1">' + IntTostr(linecount) + '</td>');
      writeln(OutputFile, '    <td><pre>' + TrimRight(inputline) + '</pre></td>');
      writeln(OutputFile, '  </tr>');
    end;
    inc(linecount);
  end;
  writeln(OutputFile, '</table>');
end;

end.
