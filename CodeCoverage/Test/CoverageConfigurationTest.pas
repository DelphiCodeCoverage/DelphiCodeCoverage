(* ************************************************************ *)
(* Delphi Code Coverage                                         *)
(*                                                              *)
(* A quick hack of a Code Coverage Tool for Delphi 2010         *)
(* by Christer Fahlgren                                         *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1                    *)
(* ************************************************************ *)

unit CoverageConfigurationTest;

interface

{$INCLUDE ..\CodeCoverage.inc}

uses
  Classes,
  SysUtils,
  TestFramework,
  CoverageConfiguration,
  I_CoverageConfiguration;

type
  TCoverageConfigurationTest = class(TTestCase)
  private
    function RandomFileName : string;
  protected
  public
  published
    //procedure TestIncompleteCommandLine;
    //procedure TestNoMapFile;
    //procedure TestUnitParams;
    //procedure TestAppParams;

    procedure TestPreParsing;

    procedure TestNoParameters;

    procedure TestInvalidParameter;

    procedure TestEnableApiLogging;

    procedure TestEnableFileLoggingDefaultFile;
    procedure TestEnableFileLoggingSpecifiedFile;

    procedure TestOutputDirectoryError;
    procedure TestOutputDirectory;

    procedure TestSourcePathFileError;
    procedure TestSourcePathFileNoExistingFile;
    procedure TestSourcePathFileFakeDir;
    procedure TestSourcePathFile;

    procedure TestSourcePathError;
    procedure TestSourcePathFakeDir;
    procedure TestSourcePathSingleDir;
    procedure TestSourcePathMultipleDir;

    procedure TestSourceDirectoryError;
    procedure TestSourceDirectory;

    procedure TestExecutableParameterEmpty;
    procedure TestExecutableParameterSingle;
    procedure TestExecutableParameterMultiple;
    procedure TestExecutableParameterUnescape;

    procedure TestUnitFileError;
    procedure TestUnitFileNoExistingFile;
    procedure TestUnitFile;
    procedure TestUnitFileStrippingOfPathAndExtensions;

    procedure TestUnitError;
    procedure TestUnitSingle;
    procedure TestUnitMultiple;
    procedure TestUnitStrippingOfPathAndExtensions;

    procedure TestMapFileError;
    procedure TestMapFile;
    procedure TestMapFileNoExistingFile;

    procedure TestExecutableError;
    procedure TestExecutable;
    procedure TestExecutableNoExistingFile;

    procedure TestMisc;
  end;

implementation

uses
  {$IFDEF SUPPORTS_INLINE}Windows,{$ENDIF}
  MockCommandLineProvider;

//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
//procedure TCoverageConfigurationTest.TestNoMapFile;
//var
//  CoverageConfiguration: ICoverageConfiguration;
//  Reason: string;
//begin
//  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cIncompleteParams));
//  CoverageConfiguration.ParseCommandLine;
//
//  CheckFalse(CoverageConfiguration.isComplete(Reason), 'Configuration should not be complete based on these parameters');
//  CheckEquals(CoverageConfiguration.GetMapFileName(), 'mapfile.map', 'Mapfile was : ' + CoverageConfiguration.getMapFileName());
//end;
//
////==============================================================================
//procedure TCoverageConfigurationTest.TestIncompleteCommandLine;
//var
//  CoverageConfiguration: ICoverageConfiguration;
//begin
//  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cNoMapFileParams));
//  try
//    CoverageConfiguration.ParseCommandLine;
//  except
//    on EConfigurationException do
//      Check(True, 'Expected ConfigurationException detected');
//    else
//      Raise;
//  end;
//end;
//
////==============================================================================
//procedure TCoverageConfigurationTest.TestUnitParams;
//var
//  CoverageConfiguration: ICoverageConfiguration;
//  UnitsStrLst: TStrings; // Pointer
//begin
//  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cUnitParams));
//  CoverageConfiguration.ParseCommandLine;
//
//  UnitsStrLst := CoverageConfiguration.getUnits;
//  CheckNotEquals(UnitsStrLst.IndexOf('testunit'), -1, 'testunit does not exist in list');
//end;
//
////==============================================================================
//procedure TCoverageConfigurationTest.TestAppParams;
//var
//  CoverageConfiguration : ICoverageConfiguration;
//  ApplicationParameters : string;
//begin
//  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cApplicationParams));
//  CoverageConfiguration.ParseCommandLine;
//
//  ApplicationParameters := CoverageConfiguration.getApplicationParameters;
//  CheckEquals(ApplicationParameters, '-inputparam');
//end;
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
function TCoverageConfigurationTest.RandomFileName: string;
var
  lp : Integer;
