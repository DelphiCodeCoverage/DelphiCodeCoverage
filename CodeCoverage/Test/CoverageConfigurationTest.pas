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
  published
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

    procedure TestExcludingFileExtension;
    procedure TestExcludingFileExtensionMultipleToggling;
    procedure TestExcludingFileExtensionFromUnitFile;

    procedure TestIncludingFileExtension;
    procedure TestIncludingFileExtensionMultipleToggling;
    procedure TestIncludingFileExtensionFromUnitFile;

    procedure TestFileExtensionFromUnitFileToggling;

    procedure TestExcludeSourceMask;
    procedure TestDProj;
  end;

implementation

uses
  {$IFDEF SUPPORTS_INLINE}Windows,{$ENDIF}
  MockCommandLineProvider, IOUtils, StrUtils;

const
  cINVALID_PARAMETER                : array [0 .. 0] of string = ('-frank');
  cENABLE_API_LOGGING               : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_LOGGING_WINAPI);
  cENABLE_FILE_LOG_DEFAULT          : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_LOGGING_TEXT);
  cENABLE_LOG_FILE_SPECIFIED        : array [0 .. 1] of string = (I_CoverageConfiguration.cPARAMETER_LOGGING_TEXT, 'some-debug-log-file.txt');
  cOUTPUT_DIRECTORY_ERROR           : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_OUTPUT_DIRECTORY);
  cOUTPUT_DIRECTORY                 : array [0 .. 1] of string = (I_CoverageConfiguration.cPARAMETER_OUTPUT_DIRECTORY, 'some-output-dir');
  cSOURCE_PATH_FILENAME_PARAMETER   : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE);
  cSOURCE_PATH_EMPTY_PARAMETER      : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS);
  cSOURCE_DIRECTORY_PARAMETER_EMPTY : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_SOURCE_DIRECTORY);
  cSOURCE_DIRECTORY_PARAMETER       : array [0 .. 1] of string = (I_CoverageConfiguration.cPARAMETER_SOURCE_DIRECTORY, 'some_parameter');
  cEXECUTABLE_PARAMETER_EMPTY       : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER);
  cEXECUTABLE_PARAMETER_SINGLE      : array [0 .. 1] of string = (I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER, 'some_parameter');
  cEXECUTABLE_PARAMETER_MULTIPLE    : array [0 .. 2] of string = (I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER, 'some_parameter', 'another_parameter');
  cEXECUTABLE_PARAMETER_ESCAPING    : array [0 .. 1] of string = (I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER, '^^some_parameter');
  cUNIT_FILENAME_PARAMETER          : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_UNIT_FILE);
  cUNIT_PARAMETER                   : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_UNIT);
  cMAP_FILE_PARAMETER               : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_MAP_FILE);
  cEXECUTABLE_PARAMETER             : array [0 .. 0] of string = (I_CoverageConfiguration.cPARAMETER_EXECUTABLE);
  cSOME_EXTENSION = '.someExt';
  cEXCLUDE_FILES_PREFIX = 'exclude';
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
  LCoverageConfiguration: ICoverageConfiguration;
  LReason : string;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create([]));

  CheckEquals('', LCoverageConfiguration.GetApplicationParameters, 'Application Parameters set');
  CheckEquals('', LCoverageConfiguration.GetExeFileName, 'Executable file name should not be set');
  CheckEquals('', LCoverageConfiguration.GetMapFileName, 'Map file name should not be set');
  CheckEquals('', LCoverageConfiguration.GetOutputDir,   'Report output directory should not be set');
  CheckEquals('', LCoverageConfiguration.GetSourceDir,   'Source directory should not be set');
  CheckEquals('', LCoverageConfiguration.GetDebugLogFile, 'Debug logging file name should not be set');
  CheckEquals(0, LCoverageConfiguration.GetSourcePaths.Count, 'Source paths should not have directories listed');
  CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'Unit list should not have any units listed');
  CheckFalse(LCoverageConfiguration.UseApiDebug, 'API Logging is turned on.');
  CheckFalse(LCoverageConfiguration.IsComplete(LReason), 'Parameters shoujld not be complete');
  CheckEquals('No map file was specified', LReason, 'Map file should not have been specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestNoParameters;
var
  LCoverageConfiguration: ICoverageConfiguration;
  LReason : string;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cINVALID_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
    Check(False, 'Command line parsing passed');
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Unexpected switch:' + cINVALID_PARAMETER[0], E.Message, 'Error message mis-match');

      CheckEquals('', LCoverageConfiguration.GetApplicationParameters, 'Application Parameters set');
      CheckEquals('', LCoverageConfiguration.GetExeFileName, 'Executable file name should not be set');
      CheckEquals('', LCoverageConfiguration.GetMapFileName, 'Map file name should not be set');
      CheckEquals('', LCoverageConfiguration.GetOutputDir,   'Report output directory should not be set');
      CheckEquals('', LCoverageConfiguration.GetSourceDir,   'Source directory should not be set');
      CheckEquals('', LCoverageConfiguration.GetDebugLogFile, 'Debug logging file name should not be set');
      CheckEquals(0, LCoverageConfiguration.GetSourcePaths.Count, 'Source paths should not have directories listed');
      CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'Unit list should not have any units listed');
      CheckFalse(LCoverageConfiguration.UseApiDebug, 'API Logging is turned on.');
      CheckFalse(LCoverageConfiguration.IsComplete(LReason), 'Parameters shoujld not be complete');
      CheckEquals('No map file was specified', LReason, 'Map file should not have been specified');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestInvalidParameter;
