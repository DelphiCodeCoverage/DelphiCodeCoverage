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
  I_BreakPoint,
  I_LogManager;

type
  TSimpleBreakPointList = TList<IBreakPoint>;

  TProcedureInfo = class(TEnumerable<Integer>)
  private
    FName: String;
    FLines: TDictionary <Integer, TSimpleBreakPointList> ;
    function IsCovered(const ABreakPointList: TSimpleBreakPointList): Boolean;
    procedure ClearLines;

    function GetName: string;
  protected
    function DoGetEnumerator: TEnumerator<Integer>; override;
  public
    const BodySuffix = '$Body';

    function LineCount: Integer;
    function CoveredLineCount: Integer;
    function PercentCovered: Integer;

    property Name: string read GetName;

    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure AddBreakPoint(
      const ALineNo: Integer;
      const ABreakPoint: IBreakPoint);
    function IsLineCovered(const ALineNo: Integer): Boolean;
  end;

  TClassInfo = class(TEnumerable<TProcedureInfo>)
  strict private
    FModule: String;
    FName: String;
    FProcedures: TDictionary<string, TProcedureInfo>;
    procedure ClearProcedures;

    function GetProcedureCount: Integer;
    function GetCoveredProcedureCount: Integer;
    function GetModule: string;
    function GetClassName: string;

    function GetIsCovered: Boolean;
  protected
    function DoGetEnumerator: TEnumerator<TProcedureInfo>; override;
  public
    property ProcedureCount: Integer read GetProcedureCount;
    property CoveredProcedureCount: Integer read GetCoveredProcedureCount;
    property Module: string read GetModule;
    property TheClassName: string read GetClassName;
    property IsCovered: Boolean read GetIsCovered;

    function LineCount: Integer;
    function CoveredLineCount: Integer;
    function PercentCovered: Integer;

    constructor Create(
      const AModuleName: string;
      const AClassName: string);
    destructor Destroy; override;
    function EnsureProcedure(const AProcedureName: string): TProcedureInfo;
  end;

  TModuleInfo = class(TEnumerable<TClassInfo>)
  strict private
    FName: string;
    FFileName: string;
    FClasses: TDictionary<string, TClassInfo>;
    function GetModuleName: string;
    function GetModuleFileName: string;
    function GetClassCount: Integer;
    function GetCoveredClassCount: Integer;
    function GetMethodCount: Integer;
    function GetCoveredMethodCount: Integer;
  protected
    function DoGetEnumerator: TEnumerator<TClassInfo>; override;
  public
    property ModuleName: string read GetModuleName;
    property ModuleFileName: string read GetModuleFileName;

    property ClassCount: Integer read GetClassCount;
    property CoveredClassCount: Integer read GetCoveredClassCount;

    property MethodCount: Integer read GetMethodCount;
    property CoveredMethodCount: Integer read GetCoveredMethodCount;

    function LineCount: Integer;
    function CoveredLineCount: Integer;

    constructor Create(
      const AModuleName: string;
      const AModuleFileName: string);
    destructor Destroy; override;

    function ToString: string; override;

    function EnsureClassInfo(
      const AModuleName: string;
      const AClassName: string): TClassInfo;
    procedure ClearClasses;
  end;

  TModuleList = class(TEnumerable<TModuleInfo>)
  strict private
    FModules: TDictionary<string, TModuleInfo>;
    procedure ClearModules;
    function GetCount: Integer;
    function GetTotalClassCount: Integer;
    function GetTotalCoveredClassCount: Integer;
    function GetTotalMethodCount: Integer;
    function GetTotalCoveredMethodCount: Integer;
    function GetTotalLineCount: Integer;
    function GetTotalCoveredLineCount: Integer;
  protected
    function DoGetEnumerator: TEnumerator<TModuleInfo>; override;
  public
    property Count: Integer read GetCount;

    property ClassCount: Integer read GetTotalClassCount;
    property CoveredClassCount: Integer read GetTotalCoveredClassCount;

    property MethodCount: Integer read GetTotalMethodCount;
    property CoveredMethodCount: Integer read GetTotalCoveredMethodCount;

    property LineCount: Integer read GetTotalLineCount;
    property CoveredLineCount: Integer read GetTotalCoveredLineCount;

    constructor Create;
    destructor Destroy; override;

    function EnsureModuleInfo(
      const AModuleName: string;
      const AModuleFileName: string): TModuleInfo;


    procedure HandleBreakPoint(
      const AModuleName: string;
      const AModuleFileName: string;
      const AQualifiedProcName: string;
      const ALineNo: Integer;
      const ABreakPoint: IBreakPoint;
      const ALogManager: ILogManager);
  end;

implementation

uses
  Types,
  SysUtils,
  StrUtils,
  {$IF CompilerVersion < 21}
  StrUtilsD9,
  {$IFEND}
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

function TModuleList.DoGetEnumerator: TEnumerator<TModuleInfo>;
begin
  Result := FModules.Values.GetEnumerator;
end;

function TModuleList.GetTotalClassCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.ClassCount);
end;

function TModuleList.GetTotalCoveredClassCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.CoveredClassCount);
end;

