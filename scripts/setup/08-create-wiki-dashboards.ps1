# 08 - Create Wiki, Dashboards, and Queries
# This script creates project wiki, dashboards with widgets, and shared queries

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\..\..\utils\config.json"
)

# Import helper functions
. "$PSScriptRoot\..\..\utils\ado-api-helper.ps1"

# Load configuration
Write-Host "Loading configuration..." -ForegroundColor Green
$config = Get-AdoConfig -ConfigPath $ConfigPath
$headers = Get-AdoHeaders -Pat $config.pat
$project = $config.project
$org = $config.organization

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Creating Wiki, Dashboards, and Queries" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================
# Step 1: Create Project Wiki
# ============================================
Write-Host "Step 1: Creating Project Wiki..." -ForegroundColor Green

try {
    # Create project wiki with correct headers
    $wikiBody = @{
        name = "$project Wiki"
        type = "projectWiki"
    } | ConvertTo-Json -Depth 10

    $wikiHeaders = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
    $wikiUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wiki/wikis" -ApiVersion "7.1-preview.2"
    $wiki = Invoke-AdoRestApi -Uri $wikiUri -Method POST -Headers $wikiHeaders -Body $wikiBody
    
    Write-Host "  ✓ Created project wiki: $($wiki.name)" -ForegroundColor Green
    
    # Wait for wiki to be ready
    Start-Sleep -Seconds 2
    
    # Create wiki pages
    $wikiPages = @(
        @{
            path = "/Home"
            content = @"
# Welcome to $project Wiki

This is the main wiki for the ADO Migration Test project.

## Purpose
This project contains comprehensive sample data for testing Azure DevOps to GitHub migration tools.

## Contents
- [Getting Started](/Getting-Started)
- [Architecture](/Architecture)
- [Testing Guide](/Testing-Guide)
- [Migration Checklist](/Migration-Checklist)

## Quick Links
- [Work Items](/$project/_workitems)
- [Boards](/$project/_boards)
- [Repos](/$project/_git)
- [Pipelines](/$project/_build)
- [Test Plans](/$project/_testManagement)

Last updated: $(Get-Date -Format "yyyy-MM-dd")
"@
        },
        @{
            path = "/Getting-Started"
            content = @"
# Getting Started

## Prerequisites
- Azure DevOps account
- Project access
- Git installed

## Initial Setup
1. Clone the repository
2. Configure your environment
3. Run the setup scripts

## Work Item Types
- **Epics**: High-level business objectives
- **Features**: Major functionality areas
- **User Stories**: User-focused requirements
- **Tasks**: Individual work items
- **Bugs**: Defects and issues
"@
        },
        @{
            path = "/Architecture"
            content = @"
# System Architecture

## Components
### Frontend
- React SPA
- TypeScript
- Material-UI

### Backend
- .NET Core Web API
- Entity Framework Core
- SQL Server

### Infrastructure
- Azure App Service
- Azure SQL Database
- Azure DevOps Pipelines

## Integration Points
- REST APIs
- Message queues
- Event-driven architecture
"@
        },
        @{
            path = "/Testing-Guide"
            content = @"
# Testing Guide

## Test Strategy
- Unit Testing
- Integration Testing
- End-to-End Testing
- Performance Testing
- Security Testing

## Test Plans
1. **Integration Test Plan**: API and service integration
2. **Regression Test Plan**: Ensure no breaking changes
3. **UAT Plan**: User acceptance criteria
4. **Performance Test Plan**: Load and stress testing
5. **Security Test Plan**: Vulnerability assessment

## Test Execution
- Manual test cases
- Automated test suites
- CI/CD integration
"@
        },
        @{
            path = "/Migration-Checklist"
            content = @"
# ADO to GitHub Migration Checklist

## Work Items
- [ ] All work item types migrated
- [ ] Work item links preserved
- [ ] Attachments transferred
- [ ] Comments and history maintained
- [ ] Custom fields mapped

## Repositories
- [ ] Source code migrated
- [ ] Branch structure preserved
- [ ] Commit history intact
- [ ] Tags and releases transferred

## Pipelines
- [ ] Build pipelines converted
- [ ] Release pipelines migrated
- [ ] Variable groups transferred
- [ ] Service connections recreated

## Test Management
- [ ] Test plans migrated
- [ ] Test cases transferred
- [ ] Test results preserved
"@
        }
    )
    
    foreach ($page in $wikiPages) {
        $pageUri = New-AdoUri -Organization $org -Project $project -Resource "wiki/wikis/$($wiki.id)/pages" -ApiVersion "7.0"
        $pageUri += "?path=$($page.path)"
        
        $pageBody = @{
            content = $page.content
        } | ConvertTo-Json -Depth 10
        
        $createdPage = Invoke-AdoRestApi -Uri $pageUri -Method PUT -Headers $headers -Body $pageBody
        Write-Host "  ✓ Created wiki page: $($page.path)" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }
    
} catch {
    Write-Host "  ✗ Error creating wiki: $_" -ForegroundColor Red
}

