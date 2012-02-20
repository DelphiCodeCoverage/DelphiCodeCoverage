(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit XMLCoverageReport;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_Report,
  I_CoverageStats,
  JclSimpleXml,
  I_CoverageConfiguration,
  ClassInfoUnit;

type
  TXMLCoverageReport = class(TInterfacedObject, IReport)
  private
    FCoverageConfiguration : ICoverageConfiguration;

    function FormatLinePercentage(const ACoverageStats : ICoverageStats) : string;
    procedure WriteAllStats(const AJclSimpleXMLElem : TJclSimpleXMLElem; const ACoverageStats : ICoverageStats; const AModuleList : TModuleList);
    procedure WriteModuleStats(const AJclSimpleXMLElem : TJclSimpleXMLElem; const AModule : TModuleInfo);
    procedure WriteClassStats(const AJclSimpleXMLElem : TJclSimpleXMLElem; const AClass : TClassInfo);
    procedure WriteMethodStats(const AJclSimpleXMLElem : TJclSimpleXMLElem; const AMethod : TProcedureInfo);
  public
    constructor Create(const ACoverageConfiguration : ICoverageConfiguration);

    procedure Generate(const ACoverage: ICoverageStats; const AModuleInfoList: TModuleList);
  end;

implementation

uses
  SysUtils,
  JclFileUtils,
  Generics.Collections;

{ TXMLCoverageReport }

procedure TXMLCoverageReport.Generate(const ACoverage: ICoverageStats;const AModuleInfoList: TModuleList);
var
  SourceFileCount : Integer;
  lpModule        : Integer;
  lpUnit          : Integer;

  ModuleIter      : TEnumerator<TModuleInfo>;
  ClassIter       : TEnumerator<TClassInfo>;
  MethodIter      : TEnumerator<TProcedureInfo>;
  JclSimpleXML            : TJclSimpleXML;
  JclSimpleXMLElemStats   : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemPackage : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemSrcFile : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemAll     : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemClass   : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemMethod  : TJclSimpleXMLElem;  // Pointer
begin
  JclSimpleXML := nil;
  try
    JclSimpleXML := TJclSimpleXML.Create;

    JclSimpleXML.Root.Name := 'report';

    JclSimpleXMLElemStats := JclSimpleXML.Root.Items.Add('stats');
    JclSimpleXMLElemStats.Items.Add('packages').Properties.Add('value', AModuleInfoList.GetCount());
    JclSimpleXMLElemStats.Items.Add('classes').Properties.Add('value', AModuleInfoList.GetTotalClassCount());
    JclSimpleXMLElemStats.Items.Add('methods').Properties.Add('value', AModuleInfoList.GetTotalMethodCount());

    JclSimpleXMLElemStats.Items.Add('srcfiles').Properties.Add('value', AModuleInfoList.GetCount());
    JclSimpleXMLElemStats.Items.Add('srclines').Properties.Add('value', AModuleInfoList.GetTotalLineCount());

    JclSimpleXMLElemAll   := JclSimpleXML.Root.Items.Add('data').Items.Add('all');
    JclSimpleXMLElemAll.Properties.Add('name', 'all classes');
    WriteAllStats(JclSimpleXMLElemAll, ACoverage, AModuleInfoList);
    ModuleIter := AModuleInfoList.getModuleIterator;
    while (ModuleIter.moveNext()) do
    begin


      JclSimpleXMLElemPackage := JclSimpleXMLElemAll.Items.Add('package');
      JclSimpleXMLElemPackage.Properties.Add('name', ModuleIter.Current.getModuleName);
      WriteModuleStats(JclSimpleXMLElemPackage, ModuleIter.Current);
      JclSimpleXMLElemSrcFile := JclSimpleXMLElemPackage.Items.Add('srcfile');
        JclSimpleXMLElemSrcFile.Properties.Add('name', ModuleIter.Current.getModuleFileName);
         WriteModuleStats(JclSimpleXMLElemSrcFile, ModuleIter.Current);
      ClassIter := ModuleIter.Current.getClassIterator;
      while (classIter.moveNext()) do
      begin

        JclSimpleXMLElemClass := JclSimpleXMLElemSrcFile.Items.Add('class');
        JclSimpleXMLElemClass.Properties.Add('name', classIter.Current.getClassName);
        WriteClassStats(JclSimpleXMLElemClass, classIter.Current);
        MethodIter := ClassIter.Current.getProcedureIterator;
        while (MethodIter.MoveNext()) do
        begin
          JclSimpleXMLElemMethod := JclSimpleXMLElemClass.Items.Add('method');
          JclSimpleXMLElemMethod.Properties.Add('name', MethodIter.Current.getName);
          WriteMethodStats(JclSimpleXMLElemMethod, MethodIter.Current);
        end;
      end;
    end;

    JclSimpleXML.SaveToFile(PathAppend(FCoverageConfiguration.GetOutputDir, 'CodeCoverage_Summary.xml'));
  finally
    JclSimpleXML.Free;
  end;
end;

constructor TXMLCoverageReport.Create(const ACoverageConfiguration: ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

function TXMLCoverageReport.FormatLinePercentage(const ACoverageStats: ICoverageStats): string;
var
  PercentageStr : string;
begin
  PercentageStr := IntToStr(ACoverageStats.GetPercentCovered());

  Result := PercentageStr +
            '%' +
            StringOfChar(' ', 4 - Length(PercentageStr)) +
            '(' +
            IntToStr(ACoverageStats.GetNumberOfCoveredLines()) +
            '/' +
            IntToStr(ACoverageStats.GetNumberOfLines()) + ')';
end;

function getCoverageStringValue(covered, total : Integer):String;
begin
  result := IntToStr(covered*100 div total)+
  '%   ('+IntToStr(covered)+
  '/' + IntToStr(total)+')';
end;

procedure TXMLCoverageReport.WriteModuleStats(const AJclSimpleXMLElem: TJclSimpleXMLElem; const AModule : TModuleInfo);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
begin
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'class, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AModule.getCoveredClassCount(), Amodule.getClassCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',  getCoverageStringValue(AModule.getCoveredMethodCount(), AModule.getMethodCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AModule.GetTotalCoveredLineCount(), AModule.GetTotalLineCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AModule.GetTotalCoveredLineCount(), AModule.GetTotalLineCount()));
end;


procedure TXMLCoverageReport.WriteClassStats(const AJclSimpleXMLElem: TJclSimpleXMLElem; const AClass : TClassInfo);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
begin
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'class, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(1, 1));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',  getCoverageStringValue(AClass.getCoveredProcedureCount(), AClass.getProcedureCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AClass.GetTotalCoveredLineCount(), AClass.getTotalLineCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AClass.GetTotalCoveredLineCount(), AClass.getTotalLineCount()));
end;



procedure TXMLCoverageReport.WriteMethodStats(const AJclSimpleXMLElem: TJclSimpleXMLElem; const AMethod : TProcedureInfo);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
  covered : Integer;
begin

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  if ( aMethod.getCoverage>0) then covered := 1 else covered := 0;

  JclSimpleXMLElemCoverage.Properties.Add('value',  getCoverageStringValue(covered, 1));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AMethod.getCoveredLines(), AMethod.getNoLines()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AMethod.getCoveredLines(), AMethod.getNoLines()));
end;
procedure TXMLCoverageReport.WriteAllStats(const AJclSimpleXMLElem: TJclSimpleXMLElem;
  const ACoverageStats: ICoverageStats; const AModuleList : TModuleList);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
begin
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'class, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AModuleList.GetTotalCoveredClassCount(), AmoduleList.getTotalClassCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  JclSimpleXMLElemCoverage.Properties.Add('value',  getCoverageStringValue(AModuleList.GetTotalCoveredMethodCount(), AmoduleList.getTotalMethodCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', getCoverageStringValue(AModuleList.GetTotalCoveredLineCount(), AModuleList.getTotalLineCount()));

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', FormatLinePercentage(ACoverageStats));
end;

end.

