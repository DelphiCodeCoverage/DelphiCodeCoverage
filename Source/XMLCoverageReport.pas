(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit XMLCoverageReport;

interface

uses
  I_Report,
  I_CoverageStats,
  JclSimpleXml,
  I_CoverageConfiguration,
  ClassInfoUnit,
  I_LogManager;

type
  TXMLCoverageReport = class(TInterfacedObject, IReport)
  strict private
    FCoverageConfiguration: ICoverageConfiguration;

    procedure AddAllStats(
      const AAllElement: TJclSimpleXMLElem;
      const ACoverageStats: ICoverageStats;
      const AModuleList: TModuleList);
    procedure AddModuleInfo(
      AAllElement: TJclSimpleXMLElem;
      const AModuleInfo: TModuleInfo);
    procedure AddModuleLineHits(
      ALineHitsElement: TJclSimpleXMLElem;
      const ACoverage: ICoverageStats);
    procedure AddModuleStats(
      const RootElement: TJclSimpleXMLElem;
      const AModule: TModuleInfo);
    procedure AddClassInfo(
      ASourceFileElement: TJclSimpleXMLElem;
      const AClassInfo: TClassInfo);
    procedure AddClassStats(
      const ARootElement: TJclSimpleXMLElem;
      const AClass: TClassInfo);
    procedure AddMethodInfo(
      AClassElement: TJclSimpleXMLElem;
      const AMethod: TProcedureInfo);
    procedure AddMethodStats(
      const ARootElement: TJclSimpleXMLElem;
      const AMethod: TProcedureInfo);

    procedure AddCoverageElement(const RootElement: TJclSimpleXMLElem;
      const AType: string; const TotalCoveredCount, TotalCount: Integer);
    function GetCoverageStringValue(const ACovered, ATotal: Integer): string;
  public
    constructor Create(const ACoverageConfiguration: ICoverageConfiguration);

    procedure Generate(
      const ACoverage: ICoverageStats;
      const AModuleInfoList: TModuleList;
      const ALogManager: ILogManager);
  end;

  TXMLCoverageReportMerger = class helper for TXMLCoverageReport
    class function MergeCoverageStatsForGenerics(const ACoverageStatsIn: ICoverageStats): ICoverageStats;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils,
  System.Math,
  JclFileUtils,
  Generics.Collections, CoverageStats;

constructor TXMLCoverageReport.Create(
  const ACoverageConfiguration: ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

procedure TXMLCoverageReport.Generate(
  const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList;
  const ALogManager: ILogManager);

var
  StatsElement: TJclSimpleXMLElem;

  procedure AddValueElement(const AElementName: string; const AValue: Integer);
  begin
    StatsElement.Items
      .Add(AElementName)
      .Properties.Add('value', AValue);
  end;

var
  ModuleInfo: TModuleInfo;
  XML: TJclSimpleXML;
  AllElement: TJclSimpleXMLElem;
  DataElement: TJclSimpleXMLElem;
  LineHitsElement: TJclSimpleXMLElem;
  CoverageIndex: Integer;
  FileIndex: Integer;
  ModuleCoverage: ICoverageStats;
  XmlLinesCoverage: ICoverageStats;
begin
  ALogManager.Log('Generating xml coverage report');

  XML := TJclSimpleXML.Create;
  try
    XML.Root.Name := 'report';

    StatsElement := XML.Root.Items.Add('stats');
    AddValueElement('packages', AModuleInfoList.Count);

    AddValueElement('classes', AModuleInfoList.ClassCount);
    AddValueElement('methods', AModuleInfoList.MethodCount);

    AddValueElement('srcfiles', AModuleInfoList.Count);
    AddValueElement('srclines', AModuleInfoList.LineCount);

    AddValueElement('totallines', ACoverage.LineCount);
    AddValueElement('coveredlines', ACoverage.CoveredLineCount);

    AddValueElement('coveredpercent', ACoverage.PercentCovered);

    DataElement := XML.Root.Items.Add('data');
    AllElement := DataElement.Items.Add('all');
    AllElement.Properties.Add('name', 'all classes');

    AddAllStats(AllElement, ACoverage, AModuleInfoList);

    for ModuleInfo in AModuleInfoList do
    begin
      AddModuleInfo(AllElement, ModuleInfo);
    end;

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

    XML.SaveToFile(
      PathAppend(FCoverageConfiguration.OutputDir, 'CodeCoverage_Summary.xml')
    );
  finally
    XML.Free;
  end;
end;

procedure TXMLCoverageReport.AddAllStats(
  const AAllElement: TJclSimpleXMLElem;
  const ACoverageStats: ICoverageStats;
  const AModuleList: TModuleList);
begin
  AddCoverageElement(
    AAllElement, 'class, %',
    AModuleList.CoveredClassCount, AModuleList.ClassCount);

  AddCoverageElement(
    AAllElement, 'method, %',
    AModuleList.CoveredMethodCount, AModuleList.MethodCount);

  AddCoverageElement(
    AAllElement, 'block, %',
    AModuleList.CoveredLineCount, AModuleList.LineCount);

  AddCoverageElement(
    AAllElement, 'line, %',
    AModuleList.CoveredLineCount, AModuleList.LineCount);
end;

procedure TXMLCoverageReport.AddModuleInfo(
  AAllElement: TJclSimpleXMLElem;
  const AModuleInfo: TModuleInfo);
var
  PackageElement: TJclSimpleXMLElem;
  SourceFileElement: TJclSimpleXMLElem;
  ClassInfo: TClassInfo;
begin
  PackageElement := AAllElement.Items.Add('package');
  PackageElement.Properties.Add('name', AModuleInfo.ModuleName);
  AddModuleStats(PackageElement, AModuleInfo);

  SourceFileElement := PackageElement.Items.Add('srcfile');
  SourceFileElement.Properties.Add('name', AModuleInfo.ModuleFileName);
  AddModuleStats(SourceFileElement, AModuleInfo);

  for ClassInfo in AModuleInfo do
  begin
    AddClassInfo(SourceFileElement, ClassInfo);
  end;
end;

procedure TXMLCoverageReport.AddModuleLineHits(
  ALineHitsElement: TJclSimpleXMLElem;
  const ACoverage: ICoverageStats);
var
  Line: Integer;
  FileElement: TJclSimpleXMLElem;
  StringBuilder: TStringBuilder;
  CoverageLine: TCoverageLine;
begin
  if FCoverageConfiguration.ExcludedUnits.IndexOf(StringReplace(ExtractFileName(ACoverage.Name), ExtractFileExt(ACoverage.Name), '', [rfReplaceAll, rfIgnoreCase])) < 0 then
  begin
    FileElement := ALineHitsElement.Items.Add('file');
    FileElement.Properties.Add('name', ACoverage.Name);
    StringBuilder := TStringBuilder.Create;
    try
      for Line := 0 to ACoverage.GetCoverageLineCount - 1 do
      begin
        CoverageLine := ACoverage.CoverageLine[Line];
        StringBuilder.Append(IfThen(Line = 0, '', ';'))
          .Append(CoverageLine.LineNumber)
          .Append('=')
          .Append(CoverageLine.LineCount);
      end;
      FileElement.Value := StringBuilder.ToString;
    finally
      StringBuilder.Free;
    end;
  end;
end;

procedure TXMLCoverageReport.AddModuleStats(
  const RootElement: TJclSimpleXMLElem;
  const AModule: TModuleInfo);
begin
  AddCoverageElement(
    RootElement, 'class, %',
    AModule.CoveredClassCount, AModule.ClassCount
  );

  AddCoverageElement(
    RootElement, 'method, %',
    AModule.CoveredMethodCount, AModule.MethodCount
  );

  AddCoverageElement(
    RootElement, 'block, %',
    AModule.CoveredLineCount, AModule.LineCount
  );

  AddCoverageElement(
    RootElement, 'line, %',
    AModule.CoveredLineCount, AModule.LineCount
  );
end;

procedure TXMLCoverageReport.AddClassInfo(
  ASourceFileElement: TJclSimpleXMLElem;
  const AClassInfo: TClassInfo);
var
  Method: TProcedureInfo;
  ClassElement: TJclSimpleXMLElem;
begin
  ClassElement := ASourceFileElement.Items.Add('class');
  ClassElement.Properties.Add('name', AClassInfo.TheClassName);
  AddClassStats(ClassElement, AClassInfo);

  for Method in AClassInfo do
    AddMethodInfo(ClassElement, Method);
end;

procedure TXMLCoverageReport.AddClassStats(
  const ARootElement: TJclSimpleXMLElem;
  const AClass: TClassInfo);
var
  IsCovered: Integer;
begin
  IsCovered := IfThen(AClass.PercentCovered > 0, 1, 0);

  AddCoverageElement(ARootElement, 'class, %', IsCovered, 1);

  AddCoverageElement(
    ARootElement, 'method, %',
    AClass.CoveredProcedureCount, AClass.ProcedureCount
  );

  AddCoverageElement(
    ARootElement, 'block, %',
    AClass.CoveredLineCount, AClass.LineCount
  );

  AddCoverageElement(
    ARootElement, 'line, %',
    AClass.CoveredLineCount, AClass.LineCount
  );
end;

procedure TXMLCoverageReport.AddMethodInfo(
  AClassElement: TJclSimpleXMLElem;
  const AMethod: TProcedureInfo);
var
  MethodElement: TJclSimpleXMLElem;
begin
  MethodElement := AClassElement.Items.Add('method');
  MethodElement.Properties.Add('name', AMethod.Name);
  AddMethodStats(MethodElement, AMethod);
end;

procedure TXMLCoverageReport.AddMethodStats(
  const ARootElement: TJclSimpleXMLElem;
  const AMethod: TProcedureInfo);
var
  IsCovered: Integer;
begin
  IsCovered := IfThen(AMethod.PercentCovered > 0, 1, 0);

  AddCoverageElement(ARootElement, 'method, %', IsCovered, 1);

  AddCoverageElement(
    ARootElement, 'block, %',
    AMethod.CoveredLineCount, AMethod.LineCount
  );

  AddCoverageElement(
    ARootElement, 'line, %',
    AMethod.CoveredLineCount, AMethod.LineCount
  );
end;

procedure TXMLCoverageReport.AddCoverageElement(
  const RootElement: TJclSimpleXMLElem;
  const AType: string;
  const TotalCoveredCount, TotalCount: Integer);
var
  CoverageElement: TJclSimpleXMLElem;
begin
  CoverageElement := RootElement.Items.Add('coverage');
  CoverageElement.Properties.Add('type', AType);
  CoverageElement.Properties.Add(
    'value',
    GetCoverageStringValue(
      TotalCoveredCount,
      TotalCount
    )
  );
end;

function TXMLCoverageReport.GetCoverageStringValue(const ACovered, ATotal: Integer): string;
var
  Percent: Integer;
begin
  if ATotal = 0 then
    Percent := 0
  else
    Percent := Round(ACovered * 100 / ATotal);

  Result := IntToStr(Percent) + '%   (' + IntToStr(ACovered) + '/' + IntToStr(ATotal) + ')';
end;

{ TXMLCoverageReportMerger }

class function TXMLCoverageReportMerger.MergeCoverageStatsForGenerics(
  const ACoverageStatsIn: ICoverageStats): ICoverageStats;
var
  i, j, line: Integer;
  LModuleStats, LUnitStats, LResultStats: ICoverageStats;
  FResultModuleName, FResultUnitName: String;
  LCoverageLine: TCoverageLine;
begin
  Result := TCoverageStats.Create(ACoverageStatsIn.Name, ACoverageStatsIn.Parent);

  //Loop all modules
  for i := 0 to ACoverageStatsIn.Count - 1 do begin
    LModuleStats := ACoverageStatsIn.CoverageReport[i];

    //Loop all units
    for j := 0 to LModuleStats.Count - 1 do begin
      LUnitStats := LModuleStats.CoverageReport[j];

      FResultModuleName := LUnitStats.Name.Substring(0, LUnitStats.Name.LastIndexOf('.'));
      FResultUnitName := LUnitStats.Name;

      LResultStats := Result.CoverageReportByName[FResultModuleName].CoverageReportByName[FResultUnitName];

      //Add all coverage lines
      for line := 0 to ACoverageStatsIn.CoverageReport[i].CoverageReport[j].GetCoverageLineCount - 1 do begin
        LCoverageLine := ACoverageStatsIn.CoverageReport[i].CoverageReport[j].CoverageLine[line];
        LResultStats.AddLineCoverage(LCoverageLine.LineNumber, LCoverageLine.LineCount);
      end;
    end;
  end;

  Result.Calculate;
end;

end.
