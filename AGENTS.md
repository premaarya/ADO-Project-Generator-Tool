# AI Agent Instructions: ADO Sample Project Generation

## Project Purpose
Generate a comprehensive Azure DevOps (ADO) project with complete sample data to test ADO-to-GitHub migration tools. This seed data must cover ALL possible ADO configurations and object types.

## Required ADO Components

### 1. Work Items - All Types
Create hierarchical work items with various states and configurations:

- **Epics** (5+)
  - Title, Description, Tags, Priority, Risk
  - Acceptance Criteria
  - Business Value
  - Time Criticality
  
- **Features** (15+, linked to Epics)
  - Title, Description, Assigned To
  - State: New, Active, Resolved, Closed
  - Effort estimates
  - Target dates
  
- **User Stories** (50+, linked to Features)
  - Complete with acceptance criteria
  - Story points
  - Priority levels (1-4)
  - States: New, Active, Resolved, Closed, Removed
  - Include attachments
  
- **Tasks** (100+, linked to User Stories)
  - Original Estimate, Remaining, Completed hours
  - Activity types: Development, Testing, Documentation, Deployment
  - States: To Do, In Progress, Done
  
- **Bugs** (30+)
  - Severity: 1-Critical, 2-High, 3-Medium, 4-Low
  - Priority: 1-4
  - Repro steps
  - System Info
  - States: New, Active, Resolved, Closed
  - Link to User Stories/Tasks
  
- **Test Cases** (40+, as work items)
  - Steps
  - Expected results
  - Automation status

### 2. Work Item Features to Include
- **Custom Fields**: Add custom fields at various levels
- **Tags**: Multiple tags per work item
- **Attachments**: PDFs, images, documents
- **Comments/Discussion**: Multiple comments with @mentions
- **Work Item Links**: 
  - Parent/Child
  - Related
  - Predecessor/Successor
  - Tests/Tested By
  - Duplicate/Duplicate Of
- **Area Paths**: Multiple areas (Team A, Team B, Infrastructure, etc.)
- **Iteration Paths**: Sprint structure (e.g., 2024\Sprint 1, Sprint 2... Sprint 12)
- **History**: Simulate work item updates over time

### 3. Test Management

#### Test Plans (5+)
- Integration Test Plan
- Regression Test Plan
- UAT Plan
- Performance Test Plan
- Security Test Plan

#### Test Suites
- Static suites
- Requirement-based suites
- Query-based suites

#### Test Cases (40+ detailed)
- Manual test cases with steps
- Automated test cases
- Shared steps
- Parameters and configurations

#### Test Runs & Results
- Test results for multiple configurations
- Pass/Fail/Blocked states
- Test attachments
- Test iterations
- Bug associations

### 4. Repositories