var
  LCoverageConfiguration: ICoverageConfiguration;
  LReason : string;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cINVALID_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Unexpected switch:' + cINVALID_PARAMETER[0], E.Message, 'Error message mis-match');

      CheckEquals('', LCoverageConfiguration.GetApplicationParameters, 'Application Parameters set');
      CheckEquals('', LCoverageConfiguration.GetExeFileName, 'Executable file name should not be set');
      CheckEquals('', LCoverageConfiguration.GetMapFileName, 'Map file name should not be set');
      CheckEquals('', LCoverageConfiguration.GetOutputDir,   'Report output directory should not be set');
      CheckEquals('', LCoverageConfiguration.GetSourceDir,   'Source directory should not be set');
      CheckEquals('', LCoverageConfiguration.GetDebugLogFile, 'Debug logging file name should not be set');
      CheckEquals(0, LCoverageConfiguration.GetSourcePaths.Count, 0, 'Source paths should not have directories listed');
      CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 0, 'Unit list should not have any units listed');
      CheckFalse(LCoverageConfiguration.UseApiDebug, 'API Logging is turned on.');
      CheckFalse(LCoverageConfiguration.IsComplete(LReason), 'Parameters shoujld not be complete');
      CheckEquals('No map file was specified', LReason, 'Map file should not have been specified');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestEnableApiLogging;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cENABLE_API_LOGGING));
  LCoverageConfiguration.ParseCommandLine;
  CheckTrue(LCoverageConfiguration.UseApiDebug, 'API Logging was not turned on.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestEnableFileLoggingDefaultFile;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cENABLE_FILE_LOG_DEFAULT));
  LCoverageConfiguration.ParseCommandLine;
  CheckEquals(I_CoverageConfiguration.cDEFULT_DEBUG_LOG_FILENAME, LCoverageConfiguration.GetDebugLogFile, 'Different debug logging file specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestEnableFileLoggingSpecifiedFile;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cENABLE_LOG_FILE_SPECIFIED));
  LCoverageConfiguration.ParseCommandLine;
  CheckEquals(cENABLE_LOG_FILE_SPECIFIED[1], LCoverageConfiguration.GetDebugLogFile, 'Different debug logging file specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestOutputDirectoryError;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cOUTPUT_DIRECTORY_ERROR));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals('Expected parameter for output directory', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestOutputDirectory;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cOUTPUT_DIRECTORY));
  LCoverageConfiguration.ParseCommandLine;
  CheckEquals(cOUTPUT_DIRECTORY[1], LCoverageConfiguration.GetOutputDir, 'Different output directory specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFileError;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSOURCE_PATH_FILENAME_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals('Expected parameter for source path file name', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFileNoExistingFile;
var
  LCmdParams : array of string;
  LCoverageConfiguration: ICoverageConfiguration;
begin
  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)] := I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE;
  LCmdParams[Low(LCmdParams) + 1] := RandomFileName;

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EInOutError do
    begin
      Check(True, 'Expected file missing detected');
      CheckEquals('I/O error 103', E.Message, 'Unexpected error message');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFileFakeDir;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LDirListFileName       : string;
  LFakeDirName           : string;
  LDirList               : TStrings;
begin
  LDirList := nil;
  try
    LDirList := TStringList.Create;
    LDirListFileName := RandomFileName();
    try
      repeat
        LFakeDirName := IncludeTrailingPathDelimiter(GetCurrentDir()) + RandomFileName();
      until not DirectoryExists(LFakeDirName);

      LDirList.Add(LFakeDirName);
      LDirList.SaveToFile(LDirListFileName);

      SetLength(LCmdParams, 2);
      LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE;
      LCmdParams[Low(LCmdParams) + 1] := LDirListFileName;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LDirList.Count - 1, LCoverageConfiguration.GetSourcePaths.Count, 'None existant directory listed');
      CheckEquals(-1, LCoverageConfiguration.GetSourcePaths.IndexOf(LFakeDirName), 'Fake directory exists in the directory list');

    finally
      if FileExists(LDirListFileName) then
        CheckTrue(SysUtils.DeleteFile(LDirListFileName), 'Unable to deleted source path directory file with fake directories');
    end;
  finally
    FreeAndNil(LDirList);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFile;

{}procedure GetDirectories(const ADirPath: string; const ADirLst: TStrings);
{}var
{}  LSearchRec : TSearchRec;
{}begin
{}  if SysUtils.FindFirst(ADirPath + PathDelim + '*.*', faDirectory, LSearchRec) = 0 then
{}  try
{}    repeat
{}      if ((LSearchRec.Attr and faDirectory) = faDirectory) and
{}         (LSearchRec.Name <> '.') and
{}         (LSearchRec.Name <> '..') then
{}      begin
{}        ADirLst.Add(IncludeTrailingPathDelimiter(ADirPath) + LSearchRec.Name);
{}        GetDirectories(IncludeTrailingPathDelimiter(ADirPath) + LSearchRec.Name, ADirLst);
{}      end;
{}    until SysUtils.FindNext(LSearchRec) <> 0;
{}  finally
{}    SysUtils.FindClose(LSearchRec)
{}  end;
{}end;

var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LDirList               : TStrings;
  LDirListFileName       : string;
begin
  LDirList := nil;
  try
    LDirList := TStringList.Create;
    GetDirectories(ExpandUNCFileName(IncludeTrailingPathDelimiter(GetCurrentDir()) + '..'), LDirList);

    LDirListFileName := RandomFileName();
    try
      LDirList.SaveToFile(LDirListFileName);

      SetLength(LCmdParams, 2);
      LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE;
      LCmdParams[Low(LCmdParams) + 1] := LDirListFileName;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LDirList.Count, LCoverageConfiguration.GetSourcePaths.Count, 'Incorrect number of directories listed');

    finally
      if FileExists(LDirListFileName) then
        CheckTrue(SysUtils.DeleteFile(LDirListFileName), 'Unable to deleted source path directory file');
    end;
  finally
    FreeAndNil(LDirList);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathError;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSOURCE_PATH_EMPTY_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Expected at least one source path', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathFakeDir;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFakeDirName           : string;
