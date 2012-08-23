(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit CoverageReport;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_Report,
  I_CoverageStats,
  I_CoverageConfiguration,
  ClassInfoUnit, I_LogManager;

type
  THtmlDetails = record
    LinkFileName : string;
    LinkName     : string;
    HasFile      : Boolean;
  end;

type
  TCoverageStatsProc = function(const ACoverageModule: ICoverageStats): THtmlDetails of object;

type
  TCoverageReport = class(TInterfacedObject, IReport)
  private
    FCoverageConfiguration : ICoverageConfiguration;

    procedure AddTableHeader(const ATableHeading : string;
                             const AColumnHeading : string;
                             const AOutputFile : TextFile);

    procedure AddTableFooter(const AHeading : string;
                             const ACoverageStats : ICoverageStats;
                             const AOutputFile : TextFile);

    procedure IterateOverStats(const ACoverageStats : ICoverageStats;
                               const AOutputFile : TextFile;
                               const ACoverageStatsProc : TCoverageStatsProc);

    procedure SetPrePostLink(const AHtmlDetails : THtmlDetails;
                             out PreLink : string;
                             out PostLink : string);

    procedure AddPostAmble(const AOutFile: TextFile);
    procedure AddPreAmble(const AOutFile: TextFile);

    function FindSourceFile(const ACoverageUnit: ICoverageStats;
                            var HtmlDetails: THtmlDetails): string;

    procedure AddStatistics(const ACoverageBase: ICoverageStats;
                            const ASourceFileName: string;
                            const AOutFile: TextFile);

    procedure GenerateCoverageTable(const ACoverageModule: ICoverageStats;
                                    const AOutputFile : TextFile;
                                    const AInputFile: TextFile);

    function GenerateModuleReport(const ACoverageModule: ICoverageStats): THtmlDetails;

    function GenerateUnitReport(const ACoverageUnit: ICoverageStats): THtmlDetails;
  public
    constructor Create(const ACoverageConfiguration : ICoverageConfiguration);

    procedure Generate(const ACoverage: ICoverageStats;const AModuleInfoList: TModuleList; logMgr: ILogManager);
  end;

var
  ParagraphStartTag : string = '<p>';
  ParagraphEndTag  : string = '</p>';
  HeadingStartTagOne : string = '<h1>';
  HeadingEndTagOne : string = '</h1>';
  BoldStartTag : string = '<strong>';
  BoldEndTag  : string = '</strong>';
  TDStartTagOne : string = '<td>';
  TDEndTagOne : string = '</td>';
  TRStartTagOne : string = '<tr>';
  TREndTagOne : string = '</tr>';

implementation

uses
  SysUtils,
  JclFileUtils,
  JvStrToHtml;

procedure TCoverageReport.Generate(const ACoverage: ICoverageStats;const AModuleInfoList: TModuleList; logMgr: ILogManager);
var
  OutputFile     : TextFile;
  OutputFileName : string;
begin
  logMgr.Log('Generating coverage report');
  if (FCoverageConfiguration.GetSourcePaths.Count > 0) then
    WriteLn('Source dir:' + FCoverageConfiguration.GetSourcePaths.Strings[0])
  else
    WriteLn('Source dir:<none>');

  WriteLn('Output dir:' + FCoverageConfiguration.GetOutputDir);

  OutputFileName := 'CodeCoverage_summary.html';
  OutputFileName := PathAppend(FCoverageConfiguration.GetOutputDir, OutputFileName);
  AssignFile(OutputFile, OutputFileName);
  try
    System.FileMode := fmOpenReadWrite;
    ReWrite(OutputFile);
    AddPreAmble(OutputFile);
    WriteLn(OutputFile, '    ' + HeadingStartTagOne + ' Summary Coverage Report' + HeadingEndTagOne);
    WriteLn(OutputFile, '    ' + ParagraphStartTag + ' Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
        ' by <a href="http://code.google.com/p/delphi-code-coverage/" title="Code Coverage for Delphi 5+" />DelphiCodeCoverage</a> - an open source tool for Delphi Code Coverage.' + ParagraphEndTag);

    AddTableHeader('Aggregate statistics for all modules', 'Unit Name', OutputFile);

    IterateOverStats(ACoverage, OutputFile, GenerateModuleReport);

    AddTableFooter('Aggregated for all units', ACoverage, OutputFile);

    AddPostAmble(OutputFile);
  finally
    CloseFile(OutputFile);
  end;
end;

function TCoverageReport.GenerateModuleReport(const ACoverageModule: ICoverageStats): THtmlDetails;
var
  OutputFile     : TextFile;
  OutputFileName : string;
begin
  if (ACoverageModule.GetCount = 1) then
  begin
    Result          := GenerateUnitReport(ACoverageModule.CoverageReport[0]);
    Result.LinkName := ACoverageModule.GetName;
    Exit;
  end;

  try
    Result.HasFile      := False;
    Result.LinkFileName := ACoverageModule.GetName + '.html';
    Result.LinkName     := ACoverageModule.GetName;

    OutputFileName := PathAppend(FCoverageConfiguration.GetOutputDir, Result.LinkFileName);

    AssignFile(OutputFile, OutputFileName);
    try
      try
        System.FileMode := fmOpenReadWrite;
        ReWrite(OutputFile);
      except
        on E: EInOutError do
        begin
          WriteLn('Exception during generation of unit coverage for:' + ACoverageModule.GetName()
              + ' could not write to:' + OutputFileName);
          WriteLn('Current directory:' + GetCurrentDir());
          raise ;
        end;
      end;
      AddPreAmble(OutputFile);
      WriteLn(OutputFile, '    ' + ParagraphStartTag + ' Coverage report for ' + BoldStartTag + ACoverageModule.GetName() + BoldeNDTag + '.' + ParagraphEndTag);
      WriteLn(OutputFile, '    ' + ParagraphStartTag + ' Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
          ' by <a href="http://code.google.com/p/delphi-code-coverage/" title="Code Coverage for Delphi 5+" />DelphiCodeCoverage</a> - an open source tool for Delphi Code Coverage.' + ParagraphEndTag);

      AddTableHeader('Aggregate statistics for all units', 'Source File Name', OutputFile);

      IterateOverStats(ACoverageModule, OutputFile, GenerateUnitReport);

      AddTableFooter('Aggregated for all files', ACoverageModule, OutputFile);

      AddPostAmble(OutputFile);
    finally
      CloseFile(OutputFile);
    end;
    Result.HasFile      := True;
  except
    on E: EInOutError do
      WriteLn('Exception during generation of unit coverage for:' + ACoverageModule.GetName() + ' exception:' + E.message)
    else
      raise;
  end;
end;

function TCoverageReport.GenerateUnitReport(const ACoverageUnit: ICoverageStats): THtmlDetails;
var
  InputFile      : TextFile;
  OutputFile     : TextFile;
  SourceFileName : string;
  OutputFileName : string;
begin
  Result.HasFile      := False;
  Result.LinkFileName := ACoverageUnit.GetReportFileName + '.html';
  Result.LinkName     := ACoverageUnit.GetName();

  if FCoverageConfiguration.GetExcludedUnits.IndexOf(StringReplace(ExtractFileName(ACoverageUnit.GetName), ExtractFileExt(ACoverageUnit.GetName), '', [rfReplaceAll, rfIgnoreCase])) < 0 then
  try
    SourceFileName := FindSourceFile(ACoverageUnit, Result);

    AssignFile(InputFile, SourceFileName);
    try
      try
        System.FileMode := fmOpenRead;
        Reset(InputFile);
      except
        on E: EInOutError do
        begin
          WriteLn('Exception during generation of unit coverage for:' + ACoverageUnit.GetName()
              + ' could not open:' + SourceFileName);
          WriteLn('Current directory:' + GetCurrentDir());
          raise ;
        end;
      end;
      OutputFileName := Result.LinkFileName;
      OutputFileName := PathAppend(FCoverageConfiguration.GetOutputDir, OutputFileName);

      AssignFile(OutputFile, OutputFileName);
      try
        try
          System.FileMode := fmOpenReadWrite;
          ReWrite(OutputFile);
        except
          on E: EInOutError do
          begin
            WriteLn('Exception during generation of unit coverage for:' + ACoverageUnit.GetName()
                + ' could not write to:' + OutputFileName);
            WriteLn('Current directory:' + GetCurrentDir());
            raise ;
          end;
        end;
        AddPreAmble(OutputFile);
        WriteLn(OutputFile, '    ' + ParagraphStartTag + ' Coverage report for ' + BoldStartTag +
                            ACoverageUnit.Parent.GetName() +
                            ' (' + SourceFileName + ')' + BoldEndTag + 
                            '.' + ParagraphEndTag);
        WriteLn(OutputFile, '    ' + ParagraphStartTag + ' Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
            ' by <a href="http://code.google.com/p/delphi-code-coverage/" title="Code Coverage for Delphi 5+" />DelphiCodeCoverage</a> - an open source tool for Delphi Code Coverage.' + ParagraphEndTag);
        AddStatistics(ACoverageUnit, SourceFileName, OutputFile);
        GenerateCoverageTable(ACoverageUnit, OutputFile, InputFile);
        AddPostAmble(OutputFile);
      finally
        CloseFile(OutputFile);
      end;
      Result.HasFile      := True;
    finally
      CloseFile(InputFile);
    end;
  except
    on E: EInOutError do
      WriteLn('Exception during generation of unit coverage for:' + ACoverageUnit.GetName() + ' exception:' + E.message)
    else
      raise;
  end;
end;

procedure TCoverageReport.IterateOverStats(const ACoverageStats: ICoverageStats;
                                           const AOutputFile : TextFile;
                                           const ACoverageStatsProc: TCoverageStatsProc);
var
  lp : Integer;
  HtmlDetails : THtmlDetails;
  PostLink: string;
  PreLink: string;
begin
  for lp := 0 to Pred(ACoverageStats.GetCount) do
  begin
    WriteLn(AOutputFile, '      <tr>');

    HtmlDetails.HasFile := False;
    if Assigned(ACoverageStatsProc) then
      HtmlDetails := ACoverageStatsProc(ACoverageStats.CoverageReport[lp]);

    SetPrePostLink(HtmlDetails, PreLink, PostLink);

    WriteLn(AOutputFile, '        <td>' + PreLink + HtmlDetails.LinkName + PostLink + '</td>');
    WriteLn(AOutputFile, '        <td style="text-align:right;">' + IntToStr(ACoverageStats.CoverageReport[lp].GetNumberOfCoveredLines()) + '</td>');
    WriteLn(AOutputFile, '        <td style="text-align:right;">' + IntToStr(ACoverageStats.CoverageReport[lp].GetNumberOfLines()) + '</td>');
    WriteLn(AOutputFile, '        <td style="text-align:right;"><em>' + IntToStr(ACoverageStats.CoverageReport[lp].GetPercentCovered()) + '%</em></td>');
    WriteLn(AOutputFile, '      </tr>');
  end;
end;

procedure TCoverageReport.SetPrePostLink(const AHtmlDetails: THtmlDetails;
                                         out PreLink: string;
                                         out PostLink: string);
var
  LLinkFileName : string;
begin
  PreLink  := '';
  PostLink := '';
  if AHtmlDetails.HasFile then
  begin
    LLinkFileName := StringReplace(AHtmlDetails.LinkFileName, '\', '/', [rfReplaceAll]);
    PreLink := '<a href="' + LLinkFileName + '">';
    PostLink := '</a>';
  end;
end;

procedure TCoverageReport.AddPreAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '<!DOCTYPE html>');
  WriteLn(AOutFile, '<html>');
  WriteLn(AOutFile, '  <head>');
  WriteLn(AOutFile, '    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />');
  WriteLn(AOutFile, '    <title>Delphi CodeCoverage Coverage Report</title>');
  if FileExists('style.css') then
    WriteLn(AOutFile, '    <link rel="stylesheet" href="style.css" type="text/css" /></HEAD>')
  else
  begin
    WriteLn(AOutFile, '    <style type="text/css">');
    Writeln(AOutFile, '      table {border-spacing:0; border-collapse:collapse;}');
    WriteLn(AOutFile, '      table, td, th {border-style: solid;border-color: black;}');
    WriteLn(AOutFile, '      td, th {background: white; margin: 0; line-height: 100%; padding-left: 0.5em; padding-right: 0.5em;}');
    WriteLn(AOutFile, '      td {border-width: 0 1px 0 0;}');
    WriteLn(AOutFile, '      th {border-width: 1px 1px 1px 0;}');
    WriteLn(AOutFile, '      p, h1, h2, h3, th {font-family: verdana,arial,sans-serif; font-size: 10pt;}');
    WriteLn(AOutFile, '      td {font-family: courier,monospace; font-size: 10pt;}');
    WriteLn(AOutFile, '      table.s td {padding-left: 0.25em; padding-right: 0.25em;}');
    WriteLn(AOutFile, '      table.s tr.notcovered td {background: #DDDDFF;}');
    WriteLn(AOutFile, '      table.s tr.nocodegen td {background: #FFFFEE;}');
    WriteLn(AOutFile, '      table.s tr.covered td {background: #CCFFCC;}');
    WriteLn(AOutFile, '      table.s {border-width: 1px 0 1px 1px;}');
    WriteLn(AOutFile, '      tr:nth-child(even) td {background: #CCCCCC;}');
	  WriteLn(AOutFile, '    </style>');
    WriteLn(AOutFile, '  </head>');
  end;	
  WriteLn(AOutFile, '  <body>');
end;

procedure TCoverageReport.AddPostAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, ' </body>');
  WriteLn(AOutFile, '</html>');