# ============================================
# Step 2: Create Shared Queries
# ============================================
Write-Host "`nStep 2: Creating Shared Queries..." -ForegroundColor Green

try {
    # Get the Shared Queries folder ID
    $queriesUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/queries/Shared Queries" -ApiVersion "7.0"
    $sharedQueriesFolder = Invoke-AdoRestApi -Uri $queriesUri -Method GET -Headers $headers
    
    $queries = @(
        @{
            name = "Active User Stories"
            wiql = "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo] FROM WorkItems WHERE [System.WorkItemType] = 'User Story' AND [System.State] = 'Active' ORDER BY [System.ChangedDate] DESC"
        },
        @{
            name = "Critical Bugs"
            wiql = "SELECT [System.Id], [System.Title], [Microsoft.VSTS.Common.Severity], [System.AssignedTo] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [Microsoft.VSTS.Common.Severity] = '1 - Critical' AND [System.State] <> 'Closed' ORDER BY [System.CreatedDate] DESC"
        },
        @{
            name = "My Work Items"
            wiql = "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] <> 'Closed' AND [System.State] <> 'Removed' ORDER BY [System.ChangedDate] DESC"
        },
        @{
            name = "Sprint Backlog"
            wiql = "SELECT [System.Id], [System.Title], [System.State], [Microsoft.VSTS.Scheduling.StoryPoints] FROM WorkItems WHERE [System.IterationPath] = @CurrentIteration AND [System.WorkItemType] IN ('User Story', 'Bug') ORDER BY [Microsoft.VSTS.Common.Priority]"
        },
        @{
            name = "Blocked Work Items"
            wiql = "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], [System.Tags] FROM WorkItems WHERE [System.Tags] CONTAINS 'Blocked' ORDER BY [System.ChangedDate] DESC"
        },
        @{
            name = "Test Cases Not Automated"
            wiql = "SELECT [System.Id], [System.Title], [Microsoft.VSTS.TCM.AutomationStatus] FROM WorkItems WHERE [System.WorkItemType] = 'Test Case' AND [Microsoft.VSTS.TCM.AutomationStatus] = 'Not Automated' ORDER BY [System.Title]"
        },
        @{
            name = "Recently Completed"
            wiql = "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.ChangedDate] FROM WorkItems WHERE [System.State] IN ('Resolved', 'Closed', 'Done') AND [System.ChangedDate] >= @Today - 7 ORDER BY [System.ChangedDate] DESC"
        }
    )
    
    foreach ($queryDef in $queries) {
        $queryBody = @{
            name = $queryDef.name
            wiql = $queryDef.wiql
        } | ConvertTo-Json -Depth 10
        
        $queryHeaders = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
        $createQueryUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/queries/Shared Queries" -ApiVersion "7.1-preview.2"
        $query = Invoke-AdoRestApi -Uri $createQueryUri -Method POST -Headers $queryHeaders -Body $queryBody
        
        Write-Host "  ✓ Created query: $($queryDef.name)" -ForegroundColor Green
        Start-Sleep -Milliseconds 300
    }
    
} catch {
    Write-Host "  ✗ Error creating queries: $_" -ForegroundColor Red
}

