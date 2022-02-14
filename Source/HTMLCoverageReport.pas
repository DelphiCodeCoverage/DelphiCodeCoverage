(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit HTMLCoverageReport;

interface

uses
  System.Classes,
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
  OverviewClass: string = 'o';
  SummaryClass: string = ' class="sum"';

implementation

uses
  System.SysUtils,
  System.Math,
  System.NetEncoding,
  JclFileUtils,
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
    'https://github.com/DelphiCodeCoverage/DelphiCodeCoverage',
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
      ConsoleOutput('Exception during generation of unit coverage for: ' + ACoverageModule.Name +
       ' could not write to: ' + OutputFileName +
       ' exception: ' + E.message)
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
  Encoding: TEncoding;
begin
  Result.HasFile:= False;
  Result.LinkFileName:= ACoverageUnit.ReportFileName + '.html';
  Result.LinkName:= ACoverageUnit.Name;

  if FCoverageConfiguration.ExcludedUnits.IndexOf(StringReplace(ExtractFileName(ACoverageUnit.Name), ExtractFileExt(ACoverageUnit.Name), '', [rfReplaceAll, rfIgnoreCase])) < 0 then
  try
    SourceFileName := FindSourceFile(ACoverageUnit, Result);

    try
      if FCoverageConfiguration.CodePage <> 0 then
        Encoding := TEncoding.GetEncoding(FCoverageConfiguration.CodePage)
      else
        Encoding := TEncoding.ANSI;
      InputFile := TStreamReader.Create(SourceFileName, Encoding, True);
    except
      on E: EFileStreamError do
      begin
        ConsoleOutput(
          'Exception during generation of unit coverage for: ' + ACoverageUnit.Name
          + ' could not open: ' + SourceFileName
        );
        ConsoleOutput('Current directory: ' + GetCurrentDir);
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
            'Exception during generation of unit coverage for: ' + ACoverageUnit.Name
            + ' could not write to: ' + OutputFileName
          );
          ConsoleOutput('Current directory: ' + GetCurrentDir);
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
        'Exception during generation of unit coverage for: ' + ACoverageUnit.Name
        + ' exception: ' + E.message
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
  PercentCovered: String;
  CurrentStats: ICoverageStats;
