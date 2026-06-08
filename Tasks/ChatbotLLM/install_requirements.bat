@echo off
REM Usage: install_requirements.bat

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "REQUIREMENTS_FILE=%SCRIPT_DIR%requirements.txt"
set "ERRORS=0"

echo ============================================================
echo   ChatbotLLM - Environment Check and Install
echo ============================================================
echo.

REM Check Python
set "PY="
where python >nul 2>&1
if %errorlevel%==0 (
    set "PY=python"
) else (
    where python3 >nul 2>&1
    if %errorlevel%==0 (
        set "PY=python3"
    )
)

if not defined PY (
    echo [1/5] Python interpreter ... NOT FOUND
    echo        Please install Python 3.10+ and add it to PATH.
    exit /b 1
)

for /f "tokens=2 delims= " %%v in ('%PY% --version 2^>^&1') do set "PY_VERSION=%%v"
for /f %%m in ('%PY% -c "import sys; print(sys.version_info.major)"') do set "PY_MAJOR=%%m"
for /f %%n in ('%PY% -c "import sys; print(sys.version_info.minor)"') do set "PY_MINOR=%%n"

if %PY_MAJOR% GEQ 3 if %PY_MINOR% GEQ 10 (
    echo [1/5] Python interpreter ... OK ^(%PY% -^> %PY_VERSION%^)
    goto :check_pip
)
echo [1/5] Python interpreter ... WARNING ^(%PY% -^> %PY_VERSION%^)
echo        Python 3.10+ is recommended. Some features may not work.
set /a ERRORS+=1

:check_pip
%PY% -m pip --version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=2 delims= " %%p in ('%PY% -m pip --version') do set "PIP_VERSION=%%p"
    echo [2/5] pip ................. OK ^(!PIP_VERSION!^)
) else (
    echo [2/5] pip ................. NOT FOUND
    echo        Install pip: %PY% -m ensurepip --upgrade
    set /a ERRORS+=1
)

REM Check requirements.txt exists
if not exist "%REQUIREMENTS_FILE%" (
    echo [3/5] requirements.txt ..... MISSING
    echo        File not found: %REQUIREMENTS_FILE%
    set /a ERRORS+=1
    goto :check_files
)
echo [3/5] requirements.txt ..... OK

REM Check and install missing packages
echo [4/5] Python packages:
set "MISSING_COUNT=0"
for /f "usebackq tokens=* delims=" %%L in ("%REQUIREMENTS_FILE%") do (
    set "LINE=%%L"
    REM Skip empty lines
    if not "!LINE!"=="" (
        REM Strip version specifiers to get package name
        for /f "tokens=1 delims=><=!" %%P in ("!LINE!") do set "PKG_NAME=%%P"

        REM Map package names to import names
        set "IMPORT_NAME=!PKG_NAME:-=_!"
        if /i "!PKG_NAME!"=="pyyaml" set "IMPORT_NAME=yaml"
        if /i "!PKG_NAME!"=="PyYAML" set "IMPORT_NAME=yaml"
        if /i "!PKG_NAME!"=="llama-cpp-python" set "IMPORT_NAME=llama_cpp"

        %PY% -c "import !IMPORT_NAME!" >nul 2>&1
        if !errorlevel!==0 (
            echo        !PKG_NAME! ... OK
        ) else (
            echo        !PKG_NAME! ... MISSING - installing...
            %PY% -m pip install !PKG_NAME!
            if !errorlevel!==0 (
                echo        !PKG_NAME! ... INSTALLED
            ) else (
                echo        !PKG_NAME! ... FAILED to install
                set /a MISSING_COUNT+=1
            )
        )
    )
)
if !MISSING_COUNT! GTR 0 (
    set /a ERRORS+=1
)

:check_files
REM Check required project files
echo [5/5] Project files:
set "FILE_ERRORS=0"
for %%F in (main.py config.yaml chat_completion_schema.json system_prompt.txt) do (
    if exist "%SCRIPT_DIR%%%F" (
        echo        %%F ... OK
    ) else (
        echo        %%F ... MISSING
        set /a FILE_ERRORS+=1
    )
)
if !FILE_ERRORS! GTR 0 set /a ERRORS+=1

REM Summary
echo.
if %ERRORS%==0 (
    echo All checks passed. You can run the chatbot:
    echo   %PY% %SCRIPT_DIR%main.py
) else (
    echo %ERRORS% check^(s^) had issues. Please review the output above.
)

endlocal