begin
  Randomize;
  repeat
    Result := '';

    for lp := 1 to 8 do
    begin
      Result := Result + Chr(Ord('A') + Random(26));
    end;

  until not FileExists(Result);
end;
//==============================================================================
procedure TCoverageConfigurationTest.TestPreParsing;
var
  CoverageConfiguration: ICoverageConfiguration;
  Reason : string;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create([]));

  CheckEquals(CoverageConfiguration.GetApplicationParameters, '', 'Application Parameters set');
  CheckEquals(CoverageConfiguration.GetExeFileName, '', 'Executable file name should not be set');
  CheckEquals(CoverageConfiguration.GetMapFileName, '', 'Map file name should not be set');
  CheckEquals(CoverageConfiguration.GetOutputDir,   '', 'Report output directory should not be set');
  CheckEquals(CoverageConfiguration.GetSourceDir,   '', 'Source directory should not be set');
  CheckEquals(CoverageConfiguration.GetDebugLogFile, '', 'Debug logging file name should not be set');
  CheckEquals(CoverageConfiguration.GetSourcePaths.Count, 0, 'Source paths should not have directories listed');
  CheckEquals(CoverageConfiguration.GetUnits.Count, 0, 'Unit list should not have any units listed');
  CheckFalse(CoverageConfiguration.UseApiDebug, 'API Logging is turned on.');
  CheckFalse(CoverageConfiguration.IsComplete(Reason), 'Parameters shoujld not be complete');
  CheckEquals(Reason, 'No map file was specified', 'Map file should not have been specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestNoParameters;
var
  CoverageConfiguration: ICoverageConfiguration;
  Reason : string;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create([]));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Unexpected switch:' + cInvalidParameter[0], 'Error message mis-match');

      CheckEquals(CoverageConfiguration.GetApplicationParameters, '', 'Application Parameters set');
      CheckEquals(CoverageConfiguration.GetExeFileName, '', 'Executable file name should not be set');
      CheckEquals(CoverageConfiguration.GetMapFileName, '', 'Map file name should not be set');
      CheckEquals(CoverageConfiguration.GetOutputDir,   '', 'Report output directory should not be set');
      CheckEquals(CoverageConfiguration.GetSourceDir,   '', 'Source directory should not be set');
      CheckEquals(CoverageConfiguration.GetDebugLogFile, '', 'Debug logging file name should not be set');
      CheckEquals(CoverageConfiguration.GetSourcePaths.Count, 0, 'Source paths should not have directories listed');
      CheckEquals(CoverageConfiguration.GetUnits.Count, 0, 'Unit list should not have any units listed');
      CheckFalse(CoverageConfiguration.UseApiDebug, 'API Logging is turned on.');
      CheckFalse(CoverageConfiguration.IsComplete(Reason), 'Parameters shoujld not be complete');
      CheckEquals(Reason, 'No map file was specified', 'Map file should not have been specified');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestInvalidParameter;
