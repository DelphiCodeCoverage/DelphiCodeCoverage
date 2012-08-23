(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)
unit ClassInfoUnit;

interface

uses
  Generics.Collections,
  I_BreakPoint;

type
  TSimpleBreakPointList = TList<IBreakPoint>;

  TProcedureInfo = class
  private
    FName: String;
    FLines: TDictionary <Integer, TSimpleBreakPointList> ;
    function IsCovered(const ABreakPointList: TSimpleBreakPointList): Boolean;
    procedure ClearLines;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure AddBreakPoint(
      const ALineNo: Integer;
      const ABreakPoint: IBreakPoint);
    function IsLineCovered(const ALineNo: Integer): Boolean;
    function GetLineCount: Integer;
    function GetCoveredLineCount: Integer;
    function GetCoverageInPercent: Integer;
    function GetName: string;
    function GetLineIterator: TEnumerator<Integer>;
  end;

  TClassInfo = class
  private
    FModule: String;
    FName: String;
    FProcedures: TDictionary<string, TProcedureInfo>;
    procedure ClearProcedures;
  public
    constructor Create(
      const AModuleName: string;
      const AClassName: string);
    destructor Destroy; override;
    function EnsureProcedure(const AProcedureName: string): TProcedureInfo;

    function GetProcedureCount: Integer;
    function GetCoveredProcedureCount: Integer;
    function GetModule: string;
    function GetClassName: string;

    function GetIsCovered: Boolean;
    function GetCoverageInPercent: Integer;
    function GetTotalLineCount: Integer;
    function GetTotalCoveredLineCount: Integer;
    function GetProcedureIterator: TEnumerator<TProcedureInfo>;
  end;

  TModuleInfo = class
  private
    FName: string;
    FFileName: string;
    FClasses: TDictionary<string, TClassInfo>;
    function EnsureClassInfo(
      const AModuleName: string;
      const AClassName: string): TClassInfo;
    procedure ClearClasses;
  public
    constructor Create(
      const AModuleName: string;
      const AModuleFileName: string);
    destructor Destroy; override;
    function GetModuleName: string;
    function GetModuleFileName: string;
    function GetClassCount: Integer;
    function GetCoveredClassCount: Integer;
    function GetMethodCount: Integer;
    function GetCoveredMethodCount: Integer;
    function GetTotalLineCount: Integer;
    function GetTotalCoveredLineCount: Integer;
    function ToString: string; override;
    function GetClassIterator: TEnumerator<TClassInfo>;
  end;

  TModuleList = class
  private
    FModules: TDictionary<string, TModuleInfo>;
    procedure ClearModules;
  public
    constructor Create;
    destructor Destroy; override;

    function EnsureModuleInfo(
      const AModuleName: string;
      const AModuleFileName: string): TModuleInfo;
    function GetCount: Integer;
    function GetTotalClassCount: Integer;
    function GetTotalCoveredClassCount: Integer;

    function GetTotalMethodCount: Integer;
    function GetTotalCoveredMethodCount: Integer;

    function GetTotalLineCount: Integer;
    function GetTotalCoveredLineCount: Integer;
    procedure HandleBreakPoint(
      const AModuleName: string;
      const AModuleFileName: string;
      const AQualifiedProcName: string;
      const ALineNo: Integer;
      const ABreakPoint: IBreakPoint);

    function GetModuleIterator: TEnumerator<TModuleInfo>;
  end;

implementation

uses
  StrUtils,
  Classes,
  uConsoleOutput;

{$region 'TModuleList'}
constructor TModuleList.Create;
begin
  inherited Create;
  FModules := TDictionary<string, TModuleInfo>.Create;
end;

destructor TModuleList.Destroy;
begin
  ClearModules;
  FModules.Free;

  inherited Destroy;
end;

procedure TModuleList.ClearModules;
var
  key: string;
begin
  for key in FModules.Keys do
    FModules[key].Free;
end;

function TModuleList.GetCount: Integer;
begin
  Result := FModules.Count;
end;

function TModuleList.GetModuleIterator: TEnumerator<TModuleInfo>;
begin
  Result := FModules.Values.GetEnumerator;
end;

function TModuleList.GetTotalClassCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.GetClassCount);
end;

function TModuleList.GetTotalCoveredClassCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.GetCoveredClassCount);
end;

function TModuleList.GetTotalMethodCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.GetMethodCount);
end;

function TModuleList.GetTotalCoveredMethodCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.GetCoveredMethodCount);
end;

function TModuleList.GetTotalLineCount: Integer;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.GetTotalLineCount);
end;

function TModuleList.GetTotalCoveredLineCount(): Integer;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.GetTotalCoveredLineCount);
end;