begin
  AOutputFile.WriteLine('<tbody');
  for StatIndex := 0 to Pred(ACoverageStats.Count) do
  begin
    CurrentStats := ACoverageStats.CoverageReport[StatIndex];

    HtmlDetails.HasFile := False;
    if Assigned(ACoverageStatsProc) then
      HtmlDetails := ACoverageStatsProc(CurrentStats);

    SetPrePostLink(HtmlDetails, PreLink, PostLink);

    PercentCovered := IntToStr(CurrentStats.PercentCovered) + '%';

    AOutputFile.WriteLine(
      '<tr>' +
         '<td>' + PreLink + HtmlDetails.LinkName + PostLink +
         '<td>' + IntToStr(CurrentStats.CoveredLineCount) +
         '<td>' + IntToStr(CurrentStats.LineCount - CurrentStats.CoveredLineCount) +
         '<td>' + IntToStr(CurrentStats.LineCount) +
         '<td style="background-image: linear-gradient(90deg, #8f8 ' + PercentCovered
                                                    + ', transparent ' + PercentCovered + ')">'
                + PercentCovered
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

    AOutFile.WriteLine('body {max-width: max-content;margin: auto;}');

    AOutFile.WriteLine('table {border-spacing:0;}');
    AOutFile.WriteLine('table, td, th {border: 0;}');
    AOutFile.WriteLine('td, th {background: white; margin: 0; padding: .5em 1em}');

    AOutFile.WriteLine('p, h1, h2, h3, th {font-family: verdana,arial,sans-serif; font-size: 10pt;}');
    AOutFile.WriteLine('td {font-family: consolas,courier,monospace; font-size: 10pt;}');
    AOutFile.WriteLine('th {background: #ccc;}');
    AOutFile.WriteLine('th[idx] {cursor: pointer; user-select: none;}');

    AOutFile.WriteLine('table.o tr td:nth-child(1) {font-weight: bold;}');
    AOutFile.WriteLine('table.o tr td:nth-child(2) {text-align: right;}');
    AOutFile.WriteLine('table.o tr td {border-width: 1px;}');

    AOutFile.WriteLine('table.s {width: calc(min(80em, 95vw));}');
    AOutFile.WriteLine('table.s tr td {padding: .1em .5em; white-space: pre-wrap;}');
    AOutFile.WriteLine('table.s tr td:first-child {text-align: right; font-weight: bold; vertical-align: top}');
    AOutFile.WriteLine('table.s tr.notcovered td {background: #ddf;}');
    AOutFile.WriteLine('table.s tr.nocodegen td {background: #ffe;}');
    AOutFile.WriteLine('table.s tr.covered td {background: #cfc;}');
    AOutFile.WriteLine('table.s tr.covered td:first-child {color: green;}');
    AOutFile.WriteLine('table.s {border-width: 1px 0 1px 1px;}');

    AOutFile.WriteLine('table.sum td { background-position: 50%; background-repeat: no-repeat; background-size: 90% 70%; }');
    AOutFile.WriteLine('table.sum tr:nth-child(odd) td { background-color: #f4f4f4}');
    AOutFile.WriteLine('table.sum tr:hover td, tr:hover td a { filter: invert(10%) }');
    AOutFile.WriteLine('table.sum tr th {text-align:left; border: 1px solid #888; height: 1em}');
    AOutFile.WriteLine('table.sum tr td {text-align:right;}');
    AOutFile.WriteLine('table.sum tr td:first-child {text-align:left;}');
    AOutFile.WriteLine('table.sum thead th { position: sticky; top:0; }');
    AOutFile.WriteLine('table.sum thead tr + tr th { position: sticky; top: calc(2.5em - 2px); }');
    AOutFile.WriteLine('table.sum tfoot th { position: sticky; bottom:0; }');


    AOutFile.WriteLine(
      '#nav {' +
         'position: fixed;' +
         'overflow: visible;' +
         'left: min(calc(50% + 41em), calc(100% - 6em));' +
         'padding: .1em .5em .1em .2em;' +
         'background: white;' +
         'box-shadow: 1px 1px 3px #888;' +
      '}');
    AOutFile.WriteLine('#nav div {opacity: .3; user-select: none; pointer-events: none;}');
    AOutFile.WriteLine('#nav div.active {opacity: 1;	cursor: pointer;	pointer-events: initial;}');
    AOutFile.WriteLine('#nav div.active:hover {color: #00A;}');

    AOutFile.WriteLine(EndTag('style'));
  end;
  AOutFile.WriteLine(EndTag('head'));
  AOutFile.WriteLine(StartTag('body'));
end;

procedure THTMLCoverageReport.AddPostAmble(const AOutFile: TTextWriter);
begin
   // minimalistic vanilla JS table sorter inspired from
   // https://stackoverflow.com/questions/14267781/sorting-html-table-with-javascript
   AOutFile.WriteLine(
        '<script>'#10
      + 'const getCellValue = (tr, idx) => tr.children[idx].innerText || tr.children[idx].textContent;'#10
      + 'const comparer = (idx, asc) => (a, b) => ((v1, v2) =>'
         + '!isNaN(parseFloat(v1 || "-")) && !isNaN(parseFloat(v2 || "-")) ? parseFloat(v1)-parseFloat(v2) : v1.toString().localeCompare(v2)'
         +')(getCellValue(asc ? a : b, idx), getCellValue(asc ? b : a, idx));'#10
      + 'document.querySelectorAll("thead th[idx]").forEach(th => th.addEventListener("click", (() => {'#10
         + #9'const table = th.closest("table").querySelector("tbody");'#10
         + #9'Array.from(table.querySelectorAll("tr"))'#10
            + #9#9'.sort(comparer(+th.getAttribute("idx"), this.asc = !this.asc))'#10
            + #9#9'.forEach(tr => table.appendChild(tr) );'#10
         + #9'})));'#10
      + '</script>');

  AOutFile.WriteLine(EndTag('body'));
  AOutFile.WriteLine(EndTag('html'));
end;

procedure THTMLCoverageReport.AddStatistics(
  const ACoverageBase: ICoverageStats;
  const ASourceFileName: string;
  const AOutFile: TTextWriter);
var
   percent : String;
begin
  AOutFile.WriteLine( p(' Statistics for ' + ASourceFileName + ' '));

  percent := IntToStr(ACoverageBase.PercentCovered) + '%';

  AOutFile.WriteLine(
    '<table class="' + OverviewClass + '">'
      + '<tr>'
         + '<td>Number of lines covered'
         + '<td>' + IntToStr(ACoverageBase.CoveredLineCount)
         + '<td rowspan=3 style="background: conic-gradient(#8f8 ' + percent
                                                         + ', #eee ' + percent + ');'
                              + 'width: 4.5em; border-radius: 50%">'
      + '<tr>'
         + '<td>Number of lines with code gen'
         + '<td>' + IntToStr(ACoverageBase.LineCount)
      + '<tr>'
         + '<td>Line coverage'
         + '<td>' + percent
    + '</table>'
  );

  AOutFile.WriteLine(lineBreak + lineBreak);
end;

procedure THTMLCoverageReport.AddTableFooter(
  const AHeading: string;
  const ACoverageStats: ICoverageStats;
  const AOutputFile: TTextWriter);
begin
  AOutputFile.WriteLine('<tfoot>');
  AOutputFile.WriteLine(
    tr(
      th(TNetEncoding.HTML.Encode(AHeading)) +
      th(IntToStr(ACoverageStats.CoveredLineCount)) +
      th(IntToStr(ACoverageStats.LineCount - ACoverageStats.CoveredLineCount)) +
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
  AOutputFile.WriteLine(p(TNetEncoding.HTML.Encode(ATableHeading)));
  AOutputFile.WriteLine(StartTag('table', SummaryClass));
  AOutputFile.WriteLine(
    '<thead>'
    + '<tr>'
      + '<th rowspan=2 idx=0>' + TNetEncoding.HTML.Encode(AColumnHeading)
      + '<th colspan=3 idx=3>Number of lines'
      + '<th rowspan=2 idx=4>Percent(s) covered'
    + '<tr>'
      + '<th idx=1>Covered'
      + '<th idx=2>Not Covered'
      + '<th idx=3>Which generated code'
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

  procedure WriteTableRow(const AClass: string; const ACount: Integer = -1);
  var
    HtmlLineCount: string;
    Count: Integer;
  begin
    Count := Min(FCoverageConfiguration.LineCountLimit, ACount);

    if FCoverageConfiguration.LineCountLimit = 0 then
      HtmlLineCount := '' // No column for count
    else if Count < 0 then
      HtmlLineCount := '<td>' // Count is blank
    else
      HtmlLineCount := '<td>' + IntToStr(Count); // Count is given

    AOutputFile.WriteLine(
      '<tr class="' + AClass + '"><td>' + IntToStr(LineCount) + HtmlLineCount
         + '<td>' + InputLine
    );
  end;

begin
  LineCoverageIter := 0;
  LineCount := 1;

  AOutputFile.WriteLine('<div id="nav"><div id="nav-prev">&#x25b2; Prev</div><div id="nav-next">&#x25bc; Next</div></div>');

  AOutputFile.WriteLine(StartTag('table', SourceClass));
  while AInputFile.Peek <> -1 do
  begin
    InputLine := AInputFile.ReadLine;
    InputLine := TNetEncoding.HTML.Encode(TrimRight(InputLine));
    LineCoverage := ACoverageModule.CoverageLine[LineCoverageIter];
    if (LineCount = LineCoverage.LineNumber) then
    begin
      if LineCoverage.IsCovered then
        WriteTableRow('covered', LineCoverage.LineCount)
      else
        WriteTableRow('notcovered');

      Inc(LineCoverageIter);
    end
    else
      WriteTableRow('nocodegen');

    Inc(LineCount);
  end;
  AOutputFile.WriteLine(EndTag('table'));

  AOutputFile.WriteLine(
  '<script>(function () {'#10 +
    'var starts = [],' +
      'prev = document.getElementById("nav-prev"),' +
   	'next = document.getElementById("nav-next");'#10 +
    '(function () {'#10 +
      'var p;'#10 +
	   'document.querySelectorAll("table.s tr").forEach(r => {'#10 +
		   'if (r.classList.contains("notcovered")) {'#10 +
			   'if (!p) starts.push(r);'#10 +
   			'p = r;'#10 +
   		'} else { p = null }'#10 +
   	'})'#10 +
    '})();'#10 +
    'function findPrev() {'#10 +
	   'var y = prev.getBoundingClientRect().top - 4;'#10 +
	   'for (var i=starts.length-1; i>=0; i--) {'#10 +
		  'if (starts[i].getBoundingClientRect().top < y) return starts[i]'#10 +
   	'}'#10 +
    '}'#10 +
    'function findNext() {'#10 +
	   'var y = next.getBoundingClientRect().top + 4;'#10 +
	   'for (var i=0; i<starts.length; i++) {'#10 +
		   'if (starts[i].getBoundingClientRect().top > y) return starts[i];'#10 +
   	'}'#10 +
    '}'#10 +
    'function onScroll() {'#10 +
	   'prev.setAttribute("class", findPrev() ? "active" : "");'#10 +
	   'next.setAttribute("class", findNext() ? "active" : "");'#10 +
	   'onScroll.pending = 0;'#10 +
    '}'#10 +
    'document.addEventListener("scroll", function() {'#10 +
	   'if (!onScroll.pending) { onScroll.pending = requestAnimationFrame(onScroll) }'#10 +
    '});'#10 +
    'onScroll();'#10 +
    'function scrollTo(row) {'#10 +
      'if (row) window.scrollTo({ behavior: "smooth", top: window.scrollY+row.getBoundingClientRect().top-prev.getBoundingClientRect().top });'#10 +
    '}'#10 +
    'next.addEventListener("click", () => scrollTo(findNext()) );'#10 +
    'prev.addEventListener("click", () => scrollTo(findPrev()) );'#10 +
  '})();</script>'
  );
end;

end.