var
  CoverageConfiguration: ICoverageConfiguration;
  Reason : string;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cInvalidParameter));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Unexpected switch:' + cInvalidParameter[0], 'Error message mis-match');

      CheckEquals(CoverageConfiguration.GetApplicationParameters, '', 'Application Parameters set');
      CheckEquals(CoverageConfiguration.GetExeFileName, '', 'Executable file name should not be set');
      CheckEquals(CoverageConfiguration.GetMapFileName, '', 'Map file name should not be set');
      CheckEquals(CoverageConfiguration.GetOutputDir,   '', 'Report output directory should not be set');
      CheckEquals(CoverageConfiguration.GetSourceDir,   '', 'Source directory should not be set');
      CheckEquals(CoverageConfiguration.GetDebugLogFile, '', 'Debug logging file name should not be set');
      CheckEquals(CoverageConfiguration.GetSourcePaths.Count, 0, 'Source paths should not have directories listed');
      CheckEquals(CoverageConfiguration.GetUnits.Count, 0, 'Unit list should not have any units listed');
      CheckFalse(CoverageConfiguration.UseApiDebug, 'API Logging is turned on.');
      CheckFalse(CoverageConfiguration.IsComplete(Reason), 'Parameters shoujld not be complete');
      CheckEquals(Reason, 'No map file was specified', 'Map file should not have been specified');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestEnableApiLogging;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEnableAPILogging));
  CoverageConfiguration.ParseCommandLine;
  CheckTrue(CoverageConfiguration.UseApiDebug, 'API Logging was not turned on.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestEnableFileLoggingDefaultFile;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEnableFileLogDefault));
  CoverageConfiguration.ParseCommandLine;
  CheckEquals(CoverageConfiguration.GetDebugLogFile, I_CoverageConfiguration.DEFULT_DEBUG_LOG_FILENAME, 'Different debug logging file specified');
end;


//==============================================================================
procedure TCoverageConfigurationTest.TestEnableFileLoggingSpecifiedFile;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEnableFileLogSpecified));
  CoverageConfiguration.ParseCommandLine;
  CheckEquals(CoverageConfiguration.GetDebugLogFile, cEnableFileLogSpecified[1], 'Different debug logging file specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestOutputDirectoryError;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cOutputDirError));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected parameter for output directory', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestOutputDirectory;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cOutputDir));
  CoverageConfiguration.ParseCommandLine;
  CheckEquals(CoverageConfiguration.GetOutputDir, cOutputDir[1], 'Different output directory specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFileError;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSourcePathFileNameParam));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected parameter for source path file name', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFileNoExistingFile;
var
  CmdParams : array of string;
  CoverageConfiguration: ICoverageConfiguration;
begin
  SetLength(CmdParams, 2);
  CmdParams[Low(CmdParams)] := cSourcePathFileNameParam[0];
  CmdParams[Low(CmdParams) + 1] := RandomFileName;

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    //on E: EConfigurationException do
    //begin
    //  Check(True, 'Expected ConfigurationException detected');
    //  CheckEquals(E.Message, 'Expected parameter for source path file name', 'Error message mis-match');
    //end;
    on E: EInOutError do
    begin
      Check(True, 'Expected file missing detected');
      CheckEquals(E.Message, 'I/O error 103', 'Unexpected error message');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFileFakeDir;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  DirListFileName       : string;
  FakeDirName           : string;
  DirList               : TStrings;
begin
  DirList := nil;
  try
    DirList := TStringList.Create;
    DirListFileName := RandomFileName();
    try
      repeat
        FakeDirName := IncludeTrailingPathDelimiter(GetCurrentDir()) + RandomFileName();
      until not DirectoryExists(FakeDirName);

      DirList.Add(FakeDirName);
      DirList.SaveToFile(DirListFileName);

      SetLength(CmdParams, 2);
      CmdParams[low(CmdParams)]     := cSourcePathFileNameParam[0];
      CmdParams[Low(CmdParams) + 1] := DirListFileName;

      CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
      CoverageConfiguration.ParseCommandLine;

      CheckEquals(CoverageConfiguration.GetSourcePaths.Count, DirList.Count - 1, 'None existant directory listed');
      CheckEquals(CoverageConfiguration.GetSourcePaths.IndexOf(FakeDirName), -1, 'Fake directory exists in the directory list');

    finally
      if FileExists(DirListFileName) then
        CheckTrue(SysUtils.DeleteFile(DirListFileName), 'Unable to deleted source path directory file with fake directories');
    end;
  finally
    DirList.Free;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFile;

{}procedure GetDirectories(const ADirPath: string; const ADirLst: TStrings);
{}var
{}  SearchRec : TSearchRec;
{}begin
{}  if SysUtils.FindFirst(ADirPath + PathDelim + '*.*', faDirectory, SearchRec) = 0 then
{}  try
{}    repeat
{}      if ((SearchRec.Attr and faDirectory) = faDirectory) and
{}         (SearchRec.Name <> '.') and
{}         (SearchRec.Name <> '..') then
{}      begin
{}        ADirLst.Add(IncludeTrailingPathDelimiter(ADirPath) + SearchRec.Name);
{}        GetDirectories(IncludeTrailingPathDelimiter(ADirPath) + SearchRec.Name, ADirLst);
{}      end;
{}    until SysUtils.FindNext(SearchRec) <> 0;
{}  finally
{}    SysUtils.FindClose(SearchRec)
{}  end;
{}end;

var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  DirListFileName       : string;
  DirList               : TStrings;
begin
  DirList := nil;
  try
    DirList := TStringList.Create;
    GetDirectories(ExpandUNCFileName(IncludeTrailingPathDelimiter(GetCurrentDir()) + '..'), DirList);

    DirListFileName := RandomFileName();
    try
      DirList.SaveToFile(DirListFileName);

      SetLength(CmdParams, 2);
      CmdParams[low(CmdParams)]     := cSourcePathFileNameParam[0];
      CmdParams[Low(CmdParams) + 1] := DirListFileName;

      CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
      CoverageConfiguration.ParseCommandLine;

      CheckEquals(CoverageConfiguration.GetSourcePaths.Count, DirList.Count, 'Incorrect number of directories listed');

    finally
      if FileExists(DirListFileName) then
        CheckTrue(SysUtils.DeleteFile(DirListFileName), 'Unable to deleted source path directory file');
    end;
  finally
    DirList.Free;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathError;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSourcePathEmptyParam));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected at least one source path', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFakeDir;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  FakeDirName           : string;
