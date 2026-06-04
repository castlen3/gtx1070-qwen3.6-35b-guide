@echo off
cd /d "C:\Users\castlen3\llama.cpp\b9500-cuda124"

echo ========================================
echo   Qwen3.6-35B-A3B — GTX 1070 8GB
echo   q8_0 KV cache | ctx=32768 | n_cpu_moe=30
echo   Expected: ~22.3 tok/s
echo ========================================
echo.

echo Cleaning port 8080...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080.*LISTENING') do (
    taskkill /f /pid %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul

echo Starting server on 0.0.0.0:8080...
echo.

llama-server.exe ^
  -m "F:\MODELS\lmstudio-community\Qwen3.6-35B-A3B-GGUF\Qwen3.6-35B-A3B-Q4_K_M.gguf" ^
  -t 4 ^
  --host 0.0.0.0 ^
  --port 8080 ^
  -ngl 40 ^
  --n-cpu-moe 30 ^
  --no-mmap ^
  --cache-type-k q8_0 ^
  --cache-type-v q8_0 ^
  -c 32768 ^
  -np 1 ^
  --reasoning off ^
  -fa on ^
  -fit off

echo.
echo Server stopped.
pause