Create 3-5 Git repositories with:
- **Main Repository**: Full application code
  - Multiple branches: main, develop, feature/*, hotfix/*, release/*
  - Branch policies configured
  - Pull requests (open and completed)
  - Code reviews with comments
  - Merge history
  
- **Infrastructure Repository**: IaC code
  - Terraform/ARM templates
  - Docker files
  
- **Documentation Repository**: Markdown docs
  
- **Microservices Repos**: 2-3 service repos

#### Repository Content
- README.md files
- .gitignore
- Source code in multiple languages (C#, Python, JavaScript)
- Configuration files
- Test files
- Commit history spanning several months
- Tags and releases

### 5. CI/CD Pipelines

#### Build Pipelines (5+)
- **Classic Build Pipeline**: .NET application build
- **YAML Build Pipeline**: Multi-stage build
- **Docker Build Pipeline**
- **NPM/Node.js Pipeline**
- **Python Application Pipeline**

**Pipeline Features**:
- Triggers (CI, Scheduled, Manual)
- Variables and variable groups
- Build artifacts
- Test execution and code coverage
- Build history with success/failure
- Pipeline templates

#### Release Pipelines (5+)
- **Multi-stage deployment**: Dev → QA → Staging → Production
- **Blue-Green Deployment**
- **Canary Release**
- **Container Deployment**
- **IaC Deployment Pipeline**

**Release Features**:
- Pre/Post deployment gates
- Approvals (individual and group)
- Manual interventions
- Environment-specific variables
- Deployment history
- Rollback scenarios

### 6. Additional ADO Objects

#### Boards Configuration
- Kanban board customization
- Sprint board settings
- Card styles and rules
- Swimlanes
- Columns: New, Active, Resolved, Testing, Closed

#### Queries
- Shared queries
- My Work queries
- Team queries
- Query folders
- Charts based on queries

#### Dashboards
- Team dashboards
- Widgets: Burndown, Velocity, Work Item charts
- Build/Release status widgets
- Test results widgets

#### Service Connections
- Azure Resource Manager
- GitHub
- Docker Registry
- Generic service connections

#### Variable Groups
- Pipeline variable groups
- Library assets
- Secure files

#### Artifacts/Packages
- NuGet packages
- NPM packages
- Universal packages
- Multiple feeds

#### Wiki
- Project wiki with multiple pages
- Code wiki linked to repo
- Markdown content
- Attachments and images

### 7. Team & Security Configuration

- **Multiple Teams** (4-5 teams)
- **Area Paths** per team
- **Iteration Paths** with team assignments
- **Security Groups**: Readers, Contributors, Admins
- **Project Settings**: 
  - Work item types customization
  - Process template customization

### 8. Cross-Object Relationships
Ensure comprehensive linking:
- Work items → Test cases
- Bugs → Build/Release
- Commits → Work items
- Pull Requests → Work items
- Test Results → Test cases → Requirements

## Implementation Approach

This project uses **PowerShell scripts with Azure DevOps REST API** for maximum control and flexibility.

### Script Architecture

#### Core Utilities (`/utils`)
- **ado-api-helper.ps1**: Reusable functions for REST API calls
  - `Invoke-AdoRestApi`: Generic REST wrapper with error handling
  - `Get-AdoHeaders`: Authentication header generation
  - `ConvertTo-JsonDepth`: Deep JSON serialization
  - Retry logic and rate limiting
  
- **config.json**: Centralized configuration
  - Organization and project details
  - PAT authentication token
  - User emails for assignments
  - Object count targets

#### Setup Scripts (`/scripts/setup`)

**01-create-project.ps1**
- Create ADO project via REST API
- Configure process template (Agile/Scrum)
- Set project visibility and version control
- API: `POST https://dev.azure.com/{organization}/_apis/projects?api-version=7.0`

**02-setup-teams-areas-iterations.ps1**
- Create 4-5 teams with distinct area paths
- Build iteration hierarchy (2024\Sprint 1-12, 2025\Sprint 1-12)
- Assign teams to iterations
- API: 
  - `POST /_apis/teams`
  - `POST /_apis/wit/classificationnodes/iterations`
  - `POST /_apis/wit/classificationnodes/areas`

**03-create-work-items.ps1**
- Generate epics, features, user stories, tasks, bugs hierarchically
- Set custom fields, tags, and states
- Add attachments via base64 encoding
- Create comments with @mentions
- API: `POST /_apis/wit/workitems/$type?api-version=7.0`
- Use PATCH operations with JSON Patch format

**04-create-test-management.ps1**
- Create test plans for each test type
- Build test suites (static, requirement-based, query-based)
- Generate detailed test cases with steps and parameters
- Create test runs with results (Pass/Fail/Blocked)
- Link bugs to failed tests
- API:
  - `POST /_apis/test/plans`
  - `POST /_apis/test/plans/{planId}/suites`
  - `POST /_apis/test/runs`

**05-create-repositories.ps1**
- Initialize Git repositories
- Create branch structure (main, develop, feature/*, release/*)
- Generate commits with realistic content
- Create sample source files (C#, Python, JavaScript)
- Add tags and releases
- API:
  - `POST /_apis/git/repositories`
  - `POST /_apis/git/repositories/{repositoryId}/pushes`

**06-create-pipelines.ps1**
- Create Classic build pipelines via definitions
- Create YAML pipelines from repository files
- Configure triggers and variables
- Generate pipeline history with runs
- Create release pipelines with stages
- API:
  - `POST /_apis/build/definitions`
  - `POST /_apis/pipelines`
  - `POST /_apis/release/definitions`

**07-link-objects.ps1**
- Create work item links (Parent/Child, Related, etc.)
- Link commits to work items
- Link builds/releases to work items
- Link test results to requirements
- API: `PATCH /_apis/wit/workitems/{id}?api-version=7.0` with relation operations

**08-create-wiki-dashboards.ps1**
- Create project wiki with pages
- Add code wiki linked to repository
- Create dashboards with widgets
- Build queries and query folders
- API:
  - `POST /_apis/wiki/wikis`
  - `PUT /_apis/wiki/wikis/{wikiId}/pages`
  - `POST /_apis/dashboard/dashboards`

### REST API Examples

#### Authentication
```powershell
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
$headers = @{
    "Authorization" = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}
```

#### Create Work Item
```powershell
$body = @(
    @{
        op = "add"
        path = "/fields/System.Title"
        value = "Implement user authentication"
    },
    @{
        op = "add"
        path = "/fields/System.Description"
        value = "As a user, I want to login securely"
    },
    @{
        op = "add"
        path = "/fields/Microsoft.VSTS.Scheduling.StoryPoints"
        value = 5
    }
) | ConvertTo-Json -Depth 10

$uri = "https://dev.azure.com/$org/$project/_apis/wit/workitems/`$User Story?api-version=7.0"
Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
```

#### Create Work Item Link
```powershell
$linkBody = @(
    @{
        op = "add"
        path = "/relations/-"
        value = @{
            rel = "System.LinkTypes.Hierarchy-Reverse"
            url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$parentId"
        }
    }
) | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri $workItemUri -Method PATCH -Headers $headers -Body $linkBody
```

#### Create Test Plan
```powershell
$testPlan = @{
    name = "Integration Test Plan"
    areaPath = "$project\Team A"
    iteration = "$project\2025\Sprint 1"
} | ConvertTo-Json

$uri = "https://dev.azure.com/$org/$project/_apis/test/plans?api-version=7.0"
Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $testPlan
```

## Output Structure
```
/scripts
  /setup
    - 01-create-project.ps1
    - 02-setup-teams-areas-iterations.ps1
    - 03-create-work-items.ps1
    - 04-create-test-management.ps1
    - 05-create-repositories.ps1
    - 06-create-pipelines.ps1
    - 07-link-objects.ps1
    - 08-create-wiki-dashboards.ps1
  /sample-data
    - work-items.json
    - test-cases.json
    - pipeline-definitions.yaml
  /utils
    - ado-api-helper.ps1
    - config.json

/docs
  - SETUP.md (instructions)
  - API-REFERENCE.md
  - MIGRATION-CHECKLIST.md

/sample-repos
  /main-app
    - (sample application code)
  /infrastructure
    - (IaC code)
```

## Configuration File
Create a `config.json` with:
```json
{
  "organization": "YOUR_ORG",
  "project": "ADO-Migration-Test",
  "pat": "YOUR_PAT",
  "users": ["user1@example.com", "user2@example.com"],
  "workItemCounts": {
    "epics": 5,
    "features": 15,
    "userStories": 50,
    "tasks": 100,
    "bugs": 30
  }
}
```

## Migration Coverage Checklist
Ensure seed data covers ALL migration scenarios:
- ✓ All work item types and states
- ✓ All link types
- ✓ Attachments and rich content
- ✓ Area and iteration paths
- ✓ Custom fields
- ✓ Test plans, suites, cases, results
- ✓ Git repos with history
- ✓ Build and release pipelines (Classic & YAML)
- ✓ Service connections
- ✓ Variable groups and libraries
- ✓ Wiki pages
- ✓ Dashboards and queries
- ✓ Security and permissions
- ✓ Cross-object relationships

## References
- [Azure DevOps REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [Azure DevOps CLI](https://learn.microsoft.com/en-us/cli/azure/devops)
- [Work Item Types](https://learn.microsoft.com/en-us/azure/devops/boards/work-items/guidance/choose-process)
- [Pipeline YAML Schema](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/)

## Notes for AI Agents
- Generate realistic sample data (names, descriptions, dates)
- Maintain referential integrity between objects
- Use timestamps spanning 6-12 months for realistic history
- Include edge cases (blocked work items, failed builds, etc.)
- Create both simple and complex scenarios
- Document any ADO-specific features that may have migration challenges
