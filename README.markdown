# Delphi Code Coverage

## Introduction
Delphi Code Coverage is a simple Code Coverage tool for Delphi that creates code coverage reports 
based on detailed MAP files.

Please also check out [this project](http://code.google.com/p/delphi-code-coverage-wizard/) as it adds a wizard to the 
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
Download [http://code.google.com/p/delphi-code-coverage/downloads/detail?name=CodeCoverage_0.5.zip](http://code.google.com/p/delphi-code-coverage/downloads/detail?name=CodeCoverage_0.5.zip), 
unzip the file and put it for example in your Delphi installations "bin" directory or somewhere where it is in 
the "path". 
You may also want to try out the [release candidate version for 1.0](http://code.google.com/p/delphi-code-coverage/downloads/detail?name=CodeCoverage_1.0_RC7.zip)
All parameters understand also environment variables in batch style (e.g. %WINDIR% etc.)
If a file is used for the source directories (see `-spf`) there are also Environment variables allowed.
It is possibile to exclude specific units in the units file (see `-uf`) by prepending a "!" before the unit name.

Open a command line prompt in the directory where your compiled application and executable is. 

Type: `CodeCoverage -m TestApp.map -e TestApp.exe -u TestUnit TestUnit2 -xml -html`

## Output
### HTML output (specify `-html` as a parameter)
For each unit there will be a unit.html with a summary of the coverage, followed by the source marked up. 
Green lines were covered. Red lines were not covered lines. The other lines didn't have code generated for it. 
There is also a CodeCoverage_summary.html file that summarizes the coverage and has links to the generated unit reports.

### XML output (specify `-xml` as a parameter)
A summary xml report called CodeCoverage_summary.xml is generated in the output directory that is compatible with the 
xml output from EMMA.

### Emma output (specify `-emma` as a parameter)
It is now possible to create EMMA compatible output which allows for using emma to merge multiple code coverage runs as 
well as using emma for generating reports.

### Delphi compatibility
DCC is compatible with Delphi 2010, XE and XE2 (32-bit), Delphi 2006, Delphi 5. If you find that it works for other 
Delphi versions, please let us know so that we can add to the list.

### Hudson integration
You can integrate the xml report using the Hudson EMMA plugin. The html report can be integrated using the 
HTML Publisher plugin.

### Sponsors
The 1.0 release was made possible through the generous support of DevFactory.

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
    <tr><td><code>-od directory</code></td><td>The directory where the output files will be put - note - the directory must exist</td></tr>
    <tr><td><code>-u TestUnit TestUnit2</code></td><td>The units that shall be checked for code coverage</td></tr>
    <tr><td><code>-uf filename</code></td><td>Cover units listed in the file pointed to by filename. One unit per line in the file</td></tr>
    <tr><td><code>-v</code></td><td>Show verbose output</td></tr>
    <tr><td><code>-dproj ProjectFile.dproj</code></td><td>Parse the project file for source dirs</td></tr>
    <tr><td><code>-a Param Param2</code></td><td>Parameters to pass on to the application that shall be checked for code coverage. ^ is an escape character</td></tr>
    <tr><td><code>-lt [filename]</code></td><td>Log events to a text log file. Default file name is: Delphi-Code-Coverage-Debug.log</td></tr>
    <tr><td><code>-lapi</code></td><td>Log events to the Windows API OutputDebugString</td></tr>
    <tr><td><code>-ife</code></td><td>Include File Extension - This will stop "Common.Encodings" being 'converted' to "Common"</td></tr>
    <tr><td><code>-efe</code></td><td>Exclude File Extension - This will 'converted' "Common.Encodings.pas" to "Common.Encodings" (and sadly, "Common.Encodings" to "Common"). This is on by default.</td></tr>
    <tr><td><code>-emma</code></td><td>Generate emma coverage output - Generate emma output as 'coverage.es' in the output directory.</td></tr>
    <tr><td><code>-meta</code></td><td>Generate separate meta and coverage files when generating emma output - 'coverage.em' and 'coverage.ec' will be generated for meta data and coverage data. NOTE: Needs -emma as well.</td></tr>
    <tr><td><code>-xml</code></td><td>Generate xml coverage output - Generate xml output as 'CodeCoverage_Summary.xml' in the output directory.</td></tr>
    <tr><td><code>-html</code></td><td>Generate html coverage output - Generate html output as 'CodeCoverage_Summary.html' in the output directory.</td></tr>
    <tr><td><code>-uns dll_or_exe unitname [unitname_2]</code></td><td>Create a separate namespace (the namespace name will be the name of the module without extension) ONLY for the listed units within the module</td></tr>
    <tr><td><code>-mns name dll_or_exe [dll_or_exe_2]</code></td><td>Create a separate namespace with the given name for the listed dll:s. All modules loaded in those module(s) will be namespaced.</td></tr>
    <tr><td><code>-lcl LineCountLimit</code></td><td>Count number of times a line is executed up to the specified limit</td></tr>
</table>
