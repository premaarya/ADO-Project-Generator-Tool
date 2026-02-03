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

# Define 12 YAML CI pipelines with reusable templates
$yamlPipelineDefinitions = @(
    @{
        name = "Main-Web-App-CI"
        repository = "main-app"
        path = "pipelines/main-web-app-ci.yaml"
        description = "CI pipeline for main web application (.NET)"
        type = "dotnet"
    },
    @{
        name = "API-Gateway-CI"
        repository = "main-app"
        path = "pipelines/api-gateway-ci.yaml"
        description = "CI pipeline for API Gateway (.NET)"
        type = "dotnet"
    },
    @{
        name = "Auth-Service-CI"
        repository = "main-app"
        path = "pipelines/auth-service-ci.yaml"
        description = "CI pipeline for Authentication Service (Node.js)"
        type = "node"
    },
    @{
        name = "User-Service-CI"
        repository = "main-app"
        path = "pipelines/user-service-ci.yaml"
        description = "CI pipeline for User Management Service (Node.js)"
        type = "node"
    },
    @{
        name = "Notification-Service-CI"
        repository = "main-app"
        path = "pipelines/notification-service-ci.yaml"
        description = "CI pipeline for Notification Service (Python)"
        type = "python"
    },
    @{
        name = "Analytics-Service-CI"
        repository = "main-app"
        path = "pipelines/analytics-service-ci.yaml"
        description = "CI pipeline for Analytics Service (Python)"
        type = "python"
    },
    @{
        name = "Frontend-App-CI"
        repository = "main-app"
        path = "pipelines/frontend-app-ci.yaml"
        description = "CI pipeline for Frontend Application (Node.js/React)"
        type = "node"
    },
    @{
        name = "Mobile-Backend-CI"
        repository = "main-app"
        path = "pipelines/mobile-backend-ci.yaml"
        description = "CI pipeline for Mobile Backend (.NET)"
        type = "dotnet"
    },
    @{
        name = "Data-Processing-CI"
        repository = "main-app"
        path = "pipelines/data-processing-ci.yaml"
        description = "CI pipeline for Data Processing Service (Python)"
        type = "python"
    },
    @{
        name = "Payment-Service-CI"
        repository = "main-app"
        path = "pipelines/payment-service-ci.yaml"
        description = "CI pipeline for Payment Service (.NET)"
        type = "dotnet"
    },
    @{
        name = "API-Docs-CI"
        repository = "documentation"
        path = "pipelines/api-docs-ci.yaml"
        description = "CI pipeline for API Documentation Generator (Node.js)"
        type = "node-docs"
    },
    @{
        name = "Container-WebApp-CI"
        repository = "main-app"
        path = "pipelines/container-webapp-ci.yaml"
        description = "CI pipeline for Web App Container"
        type = "docker"
    }
)

