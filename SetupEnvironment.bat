@echo off
:: setup following environment variables to point to correct location of external libraries

SET BASEDIR=%CD%
SET BUILD=%BASEDIR%\build
SET REPORTS=%BUILD%\reports
SET PRJDIR=%BASEDIR%\CodeCoverage\Test
SET PRJ=CodeCoverageTests

IF "%LIBS%"=="" SET LIBS=%BASEDIR%\3rdParty
IF "%JCL%"=="" SET JCL=%LIBS%\JCL
IF "%JWAPI%"=="" SET JWAPI=%LIBS%\JWAPI\jwapi2.2a
IF "%JVCL%"=="" SET JVCL=%LIBS%\JVCL

SET DPF=%PROGRAMFILES(X86)%
if "%DPF%"=="" (
	SET DPF="%PROGRAMFILES%"
)

IF EXIST "%DPF%\Embarcadero\Studio\14.0\bin\rsvars.bat" (
  ECHO Found Delphi XE6
  CALL "%DPF%\Embarcadero\Studio\14.0\bin\rsvars.bat"
) ELSE (
  :: check for Delphi XE2
  IF EXIST "%DPF%\Embarcadero\RAD Studio\9.0\bin\rsvars.bat" (
    ECHO Found Delphi XE2
    CALL "%DPF%\Embarcadero\RAD Studio\9.0\bin\rsvars.bat"
  ) ELSE (
    :: Delphi 2010
    IF EXIST "%DPF%\Embarcadero\RAD Studio\7.0\bin\rsvars.bat" (
  	ECHO Found Delphi 2010
      CALL "%DPF%\Embarcadero\RAD Studio\7.0\bin\rsvars.bat"
    ) ELSE (
      :: Delphi 2009
      IF EXIST "%DPF%\CodeGear\RAD Studio\6.0\bin\rsvars.bat" (
  	  ECHO Found Delphi 2009
        CALL "%DPF%\CodeGear\RAD Studio\6.0\bin\rsvars.bat"
      )
    )
  )
)