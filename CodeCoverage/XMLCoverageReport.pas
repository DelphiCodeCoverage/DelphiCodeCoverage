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
  I_CoverageConfiguration;

type
  TXMLCoverageReport = class(TInterfacedObject, IReport)
  private
    FCoverageConfiguration : ICoverageConfiguration;

    function FormatLinePercentage(const ACoverageStats : ICoverageStats) : string;
    procedure WriteStats(const AJclSimpleXMLElem : TJclSimpleXMLElem; const ACoverageStats : ICoverageStats);
  public
    constructor Create(const ACoverageConfiguration : ICoverageConfiguration);

    procedure Generate(const ACoverage: ICoverageStats);
  end;

implementation

uses
  SysUtils,
  JclFileUtils;

{ TXMLCoverageReport }

procedure TXMLCoverageReport.Generate(const ACoverage: ICoverageStats);
var
  SourceFileCount : Integer;
  lpModule        : Integer;
  lpUnit          : Integer;

  CoverageModule  : ICoverageStats;
  CoverageUnit    : ICoverageStats;

  JclSimpleXML            : TJclSimpleXML;
  JclSimpleXMLElemStats   : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemPackage : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemSrcFile : TJclSimpleXMLElem;  // Pointer
  JclSimpleXMLElemAll     : TJclSimpleXMLElem;  // Pointer
begin
  JclSimpleXML := nil;
  try
    JclSimpleXML := TJclSimpleXML.Create;

    JclSimpleXML.Root.Name := 'report';

    JclSimpleXMLElemStats := JclSimpleXML.Root.Items.Add('stats');
    JclSimpleXMLElemStats.Items.Add('packages').Properties.Add('value', ACoverage.GetCount());
    JclSimpleXMLElemStats.Items.Add('classes').Properties.Add('value', 0);
    JclSimpleXMLElemStats.Items.Add('methods').Properties.Add('value', 0);

    SourceFileCount     := 0;
    for lpModule := 0 to Pred(ACoverage.GetCount) do
      SourceFileCount := SourceFileCount + ACoverage.CoverageReport[lpModule].GetCount;

    JclSimpleXMLElemStats.Items.Add('srcfiles').Properties.Add('value', SourceFileCount);
    JclSimpleXMLElemStats.Items.Add('srclines').Properties.Add('value', ACoverage.GetNumberOfLines());

    JclSimpleXMLElemAll   := JclSimpleXML.Root.Items.Add('data').Items.Add('all');
    JclSimpleXMLElemAll.Properties.Add('name', 'all classes');
    WriteStats(JclSimpleXMLElemAll, ACoverage);

    for lpModule := 0 to Pred(ACoverage.GetCount) do
    begin
      CoverageModule := ACoverage.CoverageReport[lpModule];

      JclSimpleXMLElemPackage := JclSimpleXMLElemAll.Items.Add('package');
      JclSimpleXMLElemPackage.Properties.Add('name', CoverageModule.GetName);
      WriteStats(JclSimpleXMLElemPackage, CoverageModule);

      for lpUnit := 0 to Pred(CoverageModule.GetCount) do
      begin
        CoverageUnit := CoverageModule.CoverageReport[lpUnit];

        JclSimpleXMLElemSrcFile := JclSimpleXMLElemPackage.Items.Add('srcfile');
        JclSimpleXMLElemSrcFile.Properties.Add('name', CoverageUnit.GetName());

        WriteStats(JclSimpleXMLElemSrcFile, CoverageUnit);
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

procedure TXMLCoverageReport.WriteStats(const AJclSimpleXMLElem: TJclSimpleXMLElem;
  const ACoverageStats: ICoverageStats);
var
  JclSimpleXMLElemCoverage: TJclSimpleXMLElem;
begin
  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'class, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', '0%   (0/0)');

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'method, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', '0%   (0/0)');

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'block, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', '0%   (0/0)');

  JclSimpleXMLElemCoverage := AJclSimpleXMLElem.Items.Add('coverage');
  JclSimpleXMLElemCoverage.Properties.Add('type', 'line, %');
  JclSimpleXMLElemCoverage.Properties.Add('value', FormatLinePercentage(ACoverageStats));
end;

end.

