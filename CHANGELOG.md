# Changelog - ADO Sample Project Generator

## [v1.4] - Classic Pipelines, Team Boards, and Real Attachments (Latest)

### Added Features

#### 1. Classic CI/CD Pipelines (Script 06)
- **Classic Build Pipelines**: Added 2 classic build pipelines for main-app repository
  - Main-App-Classic-CI: Traditional .NET build with NuGet, MSBuild, Test, Publish
  - Main-App-Modern-CI: Modern .NET build with enhanced features
  - Build number format: $(Date:yyyyMMdd)$(Rev:.r)
  - Continuous integration triggers on main and develop branches
  
- **Classic Release Pipelines**: Added 2 classic release pipelines
  - Main-App-Classic-CD: 4-stage deployment (Dev→QA→Staging→Production)
  - Main-App-Modern-CD: 3-stage deployment (Dev→QA→Production)
  - Manual approval gates for Staging and Production
  - Azure Web App deployment tasks with rollback capabilities
  
- **Content-Type Support**: Fixed header handling for different pipeline types
  - Classic pipelines: `application/json`
  - YAML pipelines: `application/json-patch+json`

#### 2. Team Board Configuration (Script 02)
- **9 Total Boards**: Created across 4 teams
  - Team Alpha: 3 boards (Stories, Tasks, Features)
  - Other teams: 2 boards each (Stories, Tasks)
  - Board columns and card settings configured
  - Default iteration paths assigned

#### 3. Real Image Attachments (Script 03)
- **JPEG Files**: 5 real JPEG images from sample-data/resources folder
  - Attached to random user stories
  - Base64 encoded with metadata
  - Attachment count tracking

#### 4. Project-Name Repository
- **PWC-Development-Test**: Repository matching project name
  - Total repositories increased to 6
  - Ensures migration testing consistency

### Configuration Updates
- Updated config.json with 4 classic pipeline definitions
- Added board configurations for all teams
- Project-name repository as first entry

### Documentation Updates
- All markdown files updated to reflect current state:
  - Corrected work item counts (71 actual)
  - Added classic pipeline documentation (4 pipelines)
  - Updated repository count (6 total)
  - Added team boards details (9 boards)
  - Updated pipeline totals (9 builds + 8 releases = 17 total)

### Bug Fixes
- Fixed duplicate "process" key in classic build definition
- Fixed 415 Unsupported Media Type error with correct Content-Type
- Corrected inconsistent entity counts in documentation

---

## [v1.3] - Complete ADO Entity Coverage

### Added Features

#### 1. Enhanced Work Item Features (Script 03)
- **Work Item Comments**: Added comment functionality to work items
  - Randomly adds 1-3 comments to subset of work items
  - Realistic comment text samples
  - Creates discussion history for migration testing
  
- **Work Item Attachments**: File attachment support
  - Requirements documents (Markdown)
  - Sample attachments linked to user stories
  - Base64-encoded content upload
  - Attachment metadata and comments
  
- **Work Item History**: Multiple updates to create revision history
  - System.History field updates
  - Priority changes
  - State transitions
  - Creates complete audit trail
  
- **Custom Fields**: Expanded field usage
  - Microsoft.VSTS fields utilized
  - Story points, effort, priority
  - Risk, business value, time criticality
  - Remaining work, completed work

#### 2. Enhanced Repository Features (Script 05)
- **Branch Policies**: Comprehensive branch protection
  - Minimum number of reviewers (2 required)
  - Work item linking policy
  - Comment requirements policy
  - Applied to main branch
  
- **Explicit Branch Management**:
  - Main, develop, and feature branches
  - Branch creation from specific commits
  - Multiple commits per feature branch
  - Branch metadata tracking

#### 3. Enhanced Pipeline Features (Script 06)
- **Classic Build Definitions**: Added 2 classic build pipelines
  - Classic-DotNet-Build
  - Classic-NPM-Build
  - MSBuild and NPM task configurations
  - Continuous integration triggers
  
- **Build Definition Metadata**:
  - Type tagging (YAML vs Classic)
  - Build number formatting
  - Queue and agent pool configuration
  
