# 03 - Create Work Items
# This script creates a hierarchical structure of work items (Epics, Features, User Stories, Tasks, Bugs)

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

Write-Host "Creating work items for project '$project'..." -ForegroundColor Green

# Arrays to store created work item IDs
$epicIds = @()
$featureIds = @()
$userStoryIds = @()
$taskIds = @()
$bugIds = @()

# Sample data arrays
$epicTitles = @(
    "Customer Portal Modernization",
    "Performance Optimization Initiative",
    "Security Compliance Enhancement",
    "Mobile Application Development",
    "Analytics and Reporting Platform"
)

$featureTemplates = @(
    "User Authentication System",
    "Dashboard Analytics",
    "API Integration Layer",
    "Data Export Functionality",
    "Notification Service",
    "Search Optimization",
    "Cache Implementation",
    "Logging Framework",
    "Configuration Management",
    "Error Handling System"
)

$storyTemplates = @(
    "implement login functionality",
    "create user profile page",
    "add data validation",
    "implement search feature",
    "add export to CSV",
    "create notification system",
    "implement caching layer",
    "add error logging",
    "create admin dashboard",
    "implement API endpoints"
)

$taskTemplates = @(
    "Design database schema",
    "Create API endpoints",
    "Write unit tests",
    "Update documentation",
    "Code review",
    "Deploy to staging",
    "Performance testing",
    "Security audit",
    "Integration testing",
    "Bug fixes"
)

$bugSeverities = @("1 - Critical", "2 - High", "3 - Medium", "4 - Low")
$bugPriorities = @(1, 2, 3, 4)
# Note: Using default "New" state for all work items to avoid validation errors
# Work items can be transitioned to other states manually after creation
$epicStates = @("New")
$featureStates = @("New")
$storyStates = @("New")
$taskStates = @("New")
$bugStates = @("New")

# ===== CREATE EPICS =====
Write-Host "`n[1/5] Creating Epics..." -ForegroundColor Cyan

for ($i = 0; $i -lt $config.workItemCounts.epics; $i++) {
    $epicTitle = $epicTitles[$i % $epicTitles.Count]
    $areaPath = $project  # Use root project area for simplicity
    $iteration = $project  # Use root iteration path for simplicity
    
    Write-Host "  Creating Epic $($i+1)/$($config.workItemCounts.epics): $epicTitle" -ForegroundColor White
    
    $epicBody = @(
        @{
            op = "add"
            path = "/fields/System.Title"
            value = "$epicTitle - Epic $($i+1)"
        },
        @{
            op = "add"
            path = "/fields/System.Description"
            value = "This epic encompasses the strategic initiative for $epicTitle. It includes multiple features and user stories to deliver comprehensive functionality."
        },
        @{
            op = "add"
            path = "/fields/System.AreaPath"
            value = $areaPath
        },
        @{
            op = "add"
            path = "/fields/System.IterationPath"
            value = $iteration
        },
        @{
            op = "add"
            path = "/fields/System.State"
            value = $epicStates[$i % $epicStates.Count]
        },
        @{
            op = "add"
            path = "/fields/System.Tags"
            value = ($config.tags | Get-Random -Count 2) -join "; "
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Common.Priority"
            value = ($i % 4) + 1
        }
    )
    
    $epicUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/`$Epic"
    $epic = Invoke-AdoRestApi -Uri $epicUri -Method POST -Headers $headers -Body $epicBody
    $epicIds += $epic.id
    
    Write-Host "    ✓ Created Epic ID: $($epic.id)" -ForegroundColor Green
}

# ===== CREATE FEATURES =====
Write-Host "`n[2/5] Creating Features..." -ForegroundColor Cyan

for ($i = 0; $i -lt $config.workItemCounts.features; $i++) {
    $featureTitle = $featureTemplates[$i % $featureTemplates.Count]
    $parentEpicId = $epicIds[$i % $epicIds.Count]
    $areaPath = $project  # Use root project area for simplicity
    $iteration = $project
    $assignedTo = Get-RandomUser -Config $config
    
    Write-Host "  Creating Feature $($i+1)/$($config.workItemCounts.features): $featureTitle" -ForegroundColor White
    
    $featureBody = @(
        @{
            op = "add"
            path = "/fields/System.Title"
            value = "$featureTitle - Feature $($i+1)"
        },
        @{
            op = "add"
            path = "/fields/System.Description"
            value = "Feature for implementing $featureTitle with comprehensive functionality and testing."
        },
        @{
            op = "add"
            path = "/fields/System.AreaPath"
            value = $areaPath
        },
        @{
            op = "add"
            path = "/fields/System.IterationPath"
            value = $iteration
        },
        @{
            op = "add"
            path = "/fields/System.State"
            value = $featureStates[$i % $featureStates.Count]
        },
        @{
            op = "add"
            path = "/fields/System.Tags"
            value = ($config.tags | Get-Random -Count 2) -join "; "
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Common.Priority"
            value = ($i % 4) + 1
        },
        @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "System.LinkTypes.Hierarchy-Reverse"
                url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$parentEpicId"
            }
        }
    )
    
    if ($assignedTo) {
        $featureBody += @{
            op = "add"
            path = "/fields/System.AssignedTo"
            value = $assignedTo
        }
    }
    
    $featureUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/`$Feature"
    $feature = Invoke-AdoRestApi -Uri $featureUri -Method POST -Headers $headers -Body $featureBody
    $featureIds += $feature.id
    
    Write-Host "    ✓ Created Feature ID: $($feature.id) (Parent Epic: $parentEpicId)" -ForegroundColor Green
}

# ===== CREATE USER STORIES =====
Write-Host "`n[3/5] Creating User Stories..." -ForegroundColor Cyan

