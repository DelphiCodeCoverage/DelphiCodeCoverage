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
                             const AOutputFile: TextFile);

    procedure AddTableFooter(const AHeading: string;
                             const ACoverageStats: ICoverageStats;
                             const AOutputFile: TextFile);

    procedure IterateOverStats(const ACoverageStats: ICoverageStats;
                               const AOutputFile: TextFile;
                               const ACoverageStatsProc: TCoverageStatsProc);

    procedure SetPrePostLink(const AHtmlDetails: THtmlDetails;
                             out PreLink: string;
                             out PostLink: string);

    procedure AddPostAmble(const AOutFile: TextFile);
    procedure AddPreAmble(const AOutFile: TextFile);

    function FindSourceFile(const ACoverageUnit: ICoverageStats;
                            var HtmlDetails: THtmlDetails): string;

    procedure AddStatistics(const ACoverageBase: ICoverageStats;
                            const ASourceFileName: string;
                            const AOutFile: TextFile);

    procedure GenerateCoverageTable(const ACoverageModule: ICoverageStats;
                                    const AOutputFile: TextFile;
                                    const AInputFile: TextFile);

    function GenerateModuleReport(const ACoverageModule: ICoverageStats): THtmlDetails;

    function GenerateUnitReport(const ACoverageUnit: ICoverageStats): THtmlDetails;
    procedure AddGeneratedAt(var OutputFile: Text);
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
  OutputFile: TextFile;
  OutputFileName: string;
begin
  ALogManager.Log('Generating coverage report');

  if (FCoverageConfiguration.SourcePaths.Count > 0) then
    VerboseOutput('Source dir: ' + FCoverageConfiguration.SourcePaths.Strings[0])
  else
    VerboseOutput('Source dir: <none>');

  VerboseOutput('Output dir: ' + FCoverageConfiguration.OutputDir);

  OutputFileName := 'CodeCoverage_summary.html';
  OutputFileName := PathAppend(FCoverageConfiguration.OutputDir, OutputFileName);
  AssignFile(OutputFile, OutputFileName);
  try
    System.FileMode := fmOpenReadWrite;
    ReWrite(OutputFile);
    AddPreAmble(OutputFile);
    WriteLn(OutputFile,  heading('Summary Coverage Report', 1));

    AddGeneratedAt(OutputFile);

    AddTableHeader('Aggregate statistics for all modules', 'Unit Name', OutputFile);

    IterateOverStats(ACoverage, OutputFile, GenerateModuleReport);

    AddTableFooter('Aggregated for all units', ACoverage, OutputFile);

    AddPostAmble(OutputFile);
  finally
    CloseFile(OutputFile);
  end;
end;

procedure THTMLCoverageReport.AddGeneratedAt(var OutputFile: Text);
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

  WriteLn(OutputFile,  p(ParagraphText));
end;

function THTMLCoverageReport.GenerateModuleReport(
  const ACoverageModule: ICoverageStats): THtmlDetails;
var
  OutputFile: TextFile;
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

    AssignFile(OutputFile, OutputFileName);
    try
      try
        System.FileMode := fmOpenReadWrite;
        ReWrite(OutputFile);
      except
        on E: EInOutError do
        begin
          ConsoleOutput(
            'Exception during generation of unit coverage for:' + ACoverageModule.Name +
            ' could not write to: ' + OutputFileName
          );
          ConsoleOutput('Current directory:' + GetCurrentDir);
          raise;
        end;
      end;

      AddPreAmble(OutputFile);
      WriteLn(
        OutputFile,

        p('Coverage report for ' + bold(ACoverageModule.Name) + '.')
      );
      AddGeneratedAt(OutputFile);

      AddTableHeader('Aggregate statistics for all units', 'Source File Name', OutputFile);
      IterateOverStats(ACoverageModule, OutputFile, GenerateUnitReport);

      AddTableFooter('Aggregated for all files', ACoverageModule, OutputFile);

      AddPostAmble(OutputFile);
    finally
      CloseFile(OutputFile);
    end;
    Result.HasFile := True;
  except
    on E: EInOutError do
      ConsoleOutput('Exception during generation of unit coverage for:' + ACoverageModule.Name + ' exception:' + E.message)
    else
      raise;
  end;