begin
  repeat
    LFakeDirName := IncludeTrailingPathDelimiter(GetCurrentDir()) + RandomFileName();
  until not DirectoryExists(LFakeDirName);

  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS;
  LCmdParams[Low(LCmdParams) + 1] := LFakeDirName;

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Expected at least one source path', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathSingleDir;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
begin
  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)]     := cSOURCE_PATH_EMPTY_PARAMETER[0];
  LCmdParams[Low(LCmdParams) + 1] := IncludeTrailingPathDelimiter(GetCurrentDir()) + '..';

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(1, LCoverageConfiguration.GetSourcePaths.Count, 'Incorrect number of directories listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourcePathMultipleDir;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
begin
  SetLength(LCmdParams, 3);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS;
  LCmdParams[Low(LCmdParams) + 1] := IncludeTrailingPathDelimiter(GetCurrentDir()) + '..';
  LCmdParams[Low(LCmdParams) + 2] := IncludeTrailingPathDelimiter(GetCurrentDir()) + '..';

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(2, LCoverageConfiguration.GetSourcePaths.Count, 'Incorrect number of directories listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourceDirectoryError;
var
  LCoverageConfiguration : ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSOURCE_DIRECTORY_PARAMETER_EMPTY));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      Check(True, 'Expected ConfigurationException detected');
      CheckEquals('Expected parameter for source directory', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestSourceDirectory;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cSOURCE_DIRECTORY_PARAMETER));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(cSOURCE_DIRECTORY_PARAMETER[1], LCoverageConfiguration.GetSourceDir, 'Different output directory specified');
  CheckEquals(1, LCoverageConfiguration.GetSourcePaths.Count, 'Different source path count');
  CheckEquals(cSOURCE_DIRECTORY_PARAMETER[1], LCoverageConfiguration.GetSourcePaths.Strings[0], 'Different source path directory');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterEmpty;
var
  LCoverageConfiguration : ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEXECUTABLE_PARAMETER_EMPTY));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Expected at least one executable parameter', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterSingle;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEXECUTABLE_PARAMETER_SINGLE));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(cEXECUTABLE_PARAMETER_SINGLE[1], LCoverageConfiguration.GetApplicationParameters, 'Different parameter specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterMultiple;
var
  LCoverageConfiguration: ICoverageConfiguration;
  lp : Integer;
  LExpectedParams : string;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEXECUTABLE_PARAMETER_MULTIPLE));
  LCoverageConfiguration.ParseCommandLine;

  LExpectedParams := '';
  for lp := Low(cEXECUTABLE_PARAMETER_MULTIPLE) + 1 to High(cEXECUTABLE_PARAMETER_MULTIPLE) do
    LExpectedParams := LExpectedParams + ' ' + cEXECUTABLE_PARAMETER_MULTIPLE[lp];

  LExpectedParams := TrimLeft(LExpectedParams);

  CheckEquals(LExpectedParams, LCoverageConfiguration.GetApplicationParameters, 'Different parameters specified');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableParameterUnescape;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEXECUTABLE_PARAMETER_ESCAPING));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals('^some_parameter', LCoverageConfiguration.GetApplicationParameters, 'Escaped parameters difference occurred');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFileError;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cUNIT_FILENAME_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Expected parameter for units file name', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFileNoExistingFile;
var
  LCmdParams : array of string;
  LCoverageConfiguration: ICoverageConfiguration;
begin
  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_UNIT_FILE;
  LCmdParams[Low(LCmdParams) + 1] := RandomFileName();

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EInOutError do
    begin
      CheckEquals('I/O error 103', E.Message, 'Unexpected error message');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFile;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileListFileName      : string;
  LFileNameList          : TStringList;
  LNumOfFiles            : Integer;
begin
  LFileNameList := nil;
  try
    LFileNameList := TStringList.Create;
    LFileNameList.Sorted := True;
    LFileNameList.Duplicates := dupIgnore;

    LNumOfFiles := Random(20) + 10;

    while LFileNameList.Count < LNumOfFiles do
      LFileNameList.Add(RandomFileName());

    repeat
      LFileListFileName := RandomFileName();
    until not FileExists(LFileListFileName);

    try
      LFileNameList.SaveToFile(LFileListFileName);

      SetLength(LCmdParams, 2);
      LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_UNIT_FILE;
      LCmdParams[Low(LCmdParams) + 1] := LFileListFileName;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LFileNameList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

    finally
      if FileExists(LFileListFileName) then
        CheckTrue(SysUtils.DeleteFile(LFileListFileName), 'Unable to deleted unit file');
    end;
  finally
    FreeAndNil(LFileNameList);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitFileStrippingOfPathAndExtensions;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileListFileName      : string;
  LFileNameList          : TStringList;
  LFileNameListWithExt   : TStrings;
  LIdx                   : Integer;
  lp                     : Integer;
  LNumOfFiles            : Integer;
