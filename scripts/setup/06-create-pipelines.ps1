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
$classicBuildIds = @()
$classicReleaseIds = @()

# ===== CREATE CLASSIC BUILD PIPELINES =====
Write-Host "`n[1/4] Creating Classic Build Pipelines..." -ForegroundColor Cyan

$classicBuilds = $config.pipelines.build | Where-Object { $_.type -eq "classic" }

foreach ($pipeline in $classicBuilds) {
    Write-Host "  Creating classic build pipeline: $($pipeline.name)" -ForegroundColor White
    
    # Find repository
    $repository = $repos.repositories | Where-Object { $_.name -eq $pipeline.repository } | Select-Object -First 1
    
    if (-not $repository) {
        Write-Host "    ⚠ Repository not found: $($pipeline.repository)" -ForegroundColor Yellow
        continue
    }
    
    # Create classic build definition
    $buildDefinition = @{
        name = $pipeline.name
        type = "build"
        quality = "definition"
        queue = @{
            id = 1
        }
        repository = @{
            id = $repository.id
            type = "TfsGit"
            name = $repository.name
            defaultBranch = "refs/heads/main"
            clean = $true
        }
        triggers = @(
            @{
                branchFilters = @("+refs/heads/main", "+refs/heads/develop")
                pathFilters = @()
                settingsSourceType = 2
                batchChanges = $false
                maxConcurrentBuildsPerBranch = 1
                triggerType = "continuousIntegration"
            }
        )
        variables = @{
            BuildConfiguration = @{
                value = "Release"
                allowOverride = $true
            }
            BuildPlatform = @{
                value = "Any CPU"
                allowOverride = $true
            }
        }
        buildNumberFormat = "`$(Date:yyyyMMdd)`$(Rev:.r)"
        comment = $pipeline.description
        process = @{
            type = 1
            phases = @(
                @{
                    name = "Agent job 1"
                    refName = "Job_1"
                    condition = "succeeded()"
                    target = @{
                        type = 1
                        queue = @{
                            id = 1
                        }
                        allowScriptsAuthAccessOption = $false
                    }
                    jobAuthorizationScope = "projectCollection"
                    steps = @(
                        @{
                            displayName = "Restore NuGet packages"
                            enabled = $true
                            task = @{
                                id = "333b11bd-d341-40d9-afcf-b32d5ce6f23b"
                                versionSpec = "2.*"
                                definitionType = "task"
                            }
                            inputs = @{
                                command = "restore"
                                restoreSolution = "**/*.sln"
                                feedsToUse = "select"
                            }
                        },
                        @{
                            displayName = "Build solution"
                            enabled = $true
                            task = @{
                                id = "71a9a2d3-a98a-4caa-96ab-affca411ecda"
                                versionSpec = "1.*"
                                definitionType = "task"
                            }
                            inputs = @{
                                solution = "**/*.sln"
                                msbuildArgs = "/p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true"
                                platform = "`$(BuildPlatform)"
                                configuration = "`$(BuildConfiguration)"
                            }
                        },
                        @{
                            displayName = "Test Assemblies"
                            enabled = $true
                            task = @{
                                id = "ef087383-ee5e-42c7-9a53-ab56c98420f9"
                                versionSpec = "2.*"
                                definitionType = "task"
                            }
                            inputs = @{
                                testSelector = "testAssemblies"
                                testAssemblyVer2 = "**\*test*.dll`n!**\*TestAdapter.dll`n!**\obj\**"
                                searchFolder = "`$(System.DefaultWorkingDirectory)"
                                runSettingsFile = ""
                                codeCoverageEnabled = $true
                            }
                        },
                        @{
                            displayName = "Publish Build Artifacts"
                            enabled = $true
                            task = @{
                                id = "2ff763a7-ce83-4e1f-bc89-0ae63477cebe"
                                versionSpec = "1.*"
                                definitionType = "task"
                            }
                            inputs = @{
                                PathtoPublish = "`$(Build.ArtifactStagingDirectory)"
                                ArtifactName = "drop"
                                publishLocation = "Container"
                            }
                        }
                    )
                }
            )
        }
    }
    
    # Create the build definition with correct Content-Type for classic pipelines
    $classicHeaders = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
    $buildUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/build/definitions" -ApiVersion "7.1-preview.7"
    
    try {
        $createdBuild = Invoke-AdoRestApi -Uri $buildUri -Method POST -Headers $classicHeaders -Body $buildDefinition
        $classicBuildIds += @{
            id = $createdBuild.id
            name = $createdBuild.name
            type = "classic"
        }
        Write-Host "    ✓ Created classic build pipeline ID: $($createdBuild.id)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Failed to create classic build pipeline: $_" -ForegroundColor Yellow
    }
}