begin
  repeat
    FakeDirName := IncludeTrailingPathDelimiter(GetCurrentDir()) + RandomFileName();
  until not DirectoryExists(FakeDirName);

  SetLength(CmdParams, 2);
  CmdParams[low(CmdParams)]     := cSourcePathEmptyParam[0];
  CmdParams[Low(CmdParams) + 1] := FakeDirName;

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected at least one source path', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathSingleDir;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
begin
  SetLength(CmdParams, 2);
  CmdParams[low(CmdParams)]     := cSourcePathEmptyParam[0];
  CmdParams[Low(CmdParams) + 1] := IncludeTrailingPathDelimiter(GetCurrentDir()) + '..';

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CoverageConfiguration.GetSourcePaths.Count, 1, 'Incorrect number of directories listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathMultipleDir;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
begin
  SetLength(CmdParams, 3);
  CmdParams[low(CmdParams)]     := cSourcePathEmptyParam[0];
  CmdParams[Low(CmdParams) + 1] := IncludeTrailingPathDelimiter(GetCurrentDir()) + '..';
  CmdParams[Low(CmdParams) + 2] := IncludeTrailingPathDelimiter(GetCurrentDir()) + '..';

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CoverageConfiguration.GetSourcePaths.Count, 2, 'Incorrect number of directories listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourceDirectoryError;
var
  CoverageConfiguration : ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSourceDirParamEmpty));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected parameter for source directory', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourceDirectory;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSourceDirParam));
  CoverageConfiguration.ParseCommandLine;
  CheckEquals(CoverageConfiguration.GetSourceDir, cSourceDirParam[1], 'Different output directory specified');
  CheckEquals(1, CoverageConfiguration.GetSourcePaths.Count, 'Different source path count');
  CheckEquals(cSourceDirParam[1], CoverageConfiguration.GetSourcePaths.Strings[0], 'Different source path directory');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterEmpty;
