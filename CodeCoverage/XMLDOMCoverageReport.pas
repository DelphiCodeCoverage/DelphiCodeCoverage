(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit XMLDOMCoverageReport;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Contnrs,
  I_Report,
  I_CoverageStats,
  {$IFDEF XDOM}
  xdom;   // Chosen because it does not drag in any other units e.g. TComponent
  {$ENDIF}
  {$IFDEF DKADOMCORE}
  // Need "$(BDS)\Source\Win32\xml" to be added to the library path...
  //AdomCore_4_3
  // The following is from "http://www.philo.de/xml/" - Both the 'adom' and 'utils' files are required.
  dkAdomCore;
  {$ENDIF}

type
  TXMLDOMCoverageReport = class(TInterfacedObject, IReport)
  private
    FDomList : TObjectList;
    procedure AppendLF(XMLDoc : TDOMDocument);
    procedure MakeElementCurrent(const AnElement: TDomElement);
    function CurrentElement : TDomElement;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Generate(const ACoverage: ICoverageStats; const ASourceDir, AOutputDir: string);
  end;

implementation

uses
  Classes,
  JclFileUtils;

{ TXMLDOMCoverageReport }

constructor TXMLDOMCoverageReport.Create;
begin
  FDomList := TObjectList.Create(False);
end;

destructor TXMLDOMCoverageReport.Destroy;
begin
  FDomList.Free;

  inherited;
end;

procedure TXMLDOMCoverageReport.MakeElementCurrent(
  const AnElement: TDomElement);
begin
  FDomList.Add(AnElement);
end;

function TXMLDOMCoverageReport.CurrentElement: TDomElement;
begin
  Result := nil;
  if FDomList.Count > 0 then
    Result := FDomList.Items[FDomList.Count - 1] as TDomElement;
end;

procedure TXMLDOMCoverageReport.AppendLF(XMLDoc: TDOMDocument);
var
  LDomText : TDomText;
begin
  {$IFDEF XDOM}
  LDomText := XMLDoc.createTextNode(#10);
  {$ENDIF}
  {$IFDEF DKADOMCORE}
  LDomText := TDomText.Create(XMLDoc);
  LDomText.Data := #10;
  {$ENDIF}
  CurrentElement.AppendChild(LDomText);
end;

procedure TXMLDOMCoverageReport.Generate(const ACoverage: ICoverageStats;
  const ASourceDir, AOutputDir: string);
var
  LDomElement: TDomElement;
  LDomProcessingInstruction : TDomProcessingInstruction;
  XMLDoc : TDOMDocument;
  OutputFileName : string;
  PIContent : string;
const
  cEncoding             = 'UTF-8';
  cxmlStylesheet        = 'xml-stylesheet';
  cTestResults          = 'TestResults';
begin
  OutputFileName := 'CodeCoverage_summary.xml';
  OutputFileName := PathAppend(AOutputDir, OutputFileName);

  //FStack := TXMLStack.Create;
  //FAppPath := ExtractFilePath(ExePathFileName);
  //FAppName := ExtractFileName(ExePathFileName);
  //FDocName := ChangeFileExt(FAppName, cxmlExt);
  XMLDoc := TDOMDocument.create(nil);
  {$IFDEF XDOM}
  XMLDoc.Encoding := cEncoding;
  {$ENDIF}
  {$IFDEF DKADOMCORE}
  XMLDoc.InputEncoding := cEncoding;
  XMLDoc.XmlEncoding   := cEncoding;
  {$ENDIF}
  PIContent := '';
  if PIContent <> '' then
  begin
    {$IFDEF XDOM}
    LDomProcessingInstruction := XMLDoc.createProcessingInstruction(cxmlStylesheet, PIContent);
    {$ENDIF}
    {$IFDEF DKADOMCORE}
    LDomProcessingInstruction := TDomProcessingInstruction.Create(XMLDoc, cxmlStylesheet);
    LDomProcessingInstruction.Data := PIContent;
    {$ENDIF}
    XMLDoc.appendChild(LDomProcessingInstruction);
  end;
  {$IFDEF XDOM}
  LDomElement := XMLDoc.createElement(cTestResults);
  {$ENDIF}
  {$IFDEF DKADOMCORE}
  LDomElement := TDomElement.Create(XMLDoc, cTestResults);
  {$ENDIF}
  XMLDoc.appendChild(LDomElement);
  MakeElementCurrent(LDomElement);
  AppendLF(XMLDoc);
  //AppendComment(cGeneratedBy + FormatDateTime(cyyyymmddhhmmss, Now));
end;

end.
