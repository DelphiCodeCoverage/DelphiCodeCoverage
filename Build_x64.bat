echo Building Delphi Code Coverage

call SetupEnvironment.bat

msbuild /p:Platform=Win64 /t:build /p:config=Release /verbosity:detailed "Source\CodeCoverage.dproj"