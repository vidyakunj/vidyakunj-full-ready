@ECHO OFF
SET DIR=%~dp0
SET JAR=%DIR%gradle\wrapper\gradle-wrapper.jar

IF NOT EXIST "%JAR%" (
  ECHO gradle-wrapper.jar not found!
  EXIT /B 1
)

java -jar "%JAR%" %*
