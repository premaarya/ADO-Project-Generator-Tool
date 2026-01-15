# Azure DevOps REST API Helper Functions
# Provides reusable functions for interacting with Azure DevOps REST API

function Get-AdoHeaders {
    <#
    .SYNOPSIS
        Generates authentication headers for Azure DevOps REST API calls
    .PARAMETER Pat
        Personal Access Token for authentication
    .PARAMETER ContentType
        Optional Content-Type header override (default: "application/json-patch+json")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pat,
        
        [Parameter(Mandatory=$false)]
        [string]$ContentType = "application/json-patch+json"
    )
    
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
    return @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = $ContentType
        "Accept" = "application/json"
    }
}

function Invoke-AdoRestApi {
    <#
    .SYNOPSIS
        Generic wrapper for Azure DevOps REST API calls with error handling and retry logic
    .PARAMETER Uri
        The full URI for the REST API endpoint
    .PARAMETER Method
        HTTP method (GET, POST, PATCH, PUT, DELETE)
    .PARAMETER Headers
        Authentication and content-type headers
    .PARAMETER Body
        Request body (will be converted to JSON if not already)
    .PARAMETER MaxRetries
        Maximum number of retry attempts (default: 3)
    .PARAMETER RetryDelaySeconds
        Delay between retries in seconds (default: 2)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('GET','POST','PATCH','PUT','DELETE')]
        [string]$Method,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Headers,
        
        [Parameter(Mandatory=$false)]
        [object]$Body,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryDelaySeconds = 2
    )
    
    $attempt = 0
    $success = $false
    $response = $null
    
    while (-not $success -and $attempt -lt $MaxRetries) {
        $attempt++
        try {
            Write-Verbose "Attempt $attempt of $MaxRetries for $Method $Uri"
            
            $params = @{
                Uri = $Uri
                Method = $Method
                Headers = $Headers
            }
            
            if ($Body) {
                if ($Body -is [string]) {
                    $params.Body = $Body
                } else {
                    $params.Body = $Body | ConvertTo-Json -Depth 100 -Compress
                }
            }
            
            $response = Invoke-RestMethod @params
            $success = $true
            
            Write-Verbose "Successfully completed $Method request to $Uri"
            return $response
            
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMessage = $_.Exception.Message
            
            if ($statusCode -eq 429 -or $statusCode -ge 500) {
                # Retry on rate limiting or server errors
                if ($attempt -lt $MaxRetries) {
                    Write-Warning "Request failed with status $statusCode. Retrying in $RetryDelaySeconds seconds... (Attempt $attempt of $MaxRetries)"
                    Start-Sleep -Seconds $RetryDelaySeconds
                    $RetryDelaySeconds = $RetryDelaySeconds * 2  # Exponential backoff
                } else {
                    Write-Error "Request failed after $MaxRetries attempts: $errorMessage"
                    throw
                }
            } else {
                # Don't retry on client errors
                Write-Error "Request failed with status $statusCode : $errorMessage"
                Write-Error "Response: $($_.Exception.Response | ConvertTo-Json -Depth 5)"
                throw
            }
        }
    }
    
    return $response
}

function ConvertTo-JsonDepth {
    <#
    .SYNOPSIS
        Converts an object to JSON with specified depth to handle complex nested objects
    .PARAMETER InputObject
        The object to convert
    .PARAMETER Depth
        The depth of serialization (default: 100)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$InputObject,
        
        [Parameter(Mandatory=$false)]
        [int]$Depth = 100
    )
    
    return $InputObject | ConvertTo-Json -Depth $Depth -Compress
}

function Get-AdoConfig {
    <#
    .SYNOPSIS
        Loads configuration from config.json file
    .PARAMETER ConfigPath
        Path to the config.json file
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = "$PSScriptRoot\config.json"
    )
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found at: $ConfigPath"
    }
    
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    
    # Validate required fields
    $requiredFields = @('organization', 'project', 'pat')
    foreach ($field in $requiredFields) {
        if (-not $config.$field) {
            throw "Required configuration field '$field' is missing or empty"
        }
    }
    
    return $config
}

