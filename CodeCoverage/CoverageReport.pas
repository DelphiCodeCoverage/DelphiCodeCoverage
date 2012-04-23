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
  ClassInfoUnit;

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

    procedure Generate(const ACoverage: ICoverageStats;const AModuleInfoList: TModuleList);
  end;

var
  CompanyBrandingName : string = 'FMS'; // Company Name thas uses this tool
  ParagraphStartTag : string = '<P>';
  ParagraphEndTag  : string = '</P>';
  HeadingStartTagOne : string = '<H1>';
  HeadingEndTagOne : string = '</H1>';
  BoldStartTag : string = '<STRONG>';
  BoldEndTag  : string = '</STRONG>';
  TDStartTagOne : string = '<TD>';
  TDEndTagOne : string = '</TD>';
  TRStartTagOne : string = '<TR>';
  TREndTagOne : string = '</TR>';

implementation

uses
  SysUtils,
  JclFileUtils,
  JvStrToHtml;

procedure TCoverageReport.Generate(const ACoverage: ICoverageStats;const AModuleInfoList: TModuleList);
var
  OutputFile     : TextFile;
  OutputFileName : string;
begin
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
    WriteLn(OutputFile, HeadingStartTagOne + ' Summary Coverage Report' + HeadingEndTagOne);
    WriteLn(OutputFile, ParagraphStartTag + ' Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
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
      WriteLn(OutputFile, ParagraphStartTag + ' Coverage report for ' + BoldStartTag + ACoverageModule.GetName() + BoldeNDTag + '.' + ParagraphEndTag);
      WriteLn(OutputFile, ParagraphStartTag + ' Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
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
        WriteLn(OutputFile, ParagraphStartTag + ' Coverage report for ' + BoldStartTag +
                            ACoverageUnit.Parent.GetName() +
                            ' (' + SourceFileName + ')' + BoldEndTag + 
                            '.' + ParagraphEndTag);
        WriteLn(OutputFile, ParagraphStartTag + ' Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
            ' by <a href="http://code.google.com/p/delphi-code-coverage/" title="Code Coverage for Delphi 5+" />DelphiCodeCoverage</a> - an open source tool for Delphi Code Coverage.' + ParagraphEndTag);
        WriteLn(OutputFile, ParagraphStartTag + '<u>Used for ' + CompanyBrandingName + ' internal use ONLY. Any unauthroized use will be taken by law under maximum penality possible!</u>' + ParagraphEndTag);
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
    WriteLn(AOutputFile, '  <TR>');

    HtmlDetails.HasFile := False;
    if Assigned(ACoverageStatsProc) then
      HtmlDetails := ACoverageStatsProc(ACoverageStats.CoverageReport[lp]);

    SetPrePostLink(HtmlDetails, PreLink, PostLink);

    WriteLn(AOutputFile, '    <TD>' + PreLink + HtmlDetails.LinkName + PostLink + ' </TD>');
    WriteLn(AOutputFile, ' </TD>');
    WriteLn(AOutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverageStats.CoverageReport[lp].GetNumberOfCoveredLines()) + '</TD>');
    WriteLn(AOutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverageStats.CoverageReport[lp].GetNumberOfLines()) + '</TD>');
    WriteLn(AOutputFile, '    <TD ALIGN="Right"><i>' + IntToStr(ACoverageStats.CoverageReport[lp].GetPercentCovered()) + '%</i></TD>');
    WriteLn(AOutputFile, '  </TR>');
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
    PreLink := '<A HREF="' + LLinkFileName + '">';
    PostLink := '</A>';
  end;
end;

procedure TCoverageReport.AddPreAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '<HTML><HEAD><META CONTENT="text/html; charset=ISO-8859-1" HTTP-EQUIV="Content-Type" />');
  WriteLn(AOutFile, '<TITLE>Delphi CodeCoverage Coverage Report</TITLE>
  if FileExists(Application.ExeName + '\style.css') then
    WriteLn(AOutFile, '    <link rel="stylesheet" href="style.css" type="text/css" /></HEAD>')
  else
  begin
    WriteLn(AOutFile, '    <STYLE TYPE="text/css"> TABLE, TD, TH {border-style: solid;border-color: black;}');
    WriteLn(AOutFile, 'TD, TH { background: white; margin: 0; line-height: 100%; padding-left: 0.5em; padding-right: 0.5em;}');
    WriteLn(AOutFile, 'TD { border-width: 0 1px 0 0;} TH { border-width: 1px 1px 1px 0; }');
    WriteLn(AOutFile, 'P, H1, H2, H3, TH { font-family: verdana,arial,sans-serif; font-size: 10pt;}');
    WriteLn(AOutFile, 'TD { font-family: courier,monospace; font-size: 10pt;}');
    WriteLn(AOutFile, 'TABLE.s TD {padding-left: 0.25em; padding-right: 0.25em; }');
    WriteLn(AOutFile, 'TABLE.s TR.notcovered TD { background: #DDDDFF; }');
    WriteLn(AOutFile, 'TABLE.s TR.nocodegen TD { background: #FFFFEE; }');
    WriteLn(AOutFile, 'TABLE.s TR.covered TD { background: #CCFFCC; }');
    WriteLn(AOutFile, 'TABLE.s {border-width: 1px 0 1px 1px; }');
	WriteLn(AOutFile, '    </STYLE></HEAD>');
  end;	
  WriteLn(AOutFile, '<BODY>');
end;

procedure TCoverageReport.AddPostAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '</BODY></HTML>');
end;

