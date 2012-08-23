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
  I_Report,
  I_CoverageStats,
  JclSimpleXml,
  ClassInfoUnit, I_CoverageConfiguration, I_LogManager;

type
  TEmmaCoverageFile = class(TInterfacedObject, IReport)
  private
    FCoverageConfiguration: ICoverageConfiguration;

  public
    Constructor Create(const ACoverageConfiguration: ICoverageConfiguration);
    procedure Generate(const ACoverage: ICoverageStats;
      const AModuleInfoList: TModuleList; logMgr: ILogManager);
  end;

implementation

uses
  SysUtils,
  JclFileUtils, EmmaDataFile, metadataunit, coveragedataunit,
  Generics.Collections,
  I_BreakPoint, breakpoint, FileHelper;

{ TEmmaCoverageFile }

constructor TEmmaCoverageFile.Create(const ACoverageConfiguration
    : ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

procedure TEmmaCoverageFile.Generate(const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList; logMgr: ILogManager);
var
  outFile: File;
  emmafile: TEmmaFile;
  metadata: TEmmaMetaData;
  coverageData: TEmmaCoverageData;
  moduleIterator: TEnumerator<TModuleInfo>;
  module: TModuleInfo;
  cd: TClassDescriptor;
  md: TMethodDescriptor;
  I: Integer;
  dh: TDataHolder;
  classiter: TEnumerator<TClassInfo>;
  classinfo: TClassInfo;
  methoditer: TEnumerator<TProcedureInfo>;
  methodinfo: TProcedureInfo;
  bkptiter: TEnumerator<Integer>;
  boolarr: TMultiBooleanArray;
  methodindex: Integer;
  classIsCovered: Boolean;
  modulePrefix: String;
  vmStyleModuleName: String;
  vmStyleClassName: String;
  fqnClassName: String;
  currLine : Integer;
begin
  try
    logMgr.Log('Generating EMMA file');
    emmafile := TEmmaFile.Create;
    metadata := TEmmaMetaData.Create;
    coverageData := TEmmaCoverageData.Create;
    moduleIterator := AModuleInfoList.getModuleIterator;
    while (moduleIterator.MoveNext) do
    begin
      module := moduleIterator.Current;
      logMgr.Log('Generating EMMA data for module: ' + module.ToString);

      metadata.fCoverageOptions := TCoverageOptions.Create;
      metadata.fHasSrcFileInfo := true;
      metadata.fHasLineNumberInfo := true;
      classIsCovered := False;
      cd := nil;
      classiter := module.GetClassIterator;
      while (classiter.MoveNext) do
      begin
        classinfo := classiter.Current;
        logMgr.Log('Generating EMMA data for class: ' + classinfo.GetClassName()
          );
        classIsCovered := classinfo.GetIsCovered();
        modulePrefix := module.GetModuleName();
        if (Length(modulePrefix) > 0) then
        begin
          modulePrefix := modulePrefix + '.';
        end;
        vmStyleModuleName := StringReplace(module.GetModuleName(), '.', '/',
          [rfReplaceAll]);
        fqnClassName := modulePrefix + classinfo.GetClassName();
        cd := TClassDescriptor.Create(classinfo.GetClassName, 1,
          module.GetModuleFileName, fqnClassName, vmStyleModuleName);
        methoditer := classinfo.GetProcedureIterator;

        setlength(boolarr, classinfo.GetProcedureCount());
        methodindex := 0;
        while (methoditer.MoveNext) do
        begin

          methodinfo := methoditer.Current;
          logMgr.Log('Generating EMMA data for method: ' + methodinfo.GetName +
              ' l:' + IntToStr(methodinfo.GetLineCount) + ' c:' + IntToStr
              (methodinfo.GetCoveredLineCount));

          md := TMethodDescriptor.Create;
          md.fName := methodinfo.GetName;
          md.fDescriptor := '()V';
          md.fStatus := 0;
          bkptiter := methodinfo.GetLineIterator;
          setlength(md.fBlockSizes, methodinfo.GetLineCount);
          for I := 0 to methodinfo.GetLineCount() - 1 do
          begin
            md.fBlockSizes[I] := 1;
          end;

          I := 0;
          setlength(md.fBlockMap, methodinfo.GetLineCount);
          setlength(boolarr[methodindex], methodinfo.GetLineCount);
          while (bkptiter.MoveNext) do
          begin
            currLine := bkptiter.Current;

            setlength(md.fBlockMap[I], 1);
            md.fBlockMap[I, 0] := currLine;
            boolarr[methodindex, I] := methodInfo.IsLineCovered(currLine);
            inc(I);
          end;
          cd.add(md);
          inc(methodindex);
        end;
      end;
      vmStyleClassName := StringReplace(fqnClassName, '.', '/', [rfReplaceAll]);
      dh := TDataHolder.Create(vmStyleClassName, 0, boolarr);
      if (classIsCovered) then
        coverageData.add(dh);

      if Assigned(cd) then
        metadata.add(cd);
    end;

    emmafile.add(metadata);
    emmafile.add(coverageData);
    FileMode := fmOpenReadWrite;
    AssignFile(outFile, PathAppend(FCoverageConfiguration.OutputDir(),
        'coverage.es'));
    try
      rewrite(outFile, 1);
      emmafile.write(outFile);
    finally
      CloseFile(outFile);
    end;
    logMgr.Log('Emma file generated');
  except
    on eipe: EInvalidPointer do
    begin

      writeln(eipe.ToString);
      writeln(eipe.StackTrace);
    end;

  end;

end;

end.