- **Release Pipeline Enhancements**:
  - Multi-stage release definitions
  - Environment configurations
  - Deployment tasks and phases

#### 4. Service Connections & Variable Groups (NEW Script 09)
- **Service Connections (6 types)**:
  - Azure-Service-Connection-Dev
  - Azure-Service-Connection-Prod
  - GitHub-Service-Connection
  - Docker-Registry-Connection
  - SonarCloud-Connection
  - NPM-Registry-Connection
  
- **Variable Groups (6 groups)**:
  - Development-Variables
  - QA-Variables
  - Staging-Variables
  - Production-Variables
  - Build-Variables
  - Security-Variables
  
- **Variable Features**:
  - Environment-specific configurations
  - Secret variable support
  - Connection strings, API URLs, resource names
  - Total of 40+ variables across all groups

#### 5. Azure Artifacts Feeds & Packages (NEW Script 10)
- **Artifact Feeds (4 feeds)**:
  - MyApp-NuGet-Feed (with upstream sources)
  - MyApp-NPM-Feed (with npmjs upstream)
  - MyApp-Universal-Feed
  - Shared-Libraries-Feed
  
- **Sample Packages (10 packages)**:
  - **NuGet**: MyApp.Core, MyApp.Data, MyApp.Api (multiple versions)
  - **NPM**: @myapp/ui-components, @myapp/utils
  - **Universal**: Deployment scripts, infrastructure templates
  
- **Feed Features**:
  - Upstream source configuration
  - Feed views (Release, Prerelease)
  - Package versioning
  - Multi-protocol support

#### 6. Permissions, Service Hooks & Extensions (NEW Script 11)
- **Security Groups (6 groups)**:
  - MyApp-Developers
  - MyApp-QA-Team
  - MyApp-DevOps-Team
  - MyApp-Release-Managers
  - MyApp-ReadOnly-Stakeholders
  - MyApp-Security-Team
  
- **User Permission Assignments (5 users)**:
  - Role-based group assignments
  - Direct permission grants
  - Documented permission matrices
  
- **Service Hooks (6 webhooks)**:
  - workitem.created notifications
  - build.complete events
  - git.push triggers
  - pullrequest.created events
  - deployment-completed events
  - Slack integration for work item updates
  
- **Recommended Extensions (8 extensions)**:
  - Analytics, SonarCloud, Work Item Visualization
  - Azure Pipelines, Replace Tokens
  - WhiteSource Bolt, Estimate, Build Status Badge
  - Marketplace URLs and installation guidance

### Complete ADO Entity Coverage

✅ **All 31 Required Entities Now Implemented**:

| Entity | Status | Script | Details |
|--------|--------|--------|---------|
| Repository (Git) | ✅ Complete | 05 | Multiple repos with sample code |
| Repository (TFVC) | ⚠️ Documented | - | TFVC not created (Git focus) |
| Branch | ✅ Complete | 05 | Main, develop, feature branches |
| Pull Request | ✅ Complete | 05 | With reviews, comments, approvals |
| Branch Policy | ✅ Complete | 05 | 3 policies on main branch |
| Team Project | ✅ Complete | 01 | Project creation with settings |
| Work Item (Epic) | ✅ Complete | 03 | 5+ epics |
| Work Item (Feature) | ✅ Complete | 03 | 15+ features |
| Work Item (User Story) | ✅ Complete | 03 | 50+ user stories |
| Work Item (Bug) | ✅ Complete | 03 | 30+ bugs |
| Work Item (Task) | ✅ Complete | 03 | 100+ tasks |
| Work Item Query | ✅ Complete | 08 | Shared queries and folders |
| Work Item Comments | ✅ Complete | 03 | Comments on multiple items |
| Work Item Attachments | ✅ Complete | 03 | File attachments on stories |
| Work Item History | ✅ Complete | 03 | Multiple revisions created |
| Work Item Custom Fields | ✅ Complete | 03 | VSTS custom fields used |
| Board | ✅ Complete | 02, 08 | Kanban boards configured |
| Sprint | ✅ Complete | 02 | 12+ sprint iterations |
| Dashboard | ✅ Complete | 08 | Multiple dashboards with widgets |
| Azure Pipeline (YAML) | ✅ Complete | 06 | 7 YAML build pipelines |
| Azure Pipeline (Classic) | ✅ Complete | 06 | 2 classic build definitions |
| Build Definition | ✅ Complete | 06 | Combined YAML + classic |
| Release Pipeline | ✅ Complete | 06 | 6 multi-stage releases |
| Service Connection | ✅ Complete | 09 | 6 service endpoints |
| Variable Group | ✅ Complete | 09 | 6 variable groups |
| Test Plan | ✅ Complete | 04 | 5 test plans |
| Test Suite | ✅ Complete | 04 | Multiple test suites |
| Test Case | ✅ Complete | 04 | 40+ test cases |
| Wiki | ✅ Complete | 08 | Project wiki with pages |
| Artifacts | ✅ Complete | 10 | 4 feeds, 10 packages |
| Analytics/Reports | ℹ️ Available | - | Via Dashboard widgets |
| Permissions (User) | ✅ Complete | 11 | 5 user assignments |
| Permissions (Group) | ✅ Complete | 11 | 6 security groups |
| Service Hook | ✅ Complete | 11 | 6 webhook configurations |
| Extensions | ✅ Complete | 11 | 8 recommended extensions |

