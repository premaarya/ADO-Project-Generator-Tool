# 04 - Create Test Management Objects
# This script creates test plans, test suites, test cases, and test runs

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\..\..\utils\config.json"
)

# Import helper functions
. "$PSScriptRoot\..\..\utils\ado-api-helper.ps1"

# Load configuration
Write-Host "Loading configuration..." -ForegroundColor Green
$config = Get-AdoConfig -ConfigPath $ConfigPath

# Setup authentication - use different headers for different API endpoints
$headersTestApi = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"  # For test plans/suites/runs
$headers = Get-AdoHeaders -Pat $config.pat  # For work items (test cases) - uses default patch+json
$org = $config.organization
$project = $config.project

# Load work items info
$workItemsPath = "$PSScriptRoot\..\output\work-items-info.json"
if (-not (Test-Path $workItemsPath)) {
    throw "Work items info not found. Please run 03-create-work-items.ps1 first."
}
$workItems = Get-Content $workItemsPath -Raw | ConvertFrom-Json

Write-Host "Creating test management objects for project '$project'..." -ForegroundColor Green

$testPlanIds = @()
$testSuiteIds = @()
$testCaseIds = @()

# ===== CREATE TEST PLANS (Skipped - Requires Azure Test Plans License) =====
Write-Host "`n[1/4] Creating Test Plans..." -ForegroundColor Cyan
Write-Host "  ⚠ Test Plans API requires Azure Test Plans license - Skipping" -ForegroundColor Yellow
Write-Host "  Note: Test Case work items will still be created" -ForegroundColor Yellow

# ===== CREATE TEST SUITES (Skipped - Requires Test Plans) =====
Write-Host "`n[2/4] Creating Test Suites..." -ForegroundColor Cyan
Write-Host "  ⚠ Test Suites require Test Plans - Skipping" -ForegroundColor Yellow

# ===== CREATE TEST CASES =====
Write-Host "`n[3/4] Creating Test Cases..." -ForegroundColor Cyan

$testCaseTemplates = @(
    @{
        title = "Verify login functionality"
        steps = @(
            @{ action = "Navigate to login page"; expected = "Login page displays correctly" },
            @{ action = "Enter valid credentials"; expected = "Credentials accepted" },
            @{ action = "Click login button"; expected = "User is logged in successfully" }
        )
    },
    @{
        title = "Verify data export"
        steps = @(
            @{ action = "Navigate to data page"; expected = "Data grid displays" },
            @{ action = "Click export button"; expected = "Export dialog opens" },
            @{ action = "Select CSV format"; expected = "File downloads successfully" }
        )
    },
    @{
        title = "Verify search functionality"
        steps = @(
            @{ action = "Enter search term"; expected = "Search box accepts input" },
            @{ action = "Click search button"; expected = "Results display correctly" },
            @{ action = "Verify results"; expected = "Results match search criteria" }
        )
    },
    @{
        title = "Verify form validation"
        steps = @(
            @{ action = "Leave required field empty"; expected = "Validation error displays" },
            @{ action = "Enter invalid data"; expected = "Format error displays" },
            @{ action = "Enter valid data"; expected = "Form submits successfully" }
        )
    },
    @{
        title = "Verify API integration"
        steps = @(
            @{ action = "Make API request"; expected = "Response received" },
            @{ action = "Validate response data"; expected = "Data is correct" },
            @{ action = "Check error handling"; expected = "Errors handled gracefully" }
        )
    }
)