var
  CoverageConfiguration : ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cExecutableParameterEmpty));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected at least one executable parameter', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterSingle;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cExecutableParameterSingle));
  CoverageConfiguration.ParseCommandLine;
  CheckEquals(CoverageConfiguration.GetApplicationParameters, cExecutableParameterSingle[1], 'Different parameter specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterMultiple;
var
  CoverageConfiguration: ICoverageConfiguration;
  lp : Integer;
  ExpectedParams : string;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cExecutableParameterMultiple));
  CoverageConfiguration.ParseCommandLine;

  ExpectedParams := '';
  for lp := Low(cExecutableParameterMultiple) + 1 to High(cExecutableParameterMultiple) do
  begin
    ExpectedParams := ExpectedParams + ' ' + cExecutableParameterMultiple[lp];
  end;
  ExpectedParams := TrimLeft(ExpectedParams);

  CheckEquals(CoverageConfiguration.GetApplicationParameters, ExpectedParams, 'Different parameters specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterUnescape;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cExecutableParameterEscaping));
  CoverageConfiguration.ParseCommandLine;
  CheckEquals(CoverageConfiguration.GetApplicationParameters, '^some_parameter', 'Escaped parameters difference occurred');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFileError;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cUnitFileNameParam));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected parameter for units file name', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFileNoExistingFile;
var
  CmdParams : array of string;
  CoverageConfiguration: ICoverageConfiguration;
begin
  SetLength(CmdParams, 2);
  CmdParams[Low(CmdParams)]     := cUnitFileNameParam[0];
  CmdParams[Low(CmdParams) + 1] := RandomFileName();

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    //on E: EConfigurationException do
    //begin
    //  Check(True, 'Expected ConfigurationException detected');
    //  CheckEquals(E.Message, 'Expected parameter for source path file name', 'Error message mis-match');
    //end;
    on E: EInOutError do
    begin
      Check(True, 'Expected file missing detected');
      CheckEquals(E.Message, 'I/O error 103', 'Unexpected error message');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFile;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  FileListFileName      : string;
  FileNameList          : TStrings;
  lp                    : Integer;
  FileName              : string;
begin
  FileNameList := nil;
  try
    FileNameList := TStringList.Create;

    for lp := 0 to Random(20) do
    begin
      repeat
        FileName := RandomFileName();
      until FileNameList.IndexOf(FileName) = -1;

      FileNameList.Add(FileName);
    end;

    FileListFileName := RandomFileName();
    try
      FileNameList.SaveToFile(FileListFileName);

      SetLength(CmdParams, 2);
      CmdParams[low(CmdParams)]     := cUnitFileNameParam[0];
      CmdParams[Low(CmdParams) + 1] := FileListFileName;

      CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
      CoverageConfiguration.ParseCommandLine;

      CheckEquals(CoverageConfiguration.GetUnits.Count, FileNameList.Count, 'Incorrect number of units listed');

    finally
      if FileExists(FileListFileName) then
        CheckTrue(SysUtils.DeleteFile(FileListFileName), 'Unable to deleted unit file');
    end;
  finally
    FileNameList.Free;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFileStrippingOfPathAndExtensions;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  FileListFileName      : string;
  FileNameList          : TStringList;
  FileNameListWithExt   : TStrings;
  lp                    : Integer;
