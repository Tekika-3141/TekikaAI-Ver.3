@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

title Tekika AI - Environment Checker

cd /d "%~dp0"
set "BACKEND_DIR=%~dp0tekika-ai-backend"
set "VENV_PYTHON=%BACKEND_DIR%\.venv\Scripts\python.exe"
set "PYTHON_CMD=py"

echo =========================================
echo       Tekika AI Environment Checker
echo =========================================
echo.
echo This program only checks your environment.
echo It does not modify Python, Node.js, or other settings.
echo.

set "ERROR_COUNT=0"

REM =========================================
REM 1. Python
REM =========================================
echo [1/7] Python
echo -----------------------------------------

py --version >nul 2>&1

if errorlevel 1 (
    powershell -NoProfile -Command "Write-Host '[NG] Python Launcher (py) was not found.' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '    ^> Please install Python.' -ForegroundColor Yellow"
    powershell -NoProfile -Command "Write-Host '    ^> Run this checker again after installation.' -ForegroundColor Yellow"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] Python' -ForegroundColor Green"
    py --version

    py -3 -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
    if errorlevel 1 (
        powershell -NoProfile -Command "Write-Host '[NG] Python 3.10 or newer is required.' -ForegroundColor Red"
        set /a ERROR_COUNT+=1
    )

    if exist "%VENV_PYTHON%" (
        set "PYTHON_CMD=%VENV_PYTHON%"
        powershell -NoProfile -Command "Write-Host '[OK] Using .venv Python for package checks.' -ForegroundColor Green"
    ) else (
        powershell -NoProfile -Command "Write-Host '[WARN] .venv was not found. Falling back to global py.' -ForegroundColor Yellow"
    )
)

echo.


REM =========================================
REM 2. Python packages
REM =========================================
echo [2/7] Python Packages
echo -----------------------------------------

if not exist "%~dp0tekika-ai-backend\requirements.txt" (
    powershell -NoProfile -Command "Write-Host '[NG] requirements.txt was not found.' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '    ^> Make sure the tekika-ai-backend folder is correctly placed.' -ForegroundColor Yellow"
    powershell -NoProfile -Command "Write-Host '    ^> Make sure the complete Tekika AI source files are present.' -ForegroundColor Yellow"
    set /a ERROR_COUNT+=1
) else (
    call :CHECK_REQUIREMENTS_WITH_PYTHON "%~dp0tekika-ai-backend\requirements.txt"
    if errorlevel 1 (
        set /a ERROR_COUNT+=1
    ) else (
        powershell -NoProfile -Command "Write-Host '[OK] requirements.txt dependencies are satisfied.' -ForegroundColor Green"
    )
)

echo.


REM =========================================
REM 3. Node.js / npm
REM =========================================
echo [3/7] Node.js / npm
echo -----------------------------------------

node --version >nul 2>&1

if errorlevel 1 (
    powershell -NoProfile -Command "Write-Host '[NG] Node.js was not found.' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '    ^> Please install Node.js.' -ForegroundColor Yellow"
    powershell -NoProfile -Command "Write-Host '    ^> Run this checker again after installation.' -ForegroundColor Yellow"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] Node.js' -ForegroundColor Green"
    node --version
)

call npm --version >nul 2>&1

if errorlevel 1 (
    powershell -NoProfile -Command "Write-Host '[NG] npm was not found.' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '    ^> npm is included with Node.js.' -ForegroundColor Yellow"
    powershell -NoProfile -Command "Write-Host '    ^> Reinstall Node.js if npm is unavailable.' -ForegroundColor Yellow"
    powershell -NoProfile -Command "Write-Host '    ^> If Node.js was installed just now, restart this terminal and run the checker again.' -ForegroundColor Yellow"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] npm' -ForegroundColor Green"
    call npm --version
)

echo.


REM =========================================
REM 4. Frontend
REM =========================================
echo [4/7] Frontend
echo -----------------------------------------

if not exist "%~dp0tekika-ai-frontend\package.json" (
    powershell -NoProfile -Command "Write-Host '[NG] package.json was not found.' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '    ^> Make sure the tekika-ai-frontend folder is correctly placed.' -ForegroundColor Yellow"
    powershell -NoProfile -Command "Write-Host '    ^> Make sure the complete Tekika AI frontend files are present.' -ForegroundColor Yellow"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] package.json' -ForegroundColor Green"

    if exist "%~dp0tekika-ai-frontend\node_modules" (
        powershell -NoProfile -Command "Write-Host '[OK] node_modules' -ForegroundColor Green"
    ) else (
        powershell -NoProfile -Command "Write-Host '[NG] node_modules was not found.' -ForegroundColor Red"
        powershell -NoProfile -Command "Write-Host '    ^> Frontend dependencies are not installed.' -ForegroundColor Yellow"
        powershell -NoProfile -Command "Write-Host '    ^> Run npm install in the tekika-ai-frontend folder.' -ForegroundColor Yellow"
        set /a ERROR_COUNT+=1
    )
)

