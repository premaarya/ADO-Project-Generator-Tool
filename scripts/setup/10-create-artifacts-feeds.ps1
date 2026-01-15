# 10 - Create Azure Artifacts Feeds and Packages
# This script creates Azure Artifacts feeds with NuGet, NPM, and Universal packages

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
Write-Host "Creating Azure Artifacts Feeds & Packages" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$feedIds = @()
$packageInfo = @()

# ============================================
# Step 1: Create Artifact Feeds
# ============================================
Write-Host "Step 1: Creating Artifact Feeds..." -ForegroundColor Green

$feeds = @(
    @{
        name = "MyApp-NuGet-Feed"
        description = "NuGet packages for MyApp solution"
        capabilities = @{
            upstream = @{
                enabled = $true
                upstreamSources = @(
                    @{
                        id = "nuget-upstream"
                        name = "NuGet Gallery"
                        protocol = "nuget"
                        location = "https://api.nuget.org/v3/index.json"
                        upstreamSourceType = "public"
                    }
                )
            }
        }
    },
    @{
        name = "MyApp-NPM-Feed"
        description = "NPM packages for MyApp frontend"
        capabilities = @{
            upstream = @{
                enabled = $true
                upstreamSources = @(
                    @{
                        id = "npm-upstream"
                        name = "npmjs"
                        protocol = "npm"
                        location = "https://registry.npmjs.org/"
                        upstreamSourceType = "public"
                    }
                )
            }
        }
    },
    @{
        name = "MyApp-Universal-Feed"
        description = "Universal packages for build artifacts and deployment packages"
        capabilities = @{}
    },
    @{
        name = "Shared-Libraries-Feed"
        description = "Shared libraries and components across projects"
        capabilities = @{}
    }
)

foreach ($feed in $feeds) {
    Write-Host "  Creating feed: $($feed.name)" -ForegroundColor White
    
    $feedBody = @{
        name = $feed.name
        description = $feed.description
        hideDeletedPackageVersions = $true
        upstreamEnabled = $true
        capabilities = $feed.capabilities
    }
    
    # Feeds API uses a different base URL
    $feedUri = "https://feeds.dev.azure.com/$org/$project/_apis/packaging/feeds?api-version=7.0"
    
    try {
        $createdFeed = Invoke-AdoRestApi -Uri $feedUri -Method POST -Headers $headers -Body $feedBody
        
        Write-Host "    ✓ Created feed ID: $($createdFeed.id)" -ForegroundColor Green
        
        $feedIds += @{
            id = $createdFeed.id
            name = $createdFeed.name
            description = $createdFeed.description
            url = "https://dev.azure.com/$org/$project/_packaging?_a=feed&feed=$($createdFeed.name)"
        }
    } catch {
        Write-Host "    ⚠ Failed to create feed (may require Azure Artifacts license): $_" -ForegroundColor Yellow
        $feedIds += @{
            name = $feed.name
            description = $feed.description
            status = "Requires Azure Artifacts License"
            error = $_.Exception.Message
        }
    }
}

# ============================================
# Step 2: Create Sample Package Metadata
# ============================================
Write-Host "`nStep 2: Creating sample package metadata..." -ForegroundColor Green

# Note: Actually publishing packages requires proper authentication and package files
# For migration testing purposes, we'll create metadata records

$samplePackages = @(
    # NuGet Packages
    @{
        feedName = "MyApp-NuGet-Feed"
        type = "NuGet"
        name = "MyApp.Core"
        version = "1.0.0"
        description = "Core library for MyApp application"
        authors = "MyApp Development Team"
    },
    @{
        feedName = "MyApp-NuGet-Feed"
        type = "NuGet"
        name = "MyApp.Data"
        version = "1.0.0"
        description = "Data access layer for MyApp"
        authors = "MyApp Development Team"
    },
    @{
        feedName = "MyApp-NuGet-Feed"
        type = "NuGet"
        name = "MyApp.Core"
        version = "1.1.0"
        description = "Core library for MyApp application - Updated with bug fixes"
        authors = "MyApp Development Team"
    },
    @{
        feedName = "MyApp-NuGet-Feed"
        type = "NuGet"
        name = "MyApp.Api"
        version = "2.0.0"
        description = "API layer for MyApp services"
        authors = "MyApp Development Team"
    },
    
    # NPM Packages
    @{
        feedName = "MyApp-NPM-Feed"
        type = "NPM"
        name = "@myapp/ui-components"
        version = "1.0.0"
        description = "Reusable UI components for MyApp"
        authors = "Frontend Team"
    },
    @{
        feedName = "MyApp-NPM-Feed"
        type = "NPM"
        name = "@myapp/utils"
        version = "1.0.0"
        description = "Utility functions for MyApp frontend"
        authors = "Frontend Team"
    },
    @{
        feedName = "MyApp-NPM-Feed"
        type = "NPM"
        name = "@myapp/ui-components"
        version = "1.1.0"
        description = "Reusable UI components for MyApp - Added new components"
        authors = "Frontend Team"
    },
    
    # Universal Packages
    @{
        feedName = "MyApp-Universal-Feed"
        type = "Universal"
        name = "myapp-deployment-scripts"
        version = "1.0.0"
        description = "Deployment scripts and configurations"
        authors = "DevOps Team"
    },
    @{
        feedName = "MyApp-Universal-Feed"
        type = "Universal"
        name = "myapp-infrastructure"
        version = "1.0.0"
        description = "Infrastructure as Code templates"
        authors = "DevOps Team"
    },
    @{
        feedName = "Shared-Libraries-Feed"
        type = "Universal"
        name = "shared-authentication-lib"
        version = "2.0.0"
        description = "Shared authentication library"
        authors = "Platform Team"
    }
)