begin
  FileNameList := nil;
  FileNameListWithExt := nil;
  try
    FileNameList := TStringList.Create;
    FileNameList.Sorted := True;
    FileNameList.Duplicates := dupIgnore;

    FileNameListWithExt := TStringList.Create;

    for lp := 0 to Random(20) do
      FileNameList.Add(RandomFileName());

    for lp := 0 to Pred(FileNameList.Count) do
      FileNameListWithExt.Add(IncludeTrailingPathDelimiter(GetCurrentDir) + FileNameList.Strings[lp] + '.someExt');

    FileListFileName := RandomFileName();
    try
      FileNameListWithExt.SaveToFile(FileListFileName);

      SetLength(CmdParams, 2);
      CmdParams[low(CmdParams)]     := cUnitFileNameParam[0];
      CmdParams[Low(CmdParams) + 1] := FileListFileName;

      CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
      CoverageConfiguration.ParseCommandLine;

      CheckEquals(CoverageConfiguration.GetUnits.Count, FileNameList.Count, 'Incorrect number of units listed');

      for lp := 0 to Pred(FileNameList.Count) do
      begin
        CheckNotEquals(-1, CoverageConfiguration.GetUnits.IndexOf(FileNameList.Strings[lp]), 'Missing unit name');
      end;

    finally
      if FileExists(FileListFileName) then
        CheckTrue(SysUtils.DeleteFile(FileListFileName), 'Unable to deleted unit file');
    end;
  finally
    FileNameList.Free;
    FileNameListWithExt.Free;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitError;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cUnitParam));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected at least one unit', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitSingle;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
begin
  SetLength(CmdParams, 2);
  CmdParams[low(CmdParams)]     := cUnitParam[0];
  CmdParams[Low(CmdParams) + 1] := RandomFileName();

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CoverageConfiguration.GetUnits.Count, 1, 'Incorrect number of units listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitMultiple;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
begin
  SetLength(CmdParams, 3);
  CmdParams[low(CmdParams)]     := cUnitParam[0];
  CmdParams[Low(CmdParams) + 1] := RandomFileName();
  CmdParams[Low(CmdParams) + 2] := RandomFileName();

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CoverageConfiguration.GetUnits.Count, 2, 'Incorrect number of units listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitStrippingOfPathAndExtensions;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  UnitNames             : array of string;
  lp                    : Integer;
  lpSearch              : Integer;
  FileName              : string;
  IsFileNameUnique                    : Boolean;