# Function to generate YAML content based on pipeline type
function Get-PipelineYamlContent {
    param(
        [string]$PipelineName,
        [string]$Type
    )
    
    switch ($Type) {
        "dotnet" {
            return @"
# Azure DevOps CI Pipeline for $PipelineName
name: $PipelineName

trigger:
  branches:
    include:
    - main
    - develop
    - feature/*
  paths:
    include:
    - src/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: Build
    displayName: 'Build Job'
    steps:
    - template: templates/dotnet-build-template.yaml
      parameters:
        buildConfiguration: `$(buildConfiguration)
        dotnetVersion: '8.x'
        projectPath: '**/*.csproj'
        testProjectPath: '**/*Tests.csproj'
        runTests: true
        publishArtifacts: true
"@
        }
        "node" {
            return @"
# Azure DevOps CI Pipeline for $PipelineName
name: $PipelineName

trigger:
  branches:
    include:
    - main
    - develop
    - hotfix/*
  paths:
    include:
    - services/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  nodeVersion: '20.x'

stages:
- stage: Build
  displayName: 'Build Service'
  jobs:
  - job: Build
    steps:
    - template: templates/node-build-template.yaml
      parameters:
        nodeVersion: `$(nodeVersion)
        workingDirectory: '.'
        runLint: true
        runTests: true
        buildCommand: 'npm run build'
        publishArtifacts: true
"@
        }
        "python" {
            return @"
# Azure DevOps CI Pipeline for $PipelineName
name: $PipelineName

trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - services/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  pythonVersion: '3.11'

stages:
- stage: Build
  displayName: 'Build Service'
  jobs:
  - job: Build
    steps:
    - template: templates/python-build-template.yaml
      parameters:
        pythonVersion: `$(pythonVersion)
        workingDirectory: '.'
        requirementsFile: 'requirements.txt'
        runQualityChecks: true
        runTests: true
        publishArtifacts: true
"@
        }
        "docker" {
            return @"
# Azure DevOps CI Pipeline for $PipelineName
name: $PipelineName

trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - docker/*
    - src/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  imageName: 'webapp'
  containerRegistry: 'MyContainerRegistry'

stages:
- stage: Build
  displayName: 'Build Container'
  jobs:
  - job: BuildDocker
    displayName: 'Build Docker Image'
    steps:
    - template: templates/docker-build-template.yaml
      parameters:
        dockerfilePath: 'Dockerfile'
        imageName: `$(imageName)
        containerRegistry: `$(containerRegistry)
        runSecurityScan: true
        buildContext: '.'
        additionalTags:
        - 'v1.0.`$(Build.BuildId)'
"@
        }
        "node-docs" {
            return @"
# Azure DevOps CI Pipeline for $PipelineName
name: $PipelineName

trigger:
  branches:
    include:
    - main
  paths:
    include:
    - docs/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  nodeVersion: '20.x'

stages:
- stage: Build
  displayName: 'Build Documentation'
  jobs:
  - job: Build
    steps:
    - template: templates/node-build-template.yaml
      parameters:
        nodeVersion: `$(nodeVersion)
        workingDirectory: '.'
        runLint: false
        runTests: false
        buildCommand: 'npm run build:docs'
        publishArtifacts: true
"@
        }
        default {
            return @"
# Azure DevOps Pipeline for $PipelineName
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: Build
    displayName: 'Build Job'
    steps:
    - script: echo 'Building $PipelineName'
      displayName: 'Build'
"@
        }
    }
}

foreach ($pipelineDef in $yamlPipelineDefinitions) {
    Write-Host "  Creating YAML CI pipeline: $($pipelineDef.name)" -ForegroundColor White
    
    # Find repository
    $repository = $repos.repositories | Where-Object { $_.name -eq $pipelineDef.repository } | Select-Object -First 1
    
    if (-not $repository) {
        Write-Host "    ⚠ Repository not found: $($pipelineDef.repository)" -ForegroundColor Yellow
        continue
    }
    
    # Generate YAML content based on pipeline type
    $yamlContent = Get-PipelineYamlContent -PipelineName $pipelineDef.name -Type $pipelineDef.type
    
    $yamlBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($yamlContent))
    
    # Also create template files if they don't exist in the repository
    $templateFiles = @{
        "templates/dotnet-build-template.yaml" = @"
# Reusable template for .NET builds
parameters:
- name: buildConfiguration
  type: string
  default: 'Release'
- name: dotnetVersion
  type: string
  default: '8.x'
- name: projectPath
  type: string
  default: '**/*.csproj'
- name: testProjectPath
  type: string
  default: '**/*Tests.csproj'
- name: runTests
  type: boolean
  default: true
- name: publishArtifacts
  type: boolean
  default: true

steps:
- task: UseDotNet@2
  displayName: 'Install .NET SDK `${{ parameters.dotnetVersion }}'
  inputs:
    packageType: 'sdk'
    version: '`${{ parameters.dotnetVersion }}'

- task: DotNetCoreCLI@2
  displayName: 'Restore NuGet Packages'
  inputs:
    command: 'restore'
    projects: '`${{ parameters.projectPath }}'

- task: DotNetCoreCLI@2
  displayName: 'Build Solution'
  inputs:
    command: 'build'
    projects: '`${{ parameters.projectPath }}'
    arguments: '--configuration `${{ parameters.buildConfiguration }} --no-restore'

- `${{ if eq(parameters.runTests, true) }}:
  - task: DotNetCoreCLI@2
    displayName: 'Run Unit Tests'
    inputs:
      command: 'test'
      projects: '`${{ parameters.testProjectPath }}'
      arguments: '--configuration `${{ parameters.buildConfiguration }} --no-build --collect:"XPlat Code Coverage" --logger trx'
      publishTestResults: true

  - task: PublishCodeCoverageResults@1
    displayName: 'Publish Code Coverage'
    condition: succeededOrFailed()
    inputs:
      codeCoverageTool: 'Cobertura'
      summaryFileLocation: '`$(Agent.TempDirectory)/**/coverage.cobertura.xml'

- `${{ if eq(parameters.publishArtifacts, true) }}:
  - task: DotNetCoreCLI@2
    displayName: 'Publish Application'
    inputs:
      command: 'publish'
      publishWebProjects: false
      projects: '`${{ parameters.projectPath }}'
      arguments: '--configuration `${{ parameters.buildConfiguration }} --output `$(Build.ArtifactStagingDirectory) --no-build'
      zipAfterPublish: true

  - task: PublishBuildArtifacts@1
    displayName: 'Publish Build Artifacts'
    inputs:
      PathtoPublish: '`$(Build.ArtifactStagingDirectory)'
      ArtifactName: 'drop'
      publishLocation: 'Container'
"@
        "templates/node-build-template.yaml" = @"
# Reusable template for Node.js builds
parameters:
- name: nodeVersion
  type: string
  default: '20.x'
- name: workingDirectory
  type: string
  default: '.'
- name: runLint
  type: boolean
  default: true
- name: runTests
  type: boolean
  default: true
- name: buildCommand
  type: string
  default: 'npm run build'
- name: publishArtifacts
  type: boolean
  default: true

steps:
- task: NodeTool@0
  displayName: 'Install Node.js `${{ parameters.nodeVersion }}'
  inputs:
    versionSpec: '`${{ parameters.nodeVersion }}'

- script: npm ci
  displayName: 'Install Dependencies'
  workingDirectory: '`${{ parameters.workingDirectory }}'

- `${{ if eq(parameters.runLint, true) }}:
  - script: npm run lint
    displayName: 'Run Linting'
    workingDirectory: '`${{ parameters.workingDirectory }}'
    continueOnError: true

- `${{ if eq(parameters.runTests, true) }}:
  - script: npm run test
    displayName: 'Run Tests'
    workingDirectory: '`${{ parameters.workingDirectory }}'

  - task: PublishTestResults@2
    displayName: 'Publish Test Results'
    condition: succeededOrFailed()
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: '**/test-results.xml'
      searchFolder: '`${{ parameters.workingDirectory }}'

  - task: PublishCodeCoverageResults@1
    displayName: 'Publish Code Coverage'
    condition: succeededOrFailed()
    inputs:
      codeCoverageTool: 'Cobertura'
      summaryFileLocation: '`${{ parameters.workingDirectory }}/coverage/cobertura-coverage.xml'

- script: `${{ parameters.buildCommand }}
  displayName: 'Build Application'
  workingDirectory: '`${{ parameters.workingDirectory }}'

- `${{ if eq(parameters.publishArtifacts, true) }}:
  - task: ArchiveFiles@2
    displayName: 'Archive Build Output'
    inputs:
      rootFolderOrFile: '`${{ parameters.workingDirectory }}/dist'
      includeRootFolder: false
      archiveType: 'zip'
      archiveFile: '`$(Build.ArtifactStagingDirectory)/app-`$(Build.BuildId).zip'

  - task: PublishBuildArtifacts@1
    displayName: 'Publish Build Artifacts'
    inputs:
      PathtoPublish: '`$(Build.ArtifactStagingDirectory)'
      ArtifactName: 'drop'
      publishLocation: 'Container'
"@
        "templates/python-build-template.yaml" = @"
# Reusable template for Python builds
parameters:
- name: pythonVersion
  type: string
  default: '3.11'
- name: workingDirectory
  type: string
  default: '.'
- name: requirementsFile
  type: string
  default: 'requirements.txt'
- name: runQualityChecks
  type: boolean
  default: true
- name: runTests
  type: boolean
  default: true
- name: publishArtifacts
  type: boolean
  default: true

steps:
- task: UsePythonVersion@0
  displayName: 'Use Python `${{ parameters.pythonVersion }}'
  inputs:
    versionSpec: '`${{ parameters.pythonVersion }}'

- script: |
    python -m pip install --upgrade pip
    pip install -r `${{ parameters.requirementsFile }}
  displayName: 'Install Dependencies'
  workingDirectory: '`${{ parameters.workingDirectory }}'

- `${{ if eq(parameters.runQualityChecks, true) }}:
  - script: |
      pip install pylint flake8 black mypy
      black --check . || true
      flake8 . --max-line-length=120 --exclude=venv,env,.git --exit-zero
      pylint **/*.py --exit-zero
    displayName: 'Run Code Quality Checks'
    workingDirectory: '`${{ parameters.workingDirectory }}'
    continueOnError: true

- `${{ if eq(parameters.runTests, true) }}:
  - script: |
      pip install pytest pytest-cov pytest-asyncio
      pytest tests/ --cov=. --cov-report=xml --cov-report=html --junitxml=test-results.xml
    displayName: 'Run Tests with Coverage'
    workingDirectory: '`${{ parameters.workingDirectory }}'
    continueOnError: false

  - task: PublishTestResults@2
    displayName: 'Publish Test Results'
    condition: succeededOrFailed()
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: '**/test-results.xml'
      searchFolder: '`${{ parameters.workingDirectory }}'

  - task: PublishCodeCoverageResults@1
    displayName: 'Publish Code Coverage'
    condition: succeededOrFailed()
    inputs:
      codeCoverageTool: 'Cobertura'
      summaryFileLocation: '`${{ parameters.workingDirectory }}/coverage.xml'

- `${{ if eq(parameters.publishArtifacts, true) }}:
  - script: |
      pip install wheel setuptools
      python setup.py bdist_wheel || echo "No setup.py found"
    displayName: 'Build Package'
    workingDirectory: '`${{ parameters.workingDirectory }}'
    continueOnError: true

  - task: PublishBuildArtifacts@1
    displayName: 'Publish Build Artifacts'
    inputs:
      PathtoPublish: '`${{ parameters.workingDirectory }}'
      ArtifactName: 'drop'
      publishLocation: 'Container'
"@
        "templates/docker-build-template.yaml" = @"
# Reusable template for Docker builds
parameters:
- name: dockerfilePath
  type: string
  default: 'Dockerfile'
- name: imageName
  type: string
- name: containerRegistry
  type: string
  default: ''
- name: runSecurityScan
  type: boolean
  default: true
- name: buildContext
  type: string
  default: '.'
- name: additionalTags
  type: object
  default: []

steps:
- task: Docker@2
  displayName: 'Build Docker Image'
  inputs:
    command: 'build'
    repository: '`${{ parameters.imageName }}'
    dockerfile: '`${{ parameters.dockerfilePath }}'
    buildContext: '`${{ parameters.buildContext }}'
    tags: |
      `$(Build.BuildId)
      latest
      `${{ join('\n', parameters.additionalTags) }}

- `${{ if eq(parameters.runSecurityScan, true) }}:
  - script: |
      docker run --rm aquasec/trivy image --severity HIGH,CRITICAL `${{ parameters.imageName }}:`$(Build.BuildId) || true
    displayName: 'Run Security Scan'
    continueOnError: true

- `${{ if ne(parameters.containerRegistry, '') }}:
  - task: Docker@2
    displayName: 'Push Docker Image'
    inputs:
      command: 'push'
      containerRegistry: '`${{ parameters.containerRegistry }}'
      repository: '`${{ parameters.imageName }}'
      tags: |
        `$(Build.BuildId)
        latest
        `${{ join('\n', parameters.additionalTags) }}
"@
    }
    
    # Get main branch commit
    $refsUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repository.id)/refs?filter=heads/main"
    
    try {
        $mainRef = Invoke-AdoRestApi -Uri $refsUri -Method GET -Headers $headers
        
        if ($mainRef.value.Count -gt 0) {
            $mainCommitId = $mainRef.value[0].objectId
            
            # Prepare all file changes (pipeline YAML + templates)
            $allChanges = @()
            
            # Add the main pipeline YAML
            $allChanges += @{
                changeType = "add"
                item = @{
                    path = "/$($pipelineDef.path)"
                }
                newContent = @{
                    content = $yamlBase64
                    contentType = "base64encoded"
                }
            }
            
            # Add template files (only on first pipeline to avoid conflicts)
            if ($pipelineDef.name -eq "Main-Web-App-CI") {
                foreach ($templatePath in $templateFiles.Keys) {
                    $templateContent = $templateFiles[$templatePath]
                    $templateBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($templateContent))
                    
                    $allChanges += @{
                        changeType = "add"
                        item = @{
                            path = "/$templatePath"
                        }
                        newContent = @{
                            content = $templateBase64
                            contentType = "base64encoded"
                        }
                    }
                }
            }
            
            # Commit all changes at once
            $pushBody = @{
                refUpdates = @(
                    @{
                        name = "refs/heads/main"
                        oldObjectId = $mainCommitId
                    }
                )
                commits = @(
                    @{
                        comment = "Add Azure Pipeline YAML for $($pipelineDef.name)"
                        changes = $allChanges
                    }
                )
            }
            
            $pushUri = New-AdoUri -Organization $org -Project $project -Resource "_apis/git/repositories/$($repository.id)/pushes"
            $pushResult = Invoke-AdoRestApi -Uri $pushUri -Method POST -Headers $headers -Body $pushBody
            Write-Host "    ✓ Added pipeline YAML to repository" -ForegroundColor Green
            
            # Update commit ID for next iteration
            $mainCommitId = $pushResult.commits[0].commitId
        }
    } catch {
        Write-Host "    ⚠ Could not add YAML file: $_" -ForegroundColor Yellow
    }
    
    # Create pipeline definition
    $pipelineBody = @{
        name = $pipelineDef.name
        folder = "\\"
        configuration = @{
            type = "yaml"
            path = $pipelineDef.path
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
            description = $pipelineDef.description
        }
        Write-Host "    ✓ Created YAML CI pipeline ID: $($createdPipeline.id)" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Failed to create YAML pipeline: $($pipelineDef.name) - $_" -ForegroundColor Yellow
    }
    
    # Small delay to avoid rate limiting
    Start-Sleep -Milliseconds 500
}

Write-Host "`n  Summary: Created $($buildPipelineIds.Count) YAML CI pipelines with reusable templates" -ForegroundColor Green


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