# ===== CREATE YAML BUILD PIPELINES =====
Write-Host "`n[2/4] Creating YAML Build Pipelines..." -ForegroundColor Cyan

$yamlBuilds = $config.pipelines.build | Where-Object { $_.type -eq "yaml" }

foreach ($pipeline in $yamlBuilds) {
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
    
    # Create pipeline definition with correct headers
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
    
    # YAML pipelines need application/json
    $yamlHeaders = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
    $pipelinesUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/pipelines" -ApiVersion "7.1-preview.1"
    
    try {
        $createdPipeline = Invoke-AdoRestApi -Uri $pipelinesUri -Method POST -Headers $yamlHeaders -Body $pipelineBody
        $buildPipelineIds += @{
            id = $createdPipeline.id
            name = $createdPipeline.name
            type = "yaml"
        }
        Write-Host "    ✓ Created YAML pipeline ID: $($createdPipeline.id)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Failed to create YAML pipeline: $($pipeline.name)" -ForegroundColor Yellow
    }
}

# ===== CREATE CLASSIC RELEASE PIPELINES =====
Write-Host "`n[3/4] Creating Classic Release Pipelines..." -ForegroundColor Cyan

$classicReleases = $config.pipelines.release | Where-Object { $_.type -eq "classic" }

foreach ($release in $classicReleases) {
    Write-Host "  Creating classic release pipeline: $($release.name)" -ForegroundColor White
    
    # Build environments/stages for classic releases
    $environments = @()
    $rank = 1
    
    foreach ($stage in $release.stages) {
        $stageName = $stage
        $environment = @{
            id = -$rank
            name = $stageName
            rank = $rank
            owner = @{
                displayName = "Build Service"
                id = "00000000-0000-0000-0000-000000000000"
            }
            variables = @{}
            preDeployApprovals = @{
                approvals = @()
                approvalOptions = @{
                    requiredApproverCount = $null
                    releaseCreatorCanBeApprover = $false
                    autoTriggeredAndPreviousEnvironmentApprovedCanBeSkipped = $false
                    enforceIdentityRevalidation = $false
                    timeoutInMinutes = 0
                    executionOrder = "beforeGates"
                }
            }
            postDeployApprovals = @{
                approvals = @()
                approvalOptions = @{
                    requiredApproverCount = $null
                    releaseCreatorCanBeApprover = $false
                    autoTriggeredAndPreviousEnvironmentApprovedCanBeSkipped = $false
                    enforceIdentityRevalidation = $false
                    timeoutInMinutes = 0
                    executionOrder = "afterSuccessfulGates"
                }
            }
            deployPhases = @(
                @{
                    deploymentInput = @{
                        queueId = 1
                        demands = @()
                        enableAccessToken = $false
                        timeoutInMinutes = 0
                        jobCancelTimeoutInMinutes = 1
                        condition = "succeeded()"
                        overrideInputs = @{}
                    }
                    rank = 1
                    phaseType = "agentBasedDeployment"
                    name = "Agent job"
                    workflowTasks = @(
                        @{
                            taskId = "e213ff0f-5d5c-4791-802d-52ea3e7be1f1"
                            version = "2.*"
                            name = "Deploy to $stageName"
                            enabled = $true
                            alwaysRun = $false
                            continueOnError = $false
                            timeoutInMinutes = 0
                            definitionType = "task"
                            overrideInputs = @{}
                            condition = "succeeded()"
                            inputs = @{
                                ConnectedServiceName = ""
                                WebAppName = ""
                                DeployToSlotOrASEFlag = "false"
                                ResourceGroupName = ""
                                SlotName = "production"
                                Package = "`$(System.DefaultWorkingDirectory)/**/*.zip"
                                RuntimeStack = "DOTNETCORE|Latest"
                                StartupCommand = ""
                            }
                        }
                    )
                }
            )
            conditions = @(
                @{
                    conditionType = "artifact"
                    name = "ReleaseStarted"
                    value = ""
                }
            )
            executionPolicy = @{
                concurrencyCount = 1
                queueDepthCount = 0
            }
            schedules = @()
            retentionPolicy = @{
                daysToKeep = 30
                releasesToKeep = 3
                retainBuild = $true
            }
        }
        
        # Add manual approval for Production/Staging
        if ($stageName -match "Production|Staging") {
            $environment.preDeployApprovals.approvals = @(
                @{
                    rank = 1
                    isAutomated = $false
                    isNotificationOn = $true
                    approver = @{
                        displayName = "Manual Approver"
                        id = "00000000-0000-0000-0000-000000000000"
                    }
                }
            )
        }
        
        $environments += $environment
        $rank++
    }
    
    # Find artifact source (use first build pipeline created)
    $artifactSource = $null
    if ($classicBuildIds.Count -gt 0) {
        $artifactSource = $classicBuildIds[0]
    } elseif ($buildPipelineIds.Count -gt 0) {
        $artifactSource = $buildPipelineIds[0]
    }
    
    if (-not $artifactSource) {
        Write-Host "    ⚠ No build pipeline found for artifact source" -ForegroundColor Yellow
        continue
    }
    
    # Create classic release definition
    $releaseDefinition = @{
        name = $release.name
        comment = $release.description
        source = 2
        revision = 1
        environments = $environments
        artifacts = @(
            @{
                sourceId = "$($project):$($artifactSource.id)"
                type = "Build"
                alias = "_$($artifactSource.name)"
                definitionReference = @{
                    definition = @{
                        id = "$($artifactSource.id)"
                        name = $artifactSource.name
                    }
                    project = @{
                        id = $projectId
                        name = $project
                    }
                }
                isPrimary = $true
            }
        )
        triggers = @(
            @{
                triggerType = "artifactSource"
                artifactAlias = "_$($artifactSource.name)"
                triggerConditions = @()
            }
        )
        variables = @{
            Environment = @{
                value = "Production"
            }
        }
        variableGroups = @()
    }
    
    $releaseUri = New-AdoUri -Organization $org -Project $project -Resource "release/definitions" -ApiVersion "7.1-preview.4"
    $releaseUri = $releaseUri -replace "dev\.azure\.com", "vsrm.dev.azure.com"
    
    # Use application/json for classic release definitions
    $releaseHeaders = Get-AdoHeaders -Pat $config.pat -ContentType "application/json"
    
    try {
        $createdRelease = Invoke-AdoRestApi -Uri $releaseUri -Method POST -Headers $releaseHeaders -Body $releaseDefinition
        $classicReleaseIds += @{
            id = $createdRelease.id
            name = $createdRelease.name
            type = "classic"
        }
        Write-Host "    ✓ Created classic release pipeline ID: $($createdRelease.id)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Failed to create classic release pipeline: $($release.name) - $_" -ForegroundColor Yellow
    }
}