# Try to get available iterations from the project
$iterationsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/classificationnodes/iterations?`$depth=2"
$availableIterations = @()
try {
    $iterationsResponse = Invoke-AdoRestApi -Uri $iterationsUri -Method GET -Headers $headers
    if ($iterationsResponse.children) {
        foreach ($year in $iterationsResponse.children) {
            if ($year.children) {
                foreach ($sprint in $year.children) {
                    $availableIterations += $sprint.path
                }
            }
        }
    }
    Write-Host "  Found $($availableIterations.Count) iterations available" -ForegroundColor Cyan
} catch {
    Write-Host "  Could not retrieve iterations, will use project root" -ForegroundColor Yellow
}

for ($i = 0; $i -lt $config.workItemCounts.userStories; $i++) {
    $storyTitle = $storyTemplates[$i % $storyTemplates.Count]
    $parentFeatureId = $featureIds[$i % $featureIds.Count]
    $areaPath = $project  # Use root project area for simplicity
    
    # Assign to a sprint if available, otherwise use project root
    if ($availableIterations.Count -gt 0) {
        $iteration = $availableIterations[$i % $availableIterations.Count]
    } else {
        $iteration = $project
    }
    
    $assignedTo = Get-RandomUser -Config $config
    
    Write-Host "  Creating User Story $($i+1)/$($config.workItemCounts.userStories): $storyTitle" -ForegroundColor White
    
    $storyBody = @(
        @{
            op = "add"
            path = "/fields/System.Title"
            value = "As a user, I want to $storyTitle - Story $($i+1)"
        },
        @{
            op = "add"
            path = "/fields/System.Description"
            value = @"
<div>As a user, I want to $storyTitle so that I can achieve my goals efficiently.</div>
<br/>
<div><b>Acceptance Criteria:</b></div>
<ul>
<li>Functionality works as expected</li>
<li>All edge cases are handled</li>
<li>Unit tests are written and passing</li>
<li>Documentation is updated</li>
</ul>
"@
        },
        @{
            op = "add"
            path = "/fields/System.AreaPath"
            value = $areaPath
        },
        @{
            op = "add"
            path = "/fields/System.IterationPath"
            value = $iteration
        },
        @{
            op = "add"
            path = "/fields/System.State"
            value = $storyStates[$i % $storyStates.Count]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Scheduling.StoryPoints"
            value = @(1, 2, 3, 5, 8)[$i % 5]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Common.Priority"
            value = ($i % 4) + 1
        },
        @{
            op = "add"
            path = "/fields/System.Tags"
            value = ($config.tags | Get-Random -Count 3) -join "; "
        },
        @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "System.LinkTypes.Hierarchy-Reverse"
                url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$parentFeatureId"
            }
        }
    )
    
    if ($assignedTo) {
        $storyBody += @{
            op = "add"
            path = "/fields/System.AssignedTo"
            value = $assignedTo
        }
    }
    
    $storyUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/`$User Story"
    $story = Invoke-AdoRestApi -Uri $storyUri -Method POST -Headers $headers -Body $storyBody
    $userStoryIds += $story.id
    
    if ($i % 10 -eq 0) {
        Write-Host "    ✓ Created $($i+1) user stories..." -ForegroundColor Green
    }
}

