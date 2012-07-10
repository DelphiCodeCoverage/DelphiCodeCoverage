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

uses Generics.Collections, I_BreakPoint;

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
      qualifiedprocName: String; bk: IBreakPoint);
  end;

  TModuleInfo = class
  private
    fName: String;
    fFileName: String;
    fClasses: TDictionary<String, TClassInfo>;
    function ensureClassInfo(ModuleName: String; className: String): TClassInfo;
  public
    constructor Create(const AModuleName: String; const AModuleFileName: String);
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
    function toString:String;override;
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
    function getIsCovered():Boolean;

  end;

  TProcedureInfo = class
  private
    fName: String;
    fBreakPointList: TList<IBreakPoint>;
  public
    constructor Create(name: String);
    destructor Destroy; override;
    procedure AddBreakPoint(ABreakPoint: IBreakPoint);
    function getBreakPointIterator(): TEnumerator<IBreakPoint>;
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
  fBreakPointList := TList<IBreakPoint>.Create();
end;

destructor TProcedureInfo.Destroy;
begin
  fBreakPointList.Free;
end;

procedure TProcedureInfo.AddBreakPoint(ABreakPoint: IBreakPoint);
begin
  fBreakPointList.add(ABreakPoint);
end;

function TProcedureInfo.getBreakPointIterator(): TEnumerator<IBreakPoint>;
begin
  result := fBreakPointList.getEnumerator();
end;

function TProcedureInfo.getNoLines: Integer;
begin
  result := fBreakPointList.Count;
end;

function TProcedureInfo.getCoveredLines: Integer;
var
  cnt: Integer;
  I: Integer;
begin
  cnt := 0;
  for I := 0 to fBreakPointList.Count - 1 do
  begin
    if not(fBreakPointList[I].IsActive()) then
      inc(cnt);
  end;
  result := cnt;
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
  exists: boolean;
begin
  exists := fProcedures.TryGetValue(AProcedureName, info);

  if (exists) then
  begin
    result := info;
  end
  else
  begin
    info := TProcedureInfo.Create(AProcedureName);
    fProcedures.add(AProcedureName, info);
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
    tot := tot + enum.Current.getNoLines;
    cov := cov + enum.Current.getCoveredLines;
  end;
  result := cov * 100 div tot;
end;

function TClassInfo.getProcedureIterator(): TEnumerator<TProcedureInfo>;
begin
  result := fProcedures.Values.getEnumerator();
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
    if (enum.Current.getCoveredLines > 0) then
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
    inc(result, enum.Current.getNoLines());
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
    inc(result, enum.Current.getCoveredLines());
  end;
end;

function TClassInfo.getIsCovered():Boolean;
begin
  result := (getTotalCoveredLineCount>0);
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
  result := fModules.Values.getEnumerator;
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
    inc(result, iter.Current.getClassCount());
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
    inc(result, iter.Current.getCoveredClassCount());
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
    inc(result, iter.Current.getMethodCount());
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
    inc(result, iter.Current.getCoveredMethodCount());
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
    inc(result, iter.Current.GetTotalLineCount());
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
    inc(result, iter.Current.GetTotalCoveredLineCount());
  end;
end;

function TModuleList.ensureModuleInfo(ModuleName: String;
  ModuleFileName: String): TModuleInfo;
var
  info: TModuleInfo;
  exists: boolean;
begin
  exists := fModules.TryGetValue(ModuleName, info);

  if (exists) then
  begin
    result := info;
  end
  else
  begin
    info := TModuleInfo.Create(ModuleName, ModuleFileName);
    fModules.add(ModuleName, info);
    result := info;
  end;
end;

procedure TModuleList.HandleBreakPoint(ModuleName: String;
  ModuleFileName: String; qualifiedprocName: String; bk: IBreakPoint);
var
  list: TStrings;
  className: String;
  procName: String;
  clsInfo: TClassInfo;
  procInfo: TProcedureInfo;
  module: TModuleInfo;
begin

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
        procInfo.AddBreakPoint(bk);
      end
      else
      begin
        module := ensureModuleInfo(ModuleName, ModuleFileName);
        className := list[0];
        procName := list[1];
        clsInfo := module.ensureClassInfo(ModuleName, className);
        procInfo := clsInfo.ensureProcedure(procName);
        procInfo.AddBreakPoint(bk);

      end;
    end;
  finally
    list.Free;
  end;
end;

constructor TModuleInfo.Create(const AModuleName: String; const AModuleFileName: String);

begin
  fName := AModuleName;
  fFileName := AModuleFileName;
  fClasses := TDictionary<String, TClassInfo>.Create();
end;

destructor TModuleInfo.Destroy;
begin
  fClasses.Free;
end;

function TModuleInfo.ToString;
begin
  result := 'ModuleInfo[ modulename='+fName+',filename='+fFileName+']';
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
  exists: boolean;
begin
  exists := fClasses.TryGetValue(className, info);

  if (exists) then
  begin
    result := info;
  end
  else
  begin
    writeln('Creating class info for '+modulename+' class '+classname);
    info := TClassInfo.Create(ModuleName, className);
    fClasses.add(className, info);
    result := info;
  end;
end;

function TModuleInfo.getClassIterator(): TEnumerator<TClassInfo>;
begin
  result := fClasses.Values.getEnumerator();
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
    if (iter.Current.getCoverage() > 0) then
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
    inc(result, iter.Current.getProcedureCount);
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
    inc(result, iter.Current.getCoveredProcedureCount());
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
    inc(result, iter.Current.GetTotalLineCount());
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
    inc(result, iter.Current.GetTotalCoveredLineCount());
  end;
end;

end.
