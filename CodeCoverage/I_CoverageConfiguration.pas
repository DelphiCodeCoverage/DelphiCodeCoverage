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
  Classes, ModuleNameSpaceUnit;

type
  ICoverageConfiguration = interface
    procedure ParseCommandLine();

    function GetApplicationParameters         : string;
    function GetExeFileName                   : string;
    function GetMapFileName                   : string;
    function GetOutputDir                     : string;
    function GetSourceDir                     : string;
    function GetSourcePaths                   : TStrings;
    function GetUnits                         : TStrings;
    function GetDebugLogFile                  : string;
    function UseApiDebug                      : boolean;
    function IsComplete(var AReason : string) : Boolean;
    function EmmaOutput                       : Boolean;
    function XmlOutput                        : Boolean;
    function HtmlOutput                       : Boolean;
    function GetModuleNameSpace(const module:String) : TModuleNameSpace;
    function GetUnitNameSpace(const modulename : String) : TUnitNameSpace;
  end;

const
  cESCAPE_CHARACTER : char = '^';
  cDEFULT_DEBUG_LOG_FILENAME = 'Delphi-Code-Coverage-Debug.log';
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
  cPARAMETER_MODULE_NAMESPACE='-mns';
  cPARAMETER_UNIT_NAMESPACE='-uns';

implementation

end.
