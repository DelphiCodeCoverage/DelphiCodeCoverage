(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit HTMLCoverageReport;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  I_Report,
  I_CoverageStats,
  I_CoverageConfiguration,
  ClassInfoUnit,
  I_LogManager,
  uConsoleOutput;

type
  THtmlDetails = record
    LinkFileName: string;
    LinkName: string;
    HasFile: Boolean;
  end;

type
  TCoverageStatsProc = function(const ACoverageModule: ICoverageStats): THtmlDetails of object;

type
  THTMLCoverageReport = class(TInterfacedObject, IReport)
  private
    FCoverageConfiguration : ICoverageConfiguration;
    procedure AddTableHeader(const ATableHeading: string;
                             const AColumnHeading: string;
                             const AOutputFile: TTextWriter);

    procedure AddTableFooter(const AHeading: string;
                             const ACoverageStats: ICoverageStats;
                             const AOutputFile: TTextWriter);

    procedure IterateOverStats(const ACoverageStats: ICoverageStats;
                               const AOutputFile: TTextWriter;
                               const ACoverageStatsProc: TCoverageStatsProc);

    procedure SetPrePostLink(const AHtmlDetails: THtmlDetails;
                             out PreLink: string;
                             out PostLink: string);

    procedure AddPostAmble(const AOutFile: TTextWriter);
    procedure AddPreAmble(const AOutFile: TTextWriter);

    function FindSourceFile(const ACoverageUnit: ICoverageStats;
                            var HtmlDetails: THtmlDetails): string;

    procedure AddStatistics(const ACoverageBase: ICoverageStats;
                            const ASourceFileName: string;
                            const AOutFile: TTextWriter);

    procedure GenerateCoverageTable(const ACoverageModule: ICoverageStats;
                                    const AOutputFile: TTextWriter;
                                    const AInputFile: TTextReader);

    function GenerateModuleReport(const ACoverageModule: ICoverageStats): THtmlDetails;

    function GenerateUnitReport(const ACoverageUnit: ICoverageStats): THtmlDetails;
    procedure AddGeneratedAt(var OutputFile: TTextWriter);
  public
    constructor Create(const ACoverageConfiguration: ICoverageConfiguration);

    procedure Generate(
      const ACoverage: ICoverageStats;
      const AModuleInfoList: TModuleList;
      const ALogManager: ILogManager);
  end;

const
  SourceClass: string = ' class="s"';
  OverviewClass: string = ' class="o"';
  SummaryClass: string = ' class="sum"';

implementation

uses
  SysUtils,
  JclFileUtils,
  JvStrToHtml,
  HtmlHelper;

procedure THTMLCoverageReport.Generate(
  const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList;
  const ALogManager: ILogManager);
var
  OutputFile: TTextWriter;
  OutputFileName: TFileName;
begin
  ALogManager.Log('Generating coverage report');

  if (FCoverageConfiguration.SourcePaths.Count > 0) then
    VerboseOutput('Source dir: ' + FCoverageConfiguration.SourcePaths.Strings[0])
  else
    VerboseOutput('Source dir: <none>');

  VerboseOutput('Output dir: ' + FCoverageConfiguration.OutputDir);

  OutputFileName := PathAppend(FCoverageConfiguration.OutputDir, 'CodeCoverage_summary.html');
  OutputFile := TStreamWriter.Create(OutputFileName, False, TEncoding.UTF8);
  try
    AddPreAmble(OutputFile);
    OutputFile.WriteLine(heading('Summary Coverage Report', 1));

    AddGeneratedAt(OutputFile);

    AddTableHeader('Aggregate statistics for all modules', 'Unit Name', OutputFile);

    IterateOverStats(ACoverage, OutputFile, GenerateModuleReport);

    AddTableFooter('Aggregated for all units', ACoverage, OutputFile);

    AddPostAmble(OutputFile);
  finally
    OutputFile.Free;
  end;
end;

procedure THTMLCoverageReport.AddGeneratedAt(var OutputFile: TTextWriter);
var
  LinkText: string;
  ParagraphText: string;
begin
  LinkText := link(
    'DelphiCodeCoverage',
    'http://code.google.com/p/delphi-code-coverage/',
    'Code Coverage for Delphi 5+'
  );

  ParagraphText :=
      ' Generated at ' + DateToStr(now) + ' ' + TimeToStr(now)
      + ' by ' + LinkText
      + ' - an open source tool for Delphi Code Coverage.';

  OutputFile.WriteLine(p(ParagraphText));
end;

function THTMLCoverageReport.GenerateModuleReport(
  const ACoverageModule: ICoverageStats): THtmlDetails;
var
  OutputFile: TTextWriter;
  OutputFileName: string;
begin
  if (ACoverageModule.Count = 1) then
  begin
    Result          := GenerateUnitReport(ACoverageModule.CoverageReport[0]);
    Result.LinkName := ACoverageModule.Name;
    Exit;
  end;

  try
    Result.HasFile := False;
    Result.LinkFileName := ACoverageModule.Name + '.html';
    Result.LinkName := ACoverageModule.Name;

    OutputFileName := PathAppend(FCoverageConfiguration.OutputDir, Result.LinkFileName);

    OutputFile := TStreamWriter.Create(OutputFileName, False, TEncoding.UTF8);
    try
      AddPreAmble(OutputFile);
      OutputFile.WriteLine(p('Coverage report for ' + bold(ACoverageModule.Name) + '.'));
      AddGeneratedAt(OutputFile);

      AddTableHeader('Aggregate statistics for all units', 'Source File Name', OutputFile);
      IterateOverStats(ACoverageModule, OutputFile, GenerateUnitReport);

      AddTableFooter('Aggregated for all files', ACoverageModule, OutputFile);

      AddPostAmble(OutputFile);
    finally
      OutputFile.Free;
    end;
    Result.HasFile := True;
  except
    on E: EFileStreamError do
      ConsoleOutput('Exception during generation of unit coverage for:' + ACoverageModule.Name +
       ' could not write to: ' + OutputFileName +
       ' exception:' + E.message)
    else
      raise;
  end;
end;

function THTMLCoverageReport.GenerateUnitReport(
  const ACoverageUnit: ICoverageStats): THtmlDetails;
var
  InputFile: TTextReader;
  OutputFile: TTextWriter;
  SourceFileName: string;
  OutputFileName: string;
begin
  Result.HasFile:= False;
  Result.LinkFileName:= ACoverageUnit.ReportFileName + '.html';
  Result.LinkName:= ACoverageUnit.Name;

  if FCoverageConfiguration.ExcludedUnits.IndexOf(StringReplace(ExtractFileName(ACoverageUnit.Name), ExtractFileExt(ACoverageUnit.Name), '', [rfReplaceAll, rfIgnoreCase])) < 0 then
  try
    SourceFileName := FindSourceFile(ACoverageUnit, Result);

    try
      InputFile := TStreamReader.Create(SourceFileName, TEncoding.ANSI, True);
    except
      on E: EFileStreamError do
      begin
        ConsoleOutput(
          'Exception during generation of unit coverage for:' + ACoverageUnit.Name
          + ' could not open:' + SourceFileName
        );
        ConsoleOutput('Current directory:' + GetCurrentDir);
        raise;
      end;
    end;

    try
      OutputFileName := Result.LinkFileName;
      OutputFileName := PathAppend(FCoverageConfiguration.OutputDir, OutputFileName);

      try
        OutputFile := TStreamWriter.Create(OutputFileName, False, TEncoding.UTF8);
        try
          AddPreAmble(OutputFile);
          OutputFile.WriteLine(p('Coverage report for ' + bold(ACoverageUnit.Parent.Name + ' (' + SourceFileName + ')') + '.'));
          AddGeneratedAt(OutputFile);
          AddStatistics(ACoverageUnit, SourceFileName, OutputFile);
          GenerateCoverageTable(ACoverageUnit, OutputFile, InputFile);
          AddPostAmble(OutputFile);
        finally
          OutputFile.Free;
        end;
      except
        on E: EFileStreamError do
        begin
          ConsoleOutput(
            'Exception during generation of unit coverage for:' + ACoverageUnit.Name
            + ' could not write to:' + OutputFileName
          );
          ConsoleOutput('Current directory:' + GetCurrentDir);
          raise;
        end;
      end;
      Result.HasFile := True;
    finally
      InputFile.Free;
    end;
  except
    on E: EFileStreamError do
      ConsoleOutput(
        'Exception during generation of unit coverage for:' + ACoverageUnit.Name
        + ' exception:' + E.message
      )
    else
      raise;
  end;
end;

procedure THTMLCoverageReport.IterateOverStats(
  const ACoverageStats: ICoverageStats;
  const AOutputFile: TTextWriter;
  const ACoverageStatsProc: TCoverageStatsProc);
var
  StatIndex: Integer;
  HtmlDetails : THtmlDetails;
  PostLink: string;
  PreLink: string;
  CurrentStats: ICoverageStats;
begin
  for StatIndex := 0 to Pred(ACoverageStats.Count) do
  begin
    CurrentStats := ACoverageStats.CoverageReport[StatIndex];

    HtmlDetails.HasFile := False;
    if Assigned(ACoverageStatsProc) then
      HtmlDetails := ACoverageStatsProc(CurrentStats);

    SetPrePostLink(HtmlDetails, PreLink, PostLink);

    AOutputFile.WriteLine(
      tr(
        td(PreLink + HtmlDetails.LinkName + PostLink) +
        td(IntToStr(CurrentStats.CoveredLineCount)) +
        td(IntToStr(CurrentStats.LineCount)) +
        td(em(IntToStr(CurrentStats.PercentCovered) + '%'))
      )
    );
  end;
end;

procedure THTMLCoverageReport.SetPrePostLink(
  const AHtmlDetails: THtmlDetails;
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
    PreLink := StartTag('a', 'href="' + LLinkFileName + '"');
    PostLink := EndTag('a');
  end;
end;

procedure THTMLCoverageReport.AddPreAmble(const AOutFile: TTextWriter);
begin
  AOutFile.WriteLine('<!DOCTYPE html>');
  AOutFile.WriteLine(StartTag('html'));
  AOutFile.WriteLine(StartTag('head'));
  AOutFile.WriteLine('    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />');
  AOutFile.WriteLine('    ' + WrapTag('Delphi CodeCoverage Coverage Report', 'title'));
  if FileExists('style.css') then
    AOutFile.WriteLine('    <link rel="stylesheet" href="style.css" type="text/css" />')
  else
  begin
    AOutFile.WriteLine(StartTag('style', 'type="text/css"'));
    AOutFile.WriteLine('table {border-spacing:0; border-collapse:collapse;}');
    AOutFile.WriteLine('table, td, th {border: 1px solid black;}');
    AOutFile.WriteLine('td, th {background: white; margin: 0; padding: 2px 0.5em 2px 0.5em}');
    AOutFile.WriteLine('td {border-width: 0 1px 0 0;}');
    AOutFile.WriteLine('th {border-width: 1px 1px 1px 0;}');
    AOutFile.WriteLine('p, h1, h2, h3, th {font-family: verdana,arial,sans-serif; font-size: 10pt;}');
    AOutFile.WriteLine('td {font-family: courier,monospace; font-size: 10pt;}');
    AOutFile.WriteLine('th {background: #CCCCCC;}');

    AOutFile.WriteLine('table.o tr td:nth-child(1) {font-weight: bold;}');
    AOutFile.WriteLine('table.o tr td:nth-child(2) {text-align: right;}');
    AOutFile.WriteLine('table.o tr td {border-width: 1px;}');

    AOutFile.WriteLine('table.s {width: 100%;}');
    AOutFile.WriteLine('table.s tr td {padding: 0 0.25em 0 0.25em;}');
    AOutFile.WriteLine('table.s tr td:first-child {text-align: right; font-weight: bold;}');
    AOutFile.WriteLine('table.s tr.notcovered td {background: #DDDDFF;}');
    AOutFile.WriteLine('table.s tr.nocodegen td {background: #FFFFEE;}');
    AOutFile.WriteLine('table.s tr.covered td {background: #CCFFCC;}');
    AOutFile.WriteLine('table.s tr.covered td:first-child {color: green;}');
    AOutFile.WriteLine('table.s {border-width: 1px 0 1px 1px;}');

    AOutFile.WriteLine('table.sum tr td {border-width: 1px;}');
    AOutFile.WriteLine('table.sum tr th {text-align:right;}');
    AOutFile.WriteLine('table.sum tr th:first-child {text-align:center;}');
    AOutFile.WriteLine('table.sum tr td {text-align:right;}');
    AOutFile.WriteLine('table.sum tr td:first-child {text-align:left;}');
	  AOutFile.WriteLine(EndTag('style'));
  end;
  AOutFile.WriteLine(EndTag('head'));
  AOutFile.WriteLine(StartTag('body'));
end;

procedure THTMLCoverageReport.AddPostAmble(const AOutFile: TTextWriter);
begin
  AOutFile.WriteLine(EndTag('body'));
  AOutFile.WriteLine(EndTag('html'));
end;

procedure THTMLCoverageReport.AddStatistics(
  const ACoverageBase: ICoverageStats;
  const ASourceFileName: string;
  const AOutFile: TTextWriter);
begin
  AOutFile.WriteLine( p(' Statistics for ' + ASourceFileName + ' '));

  AOutFile.WriteLine(
    table(
      tr(
        td('Number of lines covered') +
        td(IntToStr(ACoverageBase.CoveredLineCount))
      ) +
      tr(
        td('Number of lines with code gen') +
        td(IntToStr(ACoverageBase.LineCount))
      ) +
      tr(
        td('Line coverage') +
        td(IntToStr(ACoverageBase.PercentCovered) + '%')
      ),
      OverviewClass
    )
  );

  AOutFile.WriteLine(lineBreak + lineBreak);
end;

procedure THTMLCoverageReport.AddTableFooter(
  const AHeading: string;
  const ACoverageStats: ICoverageStats;
  const AOutputFile: TTextWriter);
begin
  AOutputFile.WriteLine(
    tr(
      th(JvStrToHtml.StringToHtml(AHeading)) +
      th(IntToStr(ACoverageStats.CoveredLineCount)) +
      th(IntToStr(ACoverageStats.LineCount)) +
      th(em(IntToStr(ACoverageStats.PercentCovered) + '%'))
    )
  );
  AOutputFile.WriteLine(EndTag('table'));
end;

procedure THTMLCoverageReport.AddTableHeader(
  const ATableHeading: string;
  const AColumnHeading: string;
  const AOutputFile: TTextWriter);
begin
  AOutputFile.WriteLine(p(JvStrToHtml.StringToHtml(ATableHeading)));
  AOutputFile.WriteLine(StartTag('table', SummaryClass));
  AOutputFile.WriteLine(
    tr(
      th(JvStrToHtml.StringToHtml(AColumnHeading)) +
      th('Number of covered lines') +
      th('Number of lines (which generated code)') +
      th('Percent(s) covered')
    )
  );
end;

constructor THTMLCoverageReport.Create(
  const ACoverageConfiguration: ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

function THTMLCoverageReport.FindSourceFile(
  const ACoverageUnit: ICoverageStats;
  var HtmlDetails: THtmlDetails): string;
var
  SourceFound: Boolean;
  CurrentSourcePath: string;
  SourcePathIndex: Integer;
  UnitIndex: Integer;
  ACoverageModule: ICoverageStats;
begin
  SourceFound := False;

  SourcePathIndex := 0;
  while (SourcePathIndex < FCoverageConfiguration.SourcePaths.Count)
  and not SourceFound do
  begin
    CurrentSourcePath := FCoverageConfiguration.SourcePaths[SourcePathIndex];
    Result := PathAppend(CurrentSourcePath, ACoverageUnit.Name);

    if not FileExists(Result) then
    begin
      ACoverageModule := ACoverageUnit.Parent;

      UnitIndex := 0;
      while (UnitIndex < ACoverageModule.Count)
      and not SourceFound do
      begin
        Result := PathAppend(
          PathAppend(
            CurrentSourcePath,
            ExtractFilePath(ACoverageModule.CoverageReport[UnitIndex].Name)
          ),
          ACoverageUnit.Name
        );

        if FileExists(Result) then
        begin
          HtmlDetails.LinkName := PathAppend(
            ExtractFilePath(ACoverageModule.CoverageReport[UnitIndex].Name),
            HtmlDetails.LinkName
          );
          SourceFound := True;
        end;

        Inc(UnitIndex, 1);
      end;
    end
    else
      SourceFound := True;

    Inc(SourcePathIndex, 1);
  end;

  if (not SourceFound) then
    Result := ACoverageUnit.Name;
end;

procedure THTMLCoverageReport.GenerateCoverageTable(
  const ACoverageModule: ICoverageStats;
  const AOutputFile: TTextWriter;
  const AInputFile: TTextReader);
var
  LineCoverage     : TCoverageLine;
  InputLine        : string;
  LineCoverageIter : Integer;
  LineCount        : Integer;

  procedure WriteTableRow(const AClass: string);
  begin
    AOutputFile.WriteLine(
      tr(
        td(IntToStr(LineCount)) +
        td(pre(InputLine)),
        'class="' + AClass + '"'
      )
    );
  end;
begin
  LineCoverageIter := 0;
  LineCount := 1;

  AOutputFile.WriteLine(StartTag('table', SourceClass));
  while AInputFile.Peek <> -1 do
  begin
    InputLine := AInputFile.ReadLine;
    InputLine := JvStrToHtml.StringToHtml(TrimRight(InputLine));
    LineCoverage := ACoverageModule.CoverageLine[LineCoverageIter];
    if (LineCount = LineCoverage.LineNumber) then
    begin
      if (LineCoverage.IsCovered) then
        WriteTableRow('covered')
      else
        WriteTableRow('notcovered');

      Inc(LineCoverageIter);
    end
    else
      WriteTableRow('nocodegen');

    Inc(LineCount);
  end;
  AOutputFile.WriteLine(EndTag('table'));
end;

end.

