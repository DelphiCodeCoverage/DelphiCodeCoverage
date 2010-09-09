(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit CoverageReport;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  I_Report,
  I_CoverageStats;

type
  THtmlDetails = record
    LinkFileName : string;
    LinkName     : string;
    HasFile      : Boolean;
  end;

type
  TCoverageReport = class(TInterfacedObject, IReport)
  private
    procedure AddPostAmble(const AOutFile: TextFile);
    procedure AddPreAmble(const AOutFile: TextFile);

    function FindSourceFile(const ACoverageUnit: ICoverageStats; const
        ASourceDirLst: TStrings; var HtmlDetails: THtmlDetails): string;

    procedure AddStatistics(const ACoverageBase: ICoverageStats; const
        ASourceFileName: string; const AOutFile: TextFile);
    procedure GenerateCoverageTable(const ACoverageModule: ICoverageStats; const AOutputFile, AInputFile: TextFile);

    function GenerateModuleReport(const ACoverageModule: ICoverageStats; const
        ASourceDirLst: TStrings; const AOutputDir: string): THtmlDetails;
    function GenerateUnitReport(const ACoverageUnit: ICoverageStats; const
        ASourceDirLst: TStrings; const AOutputDir: string): THtmlDetails;
  public
    procedure Generate(const ACoverage: ICoverageStats;
                       const ASourceDirLst: TStrings;
                       const AOutputDir: string);
  end;

implementation

uses
  SysUtils,
  JclFileUtils;

procedure TCoverageReport.Generate(const ACoverage: ICoverageStats; const
    ASourceDirLst: TStrings; const AOutputDir: string);
var
  OutputFile     : TextFile;
  lp             : Integer;
  PreLink        : string;
  PostLink       : string;
  OutputFileName : string;
  HtmlDetails    : THtmlDetails;
begin
  if (ASourceDirLst.Count > 0) then
    WriteLn('Source dir:' + ASourceDirLst.Strings[0])
  else
    WriteLn('Source dir:<none>');

  WriteLn('Output dir:' + AOutputDir);

  OutputFileName := 'CodeCoverage_summary.html';
  OutputFileName := PathAppend(AOutputDir, OutputFileName);
  AssignFile(OutputFile, OutputFileName);
  try
    System.FileMode := fmOpenReadWrite;
    ReWrite(OutputFile);
    AddPreAmble(OutputFile);
    WriteLn(OutputFile, '<H1> Summary Coverage Report</H1>');
    WriteLn(OutputFile, '<P> Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
        ' by DelphiCodeCoverage - an open source tool for Delphi Code Coverage.</P>');

    WriteLn(OutputFile, '<P>Aggregate statistics for all modules</P>');
    WriteLn(OutputFile, '<TABLE>');
    WriteLn(OutputFile, '  <TR>');
    WriteLn(OutputFile, '    <TD>Unit Name</TD>');
    WriteLn(OutputFile, '    <TD>Number of covered lines</TD>');
    WriteLn(OutputFile, '    <TD>Number of lines (which generated code)</TD>');
    WriteLn(OutputFile, '    <TD>Percent covered</TD>');
    WriteLn(OutputFile, '  </TR>');

    for lp := 0 to Pred(ACoverage.GetCount) do
    begin
      WriteLn(OutputFile, '  <TR>');

      PreLink  := '';
      PostLink := '';

      HtmlDetails := GenerateModuleReport(ACoverage.CoverageReport[lp], ASourceDirLst, AOutputDir);

      if HtmlDetails.HasFile then
      begin
        PreLink := '<A HREF="' + HtmlDetails.LinkFileName + '">';
        PostLink := '</A>';
      end;
      WriteLn(OutputFile, '    <TD>' + PreLink + HtmlDetails.LinkName + PostLink + ' </TD>');
      WriteLn(OutputFile, ' </TD>');
      WriteLn(OutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverage.CoverageReport[lp].GetNumberOfCoveredLines()) + '</TD>');
      WriteLn(OutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverage.CoverageReport[lp].GetNumberOfLines()) + '</TD>');
      WriteLn(OutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverage.CoverageReport[lp].GetPercentCovered()) + '%</TD>');
      WriteLn(OutputFile, '  </TR>');
    end;
    WriteLn(OutputFile, '  <TR>');
    WriteLn(OutputFile, '  <TR>');
    WriteLn(OutputFile, '    <td class="h">Aggregated for all units</TD>');
    WriteLn(OutputFile, '    <TD ALIGN="Right" class="h">' + IntToStr(ACoverage.GetNumberOfCoveredLines()) + '</TD>');
    WriteLn(OutputFile, '    <TD ALIGN="Right" class="h">' + IntToStr(ACoverage.GetNumberOfLines()) + '</TD>');
    WriteLn(OutputFile, '    <TD ALIGN="Right" class="h">' + IntToStr(ACoverage.GetPercentCovered()) + '%</TD>');
    WriteLn(OutputFile, '  </TR>');
    WriteLn(OutputFile, '</TABLE>');

    AddPostAmble(OutputFile);
  finally
    CloseFile(OutputFile);
  end;
