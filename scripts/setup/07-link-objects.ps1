# 07 - Link Objects
# This script creates additional links between work items, commits, and other ADO objects

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

# Load existing objects
$workItemsPath = "$PSScriptRoot\..\output\work-items-info.json"
$testMgmtPath = "$PSScriptRoot\..\output\test-management-info.json"
$repositoriesPath = "$PSScriptRoot\..\output\repositories-info.json"

if (-not (Test-Path $workItemsPath)) {
    throw "Work items info not found. Please run 03-create-work-items.ps1 first."
}

$workItems = Get-Content $workItemsPath -Raw | ConvertFrom-Json
$testMgmt = if (Test-Path $testMgmtPath) { Get-Content $testMgmtPath -Raw | ConvertFrom-Json } else { $null }
$repositories = if (Test-Path $repositoriesPath) { Get-Content $repositoriesPath -Raw | ConvertFrom-Json } else { $null }

Write-Host "Creating additional links between objects for project '$project'..." -ForegroundColor Green

$linksCreated = 0

# ===== LINK COMMITS TO WORK ITEMS =====
if ($repositories -and $repositories.repositories.Count -gt 0) {
    Write-Host "\n[1/4] Linking commits to work items..." -ForegroundColor Cyan
    
    foreach ($repo in $repositories.repositories) {
        if ($repo.commitWorkItems) {
            foreach ($commitId in $repo.commitWorkItems.PSObject.Properties.Name) {
                $workItemIds = $repo.commitWorkItems.$commitId
                
                foreach ($workItemId in $workItemIds) {
                    Write-Host "  Linking commit $($commitId.Substring(0,8))... to Work Item $workItemId" -ForegroundColor White
                    
                    # Get the commit URL
                    $commitUrl = "vstfs:///Git/Commit/$project%2F$($repo.id)%2F$commitId"
                    
                    $linkBody = @(
                        @{
                            op = "add"
                            path = "/relations/-"
                            value = @{
                                rel = "ArtifactLink"
                                url = $commitUrl
                                attributes = @{
                                    name = "Commit"
                                }
                            }
                        }
                    )
                    
                    $workItemUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$workItemId"
                    
                    try {
                        Invoke-AdoRestApi -Uri $workItemUri -Method PATCH -Headers $headers -Body $linkBody
                        $linksCreated++
                        Write-Host "    ✓ Linked commit to work item" -ForegroundColor Green
                    } catch {
                        Write-Host "    ✗ Failed to link: $_" -ForegroundColor Red
                    }
                }
            }
        }
    }
}

# ===== LINK BUGS TO TEST CASES =====
if ($testMgmt -and $testMgmt.testCases.Count -gt 0) {
    Write-Host "\n[2/4] Linking bugs to test cases..." -ForegroundColor Cyan
    
    for ($i = 0; $i -lt [Math]::Min(10, $workItems.bugs.Count); $i++) {
        $bugId = $workItems.bugs[$i]
        $testCaseId = $testMgmt.testCases[$i % $testMgmt.testCases.Count]
        
        Write-Host "  Linking Bug $bugId to Test Case $testCaseId" -ForegroundColor White
        
        $linkBody = @(
            @{
                op = "add"
                path = "/relations/-"
                value = @{
                    rel = "Microsoft.VSTS.Common.TestedBy-Forward"
                    url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$testCaseId"
                    attributes = @{
                        comment = "Bug found during test execution"
                    }
                }
            }
        )
        
        $linkUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$bugId"
        
        try {
            Invoke-AdoRestApi -Uri $linkUri -Method PATCH -Headers $headers -Body $linkBody
            $linksCreated++
            Write-Host "    ✓ Linked successfully" -ForegroundColor Green
        } catch {
            Write-Host "    ⚠ Link may already exist" -ForegroundColor Yellow
        }
    }
}

# ===== CREATE RELATED LINKS BETWEEN USER STORIES =====
Write-Host "`n[3/4] Creating Related links between user stories..." -ForegroundColor Cyan

