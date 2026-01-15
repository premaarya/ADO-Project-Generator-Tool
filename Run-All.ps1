# Run-All.ps1
# Master orchestration script to execute all ADO project setup scripts in sequence
# This script creates a complete Azure DevOps project with sample data for migration testing

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\utils\config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipProjectCreation
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Script execution tracking
$script:StartTime = Get-Date
$script:CompletedSteps = @()
$script:FailedSteps = @()

function Write-Banner {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-StepHeader {
    param(
        [int]$StepNumber,
        [string]$StepName,
        [string]$Description
    )
    Write-Host "`n┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│ Step $StepNumber : $StepName" -ForegroundColor Yellow
    Write-Host "│ $Description" -ForegroundColor Gray
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
}

function Invoke-SetupScript {
    param(
        [int]$StepNumber,
        [string]$ScriptName,
        [string]$Description
    )
    
    $scriptPath = Join-Path $PSScriptRoot "scripts\setup\$ScriptName"
    
    Write-StepHeader -StepNumber $StepNumber -StepName $ScriptName -Description $Description
    
    try {
        $stepStartTime = Get-Date
        
        # Execute the script
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            & $scriptPath -ConfigPath $ConfigPath -Verbose
        } else {
            & $scriptPath -ConfigPath $ConfigPath
        }
        
        $stepDuration = (Get-Date) - $stepStartTime
        
        $script:CompletedSteps += @{
            Step = $StepNumber
            Name = $ScriptName
            Duration = $stepDuration
            Status = "Success"
        }
        
        Write-Host "`n✓ Step $StepNumber completed successfully in $($stepDuration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
        return $true
        
    } catch {
        $stepDuration = (Get-Date) - $stepStartTime
        
        $script:FailedSteps += @{
            Step = $StepNumber
            Name = $ScriptName
            Duration = $stepDuration
            Error = $_.Exception.Message
            Status = "Failed"
        }
        
        Write-Host "`n✗ Step $StepNumber failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
        return $false
    }
}

function Show-ExecutionSummary {
    $totalDuration = (Get-Date) - $script:StartTime
    
    Write-Banner "Execution Summary"
    
    Write-Host "Total Execution Time: " -NoNewline
    Write-Host "$($totalDuration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    
    Write-Host "`nCompleted Steps: " -NoNewline
    Write-Host "$($script:CompletedSteps.Count)" -ForegroundColor Green
    
    if ($script:CompletedSteps.Count -gt 0) {
        foreach ($step in $script:CompletedSteps) {
            Write-Host "  ✓ Step $($step.Step): $($step.Name) - $($step.Duration.TotalSeconds.ToString('F2'))s" -ForegroundColor Green
        }
    }
    
    if ($script:FailedSteps.Count -gt 0) {
        Write-Host "`nFailed Steps: " -NoNewline
        Write-Host "$($script:FailedSteps.Count)" -ForegroundColor Red
        
        foreach ($step in $script:FailedSteps) {
            Write-Host "  ✗ Step $($step.Step): $($step.Name)" -ForegroundColor Red
            Write-Host "    Error: $($step.Error)" -ForegroundColor DarkRed
        }
    }
    
    Write-Host "`n" -NoNewline
}

# ============================================
# Main Execution Flow
# ============================================

Write-Banner "ADO Sample Project Generator - Full Setup"

Write-Host "Configuration File: $ConfigPath" -ForegroundColor Gray
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Validate configuration file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Host "ERROR: Configuration file not found at: $ConfigPath" -ForegroundColor Red
    exit 1
}

# Load configuration to display project info
try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "`nTarget Configuration:" -ForegroundColor Yellow
    Write-Host "  Organization: $($config.organization)" -ForegroundColor White
    Write-Host "  Project: $($config.project)" -ForegroundColor White
    Write-Host "  Process Template: $($config.processTemplate)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to load configuration: $_" -ForegroundColor Red
    exit 1
}

# Confirm execution
Write-Host "This script will create a complete ADO project with all sample data." -ForegroundColor Yellow
Write-Host "This process may take 15-30 minutes depending on your network and ADO performance." -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Do you want to continue? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Setup cancelled by user." -ForegroundColor Yellow
    exit 0
}

# ============================================
# Execute Setup Scripts in Sequence
# ============================================

$allStepsSuccessful = $true