begin
  LFileNameList := nil;
  LFileNameListWithExt := nil;
  try
    LFileNameList := TStringList.Create;
    LFileNameList.Sorted := True;
    LFileNameList.Duplicates := dupIgnore;

    LFileNameListWithExt := TStringList.Create;

    LNumOfFiles := Random(20) + 10;
    while LFileNameList.Count < LNumOfFiles do
      LFileNameList.Add(RandomFileName());

    for lp := 0 to Pred(LFileNameList.Count) do
      LFileNameListWithExt.Add(IncludeTrailingPathDelimiter(GetCurrentDir) + LFileNameList.Strings[lp] + cSOME_EXTENSION);

    repeat
      LFileListFileName := RandomFileName();
    until not FileExists(LFileListFileName);

    try
      LFileNameListWithExt.SaveToFile(LFileListFileName);

      SetLength(LCmdParams, 2);
      LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_UNIT_FILE;
      LCmdParams[Low(LCmdParams) + 1] := LFileListFileName;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LFileNameList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

      for lp := 0 to Pred(LFileNameList.Count) do
        CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LFileNameList.Strings[lp]), 'Missing unit name');

      for lp := Pred(LFileNameList.Count) downto 0 do
      begin
        LIdx := LCoverageConfiguration.GetUnits.IndexOf(LFileNameList.Strings[lp]);
        if (LIdx <> -1) then
        begin
          LCoverageConfiguration.GetUnits.Delete(LIdx);
          LFileNameList.Delete(lp);
        end;
      end;

      CheckEquals(0, LFileNameList.Count, 'Expecting more units to be present');
      CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'More units than expected are present');
    finally
      if FileExists(LFileListFileName) then
        CheckTrue(SysUtils.DeleteFile(LFileListFileName), 'Unable to deleted unit file');
    end;
  finally
    FreeAndNil(LFileNameList);
    FreeAndNil(LFileNameListWithExt);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitError;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cUNIT_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Expected at least one unit', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitSingle;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
begin
  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_UNIT;
  LCmdParams[Low(LCmdParams) + 1] := RandomFileName();

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(1, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitMultiple;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
begin
  SetLength(LCmdParams, 3);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_UNIT;
  LCmdParams[Low(LCmdParams) + 1] := RandomFileName();
  repeat
    LCmdParams[Low(LCmdParams) + 2] := RandomFileName();
  until LCmdParams[Low(LCmdParams) + 2] <> LCmdParams[Low(LCmdParams) + 1];

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(2, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestUnitStrippingOfPathAndExtensions;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LIdx                   : Integer;
  lp                     : Integer;
  LNumOfFiles            : Integer;
  LUnitFileNames         : TStringList;
begin
  LUnitFileNames := nil;
  try
    LUnitFileNames := TStringList.Create;
    LUnitFileNames.Sorted := True;
    LUnitFileNames.Duplicates := dupIgnore;

    LNumOfFiles := Random(10) + 5;

    while LUnitFileNames.Count < LNumOfFiles do
      LUnitFileNames.Add(RandomFileName());

    LUnitFileNames.Sorted := False;

    SetLength(LCmdParams, LUnitFileNames.Count + 1);
    LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_UNIT;

    for lp := 0 to Pred(LUnitFileNames.Count) do
    begin
      if lp mod 4 = 0 then
        LUnitFileNames.Strings[lp] := IncludeTrailingPathDelimiter(GetCurrentDir) + LUnitFileNames.Strings[lp];

      LCmdParams[Low(LCmdParams) + lp + 1] := LUnitFileNames.Strings[lp];

      if lp mod 3 = 0 then
        LCmdParams[Low(LCmdParams) + lp + 1] := LCmdParams[Low(LCmdParams) + lp + 1] + cSOME_EXTENSION;
    end;

    LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
    LCoverageConfiguration.ParseCommandLine;

    CheckEquals(LUnitFileNames.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

    for lp := 0 to Pred(LUnitFileNames.Count) do
      CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LUnitFileNames.Strings[lp]), 'Missing unit name');

    for lp := Pred(LUnitFileNames.Count) downto 0 do
    begin
      LIdx := LCoverageConfiguration.GetUnits.IndexOf(LUnitFileNames.Strings[lp]);
      if (LIdx <> -1) then
      begin
        LCoverageConfiguration.GetUnits.Delete(LIdx);
        LUnitFileNames.Delete(lp);
      end;
    end;

    CheckEquals(0, LUnitFileNames.Count, 'Expecting more units to be present');
    CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'More units than expected are present');
  finally
    FreeAndNil(LUnitFileNames);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestMapFileError;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cMAP_FILE_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Expected parameter for mapfile', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestMapFile;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LReason                : string;