for ($i = 0; $i -lt $config.workItemCounts.testCases; $i++) {
    $template = $testCaseTemplates[$i % $testCaseTemplates.Count]
    $areaPath = $project  # Use root project area for simplicity
    $iteration = $project  # Use root project iteration for simplicity
    
    if ($i % 10 -eq 0) {
        Write-Host "  Creating test cases $($i+1)-$([Math]::Min($i+10, $config.workItemCounts.testCases))..." -ForegroundColor White
    }
    
    # Build steps HTML
    $stepsHtml = "<steps id=""0"" last=""$($template.steps.Count)"">"
    for ($s = 0; $s -lt $template.steps.Count; $s++) {
        $stepsHtml += @"
<step id=""$($s+1)"" type=""ValidateStep"">
<parameterizedString isformatted=""true"">&lt;DIV&gt;&lt;P&gt;$($template.steps[$s].action)&lt;/P&gt;&lt;/DIV&gt;</parameterizedString>
<parameterizedString isformatted=""true"">&lt;DIV&gt;&lt;P&gt;$($template.steps[$s].expected)&lt;/P&gt;&lt;/DIV&gt;</parameterizedString>
<description/>
</step>
"@
    }
    $stepsHtml += "</steps>"
    
    $testCaseBody = @(
        @{
            op = "add"
            path = "/fields/System.Title"
            value = "$($template.title) - Test Case $($i+1)"
        },
        @{
            op = "add"
            path = "/fields/System.Description"
            value = "Automated test case to verify $($template.title.ToLower())"
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.TCM.Steps"
            value = $stepsHtml
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
            value = "Design"  # Use Design state for all test cases (safest default)
        },
        @{
            op = "add"
            path = "/fields/Microsoft.VSTS.Common.Priority"
            value = ($i % 4) + 1
        },
        @{
            op = "add"
            path = "/fields/System.Tags"
            value = "test; " + (($config.tags | Get-Random -Count 2) -join "; ")
        }
    )
    
    # Link to related user story
    if ($workItems.userStories.Count -gt 0) {
        $relatedStoryId = $workItems.userStories[$i % $workItems.userStories.Count]
        $testCaseBody += @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "Microsoft.VSTS.Common.TestedBy-Reverse"
                url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$relatedStoryId"
            }
        }
    }
    
    $testCaseUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/wit/workitems/`$Test Case"
    $testCase = Invoke-AdoRestApi -Uri $testCaseUri -Method POST -Headers $headers -Body $testCaseBody
    $testCaseIds += $testCase.id
}

Write-Host "    ✓ All test cases created!" -ForegroundColor Green

# ===== ADD TEST CASES TO SUITES (Skipped - Requires Test Suites) =====
Write-Host "`n[3.5/4] Adding test cases to suites..." -ForegroundColor Cyan
Write-Host "  ⚠ Test Suites not created - Skipping test case assignments" -ForegroundColor Yellow

# ===== CREATE TEST RUNS (Skipped - Requires Test Plans) =====
Write-Host "`n[4/4] Creating Test Runs..." -ForegroundColor Cyan
Write-Host "  ⚠ Test Runs require Test Plans license - Skipping" -ForegroundColor Yellow
Write-Host "  Note: Would create $($config.testRuns.count) test runs with Browser and Windows 11 configurations" -ForegroundColor DarkGray

<#
DOCUMENTATION: Test Runs with Configurations (Requires Azure Test Plans License)

This section would create 10 test runs with Browser and Windows 11 configurations:

Test Configurations:
- Chrome on Windows 11
- Edge on Windows 11  
- Firefox on Windows 11

For each test plan, create multiple test runs with:
1. Configuration variables (Browser type, OS version)
2. Test results (Passed/Failed/Blocked) for each configuration
3. Run statistics and duration
4. Link to test cases

Code example for creating test runs with configurations:

$outcomes = @("Passed", "Failed", "Blocked", "NotApplicable")
$browsers = @("Chrome", "Edge", "Firefox")
$os = "Windows 11"
$testRunsCreated = 0

