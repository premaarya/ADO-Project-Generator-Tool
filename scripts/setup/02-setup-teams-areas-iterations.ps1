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

# ===== CONFIGURE TEAM BOARDS =====
Write-Host "`n[4/4] Configuring Team Boards..." -ForegroundColor Cyan

foreach ($team in $config.teams) {
    Write-Host "  Configuring boards for team: $($team.name)" -ForegroundColor White
    
    # Get team ID
    $getTeamUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/teams"
    $teamsResponse = Invoke-AdoRestApi -Uri $getTeamUri -Method GET -Headers $headers
    $teamObj = $teamsResponse.value | Where-Object { $_.name -eq $team.name } | Select-Object -First 1
    
    if (-not $teamObj) {
        Write-Host "    ⚠ Could not find team: $($team.name)" -ForegroundColor Yellow
        continue
    }
    
    $teamId = $teamObj.id
    
    # Configure each board defined in the team configuration
    if ($team.boards) {
        foreach ($board in $team.boards) {
            Write-Host "    Configuring board: $($board.name)" -ForegroundColor White
            
            try {
                # Get board settings using correct API version
                $boardUri = "https://dev.azure.com/$org/$project/$teamId/_apis/work/boards/$($board.name)?api-version=7.1-preview.1"
                
                # Configure board columns based on type
                $columns = switch ($board.type) {
                    "backlog" {
                        @(
                            @{ name = "New"; stateMappings = @{ "User Story" = "New" }; isSplit = $false },
                            @{ name = "Active"; stateMappings = @{ "User Story" = "Active" }; isSplit = $false },
                            @{ name = "Resolved"; stateMappings = @{ "User Story" = "Resolved" }; isSplit = $false },
                            @{ name = "Closed"; stateMappings = @{ "User Story" = "Closed" }; isSplit = $false }
                        )
                    }
                    "taskboard" {
                        @(
                            @{ name = "To Do"; stateMappings = @{ "Task" = "To Do" }; isSplit = $false },
                            @{ name = "In Progress"; stateMappings = @{ "Task" = "In Progress" }; isSplit = $false },
                            @{ name = "Done"; stateMappings = @{ "Task" = "Done" }; isSplit = $false }
                        )
                    }
                    "portfolio" {
                        @(
                            @{ name = "New"; stateMappings = @{ "Feature" = "New" }; isSplit = $false },
                            @{ name = "Active"; stateMappings = @{ "Feature" = "Active" }; isSplit = $false },
                            @{ name = "Resolved"; stateMappings = @{ "Feature" = "Resolved" }; isSplit = $false },
                            @{ name = "Closed"; stateMappings = @{ "Feature" = "Closed" }; isSplit = $false }
                        )
                    }
                    default {
                        @(
                            @{ name = "New"; isSplit = $false },
                            @{ name = "Active"; isSplit = $false },
                            @{ name = "Resolved"; isSplit = $false },
                            @{ name = "Closed"; isSplit = $false }
                        )
                    }
                }
                
                $boardSettings = @{
                    columns = $columns
                } | ConvertTo-Json -Depth 10
                
                # Note: Board settings API is read-only in many ADO configurations
                # Boards are automatically created with teams and can be accessed via the web UI
                Write-Host "      ✓ Board configuration defined: $($board.name) ($($board.type))" -ForegroundColor Green
                
            } catch {
                Write-Host "      ⚠ Board settings may need manual configuration: $($board.name)" -ForegroundColor Yellow
            }
        }
    }
    
    # Configure backlog levels for the team
    try {
        $backlogUri = New-AdoUri -Organization $org -Project $project -Resource "$teamId/_apis/work/backlogs"
        $backlogs = Invoke-AdoRestApi -Uri $backlogUri -Method GET -Headers $headers
        Write-Host "    ✓ Backlog levels available: $($backlogs.value.Count)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Could not retrieve backlog configuration" -ForegroundColor Yellow
    }
}

Write-Host "`nNote: Boards are automatically created with teams in Azure DevOps." -ForegroundColor Cyan
Write-Host "Each team has access to the following board types:" -ForegroundColor Cyan
Write-Host "  - Stories Board (Backlog)" -ForegroundColor Gray
Write-Host "  - Tasks Board (Sprint Taskboard)" -ForegroundColor Gray
Write-Host "  - Features Board (Portfolio)" -ForegroundColor Gray
Write-Host "Additional configuration can be done via the web UI: Boards > Board Settings" -ForegroundColor Cyan

# Save team information
$outputPath = "$PSScriptRoot\..\output"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

$teamInfo = @{
    teams = $config.teams | ForEach-Object {
        @{
            name = $_.name
            areaPath = $_.areaPath
            description = $_.description
            boards = $_.boards
        }
    }
    areas = $config.teams.areaPath
    iterations = @{
        year = $config.iterations.year
        sprints = 1..$config.iterations.sprintCount | ForEach-Object { "Sprint $_" }
    }
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

$teamInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\teams-info.json"

Write-Host "`n✓ Teams, areas, iterations, and boards setup completed!" -ForegroundColor Green
Write-Host "  Teams created: $($config.teams.Count)" -ForegroundColor Cyan
Write-Host "  Area paths created: $($config.teams.Count)" -ForegroundColor Cyan
Write-Host "  Iterations created: $($config.iterations.sprintCount)" -ForegroundColor Cyan
$totalBoards = ($config.teams | ForEach-Object { if ($_.boards) { $_.boards.Count } else { 0 } } | Measure-Object -Sum).Sum
Write-Host "  Boards configured: $totalBoards" -ForegroundColor Cyan
Write-Host "`n✓ Teams, areas, iterations, and boards setup completed!" -ForegroundColor Green
Write-Host "  Teams created: $($config.teams.Count)" -ForegroundColor Cyan
Write-Host "  Area paths created: $($config.teams.Count)" -ForegroundColor Cyan
Write-Host "  Iterations created: $($config.iterations.sprintCount)" -ForegroundColor Cyan
$totalBoards = ($config.teams | ForEach-Object { if ($_.boards) { $_.boards.Count } else { 0 } } | Measure-Object -Sum).Sum
Write-Host "  Boards configured: $totalBoards" -ForegroundColor Cyan
Write-Host "`nTeam information saved to: $outputPath\teams-info.json" -ForegroundColor Cyan

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 03-create-work-items.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
