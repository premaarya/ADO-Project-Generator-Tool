# 05 - Create Repositories
# This script creates Git repositories with sample code, branches, commits, pull requests, reviews, and approvals

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\..\..\utils\config.json"
)

# Import helper functions
. "$PSScriptRoot\..\..\utils\ado-api-helper.ps1"

# Load configuration
Write-Host "Loading configuration..." -ForegroundColor Green
$config = Get-AdoConfig -ConfigPath $ConfigPath

# Setup authentication with application/json (not json-patch+json) for git operations
$headers = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
$org = $config.organization
$project = $config.project

Write-Host "Creating repositories with branches, commits, pull requests, and reviews for project '$project'..." -ForegroundColor Green

$repoIds = @()
$allPullRequests = @()

# ===== CREATE REPOSITORIES =====
Write-Host "`n[1/6] Creating Repositories..." -ForegroundColor Cyan

# First, list existing repositories
$reposUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories"
$existingRepos = Invoke-AdoRestApi -Uri $reposUri -Method GET -Headers $headers
Write-Host "  Found $($existingRepos.value.Count) existing repositories" -ForegroundColor Gray

foreach ($repo in $config.repositories) {
    Write-Host "  Processing repository: $($repo.name)" -ForegroundColor White
    
    # Check if repo already exists
    $existing = $existingRepos.value | Where-Object { $_.name -eq $repo.name } | Select-Object -First 1
    
    if ($existing) {
        Write-Host "    ✓ Using existing repository ID: $($existing.id)" -ForegroundColor Green
        $repoIds += @{
            id = $existing.id
            name = $existing.name
            url = $existing.remoteUrl
            defaultBranch = $existing.defaultBranch
        }
    } else {
        # Create new repository - don't include project in body when it's in URI
        $repoBody = @{
            name = $repo.name
        }
        
        try {
            $createdRepo = Invoke-AdoRestApi -Uri $reposUri -Method POST -Headers $headers -Body $repoBody
            $repoIds += @{
                id = $createdRepo.id
                name = $createdRepo.name
                url = $createdRepo.remoteUrl
                defaultBranch = $createdRepo.defaultBranch
            }
            Write-Host "    ✓ Created repository ID: $($createdRepo.id)" -ForegroundColor Green
        } catch {
            Write-Host "    ✗ Failed to create repository: $_" -ForegroundColor Red
        }
    }
}

# ===== CREATE INITIAL COMMITS =====
Write-Host "`n[2/6] Creating initial commits with sample files..." -ForegroundColor Cyan