Write-Host "    ✓ All user stories created!" -ForegroundColor Green

# ===== CREATE TASKS =====
Write-Host "`n[4/5] Creating Tasks..." -ForegroundColor Cyan

for ($i = 0; $i -lt $config.workItemCounts.tasks; $i++) {
    $taskTitle = $taskTemplates[$i % $taskTemplates.Count]
    $parentStoryId = $userStoryIds[$i % $userStoryIds.Count]
    $areaPath = $project  # Use root project area for simplicity
    $iteration = $project
    $assignedTo = Get-RandomUser -Config $config
    
    if ($i % 20 -eq 0) {
        Write-Host "  Creating Tasks $($i+1)-$([Math]::Min($i+20, $config.workItemCounts.tasks))..." -ForegroundColor White
    }
    
    $taskBody = @(
        @{
            op = "add"
            path = "/fields/System.Title"
            value = "$taskTitle - Task $($i+1)"
        },
        @{
            op = "add"
            path = "/fields/System.Description"
            value = "Task to $taskTitle with proper implementation and testing."
        },
        @{
            op = "add"
            path = "/fields/System.AreaPath"
            value = $areaPath
        },
        @{
            op = "add"
            path = "/fields/System.IterationPath"
            value = $iteration
        },
        @{
            op = "add"
            path = "/fields/System.State"
            value = $taskStates[$i % $taskStates.Count]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Scheduling.OriginalEstimate"
            value = @(2, 4, 6, 8, 16)[$i % 5]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Scheduling.RemainingWork"
            value = @(0, 2, 4)[$i % 3]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Scheduling.CompletedWork"
            value = @(2, 4, 6)[$i % 3]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Common.Activity"
            value = @("Development", "Testing", "Documentation", "Deployment")[$i % 4]
        },
        @{
            op = "add"
            path = "/fields/System.Tags"
            value = ($config.tags | Get-Random -Count 2) -join "; "
        },
        @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "System.LinkTypes.Hierarchy-Reverse"
                url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$parentStoryId"
            }
        }
    )
    
    if ($assignedTo) {
        $taskBody += @{
            op = "add"
            path = "/fields/System.AssignedTo"
            value = $assignedTo
        }
    }
    
    $taskUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/`$Task"
    $task = Invoke-AdoRestApi -Uri $taskUri -Method POST -Headers $headers -Body $taskBody
    $taskIds += $task.id
}

Write-Host "    ✓ All tasks created!" -ForegroundColor Green

# ===== CREATE BUGS =====
Write-Host "`n[5/5] Creating Bugs..." -ForegroundColor Cyan

