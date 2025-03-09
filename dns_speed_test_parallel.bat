@echo off
setlocal enabledelayedexpansion

:: Check if dns_servers.txt exists
if not exist dns_servers.txt (
    echo Error: dns_servers.txt not found!
    exit /b 1
)

echo Testing DNS latency (10s max)...
echo -------------------------------------
echo DNS Server          Response Time (ms)
echo -------------------------------------

set TEST_DOMAIN=download.docker.com

:: Create a temporary file for results
set TEMP_FILE=%TEMP%\dns_results.txt

:: Clear previous results
if exist %TEMP_FILE% del %TEMP_FILE%

:: Function to test a DNS server
:TestDNS
set DNS_SERVER=%1
echo Testing DNS server: !DNS_SERVER!

:: Run nslookup and capture the response time
for /f "tokens=1-5" %%a in ('nslookup !TEST_DOMAIN! !DNS_SERVER! 2^>nul ^| findstr /i "Request time"') do (
    set RESPONSE_TIME=%%e
)

:: If no response time found, set it to Timeout
if not defined RESPONSE_TIME (
    set RESPONSE_TIME=Timeout
)

echo !DNS_SERVER!          !RESPONSE_TIME! ms >> %TEMP_FILE%
goto :eof

:: Run tests for each DNS server in the list
for /f "tokens=*" %%i in (dns_servers.txt) do (
    if "%%i" neq "" (
        call :TestDNS %%i
    )
)

:: Wait for 10 seconds before printing results
timeout /t 10 /nobreak >nul

:: Print results
echo -------------------------------------
for /f "tokens=1,2*" %%a in (%TEMP_FILE%) do (
    echo %%a %%b %%c
)

:: Clean up
del %TEMP_FILE%

echo -------------------------------------
endlocal

