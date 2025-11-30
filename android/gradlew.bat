@echo off
set DIR=%~dp0
set JAVA_EXE=java.exe
if not defined JAVA_HOME goto findJava
set JAVA_EXE=%JAVA_HOME%\bin\java.exe
:findJava
if exist "%JAVA_EXE%" goto execGradle
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
exit /B 1
:execGradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% -classpath "%DIR%gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain %*