for ($i = 0; $i -lt $config.workItemCounts.bugs; $i++) {
    $relatedStoryId = $userStoryIds[$i % $userStoryIds.Count]
    $areaPath = $project  # Use root project area for simplicity
    $iteration = $project
    $assignedTo = Get-RandomUser -Config $config
    
    Write-Host "  Creating Bug $($i+1)/$($config.workItemCounts.bugs)" -ForegroundColor White
    
    $bugBody = @(
        @{
            op = "add"
            path = "/fields/System.Title"
            value = "Bug: Issue with functionality - Bug $($i+1)"
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.TCM.ReproSteps"
            value = @"
<div><b>Steps to Reproduce:</b></div>
<ol>
<li>Navigate to the feature</li>
<li>Perform the action</li>
<li>Observe the error</li>
</ol>
<div><b>Expected Result:</b> Feature works correctly</div>
<div><b>Actual Result:</b> Error occurs</div>
"@
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.TCM.SystemInfo"
            value = "OS: Windows 11, Browser: Chrome 120, Environment: Production"
        },
        @{
            op = "add"
            path = "/fields/System.AreaPath"
            value = $areaPath
        },
        @{
            op = "add"
            path = "/fields/System.IterationPath"
            value = $iteration
        },
        @{
            op = "add"
            path = "/fields/System.State"
            value = $bugStates[$i % $bugStates.Count]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Common.Severity"
            value = $bugSeverities[$i % $bugSeverities.Count]
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Common.Priority"
            value = $bugPriorities[$i % $bugPriorities.Count]
        },
        @{
            op = "add"
            path = "/fields/System.Tags"
            value = "bug-fix; " + (($config.tags | Get-Random -Count 2) -join "; ")
        },
        @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "System.LinkTypes.Related"
                url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$relatedStoryId"
            }
        }
    )
    
    if ($assignedTo) {
        $bugBody += @{
            op = "add"
            path = "/fields/System.AssignedTo"
            value = $assignedTo
        }
    }
    
    $bugUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/`$Bug"
    $bug = Invoke-AdoRestApi -Uri $bugUri -Method POST -Headers $headers -Body $bugBody
    $bugIds += $bug.id
    
    Write-Host "    ✓ Created Bug ID: $($bug.id)" -ForegroundColor Green
}

# Save work item information
$outputPath = "$PSScriptRoot\..\output"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# ===== ADD WORK ITEM COMMENTS =====
Write-Host "`n[6/8] Adding comments to work items..." -ForegroundColor Cyan

$comments = @(
    "This looks good! Let's proceed with implementation.",
    "Can we get more details on the requirements?",
    "I've started working on this task.",
    "Blocked waiting for API documentation.",
    "Code review completed - LGTM!",
    "Updated based on feedback from stakeholders.",
    "Testing completed successfully.",
    "Found an issue during integration testing.",
    "Documentation needs to be updated.",
    "This is ready for deployment."
)

# Add comments to a subset of work items
$itemsToComment = ($userStoryIds + $taskIds + $bugIds) | Get-Random -Count (($userStoryIds.Count + $taskIds.Count + $bugIds.Count) / 3)

foreach ($workItemId in $itemsToComment) {
    $commentCount = Get-Random -Minimum 1 -Maximum 4
    
    for ($c = 0; $c -lt $commentCount; $c++) {
        $commentText = $comments | Get-Random
        
        $commentBody = @{
            text = $commentText
        }
        
        $commentUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$workItemId/comments" -ApiVersion "7.0"
        
        try {
            Invoke-AdoRestApi -Uri $commentUri -Method POST -Headers $headers -Body $commentBody | Out-Null
        } catch {
            # Comments may not be supported in all configurations
        }
    }
}

Write-Host "  ✓ Added comments to $(($itemsToComment.Count)) work items" -ForegroundColor Green

# ===== ADD WORK ITEM ATTACHMENTS =====
Write-Host "`n[7/8] Adding attachments to work items..." -ForegroundColor Cyan

# Create sample attachment content
$sampleDocContent = @"
# Requirements Document

## Overview
This document outlines the requirements for this work item.

## Functional Requirements
1. User authentication
2. Data validation
3. Error handling

## Non-Functional Requirements
1. Performance: Response time < 2s
2. Security: OAuth 2.0 implementation
3. Scalability: Support 10,000 concurrent users
"@

$sampleImageContent = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="  # 1x1 red pixel PNG

# Add attachments to a subset of user stories
$itemsToAttach = $userStoryIds | Get-Random -Count ([Math]::Min(10, $userStoryIds.Count))

