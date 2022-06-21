@echo off
:: setup following environment variables to point to correct location of external libraries

SET BASEDIR=%CD%
SET BUILD=%BASEDIR%\build
SET REPORTS=%BUILD%\reports
SET PRJDIR=%BASEDIR%\Test
SET PRJ=CodeCoverageTests

SET DPF=%PROGRAMFILES(X86)%
if "%DPF%"=="" (
	SET DPF="%PROGRAMFILES%"
)

IF EXIST "%DPF%\Embarcadero\Studio\22.0\bin\rsvars.bat" (
  ECHO Found Delphi 11 Alexandria
  CALL "%DPF%\Embarcadero\Studio\22.0\bin\rsvars.bat"
) ELSE (
IF EXIST "%DPF%\Embarcadero\Studio\21.0\bin\rsvars.bat" (
  ECHO Found Delphi 10.4 Sydney
  CALL "%DPF%\Embarcadero\Studio\21.0\bin\rsvars.bat"
) ELSE (
IF EXIST "%DPF%\Embarcadero\Studio\20.0\bin\rsvars.bat" (
  ECHO Found Delphi 10.3 Rio
  CALL "%DPF%\Embarcadero\Studio\20.0\bin\rsvars.bat"
) ELSE (
IF EXIST "%DPF%\Embarcadero\Studio\19.0\bin\rsvars.bat" (
  ECHO Found Delphi 10.2 Tokyo
  CALL "%DPF%\Embarcadero\Studio\19.0\bin\rsvars.bat"
) ELSE (
IF EXIST "%DPF%\Embarcadero\Studio\18.0\bin\rsvars.bat" (
  ECHO Found Delphi 10.1 Berlin
  CALL "%DPF%\Embarcadero\Studio\18.0\bin\rsvars.bat"
) ELSE (
IF EXIST "%DPF%\Embarcadero\Studio\17.0\bin\rsvars.bat" (
  ECHO Found Delphi 10 Seattle
  CALL "%DPF%\Embarcadero\Studio\17.0\bin\rsvars.bat"
) ELSE (
IF EXIST "%DPF%\Embarcadero\Studio\14.0\bin\rsvars.bat" (
  ECHO Found Delphi XE6
  CALL "%DPF%\Embarcadero\Studio\14.0\bin\rsvars.bat"
)
)
)
)
)
)
)