begin
  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_MAP_FILE;
  LCmdParams[Low(LCmdParams) + 1] := ParamStr(0);

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(LCmdParams[Low(LCmdParams) + 1], LCoverageConfiguration.GetMapFileName, 'Incorrect map file listed');

  CheckFalse(LCoverageConfiguration.isComplete(LReason), 'Configuration should not be complete based on these parameters');

  CheckEquals(LReason, 'No executable was specified', 'Incorrect reason returned.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestMapFileNoExistingFile;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LReason                : string;
  LExpectedReason        : string;
begin
  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_MAP_FILE;
  LCmdParams[Low(LCmdParams) + 1] := RandomFileName();

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(LCmdParams[Low(LCmdParams) + 1], LCoverageConfiguration.GetMapFileName, 'Incorrect map file listed');

  CheckFalse(LCoverageConfiguration.isComplete(LReason), 'Configuration should not be complete based on these parameters');

  LExpectedReason := 'The map file ' + LCmdParams[Low(LCmdParams) + 1] + ' does not exist. Current dir is ' + GetCurrentDir();
  CheckEquals(LReason, LExpectedReason, 'Incorrect reason returned.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableError;
var
  LCoverageConfiguration: ICoverageConfiguration;
begin
  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(cEXECUTABLE_PARAMETER));
  try
    LCoverageConfiguration.ParseCommandLine;
  except
    on E: EConfigurationException do
    begin
      CheckEquals('Expected parameter for executable', E.Message, 'Error message mis-match');
    end
    else
      Raise;
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutable;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LReason                : string;
  LExpectedReason        : string;
  LMapFileName           : string;
begin
  SetLength(LCmdParams, 2);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_EXECUTABLE;
  LCmdParams[Low(LCmdParams) + 1] := ParamStr(0);

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(LCmdParams[Low(LCmdParams) + 1], LCoverageConfiguration.GetExeFileName, 'Incorrect executable listed');

  LMapFileName := ChangeFileExt(LCmdParams[Low(LCmdParams) + 1], '.map');

  CheckEquals(LMapFileName, LCoverageConfiguration.GetMapFileName, 'Incorrect default map file listed');

  if FileExists(LMapFileName) then
  begin
    CheckTrue(LCoverageConfiguration.isComplete(LReason), 'Configuration should not be complete based on these parameters');
    CheckEquals('', LReason, 'Incorrect reason returned.');
  end
  else
  begin
    CheckFalse(LCoverageConfiguration.isComplete(LReason), 'Configuration should not be complete based on these parameters');
    LExpectedReason := 'The map file ' + LMapFileName + ' does not exist. Current dir is ' + GetCurrentDir();
    CheckEquals(LExpectedReason, LReason, 'Incorrect reason returned.');
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExecutableNoExistingFile;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LReason                : string;
  LExpectedReason        : string;
begin
  SetLength(LCmdParams, 4);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_EXECUTABLE;
  LCmdParams[Low(LCmdParams) + 1] := RandomFileName();
  // Force a valid map file...
  LCmdParams[Low(LCmdParams) + 2] := I_CoverageConfiguration.cPARAMETER_MAP_FILE;
  LCmdParams[Low(LCmdParams) + 3] := ParamStr(0);

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(LCmdParams[Low(LCmdParams) + 1], LCoverageConfiguration.GetExeFileName, 'Incorrect executable listed');

  CheckFalse(LCoverageConfiguration.isComplete(LReason), 'Configuration should not be complete based on these parameters');
  LExpectedReason := 'The executable file ' + LCmdParams[Low(LCmdParams) + 1] + ' does not exist. Current dir is ' + GetCurrentDir();
  CheckEquals(LExpectedReason, LReason, 'Incorrect reason returned.');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExcludingFileExtension;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileName             : string;
begin
  LFileName := RandomFileName();

  SetLength(LCmdParams, 3);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE;
  LCmdParams[Low(LCmdParams) + 1] := I_CoverageConfiguration.cPARAMETER_UNIT;
  LCmdParams[Low(LCmdParams) + 2] := LFileName + cSOME_EXTENSION;

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(1, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');
  CheckEquals(LFileName, LCoverageConfiguration.GetUnits.Strings[0], 'Incorrect unit name listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExcludingFileExtensionMultipleToggling;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileNameList          : TStringList;
  LExpectingFileList     : TStrings;
  LIdx                   : Integer;
  lp                    : Integer;
  LNumOfFiles            : Integer;
begin
  LFileNameList := nil;
  LExpectingFileList     := nil;
  try
    LFileNameList := TStringList.Create;
    LFileNameList.Sorted := True;
    LFileNameList.Duplicates := dupIgnore;

    LExpectingFileList := TStringList.Create;

    LNumOfFiles := Random(20) + 10;
    while LFileNameList.Count < LNumOfFiles do
      LFileNameList.Add(RandomFileName());

    SetLength(LCmdParams, LFileNameList.Count * 3);

    for lp := 0 to Pred(LFileNameList.Count) do
    begin
      if (lp mod 2 = 0) then
      begin
        LExpectingFileList.Add(LFileNameList.Strings[lp] + cSOME_EXTENSION);
        LCmdParams[Low(LCmdParams) + lp * 3] := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE;
      end
      else
      begin
        LExpectingFileList.Add(LFileNameList.Strings[lp]);
        LCmdParams[Low(LCmdParams) + lp * 3] := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE;
      end;

      LCmdParams[Low(LCmdParams) + lp * 3 + 1] := I_CoverageConfiguration.cPARAMETER_UNIT;
      LCmdParams[Low(LCmdParams) + lp * 3 + 2] := LFileNameList.Strings[lp] + cSOME_EXTENSION;
    end;

    LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
    LCoverageConfiguration.ParseCommandLine;

    CheckEquals(LExpectingFileList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

    for lp := 0 to Pred(LExpectingFileList.Count) do
      CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LExpectingFileList.Strings[lp]), 'Missing unit name');

    for lp := Pred(LExpectingFileList.Count) downto 0 do
    begin
      LIdx := LCoverageConfiguration.GetUnits.IndexOf(LExpectingFileList.Strings[lp]);
      if (LIdx <> -1) then
      begin
        LCoverageConfiguration.GetUnits.Delete(LIdx);
        LExpectingFileList.Delete(lp);
      end;
    end;

    CheckEquals(0, LExpectingFileList.Count, 'Expecting more units to be present');
    CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'More units than expected are present');
  finally
    FreeAndNil(LFileNameList);
    FreeAndNil(LExpectingFileList);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestExcludingFileExtensionFromUnitFile;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileListFileName      : string;
  LFileNameList          : TStringList;
  FileNameWithExtList   : TStrings;
  LIdx                   : Integer;
  lp                    : Integer;
  LNumOfFiles            : Integer;
begin
  LFileNameList := nil;
  FileNameWithExtList := nil;
  try
    LFileNameList := TStringList.Create;
    LFileNameList.Sorted := True;
    LFileNameList.Duplicates := dupIgnore;

    LNumOfFiles := Random(20) + 10;

    while LFileNameList.Count < LNumOfFiles do
      LFileNameList.Add(RandomFileName());

    FileNameWithExtList := TStringList.Create;

    for lp := 0 to Pred(LFileNameList.Count) do
      FileNameWithExtList.Add(LFileNameList.Strings[lp] + cSOME_EXTENSION);

    repeat
      LFileListFileName := RandomFileName();
    until not FileExists(LFileListFileName);

    try
      FileNameWithExtList.SaveToFile(LFileListFileName);

      SetLength(LCmdParams, 3);
      LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE;
      LCmdParams[Low(LCmdParams) + 1] := I_CoverageConfiguration.cPARAMETER_UNIT_FILE;
      LCmdParams[Low(LCmdParams) + 2] := LFileListFileName;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LFileNameList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

      for lp := 0 to Pred(LFileNameList.Count) do
        CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LFileNameList.Strings[lp]), 'Missing unit name');

      for lp := Pred(LFileNameList.Count) downto 0 do
      begin
        LIdx := LCoverageConfiguration.GetUnits.IndexOf(LFileNameList.Strings[lp]);
        if (LIdx <> -1) then
        begin
          LCoverageConfiguration.GetUnits.Delete(LIdx);
          LFileNameList.Delete(lp);
        end;
      end;

      CheckEquals(0, LFileNameList.Count, 'Expecting more units to be present');
      CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'More units than expected are present');
    finally
      if FileExists(LFileListFileName) then
        CheckTrue(SysUtils.DeleteFile(LFileListFileName), 'Unable to deleted unit file');
    end;
  finally
    FreeAndNil(LFileNameList);
    FreeAndNil(FileNameWithExtList);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestIncludingFileExtension;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileName             : string;