# Step 1: Create Project
if (-not $SkipProjectCreation) {
    $result = Invoke-SetupScript -StepNumber 1 -ScriptName "01-create-project.ps1" `
        -Description "Create Azure DevOps project and configure settings"
    $allStepsSuccessful = $allStepsSuccessful -and $result
} else {
    Write-Host "Skipping project creation (SkipProjectCreation flag set)" -ForegroundColor Yellow
}

# Step 2: Setup Teams, Areas, and Iterations
$result = Invoke-SetupScript -StepNumber 2 -ScriptName "02-setup-teams-areas-iterations.ps1" `
    -Description "Create teams, area paths, and sprint iterations"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 3: Create Work Items
$result = Invoke-SetupScript -StepNumber 3 -ScriptName "03-create-work-items.ps1" `
    -Description "Generate epics, features, user stories, tasks, and bugs"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 4: Create Test Management Objects
$result = Invoke-SetupScript -StepNumber 4 -ScriptName "04-create-test-management.ps1" `
    -Description "Create test plans, suites, cases, and test runs"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 5: Create Repositories
$result = Invoke-SetupScript -StepNumber 5 -ScriptName "05-create-repositories.ps1" `
    -Description "Initialize Git repositories with sample code and branches"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 6: Create CI/CD Pipelines
$result = Invoke-SetupScript -StepNumber 6 -ScriptName "06-create-pipelines.ps1" `
    -Description "Create build and release pipelines with configurations"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 7: Link Objects
$result = Invoke-SetupScript -StepNumber 7 -ScriptName "07-link-objects.ps1" `
    -Description "Create relationships between work items, commits, and builds"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 8: Create Wiki and Dashboards
$result = Invoke-SetupScript -StepNumber 8 -ScriptName "08-create-wiki-dashboards.ps1" `
    -Description "Create project wiki, dashboards, and shared queries"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 9: Create Service Connections and Variable Groups
$result = Invoke-SetupScript -StepNumber 9 -ScriptName "09-create-service-connections-variables.ps1" `
    -Description "Create service connections and library variable groups"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 10: Create Artifacts Feeds
$result = Invoke-SetupScript -StepNumber 10 -ScriptName "10-create-artifacts-feeds.ps1" `
    -Description "Create Azure Artifacts feeds with sample packages"
$allStepsSuccessful = $allStepsSuccessful -and $result

# Step 11: Create Permissions, Hooks, and Extensions
$result = Invoke-SetupScript -StepNumber 11 -ScriptName "11-create-permissions-hooks-extensions.ps1" `
    -Description "Set up security groups, service hooks, and document extensions"
$allStepsSuccessful = $allStepsSuccessful -and $result

# ============================================
# Final Summary and Next Steps
# ============================================

Show-ExecutionSummary

if ($allStepsSuccessful -and $script:FailedSteps.Count -eq 0) {
    Write-Banner "Setup Complete - Success!"
    
    Write-Host "Your ADO project has been successfully created with all sample data!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Project URL: https://dev.azure.com/$($config.organization)/$($config.project)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What's been created:" -ForegroundColor Yellow
    Write-Host "  ✓ Project structure with teams and iterations" -ForegroundColor Green
    Write-Host "  ✓ 200+ work items with comments, attachments, and history" -ForegroundColor Green
    Write-Host "  ✓ Test management (plans, suites, cases, runs)" -ForegroundColor Green
    Write-Host "  ✓ Git repositories with branches, pull requests, and policies" -ForegroundColor Green
    Write-Host "  ✓ CI/CD pipelines (YAML, classic builds, and releases)" -ForegroundColor Green
    Write-Host "  ✓ Service connections and variable groups" -ForegroundColor Green
    Write-Host "  ✓ Azure Artifacts feeds with sample packages" -ForegroundColor Green
    Write-Host "  ✓ Security groups, service hooks, and extensions" -ForegroundColor Green
    Write-Host "  ✓ Work item relationships and links" -ForegroundColor Green
    Write-Host "  ✓ Wiki, dashboards, and queries" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review the created project in Azure DevOps" -ForegroundColor White
    Write-Host "  2. Verify all objects are present and configured correctly" -ForegroundColor White
    Write-Host "  3. Use this project to test your ADO to GitHub migration tools" -ForegroundColor White
    Write-Host "  4. Review IMPLEMENTATION.md for architecture details" -ForegroundColor White
    Write-Host ""
    
    exit 0
} else {
    Write-Banner "Setup Incomplete - Errors Occurred"
    
    Write-Host "Some steps failed during execution. Please review the errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check your PAT token has sufficient permissions" -ForegroundColor White
    Write-Host "  2. Verify your organization and project names are correct" -ForegroundColor White
    Write-Host "  3. Review the error messages for specific issues" -ForegroundColor White
    Write-Host "  4. You can re-run individual scripts from /scripts/setup/" -ForegroundColor White
    Write-Host ""
    
    exit 1
}
