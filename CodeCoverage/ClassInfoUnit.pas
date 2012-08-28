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

uses Generics.Collections, I_BreakPoint, I_LogManager;

type
  TProcedureInfo = class;

  TClassInfo = class;

  TModuleInfo = class;

  TModuleList = class
  private
    fModules: TDictionary<String, TModuleInfo>;
  public
    constructor Create;
    destructor Destroy; override;

    function ensureModuleInfo(ModuleName: String;
      ModuleFileName: String): TModuleInfo;
    function getModuleIterator: TEnumerator<TModuleInfo>;
    function GetCount(): Integer;
    function GetTotalClassCount(): Integer;
    function GetTotalCoveredClassCount(): Integer;

    function GetTotalMethodCount(): Integer;
    function GetTotalCoveredMethodCount(): Integer;

    function GetTotalLineCount(): Integer;
    function GetTotalCoveredLineCount(): Integer;
    procedure HandleBreakPoint(ModuleName: String; ModuleFileName: String;
      qualifiedprocName: String; lineNo: Integer; bk: IBreakPoint; logManager : ILogManager);
  end;

  TModuleInfo = class
  private
    fName: String;
    fFileName: String;
    fClasses: TDictionary<String, TClassInfo>;
    function ensureClassInfo(ModuleName: String; className: String): TClassInfo;
  public
    constructor Create(const AModuleName: String;
      const AModuleFileName: String);
    destructor Destroy; override;
    function getModuleName(): String;
    function getModuleFileName(): String;
    function getClassIterator(): TEnumerator<TClassInfo>;
    function getClassCount(): Integer;
    function getCoveredClassCount(): Integer;
    function getMethodCount(): Integer;
    function getCoveredMethodCount(): Integer;
    function GetTotalLineCount(): Integer;
    function GetTotalCoveredLineCount(): Integer;
    function toString: String; override;
  end;

  TClassInfo = class
  private
    fModule: String;
    fName: String;
    fProcedures: TDictionary<String, TProcedureInfo>;

  public
    constructor Create(AModuleName: String; AClassName: String);
    destructor Destroy; override;
    function ensureProcedure(AProcedureName: String): TProcedureInfo;

    function getProcedureIterator(): TEnumerator<TProcedureInfo>;
    function getProcedureCount(): Integer;
    function getCoveredProcedureCount(): Integer;
    function getModule(): String;
    function getClassName(): String;
    function getCoverage: Integer;
    function GetTotalLineCount(): Integer;
    function GetTotalCoveredLineCount(): Integer;
    function getIsCovered(): Boolean;

  end;

  TProcedureInfo = class
  private
    fName: String;
    fLines: TDictionary < Integer, TList < IBreakPoint >> ;
    function covered(bpList: TList<IBreakPoint>): Boolean;
  public
    constructor Create(name: String);
    destructor Destroy; override;
    procedure AddBreakPoint(lineNo: Integer; ABreakPoint: IBreakPoint);
    function getLineIterator(): TEnumerator<Integer>;
    function isLineCovered(lineNo: Integer): Boolean;
    function getNoLines(): Integer;
    function getCoveredLines(): Integer;
    function getCoverage: Integer;
    function getName(): String;
  end;

implementation

uses strutils, Classes;

constructor TProcedureInfo.Create(name: string);
begin
  fName := name;
  fLines := TDictionary < Integer, TList < IBreakPoint >> .Create;
end;

destructor TProcedureInfo.Destroy;
var
  iter: TDictionary < Integer, TList < IBreakPoint >> .TPairEnumerator;
begin
  iter := fLines.GetEnumerator;
  while (iter.MoveNext()) do
  begin
    iter.current.Value.Free;
  end;
  fLines.Free;
end;

procedure TProcedureInfo.AddBreakPoint(lineNo: Integer;
  ABreakPoint: IBreakPoint);
var
  pair: TPair < System.Integer, TList < IBreakPoint >> ;
  bpList: TList<IBreakPoint>;
begin
  if (fLines.TryGetValue(lineNo, bpList)) then
  begin
    bpList.Add(ABreakPoint);
  end
  else
  begin
    bpList := TList<IBreakPoint>.Create;
    bpList.Add(ABreakPoint);
    fLines.Add(lineNo, bpList);
  end;

end;

function TProcedureInfo.getLineIterator(): TEnumerator<Integer>;
begin
  result := fLines.Keys.GetEnumerator;
end;

function TProcedureInfo.getNoLines: Integer;
begin
  result := fLines.Keys.Count;
end;

function TProcedureInfo.getCoveredLines: Integer;
var
  cnt: Integer;
  I: Integer;
  lineenum: TEnumerator<Integer>;
  bpList: TList<IBreakPoint>;
