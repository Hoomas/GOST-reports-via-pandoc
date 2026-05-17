# setup-symlinks.ps1
# Создаёт символические ссылки из %APPDATA%\Zettlr\defaults\ на файлы pandoc-конфигурации проекта.
# Требует запуска от имени администратора (для создания SymbolicLink в Windows).

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Force,    # перезаписать существующие симлинки/файлы без вопросов
    [switch]$DryRun    # показать, что будет сделано, но не выполнять
)

# --- Определяем пути ---
$ProjectRoot = $PSScriptRoot
$PandocDir = Join-Path $ProjectRoot "pandoc"
$ZettlrDefaults = Join-Path $env:APPDATA "Zettlr\defaults"

Write-Host "=== Zettlr Defaults Symlink Setup ===" -ForegroundColor Cyan
Write-Host "Project root:    $ProjectRoot"
Write-Host "Pandoc dir:      $PandocDir"
Write-Host "Zettlr defaults: $ZettlrDefaults"
Write-Host ""

# --- Проверки ---

# Проверка: запущен ли от админа
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] Скрипт должен быть запущен от имени Администратора." -ForegroundColor Red
    Write-Host "        Создание SymbolicLink в Windows требует повышенных прав."
    Write-Host "        Кликни правой кнопкой по PowerShell -> 'Запуск от имени администратора',"
    Write-Host "        затем запусти скрипт снова."
    exit 1
}

# Проверка: существует ли pandoc-папка
if (-not (Test-Path $PandocDir)) {
    Write-Host "[ERROR] Папка не найдена: $PandocDir" -ForegroundColor Red
    Write-Host "        Убедись, что скрипт лежит в корне проекта рядом с папкой pandoc/."
    exit 1
}

# Создаём папку defaults Zettlr, если её нет
if (-not (Test-Path $ZettlrDefaults)) {
    Write-Host "[INFO] Папка $ZettlrDefaults не существует, создаю..." -ForegroundColor Yellow
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $ZettlrDefaults -Force | Out-Null
    }
}

# --- Список симлинков ---
# Формат: @{ Source = "путь_в_проекте"; LinkName = "имя_в_папке_Zettlr"; Type = "файл/папка" }
$Links = @(
    @{ Source = "gost_report.yaml";          LinkName = "gost_report.yaml";  Type = "File"      }
    @{ Source = "template.tex";           LinkName = "template.tex";   Type = "File"      }
    @{ Source = "filters";                LinkName = "filters";        Type = "Directory" }
    @{ Source = "bibliography";           LinkName = "bibliography";   Type = "Directory" }
)

# --- Обработка каждой ссылки ---
$created = 0
$skipped = 0
$failed = 0

foreach ($link in $Links) {
    $sourcePath = Join-Path $PandocDir $link.Source
    $linkPath = Join-Path $ZettlrDefaults $link.LinkName

    Write-Host "----"
    Write-Host "  Источник: $sourcePath"
    Write-Host "  Ссылка:   $linkPath"

    # Проверяем, что источник существует
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  [SKIP] Источник не существует, пропускаю." -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Проверяем, существует ли уже что-то по пути ссылки
    if (Test-Path $linkPath) {
        $existing = Get-Item $linkPath -Force
        $isSymlink = ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

        if ($isSymlink) {
            # Существующий симлинк — проверим, куда он указывает
            $currentTarget = $existing.Target
            if ($currentTarget -eq $sourcePath) {
                Write-Host "  [OK] Симлинк уже существует и указывает правильно." -ForegroundColor Green
                $skipped++
                continue
            } else {
                Write-Host "  [WARN] Симлинк указывает на другое: $currentTarget" -ForegroundColor Yellow
                if ($Force) {
                    Write-Host "         -Force указан, удаляю старый симлинк."
                    if (-not $DryRun) { Remove-Item $linkPath -Force }
                } else {
                    Write-Host "         Используй -Force, чтобы перезаписать. Пропускаю."
                    $skipped++
                    continue
                }
            }
        } else {
            # Существует реальный файл/папка — это опасно
            Write-Host "  [WARN] По пути уже существует РЕАЛЬНЫЙ файл/папка (не симлинк)." -ForegroundColor Yellow
            if ($Force) {
                Write-Host "         -Force указан, делаю бэкап и удаляю."
                $backupPath = "$linkPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                if (-not $DryRun) {
                    Move-Item -Path $linkPath -Destination $backupPath -Force
                    Write-Host "         Бэкап: $backupPath"
                }
            } else {
                Write-Host "         Используй -Force, чтобы сделать бэкап и заменить симлинком."
                Write-Host "         Или вручную переименуй/удали этот файл и запусти снова."
                $skipped++
                continue
            }
        }
    }

    # Создаём симлинк
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Был бы создан симлинк ($($link.Type))" -ForegroundColor Cyan
        $created++
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $sourcePath -Force | Out-Null
            Write-Host "  [CREATED] Симлинк создан." -ForegroundColor Green
            $created++
        } catch {
            Write-Host "  [ERROR] Не удалось создать симлинк: $_" -ForegroundColor Red
            $failed++
        }
    }
}

# --- Итоги ---
Write-Host ""
Write-Host "=== Готово ===" -ForegroundColor Cyan
Write-Host "Создано:  $created"
Write-Host "Пропущено: $skipped"
if ($failed -gt 0) {
    Write-Host "Ошибок:   $failed" -ForegroundColor Red
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY-RUN] Это был сухой прогон. Изменения не применены." -ForegroundColor Cyan
    Write-Host "          Запусти без -DryRun, чтобы применить."
}

Write-Host ""
Write-Host "Дальнейшие шаги:"
Write-Host "  1. Перезапусти Zettlr, чтобы он подхватил новый профиль."
Write-Host "  2. При экспорте в PDF выбери профиль 'vkr-gost' в выпадающем списке."
Write-Host "  3. Все правки делай в папке проекта - Zettlr увидит их автоматически."
