# 01 - Create Azure DevOps Project
# This script creates a new ADO project with the specified configuration

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\..\..\utils\config.json"
)

# Import helper functions
. "$PSScriptRoot\..\..\utils\ado-api-helper.ps1"

# Load configuration
Write-Host "Loading configuration..." -ForegroundColor Green
$config = Get-AdoConfig -ConfigPath $ConfigPath

# Setup authentication - Use application/json for POST operations
$headers = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"

# Check if project already exists
Write-Host "Checking if project '$($config.project)' already exists..." -ForegroundColor Yellow
$projectsUri = New-AdoUri -Organization $config.organization -Resource "_apis/projects"
$existingProjects = Invoke-AdoRestApi -Uri $projectsUri -Method GET -Headers $headers

$projectExists = $existingProjects.value | Where-Object { $_.name -eq $config.project }

if ($projectExists) {
    Write-Host "Project '$($config.project)' already exists. Skipping creation." -ForegroundColor Yellow
    Write-Host "Project ID: $($projectExists.id)" -ForegroundColor Cyan
    exit 0
}

# Create project
Write-Host "`nCreating project '$($config.project)'..." -ForegroundColor Green

$projectBody = @{
    name = $config.project
    description = "ADO Migration Test Project - Generated seed data for testing ADO to GitHub migration tools"
    visibility = if ($config.visibility) { $config.visibility } else { "private" }
    capabilities = @{
        versioncontrol = @{
            sourceControlType = "Git"
        }
        processTemplate = @{
            templateTypeId = switch ($config.processTemplate) {
                "Agile" { "adcc42ab-9882-485e-a3ed-7678f01f66bc" }
                "Scrum" { "6b724908-ef14-45cf-84f8-768b5384da45" }
                "Basic" { "b8a3a935-7e91-48b8-a94c-606d37c3e9f2" }
                "CMMI" { "27450541-8e31-4150-9947-dc59f998fc01" }
                default { "adcc42ab-9882-485e-a3ed-7678f01f66bc" } # Default to Agile
            }
        }
    }
}

$createUri = New-AdoUri -Organization $config.organization -Resource "_apis/projects"
$response = Invoke-AdoRestApi -Uri $createUri -Method POST -Headers $headers -Body $projectBody

Write-Host "Project creation initiated..." -ForegroundColor Cyan

# Wait for project creation to complete
if ($response.status -eq "inProgress") {
    Write-Host "Waiting for project creation to complete..." -ForegroundColor Yellow
    $operationUri = $response.url
    
    $completed = Wait-AdoOperation -OperationUri $operationUri -Headers $headers -TimeoutSeconds 180
    
    if ($completed.status -eq "succeeded") {
        Write-Host "`n✓ Project '$($config.project)' created successfully!" -ForegroundColor Green
        
        # Get project details
        $projectUri = New-AdoUri -Organization $config.organization -Resource "_apis/projects/$($config.project)"
        $projectDetails = Invoke-AdoRestApi -Uri $projectUri -Method GET -Headers $headers
        
        Write-Host "`nProject Details:" -ForegroundColor Cyan
        Write-Host "  ID: $($projectDetails.id)" -ForegroundColor White
        Write-Host "  Name: $($projectDetails.name)" -ForegroundColor White
        Write-Host "  State: $($projectDetails.state)" -ForegroundColor White
        Write-Host "  URL: $($projectDetails._links.web.href)" -ForegroundColor White
        Write-Host "  Process: $($config.processTemplate)" -ForegroundColor White
        Write-Host "  Visibility: $($projectDetails.visibility)" -ForegroundColor White
        
        # Save project details for other scripts
        $projectInfo = @{
            id = $projectDetails.id
            name = $projectDetails.name
            url = $projectDetails.url
            state = $projectDetails.state
            createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        
        $outputPath = "$PSScriptRoot\..\output"
        if (-not (Test-Path $outputPath)) {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
        }
        
        $projectInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\project-info.json"
        Write-Host "`nProject information saved to: $outputPath\project-info.json" -ForegroundColor Cyan
        
    } else {
        throw "Project creation failed: $($completed.message)"
    }
} else {
    Write-Host "`n✓ Project '$($config.project)' created successfully!" -ForegroundColor Green
}

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 02-setup-teams-areas-iterations.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
