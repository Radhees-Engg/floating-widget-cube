try {

$appName = 'DisplayCube'
$scriptDir = 'C:\DisplayCube'
$installDir = $env:LOCALAPPDATA + '\' + $appName
$startupDir = [System.Environment]::GetFolderPath('Startup')

Clear-Host
Write-Host ''
Write-Host '  ╔══════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '  ║   D I S P L A Y   C U B E            ║' -ForegroundColor Cyan
Write-Host '  ║   Auto-Installer v1.0                 ║' -ForegroundColor Cyan
Write-Host '  ╚══════════════════════════════════════╝' -ForegroundColor Cyan
Write-Host ''

New-Item -ItemType Directory -Force -Path $installDir | Out-Null

Write-Host '  [1/4] Checking source files...' -ForegroundColor Yellow
$required = @('display_cube.cpp', 'windows_h.cpp', 'window_h.h')
foreach ($f in $required) {
    if (-not (Test-Path ($scriptDir + '\' + $f))) {
        Write-Host ('  [ERROR] Missing: C:\DisplayCube\' + $f) -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }
    Write-Host ('        Found: ' + $f) -ForegroundColor Green
}

Write-Host ''
Write-Host '  [2/4] Checking for G++...' -ForegroundColor Yellow
$mingwBin = 'C:\msys64\mingw64\bin'

if (Get-Command g++ -ErrorAction SilentlyContinue) {
    Write-Host '        G++ already on PATH.' -ForegroundColor Green
} elseif (Test-Path ($mingwBin + '\g++.exe')) {
    $env:PATH = $mingwBin + ';' + $env:PATH
    Write-Host ('        Found MinGW at ' + $mingwBin) -ForegroundColor Green
} else {
    Write-Host '        G++ not found. Installing via winget...' -ForegroundColor Yellow
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host '  [ERROR] winget not available.' -ForegroundColor Red
        Write-Host '  Install MinGW from https://winlibs.com/ then re-run.' -ForegroundColor Yellow
        Read-Host 'Press Enter to exit'
        exit 1
    }
    winget install --id MSYS2.MSYS2 -e --silent --accept-package-agreements --accept-source-agreements
    $msysBash = 'C:\msys64\usr\bin\bash.exe'
    if (-not (Test-Path $msysBash)) {
        Write-Host '  [ERROR] MSYS2 install failed.' -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }
    & $msysBash -lc 'pacman -Syu --noconfirm 2>/dev/null; pacman -S --noconfirm mingw-w64-x86_64-gcc 2>/dev/null'
    $env:PATH = $mingwBin + ';' + $env:PATH
    [System.Environment]::SetEnvironmentVariable('PATH', $mingwBin + ';' + [System.Environment]::GetEnvironmentVariable('PATH','User'), [System.EnvironmentVariableTarget]::User)
    Write-Host '        G++ installed!' -ForegroundColor Green
}

Write-Host ''
Write-Host '  [3/4] Setting up Raylib...' -ForegroundColor Yellow
$raylibDir = $installDir + '\raylib'
$raylibInc = $raylibDir + '\include'
$raylibLib = $raylibDir + '\lib'

if (Test-Path ($raylibInc + '\raylib.h')) {
    Write-Host '        Raylib already present.' -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Force -Path $raylibDir | Out-Null
    $raylibZip = $installDir + '\raylib.zip'
    $raylibUrl = 'https://github.com/raysan5/raylib/releases/download/5.5/raylib-5.5_win64_mingw-w64.zip'
    Write-Host '        Downloading Raylib...' -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $raylibUrl -OutFile $raylibZip -UseBasicParsing
    } catch {
        Write-Host '  [ERROR] Download failed. Check internet.' -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }
    Expand-Archive -Path $raylibZip -DestinationPath $raylibDir -Force
    $sub = Get-ChildItem $raylibDir -Directory | Select-Object -First 1
    if ($sub) {
        Get-ChildItem $sub.FullName | Move-Item -Destination $raylibDir -Force
        Remove-Item $sub.FullName -Recurse -Force
    }
    Remove-Item $raylibZip -Force
    Write-Host '        Raylib ready!' -ForegroundColor Green
}

Write-Host ''
Write-Host '  [4/4] Compiling...' -ForegroundColor Yellow
$outExe = $installDir + '\' + $appName + '.exe'
$src1 = $scriptDir + '\display_cube.cpp'
$src2 = $scriptDir + '\windows_h.cpp'

# Use full path to g++ so cmd /c can always find it regardless of PATH
$gppCmd = Get-Command g++ -ErrorAction SilentlyContinue
if ($gppCmd) { $gppExe = $gppCmd.Source } else { $gppExe = 'C:\msys64\mingw64\bin\g++.exe' }
if (-not (Test-Path $gppExe)) {
    Write-Host '  [ERROR] g++.exe not found at expected location.' -ForegroundColor Red
    Write-Host ('  Looked at: ' + $gppExe) -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}

$compileCmd = '"' + $gppExe + '" "' + $src1 + '" "' + $src2 + '" -I"' + $raylibInc + '" -L"' + $raylibLib + '" -o "' + $outExe + '" -lraylib -lopengl32 -lgdi32 -lwinmm -lshell32 -O2'
Write-Host ('        ' + $compileCmd) -ForegroundColor DarkGray
$buildOut = & cmd /c ($compileCmd + ' 2>&1')
if ($LASTEXITCODE -ne 0) {
    Write-Host '  [ERROR] Compilation failed:' -ForegroundColor Red
    Write-Host $buildOut -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}
Write-Host ('        Compiled => ' + $outExe) -ForegroundColor Green

Write-Host ''
Write-Host '  Adding to Windows Startup...' -ForegroundColor Yellow
$shortcutPath = $startupDir + '\' + $appName + '.lnk'
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut($shortcutPath)
$sc.TargetPath = $outExe
$sc.WorkingDirectory = $installDir
$sc.Description = 'DisplayCube Desktop Widget'
$sc.Save()
Write-Host ('        Shortcut: ' + $shortcutPath) -ForegroundColor Green
Start-Process $outExe -WorkingDirectory $installDir

Write-Host ''
Write-Host '  ╔══════════════════════════════════════╗' -ForegroundColor Green
Write-Host '  ║   Done! DisplayCube is installed.     ║' -ForegroundColor Green
Write-Host '  ║   It will auto-start with Windows.    ║' -ForegroundColor Green
Write-Host '  ╚══════════════════════════════════════╝' -ForegroundColor Green
Write-Host ''
Read-Host 'Press Enter to close'

} catch {
    Write-Host ''
    Write-Host '  [UNEXPECTED ERROR]' -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Write-Host ''
    Write-Host '  Screenshot this and share it for help.' -ForegroundColor Yellow
    Read-Host 'Press Enter to exit'
}