begin
  LFileName := RandomFileName();
  LFileName := LFileName + cSOME_EXTENSION;

  SetLength(LCmdParams, 3);
  LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE;
  LCmdParams[Low(LCmdParams) + 1] := I_CoverageConfiguration.cPARAMETER_UNIT;
  LCmdParams[Low(LCmdParams) + 2] := LFileName;

  LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
  LCoverageConfiguration.ParseCommandLine;

  CheckEquals(1, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');
  CheckEquals(LFileName, LCoverageConfiguration.GetUnits.Strings[0], 'Incorrect unit name listed');
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestIncludingFileExtensionMultipleToggling;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileNameList          : TStringList;
  LExpectingFileList     : TStrings;
  LIdx                   : Integer;
  lp                     : Integer;
  LNumOfFile             : Integer;
begin
  LFileNameList := nil;
  LExpectingFileList     := nil;
  try
    LFileNameList := TStringList.Create;
    LFileNameList.Sorted := True;
    LFileNameList.Duplicates := dupIgnore;

    LExpectingFileList := TStringList.Create;

    LNumOfFile := Random(20) + 10;
    while LFileNameList.Count < LNumOfFile do
      LFileNameList.Add(RandomFileName());

    SetLength(LCmdParams, LFileNameList.Count * 3);

    for lp := 0 to Pred(LFileNameList.Count) do
    begin
      if (lp mod 2 = 0) then
      begin
        LExpectingFileList.Add(LFileNameList.Strings[lp]);
        LCmdParams[Low(LCmdParams) + lp * 3] := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE;
      end
      else
      begin
        LExpectingFileList.Add(LFileNameList.Strings[lp] + cSOME_EXTENSION);
        LCmdParams[Low(LCmdParams) + lp * 3] := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE;
      end;

      LCmdParams[Low(LCmdParams) + lp * 3 + 1] := I_CoverageConfiguration.cPARAMETER_UNIT;
      LCmdParams[Low(LCmdParams) + lp * 3 + 2] := LFileNameList.Strings[lp] + cSOME_EXTENSION;
    end;

    LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
    LCoverageConfiguration.ParseCommandLine;

    CheckEquals(LExpectingFileList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

    for lp := 0 to Pred(LExpectingFileList.Count) do
      CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LExpectingFileList.Strings[lp]), 'Missing unit name');

    for lp := Pred(LExpectingFileList.Count) downto 0 do
    begin
      LIdx := LCoverageConfiguration.GetUnits.IndexOf(LExpectingFileList.Strings[lp]);
      if (LIdx <> -1) then
      begin
        LCoverageConfiguration.GetUnits.Delete(LIdx);
        LExpectingFileList.Delete(lp);
      end;
    end;

    CheckEquals(0, LExpectingFileList.Count, 'Expecting more units to be present');
    CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'More units than expected are present');
  finally
    FreeAndNil(LFileNameList);
    FreeAndNil(LExpectingFileList);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestIncludingFileExtensionFromUnitFile;
var
  LCoverageConfiguration : ICoverageConfiguration;
  LCmdParams             : array of string;
  LFileListFileName      : string;
  LFileNameList          : TStringList;
  LIdx                   : Integer;
  lp                     : Integer;
  LNumOfFiles            : Integer;
begin
  LFileNameList := nil;
  try
    LFileNameList := TStringList.Create;
    LFileNameList.Sorted := True;
    LFileNameList.Duplicates := dupIgnore;

    LNumOfFiles := Random(20) + 10;

    while LFileNameList.Count < LNumOfFiles do
      LFileNameList.Add(RandomFileName() + cSOME_EXTENSION);

    repeat
      LFileListFileName := RandomFileName();
    until not FileExists(LFileListFileName);

    try
      LFileNameList.SaveToFile(LFileListFileName);

      SetLength(LCmdParams, 3);
      LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE;
      LCmdParams[Low(LCmdParams) + 1] := I_CoverageConfiguration.cPARAMETER_UNIT_FILE;
      LCmdParams[Low(LCmdParams) + 2] := LFileListFileName;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LFileNameList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

      for lp := 0 to Pred(LFileNameList.Count) do
        CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LFileNameList.Strings[lp]), 'Missing unit name');

      for lp := Pred(LFileNameList.Count) downto 0 do
      begin
        LIdx := LCoverageConfiguration.GetUnits.IndexOf(LFileNameList.Strings[lp]);
        if (LIdx <> -1) then
        begin
          LCoverageConfiguration.GetUnits.Delete(LIdx);
          LFileNameList.Delete(lp);
        end;
      end;

      CheckEquals(0, LFileNameList.Count, 'Expecting more units to be present');
      CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'More units than expected are present');
    finally
      if FileExists(LFileListFileName) then
        CheckTrue(SysUtils.DeleteFile(LFileListFileName), 'Unable to deleted unit file');
    end;
  finally
    FreeAndNil(LFileNameList);
  end;
end;

//==============================================================================
procedure TCoverageConfigurationTest.TestFileExtensionFromUnitFileToggling;
var
  LCoverageConfiguration  : ICoverageConfiguration;
  LCmdParams              : array of string;
  LUnitFileNameWithExt    : string;
  LExpectedUnitList       : TStrings;
  LFileNameWithExtList    : TStringList;
  LFileNameWithoutExtList : TStringList;
  LIdx                    : Integer;
  lp                      : Integer;
  LNumOfFiles             : Integer;
  LUnitFileName           : string;
  LUnitFileNameWithoutExt : string;
begin
  LExpectedUnitList := nil;
  LFileNameWithExtList := nil;
  LFileNameWithoutExtList := nil;
  try
    LExpectedUnitList := TStringList.Create;

    LNumOfFiles := Random(20) + 5;

    LFileNameWithoutExtList := TStringList.Create;
    LFileNameWithoutExtList.Sorted := True;
    LFileNameWithoutExtList.Duplicates := dupIgnore;

    LFileNameWithExtList := TStringList.Create;
    LFileNameWithExtList.Sorted := True;
    LFileNameWithExtList.Duplicates := dupIgnore;

    while LFileNameWithExtList.Count < LNumOfFiles do
      LFileNameWithExtList.Add(RandomFileName() + cSOME_EXTENSION);

    LExpectedUnitList.AddStrings(LFileNameWithExtList);

    while LFileNameWithoutExtList.Count < LNumOfFiles do
    begin
      LUnitFileName := RandomFileName();
      if (LExpectedUnitList.IndexOf(LUnitFileName) = -1) then
      begin
        LExpectedUnitList.Add(LUnitFileName);
        LFileNameWithoutExtList.Add(LUnitFileName + cSOME_EXTENSION);
      end;
    end;

    repeat
      LUnitFileNameWithExt := RandomFileName();
    until not FileExists(LUnitFileNameWithExt);

    repeat
      LUnitFileNameWithoutExt := RandomFileName();
    until not FileExists(LUnitFileNameWithoutExt);

    try
      LFileNameWithExtList.SaveToFile(LUnitFileNameWithExt);
      LFileNameWithoutExtList.SaveToFile(LUnitFileNameWithoutExt);

      SetLength(LCmdParams, 6);
      LCmdParams[Low(LCmdParams)]     := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE;
      LCmdParams[Low(LCmdParams) + 1] := I_CoverageConfiguration.cPARAMETER_UNIT_FILE;
      LCmdParams[Low(LCmdParams) + 2] := LUnitFileNameWithoutExt;
      LCmdParams[Low(LCmdParams) + 3] := I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE;
      LCmdParams[Low(LCmdParams) + 4] := I_CoverageConfiguration.cPARAMETER_UNIT_FILE;
      LCmdParams[Low(LCmdParams) + 5] := LUnitFileNameWithExt;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LExpectedUnitList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');

      for lp := 0 to Pred(LExpectedUnitList.Count) do
        CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LExpectedUnitList.Strings[lp]), 'Missing unit name');

      for lp := Pred(LExpectedUnitList.Count) downto 0 do
      begin
        LIdx := LCoverageConfiguration.GetUnits.IndexOf(LExpectedUnitList.Strings[lp]);
        if (LIdx <> -1) then
        begin
          LCoverageConfiguration.GetUnits.Delete(LIdx);
          LExpectedUnitList.Delete(lp);
        end;
      end;

      CheckEquals(0, LExpectedUnitList.Count, 'Expecting more units to be present');
      CheckEquals(0, LCoverageConfiguration.GetUnits.Count, 'More units than expected are present');
    finally
      if FileExists(LUnitFileNameWithExt) then
        CheckTrue(SysUtils.DeleteFile(LUnitFileNameWithExt), 'Unable to deleted unit file with extensions file');
      if FileExists(LUnitFileNameWithoutExt) then
        CheckTrue(SysUtils.DeleteFile(LUnitFileNameWithoutExt), 'Unable to deleted unit file without extensions file');
    end;
  finally
    FreeAndNil(LExpectedUnitList);
    FreeAndNil(LFileNameWithExtList);
    FreeAndNil(LFileNameWithoutExtList);
  end;