end;

function TCoverageReport.GenerateModuleReport(const ACoverageModule:
    ICoverageStats; const ASourceDirLst: TStrings; const AOutputDir: string):
    THtmlDetails;
var
  OutputFile     : TextFile;
  lp             : Integer;
  OutputFileName : string;
  PreLink        : string;
  PostLink       : string;
  HtmlDetails    : THtmlDetails;
begin
  if (ACoverageModule.GetCount = 1) then
  begin
    Result          := GenerateUnitReport(ACoverageModule.CoverageReport[0], ASourceDirLst, AOutputDir);
    Result.LinkName := ACoverageModule.GetName;
    Exit;
  end;

  try
    Result.HasFile      := False;
    Result.LinkFileName := ACoverageModule.GetName + '.html';
    Result.LinkName     := ACoverageModule.GetName;

    OutputFileName := PathAppend(AOutputDir, Result.LinkFileName);

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
      WriteLn(OutputFile, '<P> Coverage report for <STRONG>' + ACoverageModule.GetName() + '</STRONG>.</P>');
      WriteLn(OutputFile, '<P> Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
          ' by DelphiCodeCoverage - an open source tool for Delphi Code Coverage.</P>');

      WriteLn(OutputFile, '<P>Aggregate statistics for all units</P>');
      WriteLn(OutputFile, '<TABLE>');
      WriteLn(OutputFile, '  <TR>');
      WriteLn(OutputFile, '    <TD>Source File Name</TD>');
      WriteLn(OutputFile, '    <TD>Number of covered lines</TD>');
      WriteLn(OutputFile, '    <TD>Number of lines (which generated code)</TD>');
      WriteLn(OutputFile, '    <TD>Percent covered</TD>');
      WriteLn(OutputFile, '  </TR>');

      for lp := 0 to Pred(ACoverageModule.GetCount) do
      begin
        WriteLn(OutputFile, '  <TR>');

        PreLink  := '';
        PostLink := '';

        HtmlDetails := GenerateUnitReport(ACoverageModule.CoverageReport[lp], ASourceDirLst, AOutputDir);

        if HtmlDetails.HasFile then
        begin
          PreLink := '<A HREF="' + HtmlDetails.LinkFileName + '">';
          PostLink := '</A>';
        end;
        WriteLn(OutputFile, '    <TD>' + PreLink + HtmlDetails.LinkName + PostLink + ' </TD>');
        WriteLn(OutputFile, ' </TD>');
        WriteLn(OutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverageModule.CoverageReport[lp].GetNumberOfCoveredLines()) + '</TD>');
        WriteLn(OutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverageModule.CoverageReport[lp].GetNumberOfLines()) + '</TD>');
        WriteLn(OutputFile, '    <TD ALIGN="Right">' + IntToStr(ACoverageModule.CoverageReport[lp].GetPercentCovered()) + '%</TD>');
        WriteLn(OutputFile, '  </TR>');
      end;
      WriteLn(OutputFile, '  <TR>');
      WriteLn(OutputFile, '  <TR>');
      WriteLn(OutputFile, '    <td class="h">Aggregated for all files</TD>');
      WriteLn(OutputFile, '    <TD ALIGN="Right" class="h">' + IntToStr(ACoverageModule.GetNumberOfCoveredLines()) + '</TD>');
      WriteLn(OutputFile, '    <TD ALIGN="Right" class="h">' + IntToStr(ACoverageModule.GetNumberOfLines()) + '</TD>');
      WriteLn(OutputFile, '    <TD ALIGN="Right" class="h">' + IntToStr(ACoverageModule.GetPercentCovered()) + '%</TD>');
      WriteLn(OutputFile, '  </TR>');
      WriteLn(OutputFile, '</TABLE>');

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

