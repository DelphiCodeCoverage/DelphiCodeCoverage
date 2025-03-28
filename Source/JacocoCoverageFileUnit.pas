(* ********************************************************************* *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi *)
(* by Christer Fahlgren and Nick Ring *)
(* *)
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/. *)

unit JacocoCoverageFileUnit;

interface

uses
  I_Report,
  I_CoverageStats,
  JclSimpleXml,
  JclStreams,
  I_CoverageConfiguration,
  ClassInfoUnit,
  I_LogManager;

type
  TJacocoCoverageReport = class(TInterfacedObject, IReport)
  strict private
    FCoverageConfiguration: ICoverageConfiguration;

    procedure AddModuleInfo(AAllElement: TJclSimpleXMLElem; const AModuleInfo: TModuleInfo;
      const ACoverage: ICoverageStats);
    procedure AddLineCodeStats(ARootElement: TJclSimpleXMLElem; const ACoverage: ICoverageStats;
      const AModule: TModuleInfo);
    procedure AddModuleLineHits(ALineHitsElement: TJclSimpleXMLElem; const ACoverage: ICoverageStats);
    procedure AddModuleStats(const RootElement: TJclSimpleXMLElem; const AModule: TModuleInfo);
    procedure AddClassInfo(ASourceFileElement: TJclSimpleXMLElem; const AModule: TModuleInfo);
    procedure AddClassStats(const ARootElement: TJclSimpleXMLElem; const AClass: TClassInfo);
    procedure AddMethodInfo(AClassElement: TJclSimpleXMLElem; const AMethod: TProcedureInfo);
    procedure AddMethodStats(const ARootElement: TJclSimpleXMLElem; const AMethod: TProcedureInfo);
    procedure AddSourceStats(const ARootElement: TJclSimpleXMLElem; const AModule: TModuleInfo);

    procedure AddCoverageElement(const RootElement: TJclSimpleXMLElem; const AType: string;
      const TotalCoveredCount, TotalUncoveredCount: Integer);
    function GetCoverageStringValue(const ACovered, ATotal: Integer): string;
  public
    constructor Create(const ACoverageConfiguration: ICoverageConfiguration);

    procedure Generate(const ACoverage: ICoverageStats; const AModuleInfoList: TModuleList;
      const ALogManager: ILogManager);
  end;

  TJacocoCoverageReportMerger = class helper for TJacocoCoverageReport
    class function MergeCoverageStatsForGenerics(const ACoverageStatsIn: ICoverageStats): ICoverageStats;
  end;

implementation

uses
  System.DateUtils,
  System.StrUtils,
  System.SysUtils,
  System.Math,
  JclFileUtils,
  Generics.Collections, CoverageStats;