end;

function THTMLCoverageReport.GenerateUnitReport(
  const ACoverageUnit: ICoverageStats): THtmlDetails;
var
  InputFile: TextFile;
  OutputFile: TextFile;
  SourceFileName: string;
  OutputFileName: string;
begin
  Result.HasFile:= False;
  Result.LinkFileName:= ACoverageUnit.ReportFileName + '.html';
  Result.LinkName:= ACoverageUnit.Name;

  if FCoverageConfiguration.ExcludedUnits.IndexOf(StringReplace(ExtractFileName(ACoverageUnit.Name), ExtractFileExt(ACoverageUnit.Name), '', [rfReplaceAll, rfIgnoreCase])) < 0 then
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
          ConsoleOutput(
            'Exception during generation of unit coverage for:' + ACoverageUnit.Name
            + ' could not open:' + SourceFileName
          );
          ConsoleOutput('Current directory:' + GetCurrentDir);
          raise;
        end;
      end;
      OutputFileName := Result.LinkFileName;
      OutputFileName := PathAppend(FCoverageConfiguration.OutputDir, OutputFileName);

      AssignFile(OutputFile, OutputFileName);
      try
        try
          System.FileMode := fmOpenReadWrite;
          ReWrite(OutputFile);
        except
          on E: EInOutError do
          begin
            ConsoleOutput(
              'Exception during generation of unit coverage for:' + ACoverageUnit.Name
              + ' could not write to:' + OutputFileName
            );
            ConsoleOutput('Current directory:' + GetCurrentDir);
            raise;
          end;
        end;
        AddPreAmble(OutputFile);
        WriteLn(
          OutputFile,

          p('Coverage report for ' + bold(ACoverageUnit.Parent.Name + ' (' + SourceFileName + ')') + '.')
        );
        AddGeneratedAt(OutputFile);
        AddStatistics(ACoverageUnit, SourceFileName, OutputFile);
        GenerateCoverageTable(ACoverageUnit, OutputFile, InputFile);
        AddPostAmble(OutputFile);
      finally
        CloseFile(OutputFile);
      end;
      Result.HasFile := True;
    finally
      CloseFile(InputFile);
    end;
  except
    on E: EInOutError do
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
  const AOutputFile: TextFile;
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

    WriteLn(
      AOutputFile,
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

procedure THTMLCoverageReport.AddPreAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '<!DOCTYPE html>');
  WriteLn(AOutFile, StartTag('html'));
  WriteLn(AOutFile, StartTag('head'));
  WriteLn(AOutFile, '    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />');
  WriteLn(AOutFile, '    ' + WrapTag('Delphi CodeCoverage Coverage Report', 'title'));
  if FileExists('style.css') then
    WriteLn(AOutFile, '    <link rel="stylesheet" href="style.css" type="text/css" />')
  else
  begin
    WriteLn(AOutFile, StartTag('style', 'type="text/css"'));
    Writeln(AOutFile, 'table {border-spacing:0; border-collapse:collapse;}');
    WriteLn(AOutFile, 'table, td, th {border: 1px solid black;}');
    WriteLn(AOutFile, 'td, th {background: white; margin: 0; padding: 2px 0.5em 2px 0.5em}');
    WriteLn(AOutFile, 'td {border-width: 0 1px 0 0;}');
    WriteLn(AOutFile, 'th {border-width: 1px 1px 1px 0;}');
    WriteLn(AOutFile, 'p, h1, h2, h3, th {font-family: verdana,arial,sans-serif; font-size: 10pt;}');
    WriteLn(AOutFile, 'td {font-family: courier,monospace; font-size: 10pt;}');
    WriteLn(AOutFile, 'th {background: #CCCCCC;}');

    WriteLn(AOutFile, 'table.o tr td:nth-child(1) {font-weight: bold;}');
    WriteLn(AOutFile, 'table.o tr td:nth-child(2) {text-align: right;}');
    WriteLn(AOutFile, 'table.o tr td {border-width: 1px;}');

    WriteLn(AOutFile, 'table.s {width: 100%;}');
    WriteLn(AOutFile, 'table.s tr td {padding: 0 0.25em 0 0.25em;}');
    WriteLn(AOutFile, 'table.s tr td:first-child {text-align: right; font-weight: bold;}');
    WriteLn(AOutFile, 'table.s tr.notcovered td {background: #DDDDFF;}');
    WriteLn(AOutFile, 'table.s tr.nocodegen td {background: #FFFFEE;}');
    WriteLn(AOutFile, 'table.s tr.covered td {background: #CCFFCC;}');
    WriteLn(AOutFile, 'table.s tr.covered td:first-child {color: green;}');
    WriteLn(AOutFile, 'table.s {border-width: 1px 0 1px 1px;}');

    WriteLn(AOutFile, 'table.sum tr td {border-width: 1px;}');
    WriteLn(AOutFile, 'table.sum tr th {text-align:right;}');
    WriteLn(AOutFile, 'table.sum tr th:first-child {text-align:center;}');
    WriteLn(AOutFile, 'table.sum tr td {text-align:right;}');
    WriteLn(AOutFile, 'table.sum tr td:first-child {text-align:left;}');
	  WriteLn(AOutFile, EndTag('style'));
  end;
  WriteLn(AOutFile, EndTag('head'));
  WriteLn(AOutFile, StartTag('body'));