# ============================================
# Step 3: Create Team Dashboards
# ============================================
Write-Host "`nStep 3: Creating Team Dashboards..." -ForegroundColor Green

try {
    foreach ($team in $config.teams) {
        $dashboardBody = @{
            name = "$($team.name) Dashboard"
            description = "Main dashboard for $($team.name)"
            widgets = @(
                @{
                    name = "Sprint Overview"
                    position = @{ row = 1; column = 1 }
                    size = @{ rowSpan = 1; columnSpan = 2 }
                    settings = $null
                    contributionId = "ms.vss-work-web.microsoft-sprint-overview-widget"
                },
                @{
                    name = "Assigned to me"
                    position = @{ row = 1; column = 3 }
                    size = @{ rowSpan = 1; columnSpan = 2 }
                    settings = $null
                    contributionId = "ms.vss-work-web.microsoft-assigned-to-me-widget"
                },
                @{
                    name = "Sprint Burndown"
                    position = @{ row = 2; column = 1 }
                    size = @{ rowSpan = 2; columnSpan = 2 }
                    settings = $null
                    contributionId = "ms.vss-work-web.microsoft-burndown-widget"
                },
                @{
                    name = "Sprint Capacity"
                    position = @{ row = 2; column = 3 }
                    size = @{ rowSpan = 1; columnSpan = 2 }
                    settings = $null
                    contributionId = "ms.vss-work-web.microsoft-capacity-widget"
                },
                @{
                    name = "Velocity"
                    position = @{ row = 3; column = 3 }
                    size = @{ rowSpan = 1; columnSpan = 2 }
                    settings = $null
                    contributionId = "ms.vss-work-web.microsoft-velocity-widget"
                }
            )
        } | ConvertTo-Json -Depth 10
        
        $dashboardHeaders = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
        $dashboardUri = "https://dev.azure.com/$org/$project/_apis/dashboard/dashboards?api-version=7.1-preview.3"
        $dashboard = Invoke-AdoRestApi -Uri $dashboardUri -Method POST -Headers $dashboardHeaders -Body $dashboardBody
        
        Write-Host "  ✓ Created dashboard for: $($team.name)" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }
    
} catch {
    Write-Host "  ✗ Error creating dashboards: $_" -ForegroundColor Red
    Write-Host "  Note: Dashboard creation may require additional permissions" -ForegroundColor Yellow
}

# ============================================
# Step 4: Create Query Folders
# ============================================
Write-Host "`nStep 4: Creating Query Folders..." -ForegroundColor Green

try {
    $queryFolders = @("Team Queries", "Sprint Queries", "Reports")
    
    foreach ($folderName in $queryFolders) {
        $folderBody = @{
            name = $folderName
            isFolder = $true
        } | ConvertTo-Json -Depth 10
        
        $folderHeaders = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
        $folderUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/queries/Shared Queries" -ApiVersion "7.1-preview.2"
        $folder = Invoke-AdoRestApi -Uri $folderUri -Method POST -Headers $folderHeaders -Body $folderBody
        
        Write-Host "  ✓ Created query folder: $folderName" -ForegroundColor Green
        Start-Sleep -Milliseconds 300
    }
    
} catch {
    Write-Host "  ✗ Error creating query folders: $_" -ForegroundColor Red
}

# ============================================
# Summary
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Wiki, Dashboards, and Queries Creation Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  ✓ Project wiki created with multiple pages" -ForegroundColor Green
Write-Host "  ✓ Shared queries created (7 queries)" -ForegroundColor Green
Write-Host "  ✓ Team dashboards created" -ForegroundColor Green
Write-Host "  ✓ Query folders organized" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  - Review wiki pages in Azure DevOps" -ForegroundColor White
Write-Host "  - Customize dashboards with additional widgets" -ForegroundColor White
Write-Host "  - Add more queries as needed" -ForegroundColor White
Write-Host "  - Configure dashboard permissions" -ForegroundColor White