end;

procedure TCoverageReport.AddStatistics(const ACoverageBase: ICoverageStats;
                                        const ASourceFileName: string;
										const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '    ' + ParagraphStartTag + ' Statistics for ' + ASourceFileName + ' ' + ParagraphEndTag);

  WriteLn(AOutFile, '    <table class="s">');
  WriteLn(AOutFile, '      <tr>');
  WriteLn(AOutFile, '        <td>Number of lines covered</td>');
  WriteLn(AOutFile, '        <td style="text-align:right;">' + IntToStr(ACoverageBase.GetNumberOfCoveredLines()) + '</td>');
  WriteLn(AOutFile, '      </tr>');
  WriteLn(AOutFile, '      <tr>');
  WriteLn(AOutFile, '        <td>Number of lines with code gen</td>');
  WriteLn(AOutFile, '        <td style="text-align:right;">' + IntToStr(ACoverageBase.GetNumberOfLines()) + '</td>');
  WriteLn(AOutFile, '      </tr>');
  WriteLn(AOutFile, '      <tr>');
  WriteLn(AOutFile, '        <td>Line coverage in <i>percent</i></td>');
  WriteLn(AOutFile, '        <td style="text-align:right;">' + IntToStr(ACoverageBase.GetPercentCovered()) + '%</td>');
  WriteLn(AOutFile, '      </tr>');
  WriteLn(AOutFile, '    </table>');

  WriteLn(AOutFile, '    <br /><br />');
