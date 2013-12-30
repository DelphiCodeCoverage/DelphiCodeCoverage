(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_CoverageConfiguration;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  ModuleNameSpaceUnit,
  I_LogManager;

type
  ICoverageConfiguration = interface
    procedure ParseCommandLine(const ALogManager: ILogManager = nil);

    function ApplicationParameters: string;
    function ExeFileName: string;
    function MapFileName: string;
    function OutputDir: string;
    function SourceDir: string;
    function SourcePaths: TStrings;
    function Units: TStrings;
    function ExcludedUnits: TStrings;
    function DebugLogFile: string;
    function UseApiDebug: Boolean;
    function IsComplete(var AReason: string): Boolean;
    function EmmaOutput: Boolean;
    function SeparateMeta: Boolean;
    function XmlOutput: Boolean;
    function HtmlOutput: Boolean;
    function TestExeExitCode: Boolean;
    function ModuleNameSpace(const AModuleName: string): TModuleNameSpace;
    function UnitNameSpace(const AModuleName: string): TUnitNameSpace;
  end;

const
  cESCAPE_CHARACTER : char = '^';
  cDEFULT_DEBUG_LOG_FILENAME = 'Delphi-Code-Coverage-Debug.log';
  cPARAMETER_VERBOSE = '-v';
  cPARAMETER_EXECUTABLE = '-e';
  cPARAMETER_MAP_FILE = '-m';
  cPARAMETER_UNIT = '-u';
  cPARAMETER_UNIT_FILE = '-uf';
  cPARAMETER_SOURCE_DIRECTORY = '-sd';
  cPARAMETER_OUTPUT_DIRECTORY = '-od';
  cPARAMETER_EXECUTABLE_PARAMETER = '-a';
  cPARAMETER_LOGGING_TEXT = '-lt';
  cPARAMETER_LOGGING_WINAPI = '-lapi';
  cPARAMETER_FILE_EXTENSION_INCLUDE = '-ife';
  cPARAMETER_FILE_EXTENSION_EXCLUDE = '-efe';
  cPARAMETER_SOURCE_PATHS = '-sp';
  cPARAMETER_SOURCE_PATHS_FILE = '-spf';
  cPARAMETER_EMMA_OUTPUT = '-emma';
  cPARAMETER_XML_OUTPUT = '-xml';
  cPARAMETER_HTML_OUTPUT = '-html';
  cPARAMETER_DPROJ = '-dproj';
  cPARAMETER_EXCLUDE_SOURCE_MASK = '-esm';
  cPARAMETER_MODULE_NAMESPACE = '-mns';
  cPARAMETER_UNIT_NAMESPACE = '-uns';
  cPARAMETER_EMMA_SEPARATE_META = '-meta';
  cPARAMETER_TESTEXE_EXIT_CODE = '-tec';

  cIGNORE_UNIT_PREFIX = '!';
implementation

end.