function TModuleList.EnsureModuleInfo(
  const AModuleName: string;
  const AModuleFileName: string): TModuleInfo;
begin
  if not FModules.TryGetValue(AModuleName, Result) then
  begin
    Result := TModuleInfo.Create(AModuleName, AModuleFileName);
    FModules.Add(AModuleName, Result);
  end;
end;

procedure TModuleList.HandleBreakPoint(
  const AModuleName: string;
  const AModuleFileName: string;
  const AQualifiedProcName: string;
  const ALineNo: Integer;
  const ABreakPoint: IBreakPoint);
var
  List: TStrings;
  ClassName: string;
  ProcName: string;
  ClsInfo: TClassInfo;
  ProcInfo: TProcedureInfo;
  Module: TModuleInfo;
begin
  List := TStringList.Create;
  try
    ExtractStrings(['.'], [], PWideChar(AQualifiedProcName), List);
    if (List.Count > 1) then
    begin
      ClassName := List[1];
      if List.Count > 2 then
      begin
        Module := EnsureModuleInfo(AModuleName, AModuleFileName);
        ProcName := List[2];
        ClsInfo := Module.EnsureClassInfo(AModuleName, ClassName);
        ProcInfo := ClsInfo.EnsureProcedure(ProcName);
        ProcInfo.AddBreakPoint(ALineNo, ABreakPoint);
      end
      else
      begin
        Module := EnsureModuleInfo(AModuleName, AModuleFileName);
        ClassName := List[0];
        ProcName := List[1];
        ClsInfo := Module.EnsureClassInfo(AModuleName, ClassName);
        ProcInfo := ClsInfo.EnsureProcedure(ProcName);
        ProcInfo.AddBreakPoint(ALineNo, ABreakPoint);
      end;
    end;
  finally
    List.Free;
  end;
end;
{$endregion 'TModuleList'}

{$region 'TModuleInfo'}
constructor TModuleInfo.Create(
  const AModuleName: string;
  const AModuleFileName: string);
begin
  inherited Create;

  FName := AModuleName;
  FFileName := AModuleFileName;
  FClasses := TDictionary<string, TClassInfo>.Create;
end;

destructor TModuleInfo.Destroy;
begin
  ClearClasses;
  FClasses.Free;

  inherited Destroy;
end;

procedure TModuleInfo.ClearClasses;
var
  key: string;
begin
  for key in FClasses.Keys do
    FClasses[key].Free;
end;

function TModuleInfo.ToString: string;
begin
  Result := 'ModuleInfo[ modulename=' + FName + ', filename=' + FFileName + ' ]';
end;

function TModuleInfo.GetModuleName: string;
begin
  Result := FName;
end;

function TModuleInfo.GetModuleFileName: string;
begin
  Result := FFileName;
end;

function TModuleInfo.EnsureClassInfo(
  const AModuleName: string;
  const AClassName: string): TClassInfo;
begin
  if not FClasses.TryGetValue(AClassName, Result) then
  begin
    VerboseOutput('Creating class info for ' + AModuleName + ' class ' + AClassName);
    Result := TClassInfo.Create(AModuleName, AClassName);
    FClasses.Add(AClassName, Result);
  end;
end;

function TModuleInfo.GetClassCount;
begin
  Result := FClasses.Count;
end;

function TModuleInfo.GetClassIterator: TEnumerator<TClassInfo>;
begin
  Result := FClasses.Values.GetEnumerator;
end;

function TModuleInfo.GetCoveredClassCount;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
  begin
    if CurrentClassInfo.GetIsCovered then
      Inc(Result, 1);
  end;
end;

function TModuleInfo.GetMethodCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.GetProcedureCount);
end;

function TModuleInfo.GetCoveredMethodCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.GetCoveredProcedureCount);
end;

function TModuleInfo.GetTotalLineCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.GetTotalLineCount);
end;

function TModuleInfo.GetTotalCoveredLineCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.GetTotalCoveredLineCount);
end;
{$endregion 'TModuleInfo'}

{$region 'TClassInfo'}
constructor TClassInfo.Create(const AModuleName: string; const AClassName: string);
begin
  inherited Create;

  FModule := AModuleName;
  FName := AClassName;
  FProcedures := TDictionary<string, TProcedureInfo>.Create;
end;

destructor TClassInfo.Destroy;
begin
  ClearProcedures;
  FProcedures.Free;

  inherited Destroy;
end;

procedure TClassInfo.ClearProcedures;
var
  key: string;
begin
  for key in FProcedures.Keys do
    FProcedures[key].Free;
end;