# ===== CREATE YAML RELEASE PIPELINES =====
Write-Host "`n[4/4] Creating YAML Release Pipelines..." -ForegroundColor Cyan

$yamlReleases = $config.pipelines.release | Where-Object { $_.type -eq "yaml" }

foreach ($release in $yamlReleases) {
    Write-Host "  Creating YAML release pipeline: $($release.name)" -ForegroundColor White
    
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
    classicBuildPipelines = $classicBuildIds
    classicReleasePipelines = $classicReleaseIds
    totalBuildPipelines = $buildPipelineIds.Count + $classicBuildIds.Count
    totalReleasePipelines = $releasePipelineIds.Count + $classicReleaseIds.Count
    yamlBuildPipelines = $buildPipelineIds.Count
    classicBuilds = $classicBuildIds.Count
    classicReleases = $classicReleaseIds.Count
    createdDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

$pipelineInfo | ConvertTo-Json -Depth 10 | Set-Content "$outputPath\pipelines-info.json"

Write-Host "`n✓ Pipeline creation completed!" -ForegroundColor Green
Write-Host "  Build Pipelines: $($buildPipelineIds.Count + $classicBuildIds.Count) (YAML: $($buildPipelineIds.Count), Classic: $($classicBuildIds.Count))" -ForegroundColor Cyan
Write-Host "  Release Pipelines: $($releasePipelineIds.Count + $classicReleaseIds.Count) (YAML: $($releasePipelineIds.Count), Classic: $($classicReleaseIds.Count))" -ForegroundColor Cyan
Write-Host "`nPipeline information saved to: $outputPath\pipelines-info.json" -ForegroundColor Cyan

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor DarkGray
Write-Host "Next Step: Run 07-link-objects.ps1" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor DarkGray