function New-AdoUri {
    <#
    .SYNOPSIS
        Constructs Azure DevOps REST API URIs
    .PARAMETER Organization
        ADO organization name
    .PARAMETER Project
        ADO project name
    .PARAMETER Resource
        API resource path (e.g., "_apis/wit/workitems")
    .PARAMETER ApiVersion
        API version (default: 7.0)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Organization,
        
        [Parameter(Mandatory=$false)]
        [string]$Project,
        
        [Parameter(Mandatory=$true)]
        [string]$Resource,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiVersion = "7.0"
    )
    
    $baseUri = "https://dev.azure.com/$Organization"
    
    if ($Project) {
        $baseUri = "$baseUri/$Project"
    }
    
    $uri = "$baseUri/$Resource"
    
    if ($Resource -notmatch '\?') {
        $uri += "?api-version=$ApiVersion"
    } elseif ($Resource -notmatch 'api-version=') {
        $uri += "&api-version=$ApiVersion"
    }
    
    return $uri
}

function Wait-AdoOperation {
    <#
    .SYNOPSIS
        Waits for an asynchronous ADO operation to complete
    .PARAMETER OperationUri
        URI to poll for operation status
    .PARAMETER Headers
        Authentication headers
    .PARAMETER TimeoutSeconds
        Maximum time to wait (default: 300)
    .PARAMETER PollIntervalSeconds
        Interval between status checks (default: 5)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$OperationUri,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Headers,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 300,
        
        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 5
    )
    
    $startTime = Get-Date
    $completed = $false
    
    while (-not $completed) {
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        
        if ($elapsed -gt $TimeoutSeconds) {
            throw "Operation timed out after $TimeoutSeconds seconds"
        }
        
        $status = Invoke-AdoRestApi -Uri $OperationUri -Method GET -Headers $Headers
        
        if ($status.status -eq "succeeded") {
            $completed = $true
            return $status
        } elseif ($status.status -eq "failed") {
            throw "Operation failed: $($status.message)"
        }
        
        Write-Verbose "Operation in progress... (elapsed: $([int]$elapsed)s)"
        Start-Sleep -Seconds $PollIntervalSeconds
    }
}

function Add-WorkItemAttachment {
    <#
    .SYNOPSIS
        Uploads an attachment to Azure DevOps and returns the attachment reference
    .PARAMETER Organization
        ADO organization name
    .PARAMETER FilePath
        Path to the file to attach
    .PARAMETER Headers
        Authentication headers
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Organization,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Headers
    )
    
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    $fileName = Split-Path $FilePath -Leaf
    $fileContent = [System.IO.File]::ReadAllBytes($FilePath)
    
    $uploadHeaders = $Headers.Clone()
    $uploadHeaders["Content-Type"] = "application/octet-stream"
    
    $uploadUri = "https://dev.azure.com/$Organization/_apis/wit/attachments?fileName=$fileName&api-version=7.0"
    
    $response = Invoke-RestMethod -Uri $uploadUri -Method POST -Headers $uploadHeaders -Body $fileContent
    
    return $response.url
}

function Get-RandomUser {
    <#
    .SYNOPSIS
        Returns a random user email from the configuration
    .PARAMETER Config
        Configuration object
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    if ($Config.users -and $Config.users.Count -gt 0) {
        return $Config.users | Get-Random
    }
    return $null
}

function Write-Progress {
    <#
    .SYNOPSIS
        Displays progress with consistent formatting
    .PARAMETER Activity
        The activity being performed
    .PARAMETER Status
        Current status message
    .PARAMETER PercentComplete
        Percentage complete (0-100)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Activity,
        
        [Parameter(Mandatory=$true)]
        [string]$Status,
        
        [Parameter(Mandatory=$false)]
        [int]$PercentComplete
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Activity - $Status" -ForegroundColor Cyan
    
    if ($PercentComplete -ge 0) {
        Microsoft.PowerShell.Utility\Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
}
