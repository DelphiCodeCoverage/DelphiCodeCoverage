(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit XMLCoverageReport;

interface

{$INCLUDE CodeCoverage.inc}

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

implementation

uses
  SysUtils,
  JclFileUtils,
  Generics.Collections;

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
  ModuleInfo: TModuleInfo;
  XML: TJclSimpleXML;
  StatsElement: TJclSimpleXMLElem; // Pointer
  AllElement: TJclSimpleXMLElem; // Pointer

  procedure AddValueElement(const AElementName: string; const AValue: Integer);
  begin
    StatsElement.Items
      .Add(AElementName)
      .Properties.Add('value', AValue);
  end;
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

    AllElement := XML.Root.Items.Add('data').Items.Add('all');
    AllElement.Properties.Add('name', 'all classes');

    AddAllStats(AllElement, ACoverage, AModuleInfoList);

    for ModuleInfo in AModuleInfoList do
      AddModuleInfo(AllElement, ModuleInfo);

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
    AddClassInfo(SourceFileElement, ClassInfo);
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
  if (AClass.PercentCovered > 0) then
    IsCovered := 1
  else
    IsCovered := 0;

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
  if (AMethod.PercentCovered > 0) then
    IsCovered := 1
  else
    IsCovered := 0;

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

end.
