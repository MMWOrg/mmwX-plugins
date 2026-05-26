# mmwx-speedtester Windows 一键安装并运行脚本
# 用法: irm <url>/install.ps1 | iex
# 或: .\install.ps1 -Master https://主控地址 -Token <令牌> -Name <名称>
param(
    [Parameter(Mandatory=$true)][string]$Master,
    [Parameter(Mandatory=$true)][string]$Token
)

$ErrorActionPreference = "Stop"
$Repo = "MMWOrg/mmwX-plugins"
$BinaryName = "mmwx-speedtester"

# 检测架构
$Arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
} else {
    Write-Error "不支持 32 位系统"; exit 1
}

$AssetName = "${BinaryName}-windows-${Arch}.exe"
Write-Host "平台: windows/${Arch}"

# 获取最新 release
Write-Host "正在查询最新版本..."
$ReleaseUrl = "https://api.github.com/repos/${Repo}/releases/latest"
$Release = Invoke-RestMethod -Uri $ReleaseUrl -Headers @{ "User-Agent" = "mmwx-installer" }
Write-Host "最新版本: $($Release.tag_name)"

$Asset = $Release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
if (-not $Asset) {
    Write-Error "未找到匹配 ${AssetName} 的下载文件，请访问 https://github.com/${Repo}/releases/latest 手动下载"
    exit 1
}

# 下载
$OutputPath = Join-Path $PWD "${BinaryName}.exe"
Write-Host "下载 ${AssetName}..."
Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $OutputPath
Write-Host "已下载到: ${OutputPath}"

# 运行
Write-Host ""
Write-Host "========================================"
Write-Host "主控地址: ${Master}"
Write-Host "========================================"
Write-Host ""
& $OutputPath -master $Master -token $Token