# Create 10 test runs across different browsers and configurations
for ($runIndex = 0; $runIndex -lt $config.testRuns.count; $runIndex++) {
    $browser = $browsers[$runIndex % $browsers.Count]
    $configName = "$browser on $os"
    
    if ($testPlanIds.Count -gt 0) {
        $planInfo = $testPlanIds[$runIndex % $testPlanIds.Count]
        
        $runBody = @{
            name = "Test Run $($runIndex + 1) - $configName - $(Get-Date -Format 'yyyy-MM-dd')"
            plan = @{
                id = $planInfo.id
            }
            configurationIds = @()  # Would reference configuration IDs
            isAutomated = ($runIndex % 2 -eq 0)  # Alternate between automated/manual
            state = "Completed"
            comment = "Test execution on $configName"
            build = @{
                name = "Build-$(Get-Random -Minimum 100 -Maximum 999)"
            }
        }
        
        $runUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/test/runs"
        
        try {
            $run = Invoke-AdoRestApi -Uri $runUri -Method POST -Headers $headersTestApi -Body $runBody
            Write-Host "    ✓ Created test run ID: $($run.id) - $configName" -ForegroundColor Green
            
            # Add test results for each test case
            $resultsToAdd = $testCaseIds
            $results = @()
            
            foreach ($tcId in $resultsToAdd) {
                $outcome = $outcomes[(Get-Random -Minimum 0 -Maximum $outcomes.Count)]
                $results += @{
                    testCase = @{ id = $tcId }
                    outcome = $outcome
                    state = "Completed"
                    comment = "Executed on $configName"
                    durationInMs = (Get-Random -Minimum 1000 -Maximum 30000)
                    configuration = @{
                        name = $configName
                    }
                }
            }
            
            $resultsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/test/runs/$($run.id)/results"
            $addResults = Invoke-AdoRestApi -Uri $resultsUri -Method POST -Headers $headersTestApi -Body $results
            
            Write-Host "      ✓ Added $($results.Count) test results with outcomes" -ForegroundColor Green
            
            # Complete the run
            $updateBody = @{
                state = "Completed"
                completedDate = (Get-Date).AddHours(-($runIndex)).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
            $updateUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/test/runs/$($run.id)"
            Invoke-AdoRestApi -Uri $updateUri -Method PATCH -Headers $headersTestApi -Body $updateBody
            
            $testRunsCreated++
            
        } catch {
            Write-Host "    ⚠ Failed to create test run for $configName" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n  Summary: Created $testRunsCreated test runs across configurations:" -ForegroundColor Cyan
Write-Host "    - Chrome on Windows 11" -ForegroundColor White
Write-Host "    - Edge on Windows 11" -ForegroundColor White
Write-Host "    - Firefox on Windows 11" -ForegroundColor White
#>

# Save test management information
$outputPath = "$PSScriptRoot\..\output"
$testInfo = @{
    testPlans = $testPlanIds
    testSuites = $testSuiteIds
    testCases = $testCaseIds
    totalPlans = $testPlanIds.Count
    totalSuites = $testSuiteIds.Count
    totalTestCases = $testCaseIds.Count
    testRunsPlanned = $config.testRuns.count
    testConfigurations = $config.testConfigurations
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    note = "Test Plans, Suites, and Runs require Azure Test Plans license - Only Test Case work items created"
    documentedTestRuns = @{
        count = $config.testRuns.count
        configurations = @("Chrome on Windows 11", "Edge on Windows 11", "Firefox on Windows 11")
        description = "10 test runs would be created across Browser and Windows 11 configurations with test results"
    }
}

$testInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\test-management-info.json"

Write-Host "`n✓ Test management objects creation completed!" -ForegroundColor Green
Write-Host "  Test Plans: $($testPlanIds.Count) (Skipped - License required)" -ForegroundColor Yellow
Write-Host "  Test Suites: $($testSuiteIds.Count) (Skipped - License required)" -ForegroundColor Yellow
Write-Host "  Test Cases: $($testCaseIds.Count)" -ForegroundColor Cyan
Write-Host "  Test Runs Documented: $($config.testRuns.count) (Browsers x Windows 11)" -ForegroundColor DarkGray
Write-Host "`nTest management information saved to: $outputPath\test-management-info.json" -ForegroundColor Cyan
Write-Host "Note: Test Case work items can be viewed in Azure DevOps Boards" -ForegroundColor DarkGray

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 05-create-repositories.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