end;

procedure TCoverageReport.AddTableFooter(const AHeading: string;
                                         const ACoverageStats: ICoverageStats;
                                         const AOutputFile: TextFile);
begin
  WriteLn(AOutputFile, '      <tr>');
  WriteLn(AOutputFile, '        <th class="h">' + JvStrToHtml.StringToHtml(AHeading) + '</td>');
  WriteLn(AOutputFile, '        <th style="text-align:right;" class="h">' + IntToStr(ACoverageStats.GetNumberOfCoveredLines()) + '</td>');
  WriteLn(AOutputFile, '        <th style="text-align:right;" class="h">' + IntToStr(ACoverageStats.GetNumberOfLines()) + '</td>');
  WriteLn(AOutputFile, '        <th style="text-align:right;" class="h"><em>' + IntToStr(ACoverageStats.GetPercentCovered()) + '%</em></td>');
  WriteLn(AOutputFile, '      </tr>');
  WriteLn(AOutputFile, '    </table>');
end;

procedure TCoverageReport.AddTableHeader(const ATableHeading: string;
                                         const AColumnHeading: string;
                                         const AOutputFile: TextFile);
begin
  WriteLn(AOutputFile, '    ' + ParagraphStartTag + JvStrToHtml.StringToHtml(ATableHeading) + ParagraphEndTag);
  WriteLn(AOutputFile, '    <table>');
  WriteLn(AOutputFile, '      <tr>');
  WriteLn(AOutputFile, '        <th>' + JvStrToHtml.StringToHtml(AColumnHeading) + '</td>');
  WriteLn(AOutputFile, '        <th>Number of covered lines</td>');
  WriteLn(AOutputFile, '        <th>Number of lines (which generated code)</td>');
  WriteLn(AOutputFile, '        <th>Percent(s) covered</td>');
  WriteLn(AOutputFile, '      </tr>');