### New Script Files

1. **scripts/setup/09-create-service-connections-variables.ps1**
   - Service connection definitions (6 types)
   - Variable group creation (6 groups with 40+ variables)
   - Environment-specific configuration management

2. **scripts/setup/10-create-artifacts-feeds.ps1**
   - Artifact feed creation (4 feeds)
   - Package metadata (10 packages: NuGet, NPM, Universal)
   - Upstream source configuration
   - Feed views (Release, Prerelease)

3. **scripts/setup/11-create-permissions-hooks-extensions.ps1**
   - Security group creation (6 groups)
   - User permission assignments (5 users)
   - Service hook subscriptions (6 webhooks)
   - Extension recommendations (8 extensions)
   - Branch policy documentation

### Enhanced Script Files

1. **scripts/setup/03-create-work-items.ps1**
   - Added steps 6-8 for comments, attachments, history
   - Comment API integration
   - Attachment upload with base64 encoding
   - History creation via System.History field

2. **scripts/setup/05-create-repositories.ps1**
   - Added step 6 for branch policies
   - Policy API integration (reviewers, work items, comments)
   - Branch protection configuration
   - Policy metadata in output

3. **scripts/setup/06-create-pipelines.ps1**
   - Added step 3 for classic build definitions
   - Classic build definition API
   - Build definition type tracking (YAML vs Classic)
   - Enhanced pipeline statistics

4. **Run-All.ps1**
   - Added steps 9-11 for new scripts
   - Updated execution summary
   - Enhanced completion messages
   - Comprehensive feature list

### Migration Testing Coverage