foreach ($repoInfo in $repoIds) {
    Write-Host "  Adding files to: $($repoInfo.name)" -ForegroundColor White
    
    $readmeContent = @"
# $($repoInfo.name)

This is a sample repository created for ADO to GitHub migration testing.

## Description
$($config.repositories | Where-Object { $_.name -eq $repoInfo.name } | Select-Object -ExpandProperty description)

## Getting Started

### Prerequisites
- .NET SDK 8.0 or later
- Node.js 18+ (for frontend)
- Docker (for containerization)

### Installation
\`\`\`bash
git clone $($repoInfo.url)
cd $($repoInfo.name)
\`\`\`

### Build
\`\`\`bash
dotnet build
\`\`\`

### Test
\`\`\`bash
dotnet test
\`\`\`

## Project Structure
\`\`\`
/src        - Source code
/tests      - Unit and integration tests
/docs       - Documentation
/scripts    - Build and deployment scripts
\`\`\`

## Contributing
Please follow the standard Git workflow:
1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License
MIT License
"@

    $srcFileContent = @"
using System;

namespace $($repoInfo.name.Replace('-', ''))
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Console.WriteLine("Welcome to $($repoInfo.name)!");
            Console.WriteLine("This is a sample application for migration testing.");
        }
    }
}
"@

    $testFileContent = @"
using Xunit;

namespace $($repoInfo.name.Replace('-', '')).Tests
{
    public class ProgramTests
    {
        [Fact]
        public void Test_MainMethod_DoesNotThrow()
        {
            var exception = Record.Exception(() => Program.Main(new string[] {}));
            Assert.Null(exception);
        }
    }
}
"@
    
    $readmeBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($readmeContent))
    $srcBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($srcFileContent))
    $testBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($testFileContent))
    
    # Get random work items to associate with this commit
    $workItemsPath = "$PSScriptRoot\..\output\work-items-info.json"
    $associatedWorkItems = @()
    if (Test-Path $workItemsPath) {
        $workItemsData = Get-Content $workItemsPath -Raw | ConvertFrom-Json
        # Associate 1-2 user stories with this commit
        if ($workItemsData.userStories -and $workItemsData.userStories.Count -gt 0) {
            $randomStories = $workItemsData.userStories | Get-Random -Count (Get-Random -Minimum 1 -Maximum 3)
            $associatedWorkItems = $randomStories
        }
    }
    
    # Build commit message with work item references
    $commitMessage = "Initial commit: Add project files"
    if ($associatedWorkItems.Count -gt 0) {
        $workItemRefs = ($associatedWorkItems | ForEach-Object { "#$_" }) -join ", "
        $commitMessage += "`n`nRelated work items: $workItemRefs"
    }
    
    # Create initial commit with multiple files
    $pushBody = @{
        refUpdates = @(
            @{
                name = "refs/heads/main"
                oldObjectId = "0000000000000000000000000000000000000000"
            }
        )
        commits = @(
            @{
                comment = $commitMessage
                changes = @(
                    @{
                        changeType = "add"
                        item = @{ path = "/README.md" }
                        newContent = @{
                            content = $readmeBase64
                            contentType = "base64encoded"
                        }
                    },
                    @{
                        changeType = "add"
                        item = @{ path = "/src/Program.cs" }
                        newContent = @{
                            content = $srcBase64
                            contentType = "base64encoded"
                        }
                    },
                    @{
                        changeType = "add"
                        item = @{ path = "/tests/ProgramTests.cs" }
                        newContent = @{
                            content = $testBase64
                            contentType = "base64encoded"
                        }
                    }
                )
            }
        )
    }
    
    $pushUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/pushes"
    
    try {
        $push = Invoke-AdoRestApi -Uri $pushUri -Method POST -Headers $headers -Body $pushBody
        Write-Host "    ✓ Created initial commit with 3 files" -ForegroundColor Green
        $repoInfo.mainCommitId = $push.commits[0].commitId
    } catch {
        Write-Host "    ⚠ Failed to create initial commit: $_" -ForegroundColor Yellow
        
        # Try to get existing main branch commit
        try {
            $refsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/refs?filter=heads/main"
            $mainRef = Invoke-AdoRestApi -Uri $refsUri -Method GET -Headers $headers
            if ($mainRef.value.Count -gt 0) {
                $repoInfo.mainCommitId = $mainRef.value[0].objectId
                Write-Host "    ✓ Using existing main branch commit" -ForegroundColor Green
            }
        } catch {
            Write-Host "    ✗ Could not get main branch" -ForegroundColor Red
        }
        continue
    }
}

# ===== CREATE FEATURE BRANCHES WITH COMMITS =====
Write-Host "`n[3/6] Creating feature branches with commits..." -ForegroundColor Cyan

$featureBranches = @(
    @{ name = "feature/user-authentication"; description = "Add user authentication system"; files = @("src/Auth/AuthService.cs", "src/Auth/UserManager.cs") },
    @{ name = "feature/api-integration"; description = "Integrate with external API"; files = @("src/Api/ApiClient.cs", "src/Api/ApiConfig.cs") },
    @{ name = "feature/logging-improvements"; description = "Improve logging infrastructure"; files = @("src/Logging/Logger.cs", "src/Logging/LogConfig.cs") },
    @{ name = "bugfix/fix-null-reference"; description = "Fix null reference exception in data layer"; files = @("src/Data/DataAccess.cs") }
)

foreach ($repoInfo in $repoIds[0..0]) {  # Only first repository for testing
    if (-not $repoInfo.mainCommitId) {
        Write-Host "  ⚠ Skipping $($repoInfo.name) - no main commit" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  Creating feature branches for: $($repoInfo.name)" -ForegroundColor White
    $repoInfo.branches = @()
    
    foreach ($featureBranch in $featureBranches) {
        $branchName = $featureBranch.name
        Write-Host "    Creating branch: $branchName" -ForegroundColor Cyan
        
        # Create branch from main
        $branchRefBody = @(
            @{
                name = "refs/heads/$branchName"
                oldObjectId = "0000000000000000000000000000000000000000"
                newObjectId = $repoInfo.mainCommitId
            }
        )
        
        $updateRefsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/refs"
        
        try {
            $branchRef = Invoke-AdoRestApi -Uri $updateRefsUri -Method POST -Headers $headers -Body $branchRefBody
            Write-Host "      ✓ Branch created" -ForegroundColor Green
        } catch {
            Write-Host "      ⚠ Branch may already exist, attempting to get commit" -ForegroundColor Yellow
        }
        
        # Get current branch commit
        $refsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/refs?filter=heads/$branchName"
        $branchRefData = Invoke-AdoRestApi -Uri $refsUri -Method GET -Headers $headers
        $currentCommitId = $branchRefData.value[0].objectId
        
        # Create commits on the feature branch
        $changes = @()
        foreach ($filePath in $featureBranch.files) {
            $fileContent = @"
using System;

namespace $($repoInfo.name.Replace('-', ''))
{
    // $($featureBranch.description)
    // File: $filePath
    // Created: $(Get-Date -Format "yyyy-MM-dd")
    
    public class $((Split-Path $filePath -Leaf) -replace '\.cs$', '')
    {
        public void Execute()
        {
            Console.WriteLine("$($featureBranch.description)");
            // TODO: Implement functionality
        }
    }
}
"@
            $fileBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent))
            
            $changes += @{
                changeType = "add"
                item = @{ path = "/$filePath" }
                newContent = @{
                    content = $fileBase64
                    contentType = "base64encoded"
                }
            }
        }
        
        $featurePushBody = @{
            refUpdates = @(
                @{
                    name = "refs/heads/$branchName"
                    oldObjectId = $currentCommitId
                }
            )
            commits = @(
                @{
                    comment = "$($featureBranch.description)`n`nThis commit adds new functionality for the feature branch."
                    changes = $changes
                }
            )
        }
        
        try {
            $featurePush = Invoke-AdoRestApi -Uri $pushUri -Method POST -Headers $headers -Body $featurePushBody
            $branchCommitId = $featurePush.commits[0].commitId
            Write-Host "      ✓ Added $($changes.Count) file(s) to branch" -ForegroundColor Green
            
            $repoInfo.branches += @{
                name = $branchName
                description = $featureBranch.description
                commitId = $branchCommitId
                files = $featureBranch.files
            }
        } catch {
            Write-Host "      ✗ Failed to create commits: $_" -ForegroundColor Red
        }
    }
}