end;

constructor TCoverageReport.Create(
  const ACoverageConfiguration: ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

function TCoverageReport.FindSourceFile(const ACoverageUnit: ICoverageStats;
                                        var HtmlDetails: THtmlDetails): string;
var
  SourceFound     : Boolean;
  CrntSourcePath  : string;
  lpLst           : Integer;
  lpUnit          : Integer;
  ACoverageModule : ICoverageStats;
begin
  SourceFound := False;

  lpLst := 0;
  while (lpLst < FCoverageConfiguration.GetSourcePaths.Count) and
        (not SourceFound) do
  begin
    CrntSourcePath := FCoverageConfiguration.GetSourcePaths.Strings[lpLst];

    Result := PathAppend(CrntSourcePath, ACoverageUnit.GetName());

    if not FileExists(Result) then
    begin
      ACoverageModule := ACoverageUnit.Parent;

      lpUnit := 0;
      while (lpUnit < ACoverageModule.GetCount) and
            (not SourceFound) do
      begin
        Result := PathAppend(PathAppend(CrntSourcePath, ExtractFilePath(ACoverageModule.CoverageReport[lpUnit].GetName)), ACoverageUnit.GetName());

        if FileExists(Result) then
        begin
          HtmlDetails.LinkName := PathAppend(ExtractFilePath(ACoverageModule.CoverageReport[lpUnit].GetName), HtmlDetails.LinkName);
          SourceFound := True;
        end;

        Inc(lpUnit, 1);
      end;
    end
    else
      SourceFound := True;

    inc(lpLst, 1);
  end;

  if (not SourceFound) then
    Result := ACoverageUnit.GetName();
end;

procedure TCoverageReport.GenerateCoverageTable(const ACoverageModule: ICoverageStats;
                                                const AOutputFile: TextFile;
                                                const AInputFile: TextFile);
var
  LineCoverage     : TCoverageLine;
  InputLine        : string;
  LineCoverageIter : Integer;
  LineCount        : Integer;
begin
  LineCoverageIter := 0;
  WriteLn(AOutputFile, '    <table class="s" width="100%" cellspacing="0">');
  LineCount := 1;
  while (not Eof(AInputFile)) do
  begin
    ReadLn(AInputFile, InputLine);
    InputLine := JvStrToHtml.StringToHtml(TrimRight(InputLine));
    LineCoverage := ACoverageModule.GetCoverageLine(LineCoverageIter);
    if (LineCount = LineCoverage.LineNumber) then
    begin
      if (LineCoverage.Covered) then
      begin
        WriteLn(AOutputFile, '      <tr class="covered">');
        WriteLn(AOutputFile, '        <td style="text-align:right;color:green;" class="1">' + BoldStartTag + IntToStr(LineCount) + BoldEndTag + '</td>');
        WriteLn(AOutputFile, '        <td><pre style="display: inline">' + InputLine + '</pre></td>');
        WriteLn(AOutputFile, '      </tr>');
      end
      else
      begin
        WriteLn(AOutputFile, '      <tr class="notcovered">');
        WriteLn(AOutputFile, '        <td style="text-align:right;" class="1">' + IntToStr(LineCount) + '</td>');
        WriteLn(AOutputFile, '        <td><pre style="display: inline">' + InputLine + '</pre></td>');
        WriteLn(AOutputFile, '      </tr>');
      end;
      inc(LineCoverageIter);
    end
    else
    begin
      WriteLn(AOutputFile, '      <tr class="nocodegen">');
      WriteLn(AOutputFile, '        <td style="text-align:right;" class="1">' + IntToStr(LineCount) + '</td>');
      WriteLn(AOutputFile, '        <td><pre style="display: inline">' + InputLine + '</pre></td>');
      WriteLn(AOutputFile, '      </tr>');
    end;
    inc(LineCount);
  end;
  WriteLn(AOutputFile, '    </table>');
end;

end.

