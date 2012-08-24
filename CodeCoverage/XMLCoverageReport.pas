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
  private
    FCoverageConfiguration: ICoverageConfiguration;

    procedure WriteAllStats(
      const AJclSimpleXMLElem: TJclSimpleXMLElem;
      const ACoverageStats: ICoverageStats;
      const AModuleList: TModuleList);
    procedure WriteModuleStats(
      const AJclSimpleXMLElem: TJclSimpleXMLElem;
      const AModule: TModuleInfo);
    procedure WriteClassStats(
      const AJclSimpleXMLElem: TJclSimpleXMLElem;
      const AClass: TClassInfo);
    procedure WriteMethodStats(
      const AJclSimpleXMLElem: TJclSimpleXMLElem;
      const AMethod: TProcedureInfo);
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

procedure TXMLCoverageReport.Generate(
  const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList;
  const ALogManager: ILogManager);
var
  ModuleInfo: TModuleInfo;
  ClassInfo: TClassInfo;
  Method: TProcedureInfo;
  JclSimpleXml: TJclSimpleXML;
  JclSimpleXMLElemStats: TJclSimpleXMLElem; // Pointer
  JclSimpleXMLElemPackage: TJclSimpleXMLElem; // Pointer
  JclSimpleXMLElemSrcFile: TJclSimpleXMLElem; // Pointer
  JclSimpleXMLElemAll: TJclSimpleXMLElem; // Pointer
  JclSimpleXMLElemClass: TJclSimpleXMLElem; // Pointer
  JclSimpleXMLElemMethod: TJclSimpleXMLElem; // Pointer
begin
  ALogManager.Log('Generating xml coverage report');

  JclSimpleXml := TJclSimpleXML.Create;
  try
    JclSimpleXml.Root.Name := 'report';

    JclSimpleXMLElemStats := JclSimpleXml.Root.Items.Add('stats');
    JclSimpleXMLElemStats.Items.Add('packages').Properties.Add(
      'value', AModuleInfoList.Count
    );
    JclSimpleXMLElemStats.Items.Add('classes').Properties.Add(
      'value', AModuleInfoList.TotalClassCount);

    JclSimpleXMLElemStats.Items.Add('methods').Properties.Add(
      'value', AModuleInfoList.TotalMethodCount);

    JclSimpleXMLElemStats.Items.Add('srcfiles').Properties.Add(
      'value', AModuleInfoList.Count);

    JclSimpleXMLElemStats.Items.Add('srclines').Properties.Add(
      'value', AModuleInfoList.TotalLineCount);

    JclSimpleXMLElemStats.Items.Add('totallines').Properties.Add(
      'value', ACoverage.LineCount);

    JclSimpleXMLElemStats.Items.Add('coveredlines').Properties.Add(
      'value', ACoverage.CoveredLineCount);

    JclSimpleXMLElemStats.Items.Add('coveredpercent').Properties.Add(
      'value', ACoverage.PercentCovered);

    JclSimpleXMLElemAll := JclSimpleXml.Root.Items.Add('data').Items.Add('all');

    JclSimpleXMLElemAll.Properties.Add('name', 'all classes');

    WriteAllStats(JclSimpleXMLElemAll, ACoverage, AModuleInfoList);

    for ModuleInfo in AModuleInfoList do
    begin
      JclSimpleXMLElemPackage := JclSimpleXMLElemAll.Items.Add('package');
      JclSimpleXMLElemPackage.Properties.Add('name', ModuleInfo.ModuleName);
      WriteModuleStats(JclSimpleXMLElemPackage, ModuleInfo);
      JclSimpleXMLElemSrcFile := JclSimpleXMLElemPackage.Items.Add('srcfile');
      JclSimpleXMLElemSrcFile.Properties.Add('name',
        ModuleInfo.ModuleFileName);
      WriteModuleStats(JclSimpleXMLElemSrcFile, ModuleInfo);
      for ClassInfo in ModuleInfo do
      begin
        JclSimpleXMLElemClass := JclSimpleXMLElemSrcFile.Items.Add('class');
        JclSimpleXMLElemClass.Properties.Add('name',
          ClassInfo.TheClassName);
        WriteClassStats(JclSimpleXMLElemClass, ClassInfo);
        for Method in ClassInfo do
        begin
          JclSimpleXMLElemMethod := JclSimpleXMLElemClass.Items.Add('method');
          JclSimpleXMLElemMethod.Properties.Add('name', Method.Name);
          WriteMethodStats(JclSimpleXMLElemMethod, Method);
        end;
      end;
    end;

    JclSimpleXml.SaveToFile(PathAppend(FCoverageConfiguration.OutputDir,
        'CodeCoverage_Summary.xml'));
  finally
    JclSimpleXml.Free;
  end;
end;

constructor TXMLCoverageReport.Create(const ACoverageConfiguration
    : ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

function getCoverageStringValue(covered, total: Integer): String;
var
  Percent: Integer;
begin
  if Total = 0 then
    Percent := 0
  else
    Percent := Round(covered * 100 / total);

  Result := IntToStr(Percent) + '%   (' + IntToStr(covered) + '/' +
    IntToStr(total) + ')';
end;

procedure TXMLCoverageReport.WriteModuleStats
  (const AJclSimpleXMLElem: TJclSimpleXMLElem; const AModule: TModuleInfo);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
begin
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'class, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModule.CoveredClassCount, AModule.ClassCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModule.CoveredMethodCount,
      AModule.MethodCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModule.TotalCoveredLineCount,
      AModule.TotalLineCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModule.TotalCoveredLineCount,
      AModule.TotalLineCount));
end;

procedure TXMLCoverageReport.WriteClassStats
  (const AJclSimpleXMLElem: TJclSimpleXMLElem; const AClass: TClassInfo);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
begin
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'class, %');
  if (AClass.IsCovered) then
  begin
    JclSimpleXMLElemCoverage.Properties.Add('value',
      getCoverageStringValue(1, 1));

  end
  else
  begin
    JclSimpleXMLElemCoverage.Properties.Add('value',
      getCoverageStringValue(0, 1));

  end;
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AClass.CoveredProcedureCount,
      AClass.ProcedureCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AClass.TotalCoveredLineCount,
      AClass.TotalLineCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AClass.TotalCoveredLineCount,
      AClass.TotalLineCount));
end;

procedure TXMLCoverageReport.WriteMethodStats
  (const AJclSimpleXMLElem: TJclSimpleXMLElem; const AMethod: TProcedureInfo);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
  covered: Integer;
begin

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  if (AMethod.CoverageInPercent > 0) then
    covered := 1
  else
    covered := 0;

  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(covered, 1));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AMethod.CoveredLineCount, AMethod.LineCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AMethod.CoveredLineCount, AMethod.LineCount));
end;

procedure TXMLCoverageReport.WriteAllStats
  (const AJclSimpleXMLElem: TJclSimpleXMLElem;
  const ACoverageStats: ICoverageStats; const AModuleList: TModuleList);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
begin
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'class, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModuleList.TotalCoveredClassCount,
      AModuleList.TotalClassCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModuleList.TotalCoveredMethodCount,
      AModuleList.TotalMethodCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModuleList.TotalCoveredLineCount,
      AModuleList.TotalLineCount));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',
    getCoverageStringValue(AModuleList.TotalCoveredLineCount,
      AModuleList.TotalLineCount));

end;

end.