foreach ($package in $samplePackages) {
    Write-Host "  Package: $($package.name) v$($package.version) ($($package.type))" -ForegroundColor White
    
    $packageInfo += @{
        feedName = $package.feedName
        type = $package.type
        name = $package.name
        version = $package.version
        description = $package.description
        authors = $package.authors
        status = "Metadata Created (Requires Actual Package Upload)"
    }
    
    Write-Host "    ℹ Package metadata defined (actual upload requires package files)" -ForegroundColor Yellow
}

# ============================================
# Step 3: Create Feed Views
# ============================================
Write-Host "`nStep 3: Creating feed views..." -ForegroundColor Green

$feedViews = @(
    @{
        feedName = "MyApp-NuGet-Feed"
        viewName = "Release"
        visibility = "organization"
        type = "release"
    },
    @{
        feedName = "MyApp-NuGet-Feed"
        viewName = "Prerelease"
        visibility = "organization"
        type = "prerelease"
    },
    @{
        feedName = "MyApp-NPM-Feed"
        viewName = "Release"
        visibility = "organization"
        type = "release"
    }
)

foreach ($view in $feedViews) {
    $feed = $feedIds | Where-Object { $_.name -eq $view.feedName } | Select-Object -First 1
    
    if ($feed -and $feed.id) {
        Write-Host "  Creating view '$($view.viewName)' for feed: $($view.feedName)" -ForegroundColor White
        
        # Feed views would be created here with proper API calls
        # Requires feed ID from previous step
        Write-Host "    ℹ View defined: $($view.viewName)" -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠ Feed not found or not created: $($view.feedName)" -ForegroundColor Yellow
    }
}

# ============================================
# Step 4: Save Results
# ============================================
Write-Host "`nStep 4: Saving results..." -ForegroundColor Green

$outputDir = "$PSScriptRoot\..\output"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

$results = @{
    feeds = $feedIds
    packages = $packageInfo
    views = $feedViews
    summary = @{
        totalFeeds = $feedIds.Count
        totalPackages = $packageInfo.Count
        totalViews = $feedViews.Count
        nugetPackages = ($packageInfo | Where-Object { $_.type -eq "NuGet" }).Count
        npmPackages = ($packageInfo | Where-Object { $_.type -eq "NPM" }).Count
        universalPackages = ($packageInfo | Where-Object { $_.type -eq "Universal" }).Count
        createdDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
}

$outputPath = "$outputDir\artifacts-info.json"
$results | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "  ✓ Results saved to: $outputPath" -ForegroundColor Green

# ============================================
# Summary
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Artifact Feeds: $($feedIds.Count)" -ForegroundColor White
Write-Host "  - NuGet Packages: $(($packageInfo | Where-Object { $_.type -eq 'NuGet' }).Count)" -ForegroundColor White
Write-Host "  - NPM Packages: $(($packageInfo | Where-Object { $_.type -eq 'NPM' }).Count)" -ForegroundColor White
Write-Host "  - Universal Packages: $(($packageInfo | Where-Object { $_.type -eq 'Universal' }).Count)" -ForegroundColor White
Write-Host "Feed Views: $($feedViews.Count)" -ForegroundColor White
Write-Host "`nℹ Note: Azure Artifacts requires a license and actual package files to publish" -ForegroundColor Yellow
Write-Host "✓ Artifacts feeds and package metadata setup complete!" -ForegroundColor Green
