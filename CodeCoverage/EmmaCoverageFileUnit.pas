(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit EmmaCoverageFileUnit;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  Windows,
  JclSimpleXml,
  I_Report,
  I_CoverageStats,
  I_CoverageConfiguration,
  I_LogManager,
  EmmaDataFile,
  CoverageDataUnit,
  MetaDataUnit,
  FileHelper,
  ClassInfoUnit;

type
  TEmmaCoverageFile = class(TInterfacedObject, IReport)
  private
    FCoverageConfiguration: ICoverageConfiguration;
    FLogManager: ILogManager;
    procedure IterateOverModules(
      const AModuleInfoList: TModuleList;
      ACoverageData: TEmmaCoverageData;
      AMetaData: TEmmaMetaData);
    procedure GetCoverageForModule(
      const AModule: TModuleInfo;
      AMetaData: TEmmaMetaData;
      ACoverageData: TEmmaCoverageData);

    procedure IterateOverClasses(
      const AModule: TModuleInfo;
      AMetaData: TEmmaMetaData;
      ACoverageData: TEmmaCoverageData);

    procedure GetCoverageForClass(
      const AClassInfo: TClassInfo;
      const AModuleName: string;
      const AModuleFileName: string;
      AMetaData: TEmmaMetaData;
      var AClassDescriptor: TClassDescriptor;
      out AFullQualifiedClassName: string;
      var ABoolArray: TMultiBooleanArray);

    function MakeFullQualifiedClassName(const AClassName, AModuleName: string): string;

    procedure GetCoverageForMethod(
      const AMethodInfo: TProcedureInfo;
      var AClassDescriptor: TClassDescriptor;
      var ABoolArray: TMultiBooleanArray;
      var AMethodIndex: Integer);

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
  Generics.Collections,
  JclFileUtils,
  I_BreakPoint,
  BreakPoint;

constructor TEmmaCoverageFile.Create(
  const ACoverageConfiguration: ICoverageConfiguration);
begin
  inherited Create;

  FCoverageConfiguration := ACoverageConfiguration;
end;

procedure TEmmaCoverageFile.Generate(
  const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList;
  const ALogManager: ILogManager);
var
  OutFile: TStream;
  EmmaFile: TEmmaFile;
  MetaData: TEmmaMetaData;
  CoverageData: TEmmaCoverageData;
  OutFileName: string;
begin
  FLogManager := ALogManager;
  try
    FLogManager.Log('Generating EMMA file');

    EmmaFile := TEmmaFile.Create;
    try
      MetaData := TEmmaMetaData.Create;
      CoverageData := TEmmaCoverageData.Create;
      try
        IterateOverModules(
          AModuleInfoList,
          CoverageData,
          MetaData
        );

        EmmaFile.Add(MetaData);
        EmmaFile.Add(CoverageData);
        FileMode := fmOpenReadWrite;

        OutFileName := PathAppend(FCoverageConfiguration.OutputDir, 'coverage.es');
        if FileExists(OutFileName) then
          DeleteFile(OutFileName);

        OutFile := TFileStream.Create(OutFileName, fmCreate or fmShareExclusive);
        try
          EmmaFile.Write(OutFile);
        finally
          OutFile.Free;
        end;
      finally
        MetaData.Free;
        CoverageData.Free;
      end;
    finally
      EmmaFile.Free;
    end;

    FLogManager.Log('Emma file generated');
  except
    on E: EInvalidPointer do
    begin
      Writeln(E.ToString);
      Writeln(E.StackTrace);
    end;
  end;

end;

procedure TEmmaCoverageFile.IterateOverModules(
  const AModuleInfoList: TModuleList;
  ACoverageData: TEmmaCoverageData;
  AMetaData: TEmmaMetaData);
var
  ModuleInfo: TModuleInfo;
begin
  for ModuleInfo in AModuleInfoList do
    GetCoverageForModule(
      ModuleInfo,
      AMetaData,
      ACoverageData
    );
end;

procedure TEmmaCoverageFile.GetCoverageForModule(
  const AModule: TModuleInfo;
  AMetaData: TEmmaMetaData;
  ACoverageData: TEmmaCoverageData);
begin
  FLogManager.Log('Generating EMMA data for module: ' + AModule.ToString);

  AMetaData.HasSourceFileInfo := true;
  AMetaData.HasLineNumberInfo := true;

  IterateOverClasses(
    AModule,
    AMetaData,
    ACoverageData
  );
end;

procedure TEmmaCoverageFile.IterateOverClasses(
  const AModule: TModuleInfo;
  AMetaData: TEmmaMetaData;
  ACoverageData: TEmmaCoverageData);
var
  ClassInfo: TClassInfo;
  ClassDescriptor: TClassDescriptor;
  BoolArray: TMultiBooleanArray;
  FullQualifiedClassName: string;
  VMStyleClassName: string;
  i: Integer;
begin
  for ClassInfo in AModule do
  begin
    ClassDescriptor := nil;

    GetCoverageForClass(
      ClassInfo,
      AModule.ModuleName,
      AModule.ModuleFileName,
      AMetaData,
      ClassDescriptor,
      FullQualifiedClassName,
      BoolArray);

    if Assigned(ClassDescriptor) then
      AMetaData.Add(ClassDescriptor);

    VMStyleClassName := StringReplace(FullQualifiedClassName, '.', '/', [rfReplaceAll]);

    if ClassInfo.IsCovered then
      ACoverageData.Add(TDataHolder.Create(VMStyleClassName, 0, BoolArray));

    for i := 0 to Length(BoolArray) - 1 do
      SetLength(BoolArray[i], 0);
    SetLength(BoolArray, 0);
  end;
end;

procedure TEmmaCoverageFile.GetCoverageForClass(
  const AClassInfo: TClassInfo;
  const AModuleName: string;
  const AModuleFileName: string;
  AMetaData: TEmmaMetaData;
  var AClassDescriptor: TClassDescriptor;
  out AFullQualifiedClassName: string;
  var ABoolArray: TMultiBooleanArray);
var
  Method: TProcedureInfo;
  MethodIndex: Integer;
begin
  FLogManager.Log('Generating EMMA data for class: ' + AClassInfo.TheClassName);

  AFullQualifiedClassName := MakeFullQualifiedClassName(AClassInfo.TheClassName, AModuleName);

  AClassDescriptor := TClassDescriptor.Create(
    AClassInfo.TheClassName,
    1,
    AModuleFileName,
    AFullQualifiedClassName,
    StringReplace(AModuleName, '.', '/', [rfReplaceAll])
  );

  SetLength(ABoolArray, AClassInfo.ProcedureCount);

  MethodIndex := 0;
  for Method in AClassInfo do
  begin
    GetCoverageForMethod(
      Method,
      AClassDescriptor,
      ABoolArray,
      MethodIndex
    );
  end;
end;

function TEmmaCoverageFile.MakeFullQualifiedClassName(
  const AClassName: string;
  const AModuleName: string): string;
var
  ModulePrefix: string;
begin
  ModulePrefix := AModuleName;

  if (Length(ModulePrefix) > 0) then
    ModulePrefix := ModulePrefix + '.';

  Result := ModulePrefix + AClassName;
end;

procedure TEmmaCoverageFile.GetCoverageForMethod(
  const AMethodInfo: TProcedureInfo;
  var AClassDescriptor: TClassDescriptor;
  var ABoolArray: TMultiBooleanArray;
  var AMethodIndex: Integer);
var
  MethodDescriptor: TMethodDescriptor;
  I: Integer;
  CurrentLine: Integer;
begin
  FLogManager.Log(
    'Generating EMMA data for method: ' + AMethodInfo.Name +
    ' l:' + IntToStr(AMethodInfo.LineCount) +
    ' c:' + IntToStr(AMethodInfo.CoveredLineCount));

  MethodDescriptor := TMethodDescriptor.Create;
  MethodDescriptor.Name := AMethodInfo.Name;
  MethodDescriptor.Descriptor := '()V';
  MethodDescriptor.Status := 0;

  MethodDescriptor.SetBlockSizesLength(AMethodInfo.LineCount);
  for I := 0 to AMethodInfo.LineCount - 1 do
  begin
    MethodDescriptor.BlockSizes[I] := 1;
  end;

  I := 0;
  MethodDescriptor.SetBlockMapLength(AMethodInfo.LineCount);
  SetLength(ABoolArray[AMethodIndex], AMethodInfo.LineCount);
  for CurrentLine in AMethodInfo do
  begin
    SetLength(MethodDescriptor.BlockMap[I], 1);
    MethodDescriptor.BlockMap[I, 0] := CurrentLine;
    ABoolArray[AMethodIndex, I] := AMethodInfo.IsLineCovered(CurrentLine);
    Inc(I);
  end;

  AClassDescriptor.add(MethodDescriptor);
  Inc(AMethodIndex);
end;

end.