begin
  cnt := 0;
  lineenum := fLines.Keys.GetEnumerator;
  while (lineenum.MoveNext) do
  begin
    I := lineenum.current;
    bpList := fLines.Items[I];
    if covered(bpList) then
      inc(cnt);
  end;
  result := cnt;
end;

function TProcedureInfo.covered(bpList: TList<IBreakPoint>): Boolean;
var
  I: Integer;
begin
  result := false;
  for I := 0 to bpList.Count - 1 do
  begin
    if (bpList[I].covered) then
    begin
      result := true;
      break;
    end;

  end;
end;

function TProcedureInfo.isLineCovered(lineNo: Integer): Boolean;
var
  bpList: TList<IBreakPoint>;
begin
  result := false;
  if (fLines.TryGetValue(lineNo, bpList)) then
  begin
    result := covered(bpList);
  end;

end;

function TProcedureInfo.getCoverage(): Integer;
begin
  result := (100 * getCoveredLines()) div getNoLines();
end;

function TProcedureInfo.getName: String;
begin
  result := fName;
end;

constructor TClassInfo.Create(AModuleName: String; AClassName: String);
begin
  fModule := AModuleName;
  fName := AClassName;
  fProcedures := TDictionary<String, TProcedureInfo>.Create();
end;

destructor TClassInfo.Destroy;
begin
  fProcedures.Free;
end;

function TClassInfo.ensureProcedure(AProcedureName: String): TProcedureInfo;
var
  info: TProcedureInfo;
  exists: Boolean;
begin
  exists := fProcedures.TryGetValue(AProcedureName, info);

  if (exists) then
  begin
    result := info;
  end
  else
  begin
    info := TProcedureInfo.Create(AProcedureName);
    fProcedures.Add(AProcedureName, info);
    result := info;
  end;
end;

function TClassInfo.getCoverage: Integer;
var
  tot: Integer;
  cov: Integer;
  enum: TEnumerator<TProcedureInfo>;

begin
  tot := 0;
  cov := 0;
  enum := getProcedureIterator();
  while (enum.MoveNext()) do
  begin
    tot := tot + enum.current.getNoLines;
    cov := cov + enum.current.getCoveredLines;
  end;
  result := cov * 100 div tot;
end;

function TClassInfo.getProcedureIterator(): TEnumerator<TProcedureInfo>;
begin
  result := fProcedures.Values.GetEnumerator();
end;

function TClassInfo.getModule: String;
begin
  result := fModule;
end;

function TClassInfo.getClassName: String;
begin
  result := fName;
end;

function TClassInfo.getProcedureCount;
begin
  result := fProcedures.Count;
end;

function TClassInfo.getCoveredProcedureCount: Integer;
var
  enum: TEnumerator<TProcedureInfo>;

begin
  result := 0;
  enum := getProcedureIterator();
  while (enum.MoveNext()) do
  begin
    if (enum.current.getCoveredLines > 0) then
      inc(result, 1);
  end;
end;

function TClassInfo.GetTotalLineCount(): Integer;
var
  enum: TEnumerator<TProcedureInfo>;
begin
  result := 0;
  enum := getProcedureIterator();
  while (enum.MoveNext()) do
  begin
    inc(result, enum.current.getNoLines());
  end;
end;

function TClassInfo.GetTotalCoveredLineCount(): Integer;
var
  enum: TEnumerator<TProcedureInfo>;

begin
  result := 0;
  enum := getProcedureIterator();
  while (enum.MoveNext()) do
  begin
    inc(result, enum.current.getCoveredLines());
  end;
end;

function TClassInfo.getIsCovered(): Boolean;
begin
  result := (GetTotalCoveredLineCount > 0);
end;

constructor TModuleList.Create();

begin
  fModules := TDictionary<String, TModuleInfo>.Create();
end;

destructor TModuleList.Destroy;
begin
  fModules.Free;
end;

function TModuleList.getModuleIterator: TEnumerator<TModuleInfo>;
begin
  result := fModules.Values.GetEnumerator;
end;

function TModuleList.GetCount: Integer;
begin
  result := fModules.Count;
end;

function TModuleList.GetTotalClassCount;
var
  iter: TEnumerator<TModuleInfo>;
begin
  result := 0;
  iter := getModuleIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.getClassCount());
  end;
end;

function TModuleList.GetTotalCoveredClassCount;
var
  iter: TEnumerator<TModuleInfo>;
begin
  result := 0;
  iter := getModuleIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.getCoveredClassCount());
  end;
end;

function TModuleList.GetTotalMethodCount;

var
  iter: TEnumerator<TModuleInfo>;
begin
  result := 0;
  iter := getModuleIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.getMethodCount());
  end;
end;

function TModuleList.GetTotalCoveredMethodCount;
var
  iter: TEnumerator<TModuleInfo>;
begin
  result := 0;
  iter := getModuleIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.getCoveredMethodCount());
  end;
end;

