# 06 - Create Pipelines
# This script creates build and release pipelines

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

# Load repositories info
$reposPath = "$PSScriptRoot\..\output\repositories-info.json"
if (-not (Test-Path $reposPath)) {
    throw "Repositories info not found. Please run 05-create-repositories.ps1 first."
}
$repos = Get-Content $reposPath -Raw | ConvertFrom-Json

Write-Host "Creating pipelines for project '$project'..." -ForegroundColor Green

$buildPipelineIds = @()
$releasePipelineIds = @()

# ===== CREATE BUILD PIPELINES (YAML) =====
Write-Host "`n[1/2] Creating Build Pipelines..." -ForegroundColor Cyan

foreach ($pipeline in $config.pipelines.build) {
    Write-Host "  Creating build pipeline: $($pipeline.name)" -ForegroundColor White
    
    # Find repository
    $repository = $repos.repositories | Where-Object { $_.name -eq $pipeline.repository } | Select-Object -First 1
    
    if (-not $repository) {
        Write-Host "    ⚠ Repository not found: $($pipeline.repository)" -ForegroundColor Yellow
        continue
    }
    
    # Create YAML pipeline definition file in repo first
    $yamlContent = @"
# Azure DevOps Pipeline for $($pipeline.name)
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - src/*
    - tests/*

variables:
  buildConfiguration: 'Release'
  dotnetVersion: '8.x'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: Build
    displayName: 'Build Job'
    pool:
      vmImage: 'ubuntu-latest'
    
    steps:
    - task: UseDotNet@2
      displayName: 'Install .NET SDK'
      inputs:
        version: `$(dotnetVersion)
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore dependencies'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build solution'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration `$(buildConfiguration)'
    
    - task: DotNetCoreCLI@2
      displayName: 'Run tests'
      inputs:
        command: 'test'
        projects: '**/*Tests.csproj'
        arguments: '--configuration `$(buildConfiguration) --collect "Code Coverage"'
    
    - task: PublishTestResults@2
      displayName: 'Publish test results'
      inputs:
        testResultsFormat: 'VSTest'
        testResultsFiles: '**/*.trx'
    
    - task: PublishBuildArtifacts@1
      displayName: 'Publish artifacts'
      inputs:
        PathtoPublish: '`$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
"@
    
    $yamlBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($yamlContent))
    
    # Get main branch commit
    $refsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repository.id)/refs?filter=heads/main"
    
    try {
        $mainRef = Invoke-AdoRestApi -Uri $refsUri -Method GET -Headers $headers
        
        if ($mainRef.value.Count -gt 0) {
            $mainCommitId = $mainRef.value[0].objectId
            
            # Add YAML file to repository
            $pushBody = @{
                refUpdates = @(
                    @{
                        name = "refs/heads/main"
                        oldObjectId = $mainCommitId
                    }
                )
                commits = @(
                    @{
                        comment = "Add Azure Pipeline YAML for $($pipeline.name)"
                        changes = @(
                            @{
                                changeType = "add"
                                item = @{
                                    path = "/$($pipeline.path)"
                                }
                                newContent = @{
                                    content = $yamlBase64
                                    contentType = "base64encoded"
                                }
                            }
                        )
                    }
                )
            }
            
            $pushUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repository.id)/pushes"
            Invoke-AdoRestApi -Uri $pushUri -Method POST -Headers $headers -Body $pushBody
            Write-Host "    ✓ Added pipeline YAML to repository" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ⚠ Could not add YAML file: $_" -ForegroundColor Yellow
    }
    
    # Create pipeline definition
    $pipelineBody = @{
        name = $pipeline.name
        folder = "\\"
        configuration = @{
            type = "yaml"
            path = $pipeline.path
            repository = @{
                id = $repository.id
                type = "azureReposGit"
            }
        }
    }
    
    $pipelinesUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/pipelines"
    
    try {
        $createdPipeline = Invoke-AdoRestApi -Uri $pipelinesUri -Method POST -Headers $headers -Body $pipelineBody
        $buildPipelineIds += @{
            id = $createdPipeline.id
            name = $createdPipeline.name
        }
        Write-Host "    ✓ Created pipeline ID: $($createdPipeline.id)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Failed to create pipeline: $($pipeline.name)" -ForegroundColor Yellow
    }
}

# ===== CREATE RELEASE PIPELINES =====
Write-Host "`n[2/2] Creating Release Pipelines..." -ForegroundColor Cyan