function TCoverageReport.GenerateUnitReport(const ACoverageUnit:
    ICoverageStats; const ASourceDirLst: TStrings; const AOutputDir: string):
    THtmlDetails;
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
    SourceFileName := FindSourceFile(ACoverageUnit, ASourceDirLst, Result);

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
      OutputFileName := PathAppend(AOutputDir, OutputFileName);

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
        WriteLn(OutputFile, '<P> Coverage report for <STRONG>' +
                            ACoverageUnit.Parent.GetName() +
                            ' (' + SourceFileName + ')' +
                            '</STRONG>.</P>');
        WriteLn(OutputFile, '<P> Generated at ' + DateToStr(now) + ' ' + TimeToStr(now) +
            ' by DelphiCodeCoverage - an open source tool for Delphi Code Coverage.</P>');
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

procedure TCoverageReport.AddPreAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '<HTML><HEAD><META CONTENT="text/html; charset=ISO-8859-1" HTTP-EQUIV="Content-Type" />');
  WriteLn(AOutFile, '<TITLE>Delphi CodeCoverage Coverage Report</TITLE> <STYLE TYPE="text/css"> TABLE, TD, TH {border-style: solid;border-color: black;}');
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
  WriteLn(AOutFile, '<BODY>');
end;

procedure TCoverageReport.AddPostAmble(const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '</BODY></HTML>');
end;

procedure TCoverageReport.AddStatistics(const ACoverageBase: ICoverageStats;
    const ASourceFileName: string; const AOutFile: TextFile);
begin
  WriteLn(AOutFile, '<P> Statistics for ' + ASourceFileName + ' </P>');

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
  WriteLn(AOutFile, '    <TD>Line coverage in percent</TD>');
  WriteLn(AOutFile, '    <TD ALIGN="RIGHT">' + IntToStr(ACoverageBase.GetPercentCovered()) + '%</TD>');
  WriteLn(AOutFile, '  </TR>');
  WriteLn(AOutFile, '</TABLE>');

  WriteLn(AOutFile, '<BR><BR>');
end;

function TCoverageReport.FindSourceFile(const ACoverageUnit: ICoverageStats;
    const ASourceDirLst: TStrings; var HtmlDetails: THtmlDetails): string;
var
  SourceFound     : Boolean;
  CrntSourcePath  : string;
  lpLst           : Integer;
  lpUnit          : Integer;
  ACoverageModule : ICoverageStats;
begin
  SourceFound := False;

  lpLst := 0;
  while (lpLst < ASourceDirLst.Count) and
        (not SourceFound) do
  begin
    CrntSourcePath := ASourceDirLst.Strings[lpLst];

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

procedure TCoverageReport.GenerateCoverageTable(const ACoverageModule:
    ICoverageStats; const AOutputFile, AInputFile: TextFile);
var
  LineCoverage     : TCoverageLine;
  InputLine        : string;
  LineCoverageiter : Integer;
  LineCount        : Integer;
begin
  LineCoverageiter := 0;
  //LineCount := 0;
  WriteLn(AOutputFile, '   <TABLE CLASS="s" WIDTH="100%" CELLSPACING="0">');
  LineCount := 1;
  while (not Eof(AInputFile)) do
  begin
    ReadLn(AInputFile, InputLine);
    LineCoverage := ACoverageModule.GetCoverageLine(LineCoverageiter);
    if (LineCount = LineCoverage.LineNumber) then
    begin
      if (LineCoverage.Covered) then
      begin
        WriteLn(AOutputFile, '  <TR CLASS="covered">');
        WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="1">' + IntToStr(LineCount) + '</TD>');
        WriteLn(AOutputFile, '    <TD><PRE STYLE="display: inline">' + TrimRight(InputLine) + '</PRE></TD>');
        WriteLn(AOutputFile, '  </TR>');
      end
      else
      begin
        WriteLn(AOutputFile, '  <TR CLASS="notcovered">');
        WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="1">' + IntToStr(LineCount) + '</TD>');
        WriteLn(AOutputFile, '    <TD><PRE STYLE="display: inline">' + TrimRight(InputLine) + '</PRE></TD>');
        WriteLn(AOutputFile, '  </TR>');
      end;
      inc(LineCoverageiter);
    end
    else
    begin
      WriteLn(AOutputFile, '  <TR CLASS="nocodegen">');
      WriteLn(AOutputFile, '    <TD ALIGN="RIGHT" CLASS="1">' + IntToStr(LineCount) + '</TD>');
      WriteLn(AOutputFile, '    <TD><PRE STYLE="display: inline">' + TrimRight(InputLine) + '</PRE></TD>');
      WriteLn(AOutputFile, '  </TR>');
    end;
    inc(LineCount);
  end;
  WriteLn(AOutputFile, '</TABLE>');
end;

end.

