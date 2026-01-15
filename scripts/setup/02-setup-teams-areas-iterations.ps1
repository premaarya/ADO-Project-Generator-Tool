# 02 - Setup Teams, Area Paths, and Iteration Paths
# This script creates teams, area paths, and iteration paths for the project

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\..\..\utils\config.json"
)

# Import helper functions
. "$PSScriptRoot\..\..\utils\ado-api-helper.ps1"

# Load configuration
Write-Host "Loading configuration..." -ForegroundColor Green
$config = Get-AdoConfig -ConfigPath $ConfigPath

# Setup authentication
$headers = Get-AdoHeaders -Pat $config.pat
$org = $config.organization
$project = $config.project

Write-Host "Setting up teams, areas, and iterations for project '$project'..." -ForegroundColor Green

# ===== CREATE AREA PATHS =====
Write-Host "`n[1/3] Creating Area Paths..." -ForegroundColor Cyan

$areasUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/classificationnodes/areas"

foreach ($team in $config.teams) {
    Write-Host "  Creating area: $($team.areaPath)" -ForegroundColor White
    
    $areaBody = @{
        name = $team.areaPath
    }
    
    try {
        $area = Invoke-AdoRestApi -Uri $areasUri -Method POST -Headers $headers -Body $areaBody
        Write-Host "    ✓ Created area: $($area.name)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Area may already exist: $($team.areaPath)" -ForegroundColor Yellow
    }
}

# ===== CREATE ITERATION PATHS =====
Write-Host "`n[2/3] Creating Iteration Paths..." -ForegroundColor Cyan

$iterationsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/classificationnodes/iterations"

# Create year node
$yearNode = @{
    name = $config.iterations.year.ToString()
}

Write-Host "  Creating year node: $($config.iterations.year)" -ForegroundColor White
try {
    $year = Invoke-AdoRestApi -Uri $iterationsUri -Method POST -Headers $headers -Body $yearNode
    Write-Host "    ✓ Created year: $($year.name)" -ForegroundColor Green
} catch {
    Write-Host "    ⚠ Year node may already exist" -ForegroundColor Yellow
}

# Create sprint nodes
$startDate = [DateTime]::Parse($config.iterations.startDate)
$sprintLength = $config.iterations.sprintLengthWeeks * 7

for ($i = 1; $i -le $config.iterations.sprintCount; $i++) {
    $sprintName = "Sprint $i"
    $sprintStart = $startDate.AddDays(($i - 1) * $sprintLength)
    $sprintEnd = $sprintStart.AddDays($sprintLength - 1)
    
    Write-Host "  Creating sprint: $sprintName ($($sprintStart.ToString('yyyy-MM-dd')) - $($sprintEnd.ToString('yyyy-MM-dd')))" -ForegroundColor White
    
    $sprintBody = @{
        name = $sprintName
        attributes = @{
            startDate = $sprintStart.ToString("yyyy-MM-ddT00:00:00Z")
            finishDate = $sprintEnd.ToString("yyyy-MM-ddT23:59:59Z")
        }
    }
    
    $sprintUri = "$iterationsUri/$($config.iterations.year)"
    
    try {
        $sprint = Invoke-AdoRestApi -Uri $sprintUri -Method POST -Headers $headers -Body $sprintBody
        Write-Host "    ✓ Created sprint: $($sprint.name)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Sprint may already exist: $sprintName" -ForegroundColor Yellow
    }
}

# ===== CREATE TEAMS =====
Write-Host "`n[3/3] Creating Teams..." -ForegroundColor Cyan

foreach ($team in $config.teams) {
    Write-Host "  Creating team: $($team.name)" -ForegroundColor White
    
    $teamBody = @{
        name = $team.name
        description = $team.description
    }
    
    $teamsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/teams"
    
    try {
        $createdTeam = Invoke-AdoRestApi -Uri $teamsUri -Method POST -Headers $headers -Body $teamBody
        Write-Host "    ✓ Created team: $($createdTeam.name)" -ForegroundColor Green
        
        # Set team area path
        $teamAreaUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/teams/$($createdTeam.id)/teamfieldsettings"
        
        $areaSettings = @{
            defaultValue = "$project\$($team.areaPath)"
        }
        
        try {
            Invoke-AdoRestApi -Uri $teamAreaUri -Method PATCH -Headers $headers -Body $areaSettings
            Write-Host "    ✓ Set team area: $($team.areaPath)" -ForegroundColor Green
        } catch {
            Write-Host "    ⚠ Could not set team area" -ForegroundColor Yellow
        }
        
        # Assign sprints to team (assign first 6 sprints)
        Write-Host "    Assigning iterations to team..." -ForegroundColor White
        for ($i = 1; $i -le 6; $i++) {
            $iterationPath = "$project\$($config.iterations.year)\Sprint $i"
            $teamIterUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/teams/$($createdTeam.id)/iterations"
            
            $iterBody = @{
                id = $iterationPath
            }
            
            try {
                Invoke-AdoRestApi -Uri $teamIterUri -Method POST -Headers $headers -Body $iterBody
                Write-Host "      ✓ Assigned Sprint $i" -ForegroundColor Green
            } catch {
                # Ignore errors for iteration assignment
            }
        }
        
    } catch {
        Write-Host "    ⚠ Team may already exist: $($team.name)" -ForegroundColor Yellow
    }
}

# Save team information
$outputPath = "$PSScriptRoot\..\output"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

$teamInfo = @{
    teams = $config.teams
    areas = $config.teams.areaPath
    iterations = @{
        year = $config.iterations.year
        sprints = 1..$config.iterations.sprintCount | ForEach-Object { "Sprint $_" }
    }
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

$teamInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\teams-info.json"

Write-Host "`n✓ Teams, areas, and iterations setup completed!" -ForegroundColor Green
Write-Host "  Teams created: $($config.teams.Count)" -ForegroundColor Cyan
Write-Host "  Area paths created: $($config.teams.Count)" -ForegroundColor Cyan
Write-Host "  Iterations created: $($config.iterations.sprintCount)" -ForegroundColor Cyan
Write-Host "`nTeam information saved to: $outputPath\teams-info.json" -ForegroundColor Cyan

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 03-create-work-items.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