# ===== CREATE PULL REQUESTS =====
Write-Host "`n[4/6] Creating pull requests..." -ForegroundColor Cyan

foreach ($repoInfo in $repoIds[0..0]) {  # Only first repository
    if (-not $repoInfo.branches) {
        Write-Host "  ⚠ Skipping $($repoInfo.name) - no feature branches" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  Creating pull requests for: $($repoInfo.name)" -ForegroundColor White
    $repoInfo.pullRequests = @()
    
    foreach ($branch in $repoInfo.branches) {
        $prTitle = $branch.description
        $prDescription = @"
## Description
$($branch.description)

## Changes
$($branch.files | ForEach-Object { "- Added file: $_" } | Out-String)

## Testing
- [x] Unit tests added
- [x] Integration tests passed
- [x] Manual testing completed

## Checklist
- [x] Code follows project coding standards
- [x] Self-review completed
- [x] Documentation updated
- [x] No breaking changes

## Related Work Items
Relates to Epic #121
"@
        
        $prBody = @{
            sourceRefName = "refs/heads/$($branch.name)"
            targetRefName = "refs/heads/main"
            title = $prTitle
            description = $prDescription
            reviewers = @()  # No reviewers since users array is empty
        }
        
        $prUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/pullrequests"
        
        try {
            $pr = Invoke-AdoRestApi -Uri $prUri -Method POST -Headers $headers -Body $prBody
            Write-Host "    ✓ Created PR #$($pr.pullRequestId): $prTitle" -ForegroundColor Green
            
            $pullRequestInfo = @{
                pullRequestId = $pr.pullRequestId
                title = $pr.title
                sourceBranch = $branch.name
                targetBranch = "main"
                status = $pr.status
                url = "https://dev.azure.com/$org/$project/_git/$($repoInfo.name)/pullrequest/$($pr.pullRequestId)"
                createdDate = $pr.creationDate
            }
            
            $repoInfo.pullRequests += $pullRequestInfo
            $allPullRequests += $pullRequestInfo
            
            # Store PR ID for review comments
            $branch.pullRequestId = $pr.pullRequestId
            
        } catch {
            Write-Host "    ✗ Failed to create PR for $($branch.name): $_" -ForegroundColor Red
        }
    }
}

# ===== ADD REVIEW COMMENTS =====
Write-Host "`n[5/6] Adding review comments to pull requests..." -ForegroundColor Cyan

$reviewComments = @(
    "This looks good! Just a few minor suggestions.",
    "LGTM! Great work on implementing this feature.",
    "Could you add more unit tests to cover edge cases?",
    "Please update the documentation to reflect these changes.",
    "Consider refactoring this method for better readability.",
    "Nice implementation! Just one question about the error handling.",
    "Approved! This addresses the issue effectively."
)

foreach ($repoInfo in $repoIds[0..0]) {
    if (-not $repoInfo.pullRequests) {
        continue
    }
    
    Write-Host "  Adding comments to PRs in: $($repoInfo.name)" -ForegroundColor White
    
    foreach ($pr in $repoInfo.pullRequests) {
        $prId = $pr.pullRequestId
        
        # Add 2-3 review comments per PR
        $commentCount = Get-Random -Minimum 2 -Maximum 4
        for ($i = 0; $i -lt $commentCount; $i++) {
            $commentText = $reviewComments | Get-Random
            
            $threadBody = @{
                comments = @(
                    @{
                        parentCommentId = 0
                        content = $commentText
                        commentType = 1  # Text comment
                    }
                )
                status = 1  # Active
            }
            
            $threadsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/pullRequests/$prId/threads"
            
            try {
                $thread = Invoke-AdoRestApi -Uri $threadsUri -Method POST -Headers $headers -Body $threadBody
                Write-Host "    ✓ Added comment to PR #$prId" -ForegroundColor Green
            } catch {
                Write-Host "    ⚠ Could not add comment: $_" -ForegroundColor Yellow
            }
        }
    }
}

# ===== ADD PR APPROVALS =====
Write-Host "`n[6/6] Adding approvals to pull requests..." -ForegroundColor Cyan

foreach ($repoInfo in $repoIds[0..0]) {
    if (-not $repoInfo.pullRequests) {
        continue
    }
    
    Write-Host "  Adding approvals to PRs in: $($repoInfo.name)" -ForegroundColor White
    
    foreach ($pr in $repoInfo.pullRequests) {
        $prId = $pr.pullRequestId
        
        # Get current user to add as reviewer
        $currentUserUri = "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=7.0"
        try {
            $currentUser = Invoke-AdoRestApi -Uri $currentUserUri -Method GET -Headers $headers
            $reviewerId = $currentUser.id
            
            # Add reviewer with approval vote
            $reviewerBody = @{
                vote = 10  # 10 = Approved, 5 = Approved with suggestions, 0 = No vote, -5 = Waiting for author, -10 = Rejected
                isReapprove = $false
            }
            
            $reviewerUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/pullRequests/$prId/reviewers/$reviewerId"
            
            try {
                $reviewer = Invoke-AdoRestApi -Uri $reviewerUri -Method PUT -Headers $headers -Body $reviewerBody
                Write-Host "    ✓ Approved PR #$prId" -ForegroundColor Green
                $pr.approved = $true
                $pr.vote = "Approved"
            } catch {
                Write-Host "    ⚠ Could not add approval: $_" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    ⚠ Could not get current user for approval" -ForegroundColor Yellow
        }
    }
}

# ===== CREATE BRANCH POLICIES =====
Write-Host "`n[6/6] Creating branch policies..." -ForegroundColor Cyan

foreach ($repoInfo in $repoIds[0..0]) {  # Only first repository
    Write-Host "  Creating branch policies for: $($repoInfo.name)" -ForegroundColor White
    
    # Get main branch ref
    $refsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repoInfo.id)/refs?filter=heads/main"
    
    try {
        $mainRef = Invoke-AdoRestApi -Uri $refsUri -Method GET -Headers $headers
        
        if ($mainRef.value -and $mainRef.value.Count -gt 0) {
            $refName = $mainRef.value[0].name  # e.g., "refs/heads/main"
            
            Write-Host "    Setting up branch policies for: $refName" -ForegroundColor Cyan
            
            # Policy 1: Minimum number of reviewers
            $reviewerPolicyBody = @{
                isEnabled = $true
                isBlocking = $true
                type = @{
                    id = "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd"  # Minimum number of reviewers policy
                }
                settings = @{
                    minimumApproverCount = 2
                    creatorVoteCounts = $false
                    allowDownvotes = $false
                    resetOnSourcePush = $true
                    scope = @(
                        @{
                            repositoryId = $repoInfo.id
                            refName = $refName
                            matchKind = "exact"
                        }
                    )
                }
            }
            
            $policyUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/policy/configurations" -ApiVersion "7.0"
            
            try {
                $policy1 = Invoke-AdoRestApi -Uri $policyUri -Method POST -Headers $headers -Body $reviewerPolicyBody
                Write-Host "      ✓ Minimum reviewers policy created (ID: $($policy1.id))" -ForegroundColor Green
            } catch {
                Write-Host "      ⚠ Failed to create reviewer policy: $_" -ForegroundColor Yellow
            }
            
            # Policy 2: Work item linking
            $workItemPolicyBody = @{
                isEnabled = $true
                isBlocking = $false
                type = @{
                    id = "40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e"  # Work item linking policy
                }
                settings = @{
                    scope = @(
                        @{
                            repositoryId = $repoInfo.id
                            refName = $refName
                            matchKind = "exact"
                        }
                    )
                }
            }
            
            try {
                $policy2 = Invoke-AdoRestApi -Uri $policyUri -Method POST -Headers $headers -Body $workItemPolicyBody
                Write-Host "      ✓ Work item linking policy created (ID: $($policy2.id))" -ForegroundColor Green
            } catch {
                Write-Host "      ⚠ Failed to create work item policy: $_" -ForegroundColor Yellow
            }
            
            # Policy 3: Comment requirements
            $commentPolicyBody = @{
                isEnabled = $true
                isBlocking = $true
                type = @{
                    id = "c6a1889d-b943-4856-b76f-9e46bb6b0df2"  # Comment requirements policy
                }
                settings = @{
                    scope = @(
                        @{
                            repositoryId = $repoInfo.id
                            refName = $refName
                            matchKind = "exact"
                        }
                    )
                }
            }
            
            try {
                $policy3 = Invoke-AdoRestApi -Uri $policyUri -Method POST -Headers $headers -Body $commentPolicyBody
                Write-Host "      ✓ Comment requirements policy created (ID: $($policy3.id))" -ForegroundColor Green
            } catch {
                Write-Host "      ⚠ Failed to create comment policy: $_" -ForegroundColor Yellow
            }
            
            Write-Host "    ✓ Branch policies configured for main branch" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ⚠ Failed to configure branch policies: $_" -ForegroundColor Yellow
    }
}

# Save repository information
$outputPath = "$PSScriptRoot\..\output"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

$repoOutput = @{
    repositories = $repoIds
    totalRepositories = $repoIds.Count
    totalBranches = ($repoIds | Where-Object { $_.branches } | ForEach-Object { $_.branches.Count } | Measure-Object -Sum).Sum
    totalPullRequests = $allPullRequests.Count
    branchPoliciesConfigured = $true
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

$repoOutput | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\repositories-info.json"

Write-Host "`n✓ Repository creation completed!" -ForegroundColor Green
Write-Host "  Repositories: $($repoIds.Count)" -ForegroundColor Cyan
Write-Host "  Branches: $(($repoIds | Where-Object { $_.branches } | ForEach-Object { $_.branches.Count } | Measure-Object -Sum).Sum)" -ForegroundColor Cyan
Write-Host "  Pull Requests: $($allPullRequests.Count)" -ForegroundColor Cyan
Write-Host "  Branch Policies: Configured" -ForegroundColor Cyan
Write-Host "`nRepository information saved to: $outputPath\repositories-info.json" -ForegroundColor Cyan

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 06-create-pipelines.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray



Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 06-create-pipelines.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
