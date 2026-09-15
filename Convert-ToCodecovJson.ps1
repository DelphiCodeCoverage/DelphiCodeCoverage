# Convert DelphiCodeCoverage HTML reports to Codecov JSON format
# Parses HTML files to extract line-level coverage data
#
# USAGE:
#   .\Convert-ToCodecovJson.ps1 [-OutputFile <path>]

param(
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"

# Get script directory and set defaults
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $OutputFile) { $OutputFile = Join-Path $ScriptDir "codecov.json" }
$ReportDir = Join-Path $ScriptDir "coverage_report"
$RepoRoot = Split-Path -Parent $ScriptDir

Write-Host "Converting DelphiCodeCoverage HTML to Codecov JSON..." -ForegroundColor Cyan

if (-not (Test-Path $ReportDir)) {
    Write-Host "ERROR: Coverage report directory not found: $ReportDir" -ForegroundColor Red
    exit 1
}

# Build file path map: filename -> repo-relative path
Write-Host "  Building file path map..." -ForegroundColor Gray
$filePathMap = @{}
$sourceDir = Join-Path $RepoRoot "Source"
Get-ChildItem -Path $sourceDir -Filter "*.pas" -Recurse | ForEach-Object {
    $filename = $_.Name
    $relativePath = $_.FullName.Substring($RepoRoot.Length + 1).Replace('\', '/')
    if (-not $filePathMap.ContainsKey($filename)) {
        $filePathMap[$filename] = $relativePath
    }
}
Write-Host "  Found $($filePathMap.Count) source files in repo" -ForegroundColor Gray

# Initialize coverage data
$coverage = @{}
$totalCovered = 0
$totalLines = 0

# Get all HTML coverage files (excluding summary)
$htmlFiles = Get-ChildItem -Path $ReportDir -Filter "*.html" | Where-Object { 
    $_.Name -ne "CodeCoverage_summary.html" -and $_.Name -match "\(.*\.pas\)\.html$"
}

Write-Host "  Processing $($htmlFiles.Count) coverage files..." -ForegroundColor Gray

foreach ($htmlFile in $htmlFiles) {
    # Extract filename from HTML filename pattern: UnitName(filename.pas).html
    if ($htmlFile.Name -match "\(([^)]+\.pas)\)\.html$") {
        $sourceFilename = $matches[1]
    } else {
        continue
    }
    
    # Get repo-relative path
    $repoPath = $sourceFilename
    if ($filePathMap.ContainsKey($sourceFilename)) {
        $repoPath = $filePathMap[$sourceFilename]
    } else {
        # Skip files not in Source directory (test files, etc.)
        continue
    }
    
    # Read and parse HTML
    $htmlContent = Get-Content $htmlFile.FullName -Raw -Encoding UTF8
    
    # Initialize line coverage for this file
    $lineCoverage = @{}
    
    # Parse table rows with coverage data
    # Pattern: <tr class="covered|notcovered|nocodegen"><td>LINE_NUMBER<td>
    $pattern = '<tr class="(covered|notcovered|nocodegen)"><td>(\d+)<td>'
    $matches2 = [regex]::Matches($htmlContent, $pattern)
    
    foreach ($match in $matches2) {
        $coverageClass = $match.Groups[1].Value
        $lineNum = $match.Groups[2].Value
        
        switch ($coverageClass) {
            "covered" { 
                $lineCoverage[$lineNum] = 1
                $totalCovered++
                $totalLines++
            }
            "notcovered" { 
                $lineCoverage[$lineNum] = 0
                $totalLines++
            }
            # "nocodegen" lines are skipped (not executable code)
        }
    }
    
    if ($lineCoverage.Count -gt 0) {
        $coverage[$repoPath] = $lineCoverage
    }
}

Write-Host "  Processed $($coverage.Count) files with coverage data" -ForegroundColor Gray

# Build Codecov JSON structure
$codecovJson = @{
    coverage = @{}
}

foreach ($file in $coverage.Keys) {
    $codecovJson.coverage[$file] = @{}
    foreach ($line in $coverage[$file].Keys) {
        $codecovJson.coverage[$file][$line] = $coverage[$file][$line]
    }
}

# Save JSON without BOM (UTF8 without BOM)
$json = $codecovJson | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($OutputFile, $json, [System.Text.UTF8Encoding]::new($false))

$coveragePercent = if ($totalLines -gt 0) { [math]::Round(($totalCovered / $totalLines) * 100, 2) } else { 0 }

Write-Host "Converted successfully!" -ForegroundColor Green
Write-Host "  Output: $OutputFile" -ForegroundColor Gray
Write-Host "  Files: $($coverage.Count)" -ForegroundColor Gray
Write-Host "  Line coverage: $coveragePercent% ($totalCovered/$totalLines)" -ForegroundColor Gray
