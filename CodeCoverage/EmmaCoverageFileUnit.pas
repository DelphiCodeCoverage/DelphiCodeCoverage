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
  Types,
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

    function IterateOverModules(
      const AModuleInfoList: TModuleList;
      ACoverageData: TEmmaCoverageData;
      AMetaData: TEmmaMetaData): Boolean;
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
      out AClassCoverageArray: TMultiBooleanArray);

    function MakeFullQualifiedClassName(const AClassName, AModuleName: string): string;

    procedure GetCoverageForMethod(
      const AMethodInfo: TProcedureInfo;
       out AMethodDescriptor: TMethodDescriptor;
       out AMethodCoverageArray: TBooleanDynArray);
    procedure WriteEmmaFile(
      const AEmmaFile: TEmmaFile;
      const AFileName: string);
    procedure WriteSeparateFiles(CoverageData: TEmmaCoverageData; MetaData: TEmmaMetaData);
    procedure WriteMergedFile(CoverageData: TEmmaCoverageData; MetaData: TEmmaMetaData);
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
  MetaData: TEmmaMetaData;
  CoverageData: TEmmaCoverageData;
begin
  FLogManager := ALogManager;
  try
    FLogManager.Log('Generating EMMA file');

    MetaData := TEmmaMetaData.Create;
    MetaData.HasSourceFileInfo := True;
    MetaData.HasLineNumberInfo := True;

    CoverageData := TEmmaCoverageData.Create;
    try
      if IterateOverModules(
        AModuleInfoList,
        CoverageData,
        MetaData
      ) then
      begin
        if (FCoverageConfiguration.SeparateMeta) then
          WriteSeparateFiles(CoverageData, MetaData)
        else
          WriteMergedFile(CoverageData, MetaData)
      end
      else
      begin
        ALogManager.Log(
          'Generating emma file - No modules found - thus no emma file generated.');
      end;
    finally
      MetaData.Free;
      CoverageData.Free;
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

procedure TEmmaCoverageFile.WriteSeparateFiles(CoverageData: TEmmaCoverageData; MetaData: TEmmaMetaData);
var
  MetaDataFile: TEmmaFile;
  CoverageFile: TEmmaFile;
begin
  MetaDataFile := TEmmaFile.Create;
  CoverageFile := TEmmaFile.Create;
  try
    MetaDataFile.Add(MetaData);
    CoverageFile.Add(CoverageData);
    WriteEmmaFile(MetaDataFile, 'coverage.em');
    WriteEmmaFile(CoverageFile, 'coverage.ec');
  finally
    MetaDataFile.Free;
    CoverageFile.Free;
  end;
end;

procedure TEmmaCoverageFile.WriteMergedFile(CoverageData: TEmmaCoverageData; MetaData: TEmmaMetaData);
var
  MergedFile: TEmmaFile;
begin
  MergedFile := TEmmaFile.Create;
  try
    MergedFile.Add(MetaData);
    MergedFile.Add(CoverageData);

    WriteEmmaFile(MergedFile, 'coverage.es');
  finally
    MergedFile.Free;
  end;
end;

procedure TEmmaCoverageFile.WriteEmmaFile(
  const AEmmaFile: TEmmaFile;
  const AFileName: string);
var
  OutFile: TStream;
  OutFileName: string;
begin
  OutFileName := PathAppend(FCoverageConfiguration.OutputDir, AFileName);
  if FileExists(OutFileName) then
    DeleteFile(OutFileName);

  OutFile := TFileStream.Create(OutFileName, fmCreate or fmShareExclusive);
  try
    AEmmaFile.Write(OutFile);
  finally
    OutFile.Free;
  end;
end;

function TEmmaCoverageFile.IterateOverModules(
  const AModuleInfoList: TModuleList;
  ACoverageData: TEmmaCoverageData;
  AMetaData: TEmmaMetaData): Boolean;
var
  ModuleInfo: TModuleInfo;
begin
  Result := false;
  for ModuleInfo in AModuleInfoList do
  begin
    Result := true; // a module was found

    GetCoverageForModule(
      ModuleInfo,
      AMetaData,
      ACoverageData
    );
  end;
end;

procedure TEmmaCoverageFile.GetCoverageForModule(
  const AModule: TModuleInfo;
  AMetaData: TEmmaMetaData;
  ACoverageData: TEmmaCoverageData);
begin
  FLogManager.Log('Generating EMMA data for module: ' + AModule.ToString);

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
  end;
end;

procedure TEmmaCoverageFile.GetCoverageForClass(
  const AClassInfo: TClassInfo;
  const AModuleName: string;
  const AModuleFileName: string;
  AMetaData: TEmmaMetaData;
  var AClassDescriptor: TClassDescriptor;
  out AFullQualifiedClassName: string;
  out AClassCoverageArray: TMultiBooleanArray);
var
  Method: TProcedureInfo;
  MethodIndex: Integer;
  MethodDescriptor: TMethodDescriptor;
  MethodCoverageArray: TBooleanDynArray;
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

  SetLength(AClassCoverageArray, AClassInfo.ProcedureCount);

  MethodIndex := 0;
  for Method in AClassInfo do
  begin
    GetCoverageForMethod(
      Method,
      MethodDescriptor,
      MethodCoverageArray
    );
    AClassDescriptor.add(MethodDescriptor);
    AClassCoverageArray[MethodIndex] := MethodCoverageArray;
    Inc(MethodIndex);
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
  out AMethodDescriptor: TMethodDescriptor;
  out AMethodCoverageArray: TBooleanDynArray);
var
  I: Integer;
  CurrentLine: Integer;
begin
  FLogManager.Log(
    'Generating EMMA data for method: ' + AMethodInfo.Name +
    ' l:' + IntToStr(AMethodInfo.LineCount) +
    ' c:' + IntToStr(AMethodInfo.CoveredLineCount));

  AMethodDescriptor := TMethodDescriptor.Create;
  AMethodDescriptor.Name := AMethodInfo.Name;
  AMethodDescriptor.Descriptor := '()V';
  AMethodDescriptor.Status := 0;

  AMethodDescriptor.SetBlockSizesLength(AMethodInfo.LineCount);
  for I := 0 to AMethodInfo.LineCount - 1 do
  begin
    AMethodDescriptor.BlockSizes[I] := 1;
  end;

  I := 0;
  AMethodDescriptor.SetBlockMapLength(AMethodInfo.LineCount);
  SetLength(AMethodCoverageArray, AMethodInfo.LineCount);
  for CurrentLine in AMethodInfo do
  begin
    SetLength(AMethodDescriptor.BlockMap[I], 1);
    AMethodDescriptor.BlockMap[I, 0] := CurrentLine;
    AMethodCoverageArray[I] := AMethodInfo.IsLineCovered(CurrentLine);
    Inc(I);
  end;
end;

end.