constructor TJacocoCoverageReport.Create(const ACoverageConfiguration: ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

procedure TJacocoCoverageReport.Generate(const ACoverage: ICoverageStats; const AModuleInfoList: TModuleList;
  const ALogManager: ILogManager);

var
  StatsElement: TJclSimpleXMLElem;

  procedure AddValueElement(const AElementName: string; const AValue: Integer);
  begin
    StatsElement.Items.Add(AElementName).Properties.Add('value', AValue);
  end;

  procedure AddElement(AElement: TJclSimpleXMLElem; const APropertyName: string; const AValue: Integer); overload;
  begin
    AElement.Properties.Add(APropertyName, AValue);
  end;

  procedure AddElement(AElement: TJclSimpleXMLElem; const APropertyName: string; const AValue: String); overload;
  begin
    AElement.Properties.Add(APropertyName, AValue);
  end;

var
  Uid: TGuid;
  Result: HResult;

  ModuleInfo: TModuleInfo;
  XML: TJclSimpleXML;
  SessionElement: TJclSimpleXMLElem;
  DataElement: TJclSimpleXMLElem;
  LineHitsElement: TJclSimpleXMLElem;
  CoverageIndex: Integer;
  FileIndex: Integer;
  ModuleCoverage: ICoverageStats;
  XmlLinesCoverage: ICoverageStats;
begin
  ALogManager.Log('Generating jacoco xml report');

  XML := TJclSimpleXML.Create;
  try

    // Prolog doesn't seem to get written properly (with carriage returns)
    XML.Prolog.AddDocType('report PUBLIC "-//JACOCO//DTD Report 1.0//EN" "report.dtd"');
    XML.Prolog.Standalone := true;

    XML.Root.Name := 'report';
    AddElement(XML.Root, 'name', 'debug'); // For now

    SessionElement := XML.Root.Items.Add('session');

    Result := CreateGuid(Uid);
    if Result = S_OK then
      SessionElement.Properties.Add('id', GuidToString(Uid)); { TODO: Not sure of the format }
    SessionElement.Properties.Add('start', DateTimeToUnix(now)); { TODO: Should be a start time }
    SessionElement.Properties.Add('dump', DateTimeToUnix(now));

    for ModuleInfo in AModuleInfoList do
    begin
      AddModuleInfo(XML.Root, ModuleInfo, ACoverage);
    end;
    (*
      if FCoverageConfiguration.XmlLines then
      begin
      if FCoverageConfiguration.XmlMergeGenerics then begin
      ALogManager.Log('Merging units for generics.');
      XmlLinesCoverage := MergeCoverageStatsForGenerics(ACoverage);
      end else
      XmlLinesCoverage := ACoverage;

      LineHitsElement := DataElement.Items.Add('linehits');
      for CoverageIndex := 0 to XmlLinesCoverage.Count - 1 do
      begin
      ModuleCoverage := XmlLinesCoverage.CoverageReport[CoverageIndex];
      ALogManager.Log('Coverage for module: ' + ModuleCoverage.Name);
      for FileIndex := 0 to ModuleCoverage.Count - 1 do
      begin
      AddModuleLineHits(LineHitsElement, ModuleCoverage[FileIndex]);
      end;
      end;
      end;
    *)

    XML.SaveToFile(PathAppend(FCoverageConfiguration.OutputDir, 'jacoco.xml'), seUTF8);
  finally
    XML.Free;
  end;
end;

procedure TJacocoCoverageReport.AddModuleInfo(AAllElement: TJclSimpleXMLElem; const AModuleInfo: TModuleInfo;
  const ACoverage: ICoverageStats);
var
  PackageElement: TJclSimpleXMLElem;
  SourceFileElement: TJclSimpleXMLElem;
begin
  PackageElement := AAllElement.Items.Add('package');
  PackageElement.Properties.Add('name', AModuleInfo.ModuleName.Replace('.', '/'));

  AddClassInfo(PackageElement, AModuleInfo);

  SourceFileElement := PackageElement.Items.Add('sourcefile');
  SourceFileElement.Properties.Add('name', AModuleInfo.ModuleFileName);

  AddLineCodeStats(SourceFileElement, ACoverage, AModuleInfo);

  { TODO: Lines }
  AddSourceStats(SourceFileElement, AModuleInfo);

end;

procedure TJacocoCoverageReport.AddModuleLineHits(ALineHitsElement: TJclSimpleXMLElem; const ACoverage: ICoverageStats);
var
  Line: Integer;
  FileElement: TJclSimpleXMLElem;
  StringBuilder: TStringBuilder;
  CoverageLine: TCoverageLine;
begin
  if FCoverageConfiguration.ExcludedUnits.IndexOf(StringReplace(ExtractFileName(ACoverage.Name),
    ExtractFileExt(ACoverage.Name), '', [rfReplaceAll, rfIgnoreCase])) < 0 then
  begin
    FileElement := ALineHitsElement.Items.Add('file');
    FileElement.Properties.Add('name', ACoverage.Name);
    StringBuilder := TStringBuilder.Create;
    try
      for Line := 0 to ACoverage.GetCoverageLineCount - 1 do
      begin
        CoverageLine := ACoverage.CoverageLine[Line];
        StringBuilder.Append(IfThen(Line = 0, '', ';')).Append(CoverageLine.LineNumber).Append('=')
          .Append(CoverageLine.LineCount);
      end;
      FileElement.Value := StringBuilder.ToString;
    finally
      StringBuilder.Free;
    end;
  end;
end;

procedure TJacocoCoverageReport.AddModuleStats(const RootElement: TJclSimpleXMLElem; const AModule: TModuleInfo);
begin
  AddCoverageElement(RootElement, 'class, %', AModule.CoveredClassCount, AModule.ClassCount);

  AddCoverageElement(RootElement, 'method, %', AModule.CoveredMethodCount, AModule.MethodCount);

  AddCoverageElement(RootElement, 'block, %', AModule.CoveredLineCount, AModule.LineCount);

  AddCoverageElement(RootElement, 'line, %', AModule.CoveredLineCount, AModule.LineCount);
end;

procedure TJacocoCoverageReport.AddSourceStats(const ARootElement: TJclSimpleXMLElem; const AModule: TModuleInfo);
begin
  AddCoverageElement(ARootElement, 'LINE', AModule.CoveredLineCount, AModule.LineCount - AModule.CoveredLineCount);

  AddCoverageElement(ARootElement, 'METHOD', AModule.CoveredMethodCount,
    AModule.MethodCount - AModule.CoveredMethodCount);

  AddCoverageElement(ARootElement, 'CLASS', AModule.CoveredClassCount, AModule.ClassCount - AModule.CoveredClassCount);
end;

procedure TJacocoCoverageReport.AddClassInfo(ASourceFileElement: TJclSimpleXMLElem; const AModule: TModuleInfo);
var
  Method: TProcedureInfo;
  ClassElement: TJclSimpleXMLElem;
  ClassInfo: TClassInfo;
begin
  for ClassInfo in AModule do
  begin
    ClassElement := ASourceFileElement.Items.Add('class');
    { TODO: Check whether this is enough }
    ClassElement.Properties.Add('name', ClassInfo.Module.Replace('.', '/') + '/' + ClassInfo.TheClassName);
    ClassElement.Properties.Add('sourcefilename', AModule.ModuleFileName);

    for Method in ClassInfo do
      AddMethodInfo(ClassElement, Method);

    AddClassStats(ClassElement, ClassInfo);
  end;
end;

procedure TJacocoCoverageReport.AddClassStats(const ARootElement: TJclSimpleXMLElem; const AClass: TClassInfo);
begin
  AddCoverageElement(ARootElement, 'LINE', AClass.CoveredLineCount, AClass.LineCount - AClass.CoveredLineCount);

  AddCoverageElement(ARootElement, 'METHOD', AClass.CoveredProcedureCount,
    AClass.ProcedureCount - AClass.CoveredProcedureCount);

  // AddCoverageElement(ARootElement,
  // 'CLASS',
  // AClass.,
  // 100 - AClass.PercentCovered);
end;

procedure TJacocoCoverageReport.AddMethodInfo(AClassElement: TJclSimpleXMLElem; const AMethod: TProcedureInfo);
var
  MethodElement: TJclSimpleXMLElem;
begin
  MethodElement := AClassElement.Items.Add('method');
  MethodElement.Properties.Add('name', AMethod.Name);
  MethodElement.Properties.Add('desc', '()'); { TODO: Not sure we can pull this out }
  AddMethodStats(MethodElement, AMethod);
end;

procedure TJacocoCoverageReport.AddMethodStats(const ARootElement: TJclSimpleXMLElem; const AMethod: TProcedureInfo);
// var
// IsCovered: Integer;
begin
  // IsCovered := IfThen(AMethod.PercentCovered > 0, 1, 0);

  { TODO: Not sure about these either! }

  // INSTRUCTION
  { TODO: Is this the same as LINE? }
  // AddCoverageElement(ARootElement,
  // 'counter',
  // 'INSTRUCTION',
  // AMethod.CoveredLineCount,
  // AMethod.LineCount - AMethod.CoveredLineCount);

  // LINE
  AddCoverageElement(ARootElement, 'LINE', AMethod.CoveredLineCount, AMethod.LineCount - AMethod.CoveredLineCount);

  // AddCoverageElement(ARootElement,
  // 'METHOD',
  // AMethod.PercentCovered,
  // 100 - AMethod.PercentCovered);

  // AddCoverageElement(ARootElement,
  // 'counter',
  // 'INSTRUCTION',
  // AMethod.CoveredLineCount,
  // AMethod.LineCount - AMethod.CoveredLineCount);

  // AddCoverageElement(ARootElement,
  // 'counter',
  // 'COMPLEXITY',
  // AMethod.CoveredLineCount,
  // AMethod.LineCount - AMethod.CoveredLineCount);

  (*
    AddCoverageElement(
    ARootElement, 'counter',
    AMethod.CoveredLineCount, AMethod.LineCount
    );

    AddCoverageElement(
    ARootElement, 'counter',
    AMethod.CoveredLineCount, AMethod.LineCount
    );

    AddCoverageElement(
    ARootElement, 'counter',
    AMethod.CoveredLineCount, AMethod.LineCount
    );
  *)
end;

procedure TJacocoCoverageReport.AddCoverageElement(const RootElement: TJclSimpleXMLElem; const AType: string;
  const TotalCoveredCount, TotalUncoveredCount: Integer);
var
  CoverageElement: TJclSimpleXMLElem;
begin
  CoverageElement := RootElement.Items.Add('counter');
  CoverageElement.Properties.Add('type', AType);
  CoverageElement.Properties.Add('covered', TotalCoveredCount);
  CoverageElement.Properties.Add('missed', TotalUncoveredCount);

end;

procedure TJacocoCoverageReport.AddLineCodeStats(ARootElement: TJclSimpleXMLElem; const ACoverage: ICoverageStats;
  const AModule: TModuleInfo);
var
  LineCount: Integer;
  LineCoverage: TCoverageLine;
  CoverageUnit: ICoverageStats;
  CoverageLineElement: TJclSimpleXMLElem;
begin
  LineCount := 0;

  CoverageUnit := ACoverage.CoverageReportByName[AModule.ModuleName].CoverageReportByName[AModule.ModuleFileName];

  for LineCount := 0 to Pred(CoverageUnit.LineCount) do
  begin
    LineCoverage := CoverageUnit.CoverageLine[LineCount];

    CoverageLineElement := ARootElement.Items.Add('line');
    CoverageLineElement.Properties.Add('nr', LineCoverage.LineNumber);

    CoverageLineElement.Properties.Add('mi', IfThen(LineCoverage.IsCovered, 0, 1));
    CoverageLineElement.Properties.Add('ci', IfThen(LineCoverage.IsCovered, 1, 0));
    CoverageLineElement.Properties.Add('mb', 0);
    CoverageLineElement.Properties.Add('cb', 0);
  end;
end;

function TJacocoCoverageReport.GetCoverageStringValue(const ACovered, ATotal: Integer): string;
var
  Percent: Integer;
begin
  if ATotal = 0 then
    Percent := 0
  else
    Percent := Round(ACovered * 100 / ATotal);

  Result := IntToStr(Percent) + '%   (' + IntToStr(ACovered) + '/' + IntToStr(ATotal) + ')';
end;

{ TJacocoCoverageReportMerger }

class function TJacocoCoverageReportMerger.MergeCoverageStatsForGenerics(const ACoverageStatsIn: ICoverageStats)
  : ICoverageStats;
var
  i, j, Line: Integer;
  LModuleStats, LUnitStats, LResultStats: ICoverageStats;
  FResultModuleName, FResultUnitName: String;
  LCoverageLine: TCoverageLine;
begin
  Result := TCoverageStats.Create(ACoverageStatsIn.Name, ACoverageStatsIn.Parent);

  // Loop all modules
  for i := 0 to ACoverageStatsIn.Count - 1 do
  begin
    LModuleStats := ACoverageStatsIn.CoverageReport[i];

    // Loop all units
    for j := 0 to LModuleStats.Count - 1 do
    begin
      LUnitStats := LModuleStats.CoverageReport[j];

      FResultModuleName := LUnitStats.Name.Substring(0, LUnitStats.Name.LastIndexOf('.'));
      FResultUnitName := LUnitStats.Name;

      LResultStats := Result.CoverageReportByName[FResultModuleName].CoverageReportByName[FResultUnitName];

      // Add all coverage lines
      for Line := 0 to ACoverageStatsIn.CoverageReport[i].CoverageReport[j].GetCoverageLineCount - 1 do
      begin
        LCoverageLine := ACoverageStatsIn.CoverageReport[i].CoverageReport[j].CoverageLine[Line];
        LResultStats.AddLineCoverage(LCoverageLine.LineNumber, LCoverageLine.LineCount);
      end;
    end;
  end;

  Result.Calculate;
end;

end.