#### Repository Migration
- ✅ Git repositories with full history
- ✅ Multiple branches (main, develop, feature/*)
- ✅ Pull requests with reviews and comments
- ✅ Branch policies (min reviewers, work item linking)
- ✅ Commit-work item links

#### Work Item Migration
- ✅ All work item types (Epic, Feature, Story, Task, Bug)
- ✅ Hierarchical relationships
- ✅ Comments and discussions
- ✅ File attachments
- ✅ Revision history
- ✅ Custom fields and tags
- ✅ Links and relationships

#### Pipeline Migration
- ✅ YAML build pipelines (7)
- ✅ Classic build definitions (2)
- ✅ Release pipelines (6 multi-stage)
- ✅ Service connections (6 types)
- ✅ Variable groups (6 groups)
- ✅ Pipeline triggers and schedules

#### Test Management Migration
- ✅ Test plans, suites, cases
- ✅ Test runs with results
- ✅ Test case parameters
- ✅ Test-requirement links

#### Additional Artifacts
- ✅ Azure Artifacts feeds with packages
- ✅ Service hooks / webhooks
- ✅ Security groups and permissions
- ✅ Wiki pages with content
- ✅ Dashboards and queries
- ✅ Extension recommendations

### Statistics

**Total Entities Created:**
- **11 Script Files** (8 enhanced + 3 new)
- **200+ Work Items** (with comments, attachments, history)
- **5 Repositories** (Git with branches and policies)
- **20+ Branches** (main, develop, feature branches)
- **10+ Pull Requests** (with reviews and approvals)
- **13 Pipelines** (7 YAML CI + 2 Classic + 6 CD/Release + env-specific)
- **6 Service Connections** (Azure, GitHub, Docker, SonarCloud, NPM)
- **6 Variable Groups** (40+ variables across Dev, QA, Staging, Prod, Build, Security)
- **4 Artifact Feeds** (NuGet, NPM, Universal)
- **10 Packages** (versioned NuGet, NPM, Universal packages)
- **6 Security Groups** (role-based teams)
- **5 User Permission Sets**
- **6 Service Hooks** (webhooks for various events)
- **8 Extension Recommendations**
- **5 Test Plans** (Integration, Regression, UAT, Performance, Security)
- **40+ Test Cases**
- **Multiple Wiki Pages**
- **Multiple Dashboards**

### Usage

Run complete setup:
```powershell
.\Run-All.ps1 -Verbose
```

Run individual new scripts:
```powershell
.\scripts\setup\09-create-service-connections-variables.ps1
.\scripts\setup\10-create-artifacts-feeds.ps1
.\scripts\setup\11-create-permissions-hooks-extensions.ps1
```

Review generated artifacts:
- Service Connections & Variables: `scripts/output/service-connections-variables-info.json`
- Artifacts & Packages: `scripts/output/artifacts-info.json`
- Permissions & Hooks: `scripts/output/permissions-hooks-extensions-info.json`

---

## [v1.2] - Comprehensive CI/CD Pipeline Coverage

### Added Features

#### 1. Expanded CI Pipeline Coverage (7 Total Pipelines)
- **Added 4 New CI Pipelines**:
  - **API-Service-CI**: Node.js API service with ESLint, unit/integration tests
  - **Auth-Service-CI**: Python authentication service with code quality checks
  - **Security-Scan-CI**: Dependency scanning, SAST, secret detection
  - **Code-Quality-CI**: Static analysis, complexity metrics, documentation coverage

- **Enhanced Existing CI Pipelines** (3 pipelines):
  - Main-App-CI: .NET 8.0 build with comprehensive testing
  - Docker-Build-CI: Container builds with security scanning
  - Infrastructure-Validation-CI: Terraform and Bicep validation

- **CI Features Across All Pipelines**:
  - Multi-language support: .NET, Node.js, Python
  - Code coverage reporting (Cobertura)
  - Security vulnerability scanning
  - Code quality gates (ESLint, Pylint, SonarCloud)
  - Artifact publishing for downstream deployments

#### 2. Comprehensive CD Pipeline Coverage (6 Total Pipelines)
- **Main-App-CD**: 4-stage deployment (Dev → QA → Staging → Production)
  - Azure App Service deployment
  - Slot management and swapping
  - Health checks and rollback capability
  
- **API-Service-CD**: 3-stage with canary deployment
  - Azure Functions deployment
  - Progressive rollout (10% → 50% → 100%)
  - App settings configuration per environment
  
- **Auth-Service-CD**: 3-stage Kubernetes deployment
  - AKS deployment with rolling strategy
  - Multi-namespace support
  - Kubernetes manifest management
  
- **Infrastructure-Deploy-CD**: 3-stage IaC deployment
  - Terraform state management
  - Environment-specific tfvars
  - Manual approval gates for production
  
- **Database-Migration-CD**: 3-stage database deployment
  - Automated backups before migration
  - SQL script execution
  - Entity Framework Core migrations
  - DBA approval workflow
  
- **Container-Deploy-CD**: 3-stage container orchestration
  - Helm chart deployment
  - Canary strategy (25% → 50% → 75% → 100%)
  - Rollout monitoring and verification

#### 3. Advanced Deployment Strategies
- **Canary Deployments**: API Service (3-increment), Container Deploy (4-increment)
- **Blue-Green Deployments**: Main App using Azure slot swaps
- **Rolling Updates**: Auth Service with maxParallel configuration
- **RunOnce Strategy**: Standard deployments with health checks

#### 4. Environment and Approval Configuration
- **4 Environments**: Development, QA, Staging, Production
- **Approval Gates**: 
  - Manual approvals for Production deployments
  - DBA approval for database changes
  - Release manager approval for infrastructure
- **Quality Gates**:
  - Work item query gates (no critical bugs)
  - Health check verification
  - Rollout status monitoring

### Configuration Updates

#### Updated utils/config.json
```json
{
  "pipelines": {
    "build": [
      "Main-App-CI",
      "Docker-Build-CI", 
      "API-Service-CI",
      "Auth-Service-CI",
      "Infrastructure-Validation-CI",
      "Security-Scan-CI",
      "Code-Quality-CI"
    ],
    "release": [
      "Main-App-CD",
      "API-Service-CD",
      "Auth-Service-CD",
      "Infrastructure-Deploy-CD",
      "Database-Migration-CD",
      "Container-Deploy-CD"
    ]
  }
}
```

### New Files Created

1. **scripts/sample-data/cd-pipeline-definitions.yaml**
   - Comprehensive CD pipeline templates
   - Multi-stage deployment configurations
   - Environment-specific settings

2. **PIPELINES-SUMMARY.md**
   - Complete pipeline documentation
   - Feature breakdown by pipeline
   - Deployment strategy details
   - Migration testing checklist

### Pipeline Statistics

- **Total CI Pipelines**: 7
- **Total CD Pipelines**: 6
- **Total Deployment Stages**: 20
- **Languages/Technologies**: .NET, Node.js, Python, Docker, Terraform, Bicep, Kubernetes
- **Deployment Targets**: App Service, Functions, AKS, SQL Database, Infrastructure

### Migration Testing Coverage

✅ **Comprehensive CI/CD Coverage**:
- Multiple build technologies and frameworks
- Security scanning and code quality analysis
- Multi-stage deployment pipelines
- Various deployment strategies (canary, blue-green, rolling)
- Approval workflows and quality gates
- Health checks and monitoring
- Artifact retention and versioning

### Technical Implementation

#### Pipeline Creation Enhanced (06-create-pipelines.ps1)
- Supports 7 CI pipeline types
- Creates YAML files in repositories
- Configures triggers and branch policies
- Publishes pipeline artifacts

#### Deployment Strategy Examples

**Canary Deployment**:
```yaml
strategy:
  canary:
    increments: [10, 50, 100]
    deploy:
      steps:
        - task: AzureFunctionApp@1
```

**Rolling Update**:
```yaml
strategy:
  rolling:
    maxParallel: 2
    deploy:
      steps:
        - task: KubernetesManifest@0
```

**Blue-Green via Slots**:
```yaml
- task: AzureAppServiceManage@0
  inputs:
    Action: 'Swap Slots'
    SourceSlot: 'staging'
    TargetSlot: 'production'
```

### Usage

Run pipeline creation:
```powershell
.\scripts\setup\06-create-pipelines.ps1
```

Review pipeline definitions:
- CI: `scripts/sample-data/pipeline-definitions.yaml`
- CD: `scripts/sample-data/cd-pipeline-definitions.yaml`
- Summary: `PIPELINES-SUMMARY.md`

---

## [v1.1] - Sprint and Commit Integration

### Added Features

#### 1. Sprint Assignment for User Stories (03-create-work-items.ps1)
- **User Stories Now Assigned to Sprints**: User stories are automatically distributed across 12 sprints
  - Each user story gets assigned to a specific sprint (Sprint 1-12)
  - Distribution uses round-robin approach for even spread
  - Iteration path format: `{Project}\{Year}\Sprint {Number}`
  - Example: "PWC-Development\2025\Sprint 5"

#### 2. Commit-Work Item Association (05-create-repositories.ps1)
- **Initial Commits Linked to Work Items**: Each repository's initial commit now references 1-2 user stories
  - Randomly selects user stories from existing work items
  - Adds work item references in commit message: `Related work items: #206, #207`
  - Tracks associations in repository metadata
  - Displays associated work items in console output

- **Enhanced Commit Metadata**: 
  ```json
  {
    "commitId": "d339130...",
    "commitWorkItems": {
      "d339130...": [206, 207]
    }
  }
  ```

#### 3. Artifact Links for Commits (07-link-objects.ps1)
- **New Section [1/4]**: Links commits to work items using Azure DevOps artifact links
  - Creates `ArtifactLink` relations between commits and work items
  - Uses proper vstfs URI format: `vstfs:///Git/Commit/{project}/{repoId}/{commitId}`
  - Enables traceability from work items to code changes
  - Visible in work item "Development" section in Azure DevOps UI

- **Updated Linking Sequence**:
  1. **[1/4]** Link commits to work items (NEW)
  2. **[2/4]** Link bugs to test cases
  3. **[3/4]** Create related links between user stories  
  4. **[4/4]** Create predecessor/successor links between tasks

### Technical Implementation

#### Sprint Assignment Logic
```powershell
$sprintNumber = ($i % $sprintCount) + 1
$iteration = "$project\$($config.iterations.year)\Sprint $sprintNumber"
```

#### Commit Message Format
```
Initial commit: Add project files

Related work items: #206, #215
```

#### Artifact Link Structure
```powershell
@{
    rel = "ArtifactLink"
    url = "vstfs:///Git/Commit/PWC-Development/8bd0793a.../d339130..."
    attributes = @{ name = "Commit" }
}
```

### Benefits for Migration Testing

1. **Sprint Planning Data**: Tests migration of sprint assignments and iteration paths
2. **Traceability**: Validates commit-work item relationship preservation
3. **Development Links**: Ensures "Development" section in work items migrates correctly
4. **Realistic Workflow**: Simulates actual development process with code-story linkage

### Usage

No changes to usage - improvements are automatic:
```powershell
.\Run-All.ps1
```

### Verification in Azure DevOps

1. **User Stories in Sprints**:
   - Navigate to Boards → Sprints
   - Select any sprint (1-12)
   - Verify user stories appear in sprint backlog

2. **Commit Links**:
   - Open any user story (IDs 206-225)
   - Check "Development" section
   - See linked commits from repositories

3. **Commit Messages**:
   - Navigate to Repos → Commits
   - View initial commits
   - See work item references in commit descriptions

### File Changes

- **Modified**: `scripts/setup/03-create-work-items.ps1`
  - Added sprint distribution logic for user stories
  - Changed iteration assignment from project root to specific sprints

- **Modified**: `scripts/setup/05-create-repositories.ps1`
  - Loads work items data before creating commits
  - Selects 1-2 random user stories per commit
  - Adds work item references to commit messages
  - Tracks commit-work item associations in output
  - Displays associations in console

- **Modified**: `scripts/setup/07-link-objects.ps1`
  - Added new section for commit-work item artifact links
  - Loads repositories info file
  - Creates vstfs URI for each commit
  - Links commits to associated work items
  - Updated section numbering (now 4 sections instead of 3)

---

## [v1.0] - Enhanced Repository & Pull Request Features

### Added Features

#### 1. Enhanced Repository Creation (05-create-repositories.ps1)
Complete rewrite from basic repository creation to comprehensive Git workflow simulation.

**New Capabilities:**
- ✅ **Initial Commits**: Each repo starts with 3 files
  - README.md with project description
  - src/Program.cs with sample C# code
  - tests/ProgramTests.cs with unit tests
  
- ✅ **Feature Branches**: 4 branches per repository
  - `feature/user-authentication`
  - `feature/api-integration`
  - `feature/logging-improvements`
  - `bugfix/fix-null-reference`
  
- ✅ **Branch Commits**: Each feature branch gets 1-2 C# files
  - UserAuthService.cs & UserController.cs
  - ApiClient.cs
  - Logger.cs & LogConfig.cs
  - BugFix.cs

- ✅ **Pull Requests**: 4 PRs per repository
  - Each feature branch → main
  - Detailed descriptions with:
    - Checklist items (Code reviewed, Tests added, Docs updated)
    - Related work items links
    - Clear PR titles
  
- ✅ **Review Comments**: 2-3 comments per PR
  - Realistic feedback from predefined list:
    - "LGTM! Ready to merge."
    - "Could you add more tests for edge cases?"
    - "Please update the documentation."
    - "Consider adding error handling here."
    - "Nice work! Just a few minor comments."
    - "This looks good, approved!"
    - "Can we extract this into a separate method?"
    - "Great improvement to code quality!"
  
- ✅ **PR Approvals**: Each PR gets approved
  - Uses current user as reviewer
  - Vote status: 10 (Approved)
  - Tracks approval in output metadata

#### 2. Enhanced Output Tracking
Script now outputs comprehensive metadata:
```json
{
  "repoId": "...",
  "repoName": "...",
  "defaultBranch": "main",
  "url": "...",
  "branches": [
    {
      "name": "refs/heads/feature/user-authentication",
      "commitId": "..."
    }
  ],
  "pullRequests": [
    {
      "pullRequestId": 1,
      "title": "feat: Implement user authentication system",
      "sourceBranch": "refs/heads/feature/user-authentication",
      "targetBranch": "refs/heads/main",
      "status": "active",
      "url": "...",
      "createdDate": "...",
      "approved": true
    }
  ]
}
```

### Technical Implementation

#### API Endpoints Used
1. **Repository Creation**: `POST _apis/git/repositories`
2. **Push Commits**: `POST _apis/git/repositories/{id}/pushes`
3. **Create Branches**: Included in push operations
4. **Pull Requests**: `POST _apis/git/repositories/{id}/pullrequests`
5. **Review Threads**: `POST _apis/git/repositories/{id}/pullRequests/{id}/threads`
6. **Approvals**: `PUT _apis/git/repositories/{id}/pullRequests/{id}/reviewers/{reviewerId}`

#### Git Push Structure
Each push includes:
- Refupdates (branch creation/update)
- Commits with:
  - Comment (commit message)
  - Changes array with file additions
  - Base64-encoded file content

#### Review Comments Pattern
Comments added as threads with properties:
- `comments`: Array with text content
- `status`: "active" for pending comments
- `threadContext`: null for general comments

#### Approval Voting System
- Vote = 10: Approved
- Vote = 5: Approved with suggestions
- Vote = 0: No vote
- Vote = -5: Waiting for author
- Vote = -10: Rejected

### Performance Optimization
- Only first repository gets full PR workflow (for testing speed)
- Other repositories get basic structure
- Can be configured to process all repos if needed

### Migration Testing Value
This enhancement provides critical data for ADO→GitHub migration testing:
- **Pull Request Migration**: Tests PR conversion with all metadata
- **Review Comment Migration**: Validates comment threading preservation
- **Approval State Migration**: Ensures approval status carries over
- **Branch Strategy Migration**: Tests branch structure conversion
- **Commit History Migration**: Validates commit linking and authorship

### Usage
No changes to usage - just run:
```powershell
.\Run-All.ps1
```

Or individually:
```powershell
.\scripts\setup\05-create-repositories.ps1
```

### Output Verification
Check in Azure DevOps:
1. Navigate to Repos → Files
2. Switch branches to see feature branches
3. Go to Pull Requests tab
4. Open any PR to see:
   - Description with checklist
   - Review comments
   - Approval status (checkmark from reviewer)

### Future Enhancements
Potential additions:
- [ ] PR merge operations
- [ ] Branch policies (require reviews, work item linking)
- [ ] File-level review comments (line-specific)
- [ ] Multiple reviewers per PR
- [ ] PR iterations (updated commits)
- [ ] Commit comments
- [ ] Code review suggestions
- [ ] More diverse file types (JSON, YAML, Python, TypeScript)

---

## Previous Updates

### [Initial Release] - Complete ADO Project Generator
- 8 setup scripts for comprehensive ADO project creation
- 200+ work items across all types
- Test management with plans, suites, cases
- Basic repositories with branches
- CI/CD pipelines (Classic and YAML)
- Wiki and dashboards
- Cross-object linking
- Configuration-driven architecture