procedure TCoverageReport.AddStatistics(const ACoverageBase: ICoverageStats;
                                        const ASourceFileName: string;
										const AOutFile: TextFile);
begin
  WriteLn(AOutFile, ParagraphStartTag + ' Statistics for ' + ASourceFileName + ' ' + ParagraphEndTag);

  WriteLn(AOutFile, '<TABLE CLASS="s" CELLSPACING="0">');
  WriteLn(AOutFile, '  <TR>');
  WriteLn(AOutFile, '    <TD>Number of lines covered</TD>');
  WriteLn(AOutFile, '    <TD ALIGN="RIGHT">' + IntToStr(ACoverageBase.GetNumberOfCoveredLines()) + '</TD>');
  WriteLn(AOutFile, '  </TR>');
  WriteLn(AOutFile, '  <TR>');
  WriteLn(AOutFile, '    <TD>Number of lines with code gen</TD>');
  WriteLn(AOutFile, '    <TD ALIGN="RIGHT">' + IntToStr(ACoverageBase.GetNumberOfLines()) + '</TD>');
  WriteLn(AOutFile, '  </TR>');
  WriteLn(AOutFile, '  <TR>');
  WriteLn(AOutFile, '    <TD>Line coverage in <i>percent</i></TD>');
  WriteLn(AOutFile, '    <TD ALIGN="RIGHT">' + IntToStr(ACoverageBase.GetPercentCovered()) + '%</TD>');
  WriteLn(AOutFile, '  </TR>');
  WriteLn(AOutFile, '</TABLE>');

  WriteLn(AOutFile, '<BR><BR>');
end;

procedure TCoverageReport.AddTableFooter(const AHeading: string;
                                         const ACoverageStats: ICoverageStats;
                                         const AOutputFile: TextFile);
begin
  WriteLn(AOutputFile, '  <TR>');
  WriteLn(AOutputFile, '  <TR>');
  WriteLn(AOutputFile, '    <TD CLASS="h">' + JvStrToHtml.StringToHtml(AHeading) + '</TD>');
  WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="h">' + IntToStr(ACoverageStats.GetNumberOfCoveredLines()) + '</TD>');
  WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="h">' + IntToStr(ACoverageStats.GetNumberOfLines()) + '</TD>');
  WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="h"></i>' + IntToStr(ACoverageStats.GetPercentCovered()) + '%</i></TD>');
  WriteLn(AOutputFile, '  </TR>');
  WriteLn(AOutputFile, '</TABLE>');
end;

procedure TCoverageReport.AddTableHeader(const ATableHeading: string;
                                         const AColumnHeading: string;
                                         const AOutputFile: TextFile);
begin
  WriteLn(AOutputFile, ParagraphStartTag + JvStrToHtml.StringToHtml(ATableHeading) + ParagraphEndTag);
  WriteLn(AOutputFile, '<TABLE>');
  WriteLn(AOutputFile, '  <TR>');
  WriteLn(AOutputFile, '    <TD>' + JvStrToHtml.StringToHtml(AColumnHeading) + '</TD>');
  WriteLn(AOutputFile, '    <TD>Number of covered lines</TD>');
  WriteLn(AOutputFile, '    <TD>Number of lines (which generated code)</TD>');
  WriteLn(AOutputFile, '    <TD>Percent(s) covered</TD>');
  WriteLn(AOutputFile, '  </TR>');
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
  LineCoverageiter : Integer;
  LineCount        : Integer;
begin
  LineCoverageiter := 0;
  WriteLn(AOutputFile, '   <TABLE CLASS="s" WIDTH="100%" CELLSPACING="0">');
  LineCount := 1;
  while (not Eof(AInputFile)) do
  begin
    ReadLn(AInputFile, InputLine);
    InputLine := JvStrToHtml.StringToHtml(TrimRight(InputLine));
    LineCoverage := ACoverageModule.GetCoverageLine(LineCoverageiter);
    if (LineCount = LineCoverage.LineNumber) then
    begin
      if (LineCoverage.Covered) then
      begin
        WriteLn(AOutputFile, '  <TR CLASS="covered">');
        WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="1"><font color="green"> + BoldStartTag + IntToStr(LineCount) + BoldEndTag + '</font></TD>');
        WriteLn(AOutputFile, '    <TD><PRE STYLE="display: inline">' + InputLine + '</PRE></TD>');
        WriteLn(AOutputFile, '  </TR>');
      end
      else
      begin
        WriteLn(AOutputFile, '  <TR CLASS="notcovered">');
        WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="1">' + IntToStr(LineCount) + '</TD>');
        WriteLn(AOutputFile, '    <TD><PRE STYLE="display: inline">' + InputLine + '</PRE></TD>');
        WriteLn(AOutputFile, '  </TR>');
      end;
      inc(LineCoverageiter);
    end
    else
    begin
      WriteLn(AOutputFile, '  <TR CLASS="nocodegen">');
      WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="1">' + IntToStr(LineCount) + '</TD>');
      WriteLn(AOutputFile, '    <TD><PRE STYLE="display: inline">' + InputLine + '</PRE></TD>');
      WriteLn(AOutputFile, '  </TR>');
    end;
    inc(LineCount);
  end;
  WriteLn(AOutputFile, '</TABLE>');
end;

end.

