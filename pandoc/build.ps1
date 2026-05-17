# build.ps1 — сборка .md в .pdf через pandoc с конфигурацией проекта
# Использование: .\build.ps1 <путь_к_md_файлу> [-Open]
#   -Open : открыть PDF после сборки

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputFile,

    [switch]$Open    # открыть PDF после успешной сборки
)

# Кодировка консоли — UTF-8, чтобы pandoc корректно работал с кириллицей
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Пути
$ScriptDir = $PSScriptRoot
$DefaultsFile = Join-Path $ScriptDir "gost_report.yaml"

# Проверка входного файла
if (-not (Test-Path $InputFile)) {
    Write-Host "[ERROR] Файл не найден: $InputFile" -ForegroundColor Red
    exit 1
}

# Абсолютные пути
$InputAbs = (Resolve-Path $InputFile).Path
$InputDir = Split-Path $InputAbs -Parent
$InputName = [System.IO.Path]::GetFileNameWithoutExtension($InputAbs)
$OutputPdf = Join-Path $InputDir "$InputName.pdf"

# Проверка defaults
if (-not (Test-Path $DefaultsFile)) {
    Write-Host "[ERROR] Не найден defaults-файл: $DefaultsFile" -ForegroundColor Red
    exit 1
}

Write-Host "=== Pandoc Build ===" -ForegroundColor Cyan
Write-Host "Input:    $InputAbs"
Write-Host "Output:   $OutputPdf"
Write-Host "Defaults: $DefaultsFile"
Write-Host ""

# Переходим в папку документа — pandoc найдёт картинки по относительным путям
Push-Location $InputDir
try {
    pandoc --defaults $DefaultsFile --output $OutputPdf $InputAbs
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

# Итог
if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "[OK] Сборка завершена: $OutputPdf" -ForegroundColor Green

    if ($Open) {
        Start-Process $OutputPdf
    }
    exit 0
} else {
    Write-Host ""
    Write-Host "[FAIL] Pandoc вышел с кодом $exitCode" -ForegroundColor Red
    exit $exitCode
}
