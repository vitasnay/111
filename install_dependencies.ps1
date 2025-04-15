# Скрипт установки зависимостей для Windows
# Требует прав администратора

# Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Этот скрипт требует прав администратора. Запустите PowerShell от имени администратора." -ForegroundColor Red
    exit 1
}

# Функция для проверки наличия программы
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

# Проверка наличия необходимых программ
$requiredPrograms = @(
    @{Name = "git"; Version = "2.0.0"; CheckVersion = $true},
    @{Name = "cmake"; Version = "3.15.0"; CheckVersion = $true},
    @{Name = "vcpkg"; Version = "2023.11.20"; CheckVersion = $true}
)

foreach ($program in $requiredPrograms) {
    if (-not (Test-CommandExists $program.Name)) {
        Write-Host "Программа $($program.Name) не установлена." -ForegroundColor Yellow
        if ($program.Name -eq "vcpkg") {
            # Установка vcpkg
            Write-Host "Установка vcpkg..." -ForegroundColor Cyan
            git clone https://github.com/Microsoft/vcpkg.git
            Set-Location vcpkg
            .\bootstrap-vcpkg.bat
            .\vcpkg integrate install
            Set-Location ..
        }
    } elseif ($program.CheckVersion) {
        $version = & $program.Name --version 2>&1
        if ($version -match $program.Version) {
            Write-Host "$($program.Name) версии $($program.Version) или выше уже установлен." -ForegroundColor Green
        } else {
            Write-Host "$($program.Name) требует обновления до версии $($program.Version) или выше." -ForegroundColor Yellow
        }
    }
}

# Установка CUDA Toolkit
$cudaVersion = "11.0"
$cudaInstaller = "cuda_${cudaVersion}_windows.exe"
$cudaUrl = "https://developer.download.nvidia.com/compute/cuda/${cudaVersion}/local_installers/${cudaInstaller}"

if (-not (Test-Path "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v${cudaVersion}")) {
    Write-Host "Установка CUDA Toolkit ${cudaVersion}..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $cudaUrl -OutFile $cudaInstaller
    Start-Process -FilePath ".\${cudaInstaller}" -ArgumentList "-s" -Wait
    Remove-Item $cudaInstaller
} else {
    Write-Host "CUDA Toolkit ${cudaVersion} уже установлен." -ForegroundColor Green
}

# Установка Qt6
$qtVersion = "6.2.0"
$qtInstaller = "qt-unified-windows-x64-4.6.0-online.exe"
$qtUrl = "https://download.qt.io/official_releases/online_installers/${qtInstaller}"

if (-not (Test-Path "C:\Qt\${qtVersion}")) {
    Write-Host "Установка Qt ${qtVersion}..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $qtUrl -OutFile $qtInstaller
    Start-Process -FilePath ".\${qtInstaller}" -ArgumentList "--script qt-installer-script.js" -Wait
    Remove-Item $qtInstaller
} else {
    Write-Host "Qt ${qtVersion} уже установлен." -ForegroundColor Green
}

# Установка OpenCV через vcpkg
Write-Host "Установка OpenCV..." -ForegroundColor Cyan
.\vcpkg\vcpkg install opencv4:x64-windows

# Установка дополнительных зависимостей
Write-Host "Установка дополнительных зависимостей..." -ForegroundColor Cyan
.\vcpkg\vcpkg install gtest:x64-windows
.\vcpkg\vcpkg install nlohmann-json:x64-windows

# Настройка переменных окружения
$env:PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v${cudaVersion}\bin;$env:PATH"
$env:PATH = "C:\Qt\${qtVersion}\msvc2019_64\bin;$env:PATH"
$env:PATH = "$(Get-Location)\vcpkg;$env:PATH"

# Сохранение переменных окружения
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("CUDA_PATH", "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v${cudaVersion}", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("Qt6_DIR", "C:\Qt\${qtVersion}\msvc2019_64\lib\cmake\Qt6", [EnvironmentVariableTarget]::Machine)

Write-Host "Установка зависимостей завершена успешно!" -ForegroundColor Green 