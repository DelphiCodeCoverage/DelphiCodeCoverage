# Delphi Code Coverage

## Introduction
Delphi Code Coverage is a simple Code Coverage tool for Delphi that creates code coverage reports 
based on detailed MAP files.

Please also check out [this project](https://github.com/MHumm/delphi-code-coverage-wizard-plus) as it adds a wizard to the 
Delphi IDE to help create configuration and launch Delphi Code Coverage.

## Preconditions
The project you want to run a code coverage report for must have a "debug" configuration that generates a 
detailed MAP file.

## What kind of code coverage does it do
Delphi Code Coverage currently only measures "line coverage", i.e. it will track each line that code was generated for 
and mark it if it was executed.

## Coverage of DLLs and BPLs
For applications who uses Borland Package Libraries (which are essentially DLLs) or external DLLs, DCC will attempt to 
load a .map file for each DLL and if it exists and units in those libraries are part of the covered units, 
code coverage will span the DLL/BPL loaded as part of the application. The .map file need to exist in the same 
directory as the dll that was loaded.

## Usage
Download the latest [release](https://github.com/DelphiCodeCoverage/DelphiCodeCoverage/releases), 
unzip the file and put it for example in your Delphi installations "bin" directory or somewhere where it is in 
the "path". 

All parameters understand also environment variables in batch style (e.g. %WINDIR% etc.)
If a file is used for the source directories (see `-spf`) there are also Environment variables allowed.
It is possibile to exclude specific units in the units file (see `-uf`) by prepending a "!" before the unit name.

Open a command line prompt in the directory where your compiled application and executable is. 

Type: `CodeCoverage -m TestApp.map -e TestApp.exe -u TestUnit TestUnit2 -xml -html`

## Building

Due to newer language features used, somewhat newer compiler is required. The project is known to not support Delphi XE2.
XE3 will probably work. Main develop is done with 10.x versions.

## Output
### HTML output (specify `-html` as a parameter)
For each unit there will be a unit.html with a summary of the coverage, followed by the source marked up. 
Green lines were covered. Red lines were not covered lines. The other lines didn't have code generated for it. 
There is also a CodeCoverage_summary.html file that summarizes the coverage and has links to the generated unit reports.

### XML output (specify `-xml` as a parameter)
A summary xml report called CodeCoverage_summary.xml is generated in the output directory that is compatible with the 
xml output from EMMA. Use in combination with the switches '-xmllines' and '-xmlgenerics' for detailed code coverage per line.

### Emma output (specify `-emma` or `-emma21` as a parameter)
It is now possible to create EMMA compatible output which allows for using emma to merge multiple code coverage runs as 
well as using emma for generating reports.

### Delphi compatibility
DCC is compatible with Delphi up to 10.4.2, both 32 and 64 bit.

### SonarQube integration
You can integrate the results of the xml report in SonarQube. See the [Delphi SonarQube plugin](https://github.com/mendrix/SonarDelphi) 
or [newer version here](https://github.com/JAM-Software/SonarDelphi) 
for detailed information.

### Hudson integration
You can integrate the xml report using the Hudson EMMA plugin. The html report can be integrated using the 
HTML Publisher plugin.

### Sponsors
The latest released were made possible through the generous support of DevFactory and MendriX.

### Inspiration
This project was inspired by great tools in the Java world such as Emma. This project has been lingering in an 
unfinished form on my harddrive for more than a year. Finally it slipped out.

### Switches
<table>
    <tr><td><code>-m MapFile.map</code></td><td>The map file used as input</td></tr>
    <tr><td><code>-e Executable.exe</code></td><td>The executable to run</td></tr>
    <tr><td><code>-sd directory</code></td><td>The directory where the source can be found</td></tr>
    <tr><td><code>-sp directory directory2</code></td><td>The directories where the source can be found</td></tr>
    <tr><td><code>-spf filename</code></td><td>Use source directories listed in the file pointed to by filename. One directory per line in the file</td></tr>
    <tr><td><code>-esm mask1 mask2 etc</code></td><td>A list of file masks to exclude from list of units</td></tr>
    <tr><td><code>-od directory</code></td><td>The directory where the output files will be put - note - the directory must exist</td></tr>
    <tr><td><code>-u TestUnit TestUnit2</code></td><td>The units that shall be checked for code coverage</td></tr>
    <tr><td><code>-uf filename</code></td><td>Cover units listed in the file pointed to by filename. One unit per line in the file</td></tr>
    <tr><td><code>-v</code></td><td>Show verbose output</td></tr>
    <tr><td><code>-dproj ProjectFile.dproj</code></td><td>Parse the project file for source dirs, executable name, code page and other options. Note that options that could only have single value, like code page, will be overwritten in the order of appearance if multiple related switches are encountered.</td></tr>
    <tr><td><code>-a Param Param2</code></td><td>Parameters to pass on to the application that shall be checked for code coverage. ^ is an escape character</td></tr>
    <tr><td><code>-lt [filename]</code></td><td>Log events to a text log file. Default file name is: Delphi-Code-Coverage-Debug.log</td></tr>
    <tr><td><code>-lapi</code></td><td>Log events to the Windows API OutputDebugString</td></tr>
    <tr><td><code>-ife</code></td><td>Include File Extension - This will stop "Common.Encodings" being 'converted' to "Common"</td></tr>
    <tr><td><code>-efe</code></td><td>Exclude File Extension - This will 'converted' "Common.Encodings.pas" to "Common.Encodings" (and sadly, "Common.Encodings" to "Common"). This is on by default.</td></tr>
    <tr><td><code>-emma</code></td><td>Generate emma coverage output as 'coverage.es' in the output directory.</td></tr>
    <tr><td><code>-emma21</code></td><td>Generate emma21 coverage output as 'coverage.es' in the output directory.</td></tr>	
    <tr><td><code>-meta</code></td><td>Generate separate meta and coverage files when generating emma output - 'coverage.em' and 'coverage.ec' will be generated for meta data and coverage data. NOTE: Needs -emma as well.</td></tr>
    <tr><td><code>-xml</code></td><td>Generate xml coverage output - Generate xml output as 'CodeCoverage_Summary.xml' in the output directory.</td></tr>
    <tr><td><code>-xmllines</code></td><td>Adds lines coverage to the generated xml coverage output.</td></tr>
    <tr><td><code>-xmlgenerics</code></td><td>Combine lines coverage for multiple occurrences of the same filename (especially usefull in case of generic classes).</td></tr>	
    <tr><td><code>-html</code></td><td>Generate html coverage output as 'CodeCoverage_Summary.html' in the output directory.</td></tr>
    <tr><td><code>-uns dll_or_exe unitname [unitname_2]</code></td><td>Create a separate namespace (the namespace name will be the name of the module without extension) ONLY for the listed units within the module</td></tr>
    <tr><td><code>-mns name dll_or_exe [dll_or_exe_2]</code></td><td>Create a separate namespace with the given name for the listed dll:s. All modules loaded in those module(s) will be namespaced.</td></tr>
    <tr><td><code>-lcl LineCountLimit</code></td><td>Count number of times a line is executed up to the specified limit</td></tr>
    <tr><td><code>-cp CodePage</code></td><td>Code page number of source files</td></tr>
    <tr><td><code>-tec</code></td><td>Passthrough the exitcode of the application inspected</td></tr>
    <tr><td><code>-twd</code></td><td>Use the application's path as working directory</td></tr>
</table>

## License

Delphi Code Coverage is licensed under the terms of the Mozilla Public
License, v. 2.0. You can obtain a copy of the license at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