end;

procedure THTMLCoverageReport.AddPostAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, EndTag('body'));
  WriteLn(AOutFile, EndTag('html'));
end;

procedure THTMLCoverageReport.AddStatistics(
  const ACoverageBase: ICoverageStats;
  const ASourceFileName: string;
  const AOutFile: TextFile);
begin
  WriteLn(AOutFile,  p(' Statistics for ' + ASourceFileName + ' '));

  WriteLn(
    AOutFile,
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

  WriteLn(AOutFile, lineBreak + lineBreak);
end;

procedure THTMLCoverageReport.AddTableFooter(
  const AHeading: string;
  const ACoverageStats: ICoverageStats;
  const AOutputFile: TextFile);
begin
  WriteLn(AOutputFile,
    tr(
      th(JvStrToHtml.StringToHtml(AHeading)) +
      th(IntToStr(ACoverageStats.CoveredLineCount)) +
      th(IntToStr(ACoverageStats.LineCount)) +
      th(em(IntToStr(ACoverageStats.PercentCovered) + '%'))
    )
  );
  WriteLn(AOutputFile, EndTag('table'));
end;

procedure THTMLCoverageReport.AddTableHeader(
  const ATableHeading: string;
  const AColumnHeading: string;
  const AOutputFile: TextFile);
begin
  WriteLn(AOutputFile, p(JvStrToHtml.StringToHtml(ATableHeading)));
  WriteLn(AOutputFile, StartTag('table', SummaryClass));
  WriteLn(
    AOutputFile,
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
  const AOutputFile: TextFile;
  const AInputFile: TextFile);
var
  LineCoverage     : TCoverageLine;
  InputLine        : string;
  LineCoverageIter : Integer;
  LineCount        : Integer;

  procedure WriteTableRow(const AClass: string);
  begin
    WriteLn(
      AOutputFile,
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

  WriteLn(AOutputFile, StartTag('table', SourceClass));
  while (not Eof(AInputFile)) do
  begin
    ReadLn(AInputFile, InputLine);
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
  WriteLn(AOutputFile, EndTag('table'));
end;

end.

