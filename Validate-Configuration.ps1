# Validate-Configuration.ps1
# Validates config.json before running the setup scripts

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\utils\config.json"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Configuration Validation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$errors = @()
$warnings = @()

# Check if config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Host "✗ Configuration file not found at: $ConfigPath" -ForegroundColor Red
    Write-Host "`nDid you mean to use config.json.example?" -ForegroundColor Yellow
    Write-Host "Copy utils\config.json.example to utils\config.json and edit with your details.`n" -ForegroundColor White
    exit 1
}

# Load configuration
try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "✓ Configuration file loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to parse configuration file: $_" -ForegroundColor Red
    exit 1
}

# Validate required fields
Write-Host "`nValidating required fields..." -ForegroundColor Yellow

# Organization
if ([string]::IsNullOrWhiteSpace($config.organization)) {
    $errors += "Organization name is required"
} elseif ($config.organization -eq "YOUR_ORG_NAME") {
    $errors += "Organization name must be changed from default value"
} else {
    Write-Host "  ✓ Organization: $($config.organization)" -ForegroundColor Green
}

# Project
if ([string]::IsNullOrWhiteSpace($config.project)) {
    $errors += "Project name is required"
} else {
    Write-Host "  ✓ Project: $($config.project)" -ForegroundColor Green
}

# PAT Token
if ([string]::IsNullOrWhiteSpace($config.pat)) {
    $errors += "Personal Access Token (PAT) is required"
} elseif ($config.pat -eq "YOUR_PERSONAL_ACCESS_TOKEN_HERE" -or $config.pat -eq "YOUR_PERSONAL_ACCESS_TOKEN") {
    $errors += "PAT must be changed from default value"
} elseif ($config.pat.Length -lt 20) {
    $warnings += "PAT token seems too short - verify it's correct"
} else {
    $maskedPat = $config.pat.Substring(0, 4) + "****" + $config.pat.Substring($config.pat.Length - 4)
    Write-Host "  ✓ PAT: $maskedPat" -ForegroundColor Green
}

# Process Template
if ([string]::IsNullOrWhiteSpace($config.processTemplate)) {
    $warnings += "Process template not specified, will use 'Agile'"
} elseif ($config.processTemplate -notin @('Agile', 'Scrum', 'CMMI', 'Basic')) {
    $warnings += "Process template '$($config.processTemplate)' may not be valid. Valid values: Agile, Scrum, CMMI, Basic"
} else {
    Write-Host "  ✓ Process Template: $($config.processTemplate)" -ForegroundColor Green
}

# Users
if ($null -eq $config.users -or $config.users.Count -eq 0) {
    $warnings += "No users defined - work items will not be assigned"
} else {
    Write-Host "  ✓ Users: $($config.users.Count) configured" -ForegroundColor Green
    
    # Check for example emails
    $exampleUsers = $config.users | Where-Object { $_ -like "*@example.com" }
    if ($exampleUsers.Count -gt 0) {
        $warnings += "$($exampleUsers.Count) user(s) have example email addresses"
    }
}

# Teams
if ($null -eq $config.teams -or $config.teams.Count -eq 0) {
    $warnings += "No teams defined"
} else {
    Write-Host "  ✓ Teams: $($config.teams.Count) configured" -ForegroundColor Green
}

# Work Item Counts
if ($null -eq $config.workItemCounts) {
    $warnings += "Work item counts not defined, will use defaults"
} else {
    $totalWorkItems = $config.workItemCounts.epics + $config.workItemCounts.features + 
                     $config.workItemCounts.userStories + $config.workItemCounts.tasks + 
                     $config.workItemCounts.bugs
    Write-Host "  ✓ Work Items: $totalWorkItems total planned" -ForegroundColor Green
    
    if ($totalWorkItems -gt 500) {
        $warnings += "High work item count ($totalWorkItems) may increase execution time significantly"
    }
}

# Test PAT token connection (optional but recommended)
Write-Host "`nTesting Azure DevOps connection..." -ForegroundColor Yellow

try {
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($config.pat)"))
    $headers = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = "application/json"
    }
    
    $uri = "https://dev.azure.com/$($config.organization)/_apis/projects?api-version=7.0"
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -TimeoutSec 10
    
    Write-Host "  ✓ Successfully connected to Azure DevOps" -ForegroundColor Green
    Write-Host "  ✓ Organization has $($response.count) existing project(s)" -ForegroundColor Green
    
    # Check if project already exists
    $existingProject = $response.value | Where-Object { $_.name -eq $config.project }
    if ($existingProject) {
        $warnings += "Project '$($config.project)' already exists - you may want to use -SkipProjectCreation"
    }
    
} catch {
    $errors += "Failed to connect to Azure DevOps: $($_.Exception.Message)"
    Write-Host "  ✗ Connection test failed" -ForegroundColor Red
    Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkRed
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Validation Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ All validations passed!" -ForegroundColor Green
    Write-Host "`nConfiguration is ready to use." -ForegroundColor Green
    Write-Host "Run .\Run-All.ps1 to start creating the ADO project.`n" -ForegroundColor White
    exit 0
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠ Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  • $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($errors.Count -gt 0) {
    Write-Host "✗ Errors ($($errors.Count)):" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  • $error" -ForegroundColor Red
    }
    Write-Host "`nPlease fix these errors before running the setup.`n" -ForegroundColor Red
    exit 1
}

if ($warnings.Count -gt 0 -and $errors.Count -eq 0) {
    Write-Host "Configuration has warnings but can proceed." -ForegroundColor Yellow
    Write-Host "Review warnings above and run .\Run-All.ps1 when ready.`n" -ForegroundColor White
    exit 0
}