function TModuleList.GetTotalLineCount(): Integer;
var
  iter: TEnumerator<TModuleInfo>;
begin
  result := 0;
  iter := getModuleIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.GetTotalLineCount());
  end;
end;

function TModuleList.GetTotalCoveredLineCount(): Integer;
var
  iter: TEnumerator<TModuleInfo>;
begin
  result := 0;
  iter := getModuleIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.GetTotalCoveredLineCount());
  end;
end;

function TModuleList.ensureModuleInfo(ModuleName: String;
  ModuleFileName: String): TModuleInfo;
var
  info: TModuleInfo;
  exists: Boolean;
begin
  exists := fModules.TryGetValue(ModuleName, info);

  if (exists) then
  begin
    result := info;
  end
  else
  begin
    info := TModuleInfo.Create(ModuleName, ModuleFileName);
    fModules.Add(ModuleName, info);
    result := info;
  end;
end;

procedure TModuleList.HandleBreakPoint(ModuleName: String;
  ModuleFileName: String; qualifiedprocName: String; lineNo: Integer;
  bk: IBreakPoint; logManager : ILogManager);
var
  list: TStrings;
  className: String;
  procName: String;
  clsInfo: TClassInfo;
  procInfo: TProcedureInfo;
  module: TModuleInfo;
begin

  logManager.log('Adding bkpt for '+qualifiedProcName + ' in '+moduleFilename);
  list := TStringList.Create;
  try
    ExtractStrings(['.'], [], PWideChar(qualifiedprocName), list);
    if (list.Count > 1) then
    begin
      className := list[1];
      if list.Count > 2 then
      begin
        module := ensureModuleInfo(ModuleName, ModuleFileName);
        procName := list[2];
        clsInfo := module.ensureClassInfo(ModuleName, className);
        procInfo := clsInfo.ensureProcedure(procName);
        procInfo.AddBreakPoint(lineNo, bk);
      end
      else
      begin
        module := ensureModuleInfo(ModuleName, ModuleFileName);
        className := list[0];
        procName := list[1];
        clsInfo := module.ensureClassInfo(ModuleName, className);
        procInfo := clsInfo.ensureProcedure(procName);
        procInfo.AddBreakPoint(lineNo, bk);

      end;
    end;
  finally
    list.Free;
  end;
end;

constructor TModuleInfo.Create(const AModuleName: String;
  const AModuleFileName: String);

begin
  fName := AModuleName;
  fFileName := AModuleFileName;
  fClasses := TDictionary<String, TClassInfo>.Create();
end;

destructor TModuleInfo.Destroy;
begin
  fClasses.Free;
end;

function TModuleInfo.toString;
begin
  result := 'ModuleInfo[ modulename=' + fName + ',filename=' + fFileName + ']';
end;

function TModuleInfo.getModuleName: String;
begin
  result := fName;
end;

function TModuleInfo.getModuleFileName: String;
begin
  result := fFileName;
end;

function TModuleInfo.ensureClassInfo(ModuleName: String;
  className: String): TClassInfo;
var
  info: TClassInfo;
  exists: Boolean;
begin
  exists := fClasses.TryGetValue(className, info);

  if (exists) then
  begin
    result := info;
  end
  else
  begin
    writeln('Creating class info for ' + ModuleName + ' class ' + className);
    info := TClassInfo.Create(ModuleName, className);
    fClasses.Add(className, info);
    result := info;
  end;
end;

function TModuleInfo.getClassIterator(): TEnumerator<TClassInfo>;
begin
  result := fClasses.Values.GetEnumerator();
end;

function TModuleInfo.getClassCount;
begin
  result := fClasses.Count;
end;

function TModuleInfo.getCoveredClassCount;
var
  iter: TEnumerator<TClassInfo>;
begin
  result := 0;
  iter := getClassIterator();
  while (iter.MoveNext) do
  begin
    if (iter.current.getCoverage() > 0) then
      inc(result, 1);
  end;
end;

function TModuleInfo.getMethodCount: Integer;
var
  iter: TEnumerator<TClassInfo>;
begin
  result := 0;
  iter := getClassIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.getProcedureCount);
  end;
end;

function TModuleInfo.getCoveredMethodCount: Integer;
var
  iter: TEnumerator<TClassInfo>;
begin
  result := 0;
  iter := getClassIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.getCoveredProcedureCount());
  end;
end;

function TModuleInfo.GetTotalLineCount(): Integer;
var
  iter: TEnumerator<TClassInfo>;
begin
  result := 0;
  iter := getClassIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.GetTotalLineCount());
  end;
end;

function TModuleInfo.GetTotalCoveredLineCount(): Integer;
var
  iter: TEnumerator<TClassInfo>;
begin
  result := 0;
  iter := getClassIterator();
  while (iter.MoveNext) do
  begin
    inc(result, iter.current.GetTotalCoveredLineCount());
  end;
end;

end.