echo.


REM =========================================
REM 5. Environment
REM =========================================
echo [5/7] Environment Configuration
echo -----------------------------------------

if not exist "%~dp0tekika-ai-backend\.env" (
    powershell -NoProfile -Command "Write-Host '[NG] .env was not found.' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '    ^> Copy .env.example to .env and configure it.' -ForegroundColor Yellow"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] .env' -ForegroundColor Green"
)

if not exist "%~dp0tekika-ai-backend\.env.example" (
    powershell -NoProfile -Command "Write-Host '[NG] .env.example was not found.' -ForegroundColor Red"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] .env.example' -ForegroundColor Green"
)

set "LLM_PROVIDER="

if exist "%~dp0tekika-ai-backend\.env" (
    for /f "usebackq tokens=1,* delims==" %%A in (`findstr /B /C:"LLM_PROVIDER=" "%~dp0tekika-ai-backend\.env"`) do set "LLM_PROVIDER=%%B"
)

if not defined LLM_PROVIDER (
    powershell -NoProfile -Command "Write-Host '[NG] LLM_PROVIDER is not configured.' -ForegroundColor Red"
    powershell -NoProfile -Command "Write-Host '    ^> Set it to ollama, openai, claude, or gemini in .env.' -ForegroundColor Yellow"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] LLM_PROVIDER = !LLM_PROVIDER!' -ForegroundColor Green"
)

if /I "!LLM_PROVIDER!"=="openai" call :check_key "OPENAI_API_KEY" "OpenAI"
if /I "!LLM_PROVIDER!"=="claude" call :check_key "ANTHROPIC_API_KEY" "Anthropic Claude"
if /I "!LLM_PROVIDER!"=="gemini" call :check_key "GOOGLE_API_KEY" "Google Gemini"

echo.


REM =========================================
REM 6. Ollama
REM =========================================
echo [6/7] Ollama
echo -----------------------------------------

if /I not "!LLM_PROVIDER!"=="ollama" (
    powershell -NoProfile -Command "Write-Host '[SKIP] LLM_PROVIDER is not ollama. Ollama check skipped.' -ForegroundColor Yellow"
) else (
    ollama --version >nul 2>&1

    if errorlevel 1 (
        powershell -NoProfile -Command "Write-Host '[NG] Ollama was not found.' -ForegroundColor Red"
        powershell -NoProfile -Command "Write-Host '    ^> Please install Ollama.' -ForegroundColor Yellow"
        set /a ERROR_COUNT+=1
    ) else (
        powershell -NoProfile -Command "Write-Host '[OK] Ollama' -ForegroundColor Green"
        ollama --version

        echo.
        echo Checking connection to the Ollama server...

        powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -UseBasicParsing -TimeoutSec 3 | Out-Null; exit 0 } catch { exit 1 }"

        if errorlevel 1 (
            powershell -NoProfile -Command "Write-Host '[NG] Cannot connect to the Ollama server.' -ForegroundColor Red"
            powershell -NoProfile -Command "Write-Host '    ^> Make sure Ollama is running.' -ForegroundColor Yellow"
            set /a ERROR_COUNT+=1
        ) else (
            powershell -NoProfile -Command "Write-Host '[OK] Connected to the Ollama server.' -ForegroundColor Green"
            set "OLLAMA_MODEL=qwen2.5:latest"
            if exist "%~dp0tekika-ai-backend\.env" (
                for /f "usebackq tokens=1,* delims==" %%A in (`findstr /B /C:"OLLAMA_DEFAULT_MODEL=" "%~dp0tekika-ai-backend\.env"`) do set "OLLAMA_MODEL=%%B"
            )
            powershell -NoProfile -Command "$m=(Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 5).models.name; if($m -contains '!OLLAMA_MODEL!'){exit 0}else{exit 1}" >nul 2>&1
            if errorlevel 1 (
                powershell -NoProfile -Command "Write-Host '[WARN] Required Ollama model !OLLAMA_MODEL! is missing.' -ForegroundColor Yellow"
            ) else (
                powershell -NoProfile -Command "Write-Host '[OK] Required Ollama model !OLLAMA_MODEL!' -ForegroundColor Green"
            )
        )

        echo.
        echo Installed models:
        ollama list
    )
)

echo.


REM =========================================
REM 7. Backend
REM =========================================
echo [7/7] Backend Structure
echo -----------------------------------------