foreach ($release in $config.pipelines.release) {
    Write-Host "  Creating release pipeline: $($release.name)" -ForegroundColor White
    
    # Build environments/stages
    $environments = @()
    $rank = 1
    
    foreach ($stage in $release.stages) {
        $environments += @{
            id = -1
            name = $stage
            rank = $rank
            owner = @{
                displayName = "Release Admin"
            }
            conditions = @(
                @{
                    name = "ReleaseStarted"
                    conditionType = "event"
                    value = ""
                }
            )
            deployPhases = @(
                @{
                    deploymentInput = @{
                        parallelExecution = @{
                            parallelExecutionType = "none"
                        }
                        skipArtifactsDownload = $false
                        artifactsDownloadInput = @{}
                        queueId = 1
                        demands = @()
                        enableAccessToken = $false
                        timeoutInMinutes = 0
                        jobCancelTimeoutInMinutes = 1
                        condition = "succeeded()"
                        overrideInputs = @{}
                    }
                    workflowTasks = @(
                        @{
                            taskId = "e213ff0f-5d5c-4791-802d-52ea3e7be1f1"  # PowerShell task
                            version = "2.*"
                            name = "Deploy to $stage"
                            enabled = $true
                            alwaysRun = $false
                            continueOnError = $false
                            timeoutInMinutes = 0
                            definitionType = "task"
                            inputs = @{
                                targetType = "inline"
                                script = "Write-Host 'Deploying to $stage environment'"
                            }
                        }
                    )
                }
            )
        }
        
        $rank++
    }
    
    $releaseBody = @{
        name = $release.name
        source = "restApi"
        comment = "Release pipeline created via REST API for ADO migration testing"
        environments = $environments
        artifacts = @(
            @{
                alias = "_build"
                type = "Build"
                definitionReference = @{
                    definition = @{
                        id = if ($buildPipelineIds.Count -gt 0) { $buildPipelineIds[0].id.ToString() } else { "1" }
                        name = if ($buildPipelineIds.Count -gt 0) { $buildPipelineIds[0].name } else { "Build" }
                    }
                    project = @{
                        id = ""
                        name = $project
                    }
                }
            }
        )
        triggers = @()
    }
    
    $releaseUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/release/definitions"
    
    try {
        $createdRelease = Invoke-AdoRestApi -Uri $releaseUri -Method POST -Headers $headers -Body $releaseBody
        $releasePipelineIds += @{
            id = $createdRelease.id
            name = $createdRelease.name
            type = "Classic Release"
        }
        Write-Host "    ✓ Created release pipeline ID: $($createdRelease.id)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Failed to create release pipeline: $($release.name) - $_" -ForegroundColor Yellow
    }
}

# ===== CREATE CLASSIC BUILD DEFINITIONS =====
Write-Host "`n[3/3] Creating Classic Build Definitions..." -ForegroundColor Cyan

$classicBuilds = @(
    @{
        name = "Classic-DotNet-Build"
        description = "Classic build definition for .NET applications"
    },
    @{
        name = "Classic-NPM-Build"
        description = "Classic build definition for NPM applications"
    }
)

foreach ($build in $classicBuilds) {
    Write-Host "  Creating classic build: $($build.name)" -ForegroundColor White
    
    # Get first repository
    $repository = $repos.repositories[0]
    
    $classicBuildBody = @{
        name = $build.name
        type = "build"
        quality = "definition"
        queue = @{
            id = 1
        }
        build = @(
            @{
                enabled = $true
                continueOnError = $false
                alwaysRun = $false
                displayName = "Build solution"
                task = @{
                    id = "71a9a2d3-a98a-4caa-96ab-affca411ecda"  # MSBuild task
                    versionSpec = "1.*"
                }
                inputs = @{
                    solution = "**/*.sln"
                    platform = "`$(BuildPlatform)"
                    configuration = "`$(BuildConfiguration)"
                }
            }
        )
        repository = @{
            id = $repository.id
            type = "TfsGit"
            name = $repository.name
            defaultBranch = "refs/heads/main"
            clean = $false
            checkoutSubmodules = $false
        }
        processParameters = @{
            inputs = @(
                @{
                    name = "BuildConfiguration"
                    defaultValue = "Release"
                }
                @{
                    name = "BuildPlatform"
                    defaultValue = "Any CPU"
                }
            )
        }
        options = @(
            @{
                enabled = $true
                definition = @{
                    id = "7c555368-ca64-4199-add6-9ebaf0b0137d"  # Build number format
                }
                inputs = @{
                    buildNumberFormat = "`$(date:yyyyMMdd)`$(rev:.r)"
                }
            }
        )
        triggers = @(
            @{
                triggerType = "continuousIntegration"
                branchFilters = @("+refs/heads/main")
            }
        )
    }
    
    $classicBuildUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/build/definitions" -ApiVersion "7.0"
    
    try {
        $createdBuild = Invoke-AdoRestApi -Uri $classicBuildUri -Method POST -Headers $headers -Body $classicBuildBody
        $buildPipelineIds += @{
            id = $createdBuild.id
            name = $createdBuild.name
            type = "Classic Build"
        }
        Write-Host "    ✓ Created classic build definition ID: $($createdBuild.id)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Failed to create classic build: $($build.name) - $_" -ForegroundColor Yellow
    }
}

# Save pipeline information
$outputPath = "$PSScriptRoot\..\output"
$pipelineInfo = @{
    buildPipelines = $buildPipelineIds
    releasePipelines = $releasePipelineIds
    totalBuildPipelines = $buildPipelineIds.Count
    totalReleasePipelines = $releasePipelineIds.Count
    yamlPipelines = ($buildPipelineIds | Where-Object { $_.type -ne "Classic Build" }).Count
    classicBuilds = ($buildPipelineIds | Where-Object { $_.type -eq "Classic Build" }).Count
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

$pipelineInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\pipelines-info.json"

Write-Host "`n✓ Pipeline creation completed!" -ForegroundColor Green
Write-Host "  Build Pipelines: $($buildPipelineIds.Count) (YAML: $(($buildPipelineIds | Where-Object { $_.type -ne 'Classic Build' }).Count), Classic: $(($buildPipelineIds | Where-Object { $_.type -eq 'Classic Build' }).Count))" -ForegroundColor Cyan
Write-Host "  Release Pipelines: $($releasePipelineIds.Count)" -ForegroundColor Cyan
Write-Host "`nPipeline information saved to: $outputPath\pipelines-info.json" -ForegroundColor Cyan

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 07-link-objects.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