function TModuleList.GetTotalMethodCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.MethodCount);
end;

function TModuleList.GetTotalCoveredMethodCount;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.CoveredMethodCount);
end;

function TModuleList.GetTotalLineCount: Integer;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.LineCount);
end;

function TModuleList.GetTotalCoveredLineCount(): Integer;
var
  CurrentModuleInfo: TModuleInfo;
begin
  Result := 0;
  for CurrentModuleInfo in FModules.Values do
    Inc(Result, CurrentModuleInfo.CoveredLineCount);
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
  const ABreakPoint: IBreakPoint;
  const ALogManager: ILogManager);
var
  List: TStrings;
  ClassName: string;
  ProcedureName: string;
  ClsInfo: TClassInfo;
  ProcInfo: TProcedureInfo;
  Module: TModuleInfo;
  ProcedureNameParts: TStringDynArray;
  I: Integer;
  QualifiedProcName: string;
begin
  ALogManager.Log('Adding breakpoint for '+ AQualifiedProcName + ' in ' + AModuleFileName);
  List := TStringList.Create;
  try
    // detect module initialization section
    if AQualifiedProcName = AModuleName + '.' + AModuleName then
      QualifiedProcName := AModuleName + '.Initialization'
    else
      QualifiedProcName := AQualifiedProcName;

    ExtractStrings(['.'], [], PWideChar(QualifiedProcName), List);
    if (List.Count > 1) then
    begin
      if EndsStr(TProcedureInfo.BodySuffix, List[List.Count - 1]) then
        List.Delete(List.Count - 1);

      ProcedureNameParts := SplitString(List[List.Count - 1], '$');
      ProcedureName := ProcedureNameParts[0];

      if List.Count > 2 then
      begin
        ClassName := '';
        for I := 0 to List.Count - 2 do
        begin
          if ClassName = '' then
            ClassName := List[I]
          else
            ClassName := ClassName + '.' + List[i];
        end;
      end
      else
        ClassName := List[0];

      Module := EnsureModuleInfo(AModuleName, AModuleFileName);
      ClsInfo := Module.EnsureClassInfo(AModuleName, ClassName);
      ProcInfo := ClsInfo.EnsureProcedure(ProcedureName);
      ProcInfo.AddBreakPoint(ALineNo, ABreakPoint);
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

function TModuleInfo.DoGetEnumerator: TEnumerator<TClassInfo>;
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
    if CurrentClassInfo.IsCovered then
      Inc(Result, 1);
  end;
end;

function TModuleInfo.GetMethodCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.ProcedureCount);
end;

function TModuleInfo.GetCoveredMethodCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.CoveredProcedureCount);
end;

function TModuleInfo.LineCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.LineCount);
end;

function TModuleInfo.CoveredLineCount: Integer;
var
  CurrentClassInfo: TClassInfo;
begin
  Result := 0;
  for CurrentClassInfo in FClasses.Values do
    Inc(Result, CurrentClassInfo.CoveredLineCount);
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

function TClassInfo.DoGetEnumerator: TEnumerator<TProcedureInfo>;
begin
  Result := FProcedures.Values.GetEnumerator;
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

function TClassInfo.PercentCovered: Integer;
var
  Total: Integer;
  Covered: Integer;
  CurrentInfo: TProcedureInfo;
begin
  Total := 0;
  Covered := 0;

  for CurrentInfo in FProcedures.Values do
  begin
    Total := Total + CurrentInfo.LineCount;
    Covered := Covered + CurrentInfo.CoveredLineCount;
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

function TClassInfo.GetCoveredProcedureCount: Integer;
var
  CurrentProcedureInfo: TProcedureInfo;
begin
  Result := 0;

  for CurrentProcedureInfo in FProcedures.Values do
  begin
    if CurrentProcedureInfo.CoveredLineCount > 0 then
      Inc(Result);
  end;
end;

function TClassInfo.LineCount: Integer;
var
  CurrentProcedureInfo: TProcedureInfo;
begin
  result := 0;
  for CurrentProcedureInfo in FProcedures.Values do
    Inc(Result, CurrentProcedureInfo.LineCount);
end;

function TClassInfo.CoveredLineCount: Integer;
var
  CurrentProcedureInfo: TProcedureInfo;
begin
  Result := 0;
  for CurrentProcedureInfo in FProcedures.Values do
    Inc(Result, CurrentProcedureInfo.CoveredLineCount);
end;

function TClassInfo.GetIsCovered: Boolean;
begin
  Result := CoveredLineCount > 0;
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

function TProcedureInfo.DoGetEnumerator: TEnumerator<Integer>;
begin
  Result := FLines.Keys.GetEnumerator
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

function TProcedureInfo.LineCount: Integer;
begin
  Result := FLines.Keys.Count;
end;

function TProcedureInfo.CoveredLineCount: Integer;
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
    if CurrentBreakPoint.IsCovered then
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

function TProcedureInfo.PercentCovered: Integer;
begin
  Result := (100 * CoveredLineCount) div LineCount;
end;

function TProcedureInfo.GetName: string;
begin
  Result := FName;
end;
{$endregion 'TProcedureInfo'}

end.