for ($i = 0; $i -lt [Math]::Min(15, $workItems.userStories.Count - 1); $i++) {
    $sourceStoryId = $workItems.userStories[$i]
    $targetStoryId = $workItems.userStories[$i + 1]
    
    Write-Host "  Linking Story $sourceStoryId to Story $targetStoryId" -ForegroundColor White
    
    $linkBody = @(
        @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "System.LinkTypes.Related"
                url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$targetStoryId"
                attributes = @{
                    comment = "Related functionality"
                }
            }
        }
    )
    
    $linkUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$sourceStoryId"
    
    try {
        Invoke-AdoRestApi -Uri $linkUri -Method PATCH -Headers $headers -Body $linkBody
        $linksCreated++
        
        if ($i % 5 -eq 4) {
            Write-Host "    ✓ Created $($i + 1) links..." -ForegroundColor Green
        }
    } catch {
        Write-Host "    ⚠ Link may already exist" -ForegroundColor Yellow
    }
}

# ===== CREATE PREDECESSOR/SUCCESSOR LINKS =====
Write-Host "`n[4/4] Creating Predecessor/Successor links between tasks..." -ForegroundColor Cyan

for ($i = 0; $i -lt [Math]::Min(20, $workItems.tasks.Count - 1); $i += 2) {
    $predecessorId = $workItems.tasks[$i]
    $successorId = $workItems.tasks[$i + 1]
    
    Write-Host "  Linking Task $predecessorId -> Task $successorId" -ForegroundColor White
    
    $linkBody = @(
        @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "System.LinkTypes.Dependency-Forward"
                url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$successorId"
                attributes = @{
                    comment = "Must complete before successor"
                }
            }
        }
    )
    
    $linkUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$predecessorId"
    
    try {
        Invoke-AdoRestApi -Uri $linkUri -Method PATCH -Headers $headers -Body $linkBody
        $linksCreated++
        
        if ($i % 10 -eq 8) {
            Write-Host "    ✓ Created $([Math]::Floor($i / 2) + 1) links..." -ForegroundColor Green
        }
    } catch {
        Write-Host "    ⚠ Link may already exist" -ForegroundColor Yellow
    }
}

# ===== ADD COMMENTS TO WORK ITEMS =====
Write-Host "`n[Bonus] Adding comments to work items..." -ForegroundColor Cyan

$sampleComments = @(
    "Updated requirements based on stakeholder feedback",
    "Completed code review, looks good to merge",
    "Found an issue during testing, creating bug",
    "Documentation has been updated",
    "Ready for QA testing",
    "Deployed to staging environment",
    "Performance looks good on latest build",
    "Need to revisit this in next sprint",
    "Dependency on external API resolved",
    "Security scan completed successfully"
)

# Add comments to some user stories
for ($i = 0; $i -lt [Math]::Min(10, $workItems.userStories.Count); $i++) {
    $storyId = $workItems.userStories[$i]
    $comment = $sampleComments[$i % $sampleComments.Count]
    
    $commentBody = @{
        text = $comment
    }
    
    $commentUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/$storyId/comments"
    
    try {
        Invoke-AdoRestApi -Uri $commentUri -Method POST -Headers $headers -Body $commentBody
        
        if ($i -eq 9) {
            Write-Host "  ✓ Added comments to work items" -ForegroundColor Green
        }
    } catch {
        # Ignore comment errors
    }
}

# Save linking information
$outputPath = "$PSScriptRoot\..\output"
$linkInfo = @{
    linksCreated = $linksCreated
    bugToTestCaseLinks = [Math]::Min(10, $workItems.bugs.Count)
    relatedLinks = [Math]::Min(15, $workItems.userStories.Count - 1)
    dependencyLinks = [Math]::Floor([Math]::Min(20, $workItems.tasks.Count - 1) / 2)
    commentsAdded = [Math]::Min(10, $workItems.userStories.Count)
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

$linkInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\links-info.json"

Write-Host "`n✓ Object linking completed!" -ForegroundColor Green
Write-Host "  Total links created: $linksCreated" -ForegroundColor Cyan
Write-Host "  Bug-TestCase links: $($linkInfo.bugToTestCaseLinks)" -ForegroundColor Cyan
Write-Host "  Related links: $($linkInfo.relatedLinks)" -ForegroundColor Cyan
Write-Host "  Dependency links: $($linkInfo.dependencyLinks)" -ForegroundColor Cyan
Write-Host "  Comments added: $($linkInfo.commentsAdded)" -ForegroundColor Cyan
Write-Host "`nLink information saved to: $outputPath\links-info.json" -ForegroundColor Cyan

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 08-create-wiki-dashboards.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