foreach ($workItemId in $itemsToAttach) {
    # Upload document attachment
    $docBytes = [System.Text.Encoding]::UTF8.GetBytes($sampleDocContent)
    $docBase64 = [Convert]::ToBase64String($docBytes)
    
    $attachmentUri = "https://dev.azure.com/$org/$project/_apis/wit/attachments?fileName=requirements.md&api-version=7.0"
    $attachmentHeaders = @{
        "Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($config.pat)")))"
        "Content-Type" = "application/octet-stream"
    }
    
    try {
        $uploadedAttachment = Invoke-RestMethod -Uri $attachmentUri -Method POST -Headers $attachmentHeaders -Body $docBytes
        
        # Link attachment to work item
        $linkBody = @(
            @{
                op = "add"
                path = "/relations/-"
                value = @{
                    rel = "AttachedFile"
                    url = $uploadedAttachment.url
                    attributes = @{
                        comment = "Requirements document"
                    }
                }
            }
        )
        
        $workItemUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$workItemId"
        Invoke-AdoRestApi -Uri $workItemUri -Method PATCH -Headers $headers -Body $linkBody | Out-Null
    } catch {
        # Attachments may fail in some configurations
    }
}

Write-Host "  ✓ Added attachments to $(($itemsToAttach.Count)) work items" -ForegroundColor Green

# ===== ADD CUSTOM FIELDS AND HISTORY =====
Write-Host "`n[8/8] Adding custom field updates to create history..." -ForegroundColor Cyan

# Update some work items to create history
$itemsToUpdate = ($userStoryIds + $bugIds) | Get-Random -Count ([Math]::Min(15, ($userStoryIds.Count + $bugIds.Count)))

foreach ($workItemId in $itemsToUpdate) {
    # Make multiple updates to create history
    $updates = @(
        @{
            op = "add"
            path = "/fields/System.History"
            value = "Initial analysis completed. Ready for development."
        },
        @{
            op = "replace"
            path = "/fields/Microsoft.VSTS.Common.Priority"
            value = (Get-Random -Minimum 1 -Maximum 4)
        }
    )
    
    $updateUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$workItemId"
    
    try {
        Invoke-AdoRestApi -Uri $updateUri -Method PATCH -Headers $headers -Body $updates | Out-Null
        Start-Sleep -Milliseconds 500
        
        # Second update
        $updates2 = @(
            @{
                op = "add"
                path = "/fields/System.History"
                value = "Development in progress. Implemented core functionality."
            }
        )
        
        Invoke-AdoRestApi -Uri $updateUri -Method PATCH -Headers $headers -Body $updates2 | Out-Null
    } catch {
        # Updates may fail in some scenarios
    }
}

Write-Host "  ✓ Updated $(($itemsToUpdate.Count)) work items to create history" -ForegroundColor Green

# Save work item information
$workItemInfo = @{
    epics = $epicIds
    features = $featureIds
    userStories = $userStoryIds
    tasks = $taskIds
    bugs = $bugIds
    totalCount = $epicIds.Count + $featureIds.Count + $userStoryIds.Count + $taskIds.Count + $bugIds.Count
    commentsAdded = $itemsToComment.Count
    attachmentsAdded = $itemsToAttach.Count
    historyUpdates = $itemsToUpdate.Count
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

$workItemInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\work-items-info.json"

Write-Host "`n✓ Work items creation completed!" -ForegroundColor Green
Write-Host "  Epics: $($epicIds.Count)" -ForegroundColor Cyan
Write-Host "  Features: $($featureIds.Count)" -ForegroundColor Cyan
Write-Host "  User Stories: $($userStoryIds.Count)" -ForegroundColor Cyan
Write-Host "  Tasks: $($taskIds.Count)" -ForegroundColor Cyan
Write-Host "  Bugs: $($bugIds.Count)" -ForegroundColor Cyan
Write-Host "  Total: $($workItemInfo.totalCount)" -ForegroundColor Cyan
Write-Host "`nWork item information saved to: $outputPath\work-items-info.json" -ForegroundColor Cyan

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 04-create-test-management.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