begin
  SetLength(UnitNames, Random(10) + 5);
  for lp := Low(UnitNames) to High(UnitNames) do
  begin
    IsFileNameUnique := True;
    repeat
      FileName := RandomFileName();
      for lpSearch := Low(UnitNames) to lp do
        IsFileNameUnique := IsFileNameUnique and (UnitNames[lpSearch] <> FileName);
    until IsFileNameUnique;

    UnitNames[lp] := FileName;
  end;

  SetLength(CmdParams, Length(UnitNames) + 1);
  CmdParams[low(CmdParams)]     := cUnitParam[0];

  for lp := Low(UnitNames) to High(UnitNames) do
  begin
    CmdParams[lp + 1] := UnitNames[lp];
    if lp mod 4 = 0 then
      CmdParams[lp + 1] := IncludeTrailingPathDelimiter(GetCurrentDir) + CmdParams[lp + 1];

    if lp mod 3 = 0 then
      CmdParams[lp + 1] := CmdParams[lp + 1] + '.someExt';
  end;

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CoverageConfiguration.GetUnits.Count, Length(UnitNames), 'Incorrect number of units listed');

  for lp := (Low(UnitNames) + 1) to High(UnitNames) do
  begin
    //CheckNotEquals(-1, CoverageConfiguration.GetUnits.IndexOf(UnitNames[lp]), 'Missing unit name');
    CheckNotEquals(-1, CoverageConfiguration.GetUnits.IndexOf(ChangeFileExt(CmdParams[lp], '')), 'Missing unit name');
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestMapFileError;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cMapFileParam));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected parameter for mapfile', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestMapFile;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  Reason                : string;
begin
  SetLength(CmdParams, 2);
  CmdParams[low(CmdParams)]     := cMapFileParam[0];
  CmdParams[Low(CmdParams) + 1] := ParamStr(0);

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CmdParams[Low(CmdParams) + 1], CoverageConfiguration.GetMapFileName, 'Incorrect map file listed');

  CheckFalse(CoverageConfiguration.isComplete(Reason), 'Configuration should not be complete based on these parameters');

  CheckEquals('No executable was specified', Reason, 'Incorrect reason returned.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestMapFileNoExistingFile;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  Reason                : string;
  ExpectedReason        : string;
begin
  SetLength(CmdParams, 2);
  CmdParams[low(CmdParams)]     := cMapFileParam[0];
  CmdParams[Low(CmdParams) + 1] := RandomFileName();

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CmdParams[Low(CmdParams) + 1], CoverageConfiguration.GetMapFileName, 'Incorrect map file listed');

  CheckFalse(CoverageConfiguration.isComplete(Reason), 'Configuration should not be complete based on these parameters');

  ExpectedReason := 'The map file ' + CmdParams[Low(CmdParams) + 1] + ' does not exist. Current dir is ' + GetCurrentDir();
  CheckEquals(ExpectedReason, Reason, 'Incorrect reason returned.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableError;
var
  CoverageConfiguration: ICoverageConfiguration;
begin
  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cExecutableParam));
  try
    CoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals(E.Message, 'Expected parameter for executable', 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutable;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  Reason                : string;
  ExpectedReason        : string;
  MapFileName           : string;
begin
  SetLength(CmdParams, 2);
  CmdParams[low(CmdParams)]     := cExecutableParam[0];
  CmdParams[Low(CmdParams) + 1] := ParamStr(0);

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CmdParams[Low(CmdParams) + 1], CoverageConfiguration.GetExeFileName, 'Incorrect executable listed');

  MapFileName := ChangeFileExt(CmdParams[Low(CmdParams) + 1], '.map');

  CheckEquals(MapFileName, CoverageConfiguration.GetMapFileName, 'Incorrect default map file listed');

  if FileExists(MapFileName) then
  begin
    CheckTrue(CoverageConfiguration.isComplete(Reason), 'Configuration should not be complete based on these parameters');
    CheckEquals('', Reason, 'Incorrect reason returned.');
  end
  else
  begin
    CheckFalse(CoverageConfiguration.isComplete(Reason), 'Configuration should not be complete based on these parameters');
    ExpectedReason := 'The map file ' + MapFileName + ' does not exist. Current dir is ' + GetCurrentDir();
    CheckEquals(ExpectedReason, Reason, 'Incorrect reason returned.');
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableNoExistingFile;
var
  CoverageConfiguration : ICoverageConfiguration;
  CmdParams             : array of string;
  Reason                : string;
  ExpectedReason        : string;
begin
  SetLength(CmdParams, 4);
  CmdParams[low(CmdParams)]     := cExecutableParam[0];
  CmdParams[Low(CmdParams) + 1] := RandomFileName();
  // Force a valid map file...
  CmdParams[low(CmdParams) + 2] := cMapFileParam[0];
  CmdParams[Low(CmdParams) + 3] := ParamStr(0);

  CoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(CmdParams));
  CoverageConfiguration.ParseCommandLine;

  CheckEquals(CmdParams[Low(CmdParams) + 1], CoverageConfiguration.GetExeFileName, 'Incorrect executable listed');

  CheckFalse(CoverageConfiguration.isComplete(Reason), 'Configuration should not be complete based on these parameters');
  ExpectedReason := 'The executable file ' + CmdParams[Low(CmdParams) + 1] + ' does not exist. Current dir is ' + GetCurrentDir();
  CheckEquals(ExpectedReason, Reason, 'Incorrect reason returned.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestMisc;
begin

end;

//==============================================================================
initialization
  RegisterTest(TCoverageConfigurationTest.Suite);

//==============================================================================
//==============================================================================
//==============================================================================
end.
//==============================================================================