end;

procedure TCoverageConfigurationTest.TestExcludeSourceMask;
var
  LNumOfFiles             : Integer;
  LTotalUnitList          : TStrings;
  LUnitName               : TFileName;
  LCmdParams              : array of string;
  LCoverageConfiguration  : ICoverageConfiguration;
  I                       : Integer;
begin
  LNumOfFiles := Random(20) + 5;
  SetLength(LCmdParams, LNumOfFiles + 3);
  LCmdParams[0] := '-esm';
  LCmdParams[1] := cEXCLUDE_FILES_PREFIX + '*';
  LCmdParams[2] := '-u';

  LTotalUnitList := TStringList.Create;
  try
    for I := 1 to LNumOfFiles do
    begin
      LUnitName := IfThen(I mod 2 = 0, cEXCLUDE_FILES_PREFIX, '') + RandomFileName();
      LTotalUnitList.Add(LUnitName);
      LCmdParams[I + 2] := LUnitName;
    end;

    LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
    LCoverageConfiguration.ParseCommandLine;
    for I := 0 to Pred(LTotalUnitList.Count) do
      if LeftStr(LTotalUnitList[I], Length(cEXCLUDE_FILES_PREFIX)) = cEXCLUDE_FILES_PREFIX then
        CheckEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LTotalUnitList[I]), 'Unit should have been excluded')
      else
        CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LTotalUnitList[I]), 'Missing unit name');
  finally
    LTotalUnitList.Free;
  end;
end;

procedure TCoverageConfigurationTest.TestDProj;
var
  LDProjName              : TFileName;
  LNumOfFiles             : Integer;
  LTotalUnitList          : TStrings;
  LDproj                  : TStrings;
  LUnitName               : TFileName;
  LExeName                : TFileName;
  LCmdParams              : array of string;
  LCoverageConfiguration  : ICoverageConfiguration;
  I                       : Integer;
begin
  LDProjName := IncludeTrailingPathDelimiter(GetCurrentDir()) + RandomFileName() + '.dproj';

  LDproj := TStringList.Create;
  try
    LDproj.Add('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">');
    LDProj.Add('<PropertyGroup Condition="''$(Base)''!=''''">');
    LExeName := RandomFileName();
    LDProj.Add('<DCC_DependencyCheckOutputName>' + LExeName+ '</DCC_DependencyCheckOutputName>');
    LDProj.Add('</PropertyGroup>');

    LTotalUnitList := TStringList.Create;
    try
      LNumOfFiles := Random(20) + 5;
      LDProj.Add('<ItemGroup>');
      for I := 0 to LNumOfFiles - 1 do
      begin
        LUnitName := RandomFileName();
        LTotalUnitList.Add(LUnitName);
        LDProj.Add('<DCCReference Include="' + LUnitName + '"/>');
      end;
      LDProj.Add('</ItemGroup>');
      LDProj.Add('</Project>');
      LDProj.SaveToFile(LDProjName);

      SetLength(LCmdParams, 2);
      LCmdParams[0] := '-dproj';
      LCmdParams[1] := LDProjName;

      LCoverageConfiguration := TCoverageConfiguration.Create(TMockCommandLineProvider.Create(LCmdParams));
      LCoverageConfiguration.ParseCommandLine;

      CheckEquals(LTotalUnitList.Count, LCoverageConfiguration.GetUnits.Count, 'Incorrect number of units listed');
      CheckEquals(IncludeTrailingPathDelimiter(GetCurrentDir()) + LExeName, LCoverageConfiguration.GetExeFileName, 'Incorrect executable listed');
      CheckEquals(ChangeFileExt((IncludeTrailingPathDelimiter(GetCurrentDir()) + LExeName), '.map'), LCoverageConfiguration.GetMapFileName, 'Incorrect map file name');

      for I := 0 to Pred(LTotalUnitList.Count) do
        CheckNotEquals(-1, LCoverageConfiguration.GetUnits.IndexOf(LTotalUnitList[I]), 'Missing unit name');
    finally
      LTotalUnitList.Free;
    end;
  finally
    TFile.Delete(LDProjName);
    LDproj.Free;
  end;
end;

//==============================================================================
initialization
  RegisterTest(TCoverageConfigurationTest.Suite);

//==============================================================================
//==============================================================================
//==============================================================================
end.
//==============================================================================