function TClassInfo.EnsureProcedure(const AProcedureName: string): TProcedureInfo;
begin
  if not FProcedures.TryGetValue(AProcedureName, Result) then
  begin
    Result := TProcedureInfo.Create(AProcedureName);
    FProcedures.Add(AProcedureName, Result);
  end;
end;

function TClassInfo.GetCoverageInPercent: Integer;
var
  Total: Integer;
  Covered: Integer;
  CurrentInfo: TProcedureInfo;
begin
  Total := 0;
  Covered := 0;

  for CurrentInfo in FProcedures.Values do
  begin
    Total := Total + CurrentInfo.GetLineCount;
    Covered := Covered + CurrentInfo.GetCoveredLineCount;
  end;

  Result := Covered * 100 div Total;
end;

function TClassInfo.GetModule: string;
begin
  Result := FModule;
end;

function TClassInfo.GetClassName: string;
begin
  result := FName;
end;

function TClassInfo.GetProcedureCount;
begin
  result := FProcedures.Count;
end;

function TClassInfo.GetProcedureIterator: TEnumerator<TProcedureInfo>;
begin
  Result := FProcedures.Values.GetEnumerator;
end;

function TClassInfo.GetCoveredProcedureCount: Integer;
var
  CurrentProcedureInfo: TProcedureInfo;
begin
  Result := 0;

  for CurrentProcedureInfo in FProcedures.Values do
  begin
    if CurrentProcedureInfo.GetCoveredLineCount > 0 then
      Inc(Result);
  end;
end;

function TClassInfo.GetTotalLineCount: Integer;
var
  CurrentProcedureInfo: TProcedureInfo;
begin
  result := 0;
  for CurrentProcedureInfo in FProcedures.Values do
    Inc(Result, CurrentProcedureInfo.GetLineCount);
end;

function TClassInfo.GetTotalCoveredLineCount: Integer;
var
  CurrentProcedureInfo: TProcedureInfo;
begin
  Result := 0;
  for CurrentProcedureInfo in FProcedures.Values do
    Inc(Result, CurrentProcedureInfo.GetCoveredLineCount);
end;

function TClassInfo.GetIsCovered: Boolean;
begin
  Result := GetTotalCoveredLineCount > 0;
end;
{$endregion 'TClassInfo'}

{$region 'TProcedureInfo'}
constructor TProcedureInfo.Create(const AName: string);
begin
  inherited Create;

  FName := AName;
  FLines := TDictionary <Integer, TSimpleBreakPointList>.Create;
end;

destructor TProcedureInfo.Destroy;
begin
  ClearLines;
  FLines.Free;

  inherited Destroy;
end;

procedure TProcedureInfo.ClearLines;
var
  i: Integer;
begin
  for i in FLines.Keys do
    FLines[i].Free;
end;

procedure TProcedureInfo.AddBreakPoint(
  const ALineNo: Integer;
  const ABreakPoint: IBreakPoint);
var
  BreakPointList: TSimpleBreakPointList;
begin
  if not (FLines.TryGetValue(ALineNo, BreakPointList)) then
  begin
    BreakPointList := TSimpleBreakPointList.Create;
    FLines.Add(ALineNo, BreakPointList);
  end;

  BreakPointList.Add(ABreakPoint);
end;

function TProcedureInfo.GetLineCount: Integer;
begin
  Result := FLines.Keys.Count;
end;

function TProcedureInfo.GetLineIterator: TEnumerator<Integer>;
begin
  Result := FLines.Keys.GetEnumerator;
end;

function TProcedureInfo.GetCoveredLineCount: Integer;
var
  I: Integer;
  BreakPointList: TSimpleBreakPointList;
begin
  Result := 0;
  for I in FLines.Keys do
  begin
    BreakPointList := FLines[I];
    if IsCovered(BreakPointList) then
      Inc(Result);
  end;
end;

function TProcedureInfo.IsCovered(const ABreakPointList: TSimpleBreakPointList): Boolean;
var
  CurrentBreakPoint: IBreakPoint;
begin
  Result := false;
  for CurrentBreakPoint in ABreakPointList do
  begin
    if CurrentBreakPoint.Covered then
      Exit(True);
  end;
end;

function TProcedureInfo.IsLineCovered(const ALineNo: Integer): Boolean;
var
  BreakPointList: TSimpleBreakPointList;
begin
  Result := false;
  if FLines.TryGetValue(ALineNo, BreakPointList) then
    Result := IsCovered(BreakPointList);
end;

function TProcedureInfo.GetCoverageInPercent: Integer;
begin
  Result := (100 * GetCoveredLineCount) div GetLineCount;
end;

function TProcedureInfo.GetName: string;
begin
  Result := FName;
end;
{$endregion 'TProcedureInfo'}

end.