if exist "%~dp0tekika-ai-backend\backend\main.py" (
    powershell -NoProfile -Command "Write-Host '[OK] backend\main.py' -ForegroundColor Green"
) else (
    powershell -NoProfile -Command "Write-Host '[NG] backend\main.py was not found.' -ForegroundColor Red"
    set /a ERROR_COUNT+=1
)

if exist "%~dp0tekika-ai-backend\backend\agent\factory.py" (
    powershell -NoProfile -Command "Write-Host '[OK] agent\factory.py' -ForegroundColor Green"
) else (
    powershell -NoProfile -Command "Write-Host '[NG] agent\factory.py was not found.' -ForegroundColor Red"
    set /a ERROR_COUNT+=1
)

if exist "%~dp0tekika-ai-backend\backend\agent\orchestrator.py" (
    powershell -NoProfile -Command "Write-Host '[OK] agent\orchestrator.py' -ForegroundColor Green"
) else (
    powershell -NoProfile -Command "Write-Host '[NG] agent\orchestrator.py was not found.' -ForegroundColor Red"
    set /a ERROR_COUNT+=1
)

echo.


REM =========================================
REM Result
REM =========================================
echo =========================================
echo             Check Result
echo =========================================
echo.

if "%ERROR_COUNT%"=="0" (
    powershell -NoProfile -Command "Write-Host '[OK] All checks passed.' -ForegroundColor Green"
    echo.
    echo Tekika AI is ready to start.
    echo Run start-tekika.bat to launch Tekika AI.
) else (
    powershell -NoProfile -Command "Write-Host '[NG] %ERROR_COUNT% problem(s) found.' -ForegroundColor Red"
    echo.
    powershell -NoProfile -Command "Write-Host 'Please review the [NG] items and the yellow instructions above.' -ForegroundColor Yellow"
)

echo.
echo =========================================
echo             Check Finished
echo =========================================
echo.
echo Press Enter to exit.
echo.

pause
if "%ERROR_COUNT%"=="0" (
    exit /b 0
) else (
    exit /b 1
)


REM =========================================
REM requirements.txt Check
REM =========================================
:CHECK_REQUIREMENTS_WITH_PYTHON

if not exist "%~1" (
    powershell -NoProfile -Command "Write-Host '[NG] requirements.txt was not found.' -ForegroundColor Red"
    exit /b 1
)

"%PYTHON_CMD%" -m pip --version >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Write-Host '[NG] pip is not available in the selected Python environment.' -ForegroundColor Red"
    exit /b 1
)

"%PYTHON_CMD%" -c "exec('import re,sys,importlib.metadata as md\nfrom pip._vendor.packaging.requirements import Requirement\nnorm=lambda s: re.sub(r\"[-_.]+\",\"-\",s).lower()\nreq_file=sys.argv[1]\ninstalled={norm((d.metadata.get(\"Name\") or d.metadata.get(\"name\") or d.name)): d.version for d in md.distributions()}\nmissing=[]\nfor raw in open(req_file, encoding=\"utf-8\").read().splitlines():\n line=raw.strip()\n if not line or line.startswith(\"#\"):\n  continue\n try:\n  req=Requirement(line)\n except Exception:\n  print(\"[NG] Invalid requirement line: {0}\".format(line))\n  missing.append(line)\n  continue\n if req.marker is not None and not req.marker.evaluate():\n  continue\n ver=installed.get(norm(req.name))\n if ver is None:\n  print(\"[NG] Missing package from requirements.txt: {0}\".format(line))\n  missing.append(line)\n  continue\n if req.specifier and not req.specifier.contains(ver, prereleases=True):\n  print(\"[NG] Version mismatch for {0} (installed {1})\".format(line, ver))\n  missing.append(line)\nif missing:\n sys.exit(1)\nsys.exit(0)')" "%~1"
if errorlevel 1 (
    powershell -NoProfile -Command "Write-Host '    ^> Install missing dependencies from requirements.txt.' -ForegroundColor Yellow"
    exit /b 1
)

exit /b 0


REM =========================================
REM API Key Check
REM =========================================
:check_key

set "CHECK_KEY="

if exist "%~dp0tekika-ai-backend\.env" (
    for /f "usebackq tokens=1,* delims==" %%A in (`findstr /B /C:"%~1=" "%~dp0tekika-ai-backend\.env"`) do set "CHECK_KEY=%%B"
)

if not defined CHECK_KEY (
    powershell -NoProfile -Command "Write-Host '[NG] %~2 API key (%~1) is not configured or is empty.' -ForegroundColor Red"
    set /a ERROR_COUNT+=1
) else (
    powershell -NoProfile -Command "Write-Host '[OK] %~2 API key is configured.' -ForegroundColor Green"
)

exit /b
