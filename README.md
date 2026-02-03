# ADO Sample Project Generator

A comprehensive PowerShell-based solution for generating complete Azure DevOps (ADO) projects with realistic sample data. This tool creates all ADO object types including work items, test plans, repositories, pipelines, and more - perfect for testing ADO-to-GitHub migration tools.

## 🎯 Purpose

This project generates a fully-populated Azure DevOps project that covers **ALL** possible ADO configurations and object types, providing comprehensive seed data to validate migration tools that convert ADO projects to GitHub.

## ✨ What Gets Created

### **COMPREHENSIVE ADO OBJECT INVENTORY**

This solution creates **~200+ Azure DevOps objects** covering ALL ADO entity types for complete migration testing.

---

### **1. PROJECT FOUNDATION**
- **1 Azure DevOps Project**
  - Process Template: Agile (configurable)
  - Visibility: Private (configurable)

---

### **2. ORGANIZATIONAL STRUCTURE**

**Teams**: 4
- Team Alpha (Frontend development)
- Team Beta (Backend development)
- Team Gamma (Infrastructure and DevOps)
- Team Delta (QA and testing)

**Team Boards**: 9 total
- Team Alpha: 3 boards (Stories, Tasks, Features)
- Team Beta: 2 boards (Stories, Tasks)
- Team Gamma: 2 boards (Stories, Tasks)
- Team Delta: 2 boards (Stories, Tasks)

**Area Paths**: 4
- Team Alpha, Team Beta, Team Gamma, Team Delta

**Iterations/Sprints**: 12
- Sprint 1 through Sprint 12 (Year 2025)
- 2-week sprint cycles with start dates

---

### **3. WORK ITEMS** - **Total: 71 items**

| Type | Count | IDs | Details |
|------|-------|-----|---------|
| **Epics** | 3 | 501-503 | Business objectives with risk assessment |
| **Features** | 8 | 504-511 | Major functionality areas with effort estimates |
| **User Stories** | 20 | 512-531 | Acceptance criteria, story points, priority levels |
| **Tasks** | 30 | 532-561 | Time tracking, activity types, assigned to teams |
| **Bugs** | 10 | 562-571 | Severity levels (1-4), repro steps, system info |

**Work Item Features**:
- ✓ 20 Comments with @mentions
- ✓ 10 Attachments (5 real JPEG images from sample-data/resources folder)
- ✓ 15 History updates
- ✓ 10 Tags (frontend, backend, database, api, ui, performance, security, testing, documentation, infrastructure)
- ✓ Custom fields populated
- ✓ States: New, Active, Resolved, Closed
- ✓ Hierarchical parent/child relationships

---

### **4. TEST MANAGEMENT** - **Total: 15 test cases + documentation**

**Test Cases**: 15 (Work Items)
- IDs: 590-604
- State: Design
- Includes detailed test steps in HTML format
- Priority levels (1-4)
- Tags applied
- Linked to User Stories

**Test Configurations**: 3 documented
- Chrome on Windows 11
- Edge on Windows 11
- Firefox on Windows 11

**Test Plans**: 5 (documented - requires Azure Test Plans license)
- Integration Test Plan
- Regression Test Plan
- UAT Plan
- Performance Test Plan
- Security Test Plan

**Test Runs**: 10 (documented - requires Azure Test Plans license)
- 10 test runs planned across Browser × Windows 11 configurations
- Includes Pass/Fail/Blocked outcomes
- Duration tracking and build references
- Automated vs manual test distinctions

---

### **5. REPOSITORIES & CODE** - **Total: 6 repositories**

| Repository | ID | Purpose |
|------------|-----|---------|
| **PWC-Development-Test** | - | Project-name repository matching project name |
| **main-app** | f42cebf0... | Main application with frontend/backend code |
| **infrastructure** | e4f7ea5d... | Terraform and Docker configurations |
| **documentation** | 33f066f9... | Project documentation and markdown |
| **api-service** | 9d89f24e... | Microservice for API gateway |
| **auth-service** | bd71a2d8... | Authentication/authorization microservice |

**Repository Features**:
- ✓ Initial commits with sample code
- ✓ Branch policies configured on main
- ✓ README.md files
- ✓ Sample code (C#, Python, JavaScript, Terraform)
- ✓ .gitignore and configuration files
- ✓ Commit history with work item links

---

### **6. PIPELINES** - **Total: 17 pipeline definitions**

**Build Pipelines**: 12 YAML CI pipelines **with reusable templates**

**CI Pipelines (.NET - 4)**:
- Main-Web-App-CI (main web application)
- API-Gateway-CI (API gateway service)
- Mobile-Backend-CI (mobile backend service)
- Payment-Service-CI (payment processing)

**CI Pipelines (Node.js - 4)**:
- Auth-Service-CI (authentication service)
- User-Service-CI (user management)
- Frontend-App-CI (React/Angular frontend)
- API-Docs-CI (API documentation generator)

**CI Pipelines (Python - 3)**:
- Notification-Service-CI (notification service)
- Analytics-Service-CI (analytics service)
- Data-Processing-CI (data processing)

**CI Pipelines (Docker - 1)**:
- Container-WebApp-CI (containerized app)

**Reusable YAML Templates**: 4 templates
- dotnet-build-template.yaml (for .NET builds)
- node-build-template.yaml (for Node.js builds)
- python-build-template.yaml (for Python builds)
- docker-build-template.yaml (for container builds)

**Release Pipelines**: 5 classic multi-stage deployments
- Main-App-CD: Dev → QA → Staging → Production (4 stages)
- API-Service-CD: Dev → QA → Production (3 stages)
- Database-Migration-CD: Dev → QA → Production (3 stages)
- Infrastructure-Deploy-CD: Dev → Staging → Production (3 stages)
- Container-Deploy-CD: Dev → QA → Production (3 stages)

**Pipeline Features**:
- ✓ YAML files with template references committed to repositories
- ✓ Reusable build templates for code consistency
- ✓ Parameterized pipelines for flexibility
- ✓ Multi-stage pipelines
- ✓ Triggers (CI, path filters, branch filters)
- ✓ Variables and configurations
- ✓ Test execution and code coverage
- ✓ Artifact publishing
- ✓ Security scanning (containers)
- ✓ Environment-specific configurations
- ✓ Approvals and gates documented

**📚 See [YAML-PIPELINES-README.md](YAML-PIPELINES-README.md) for detailed pipeline and template documentation**

---

### **7. WORK ITEM LINKS** - **Total: 35+ relationships**

| Link Type | Count | Description |
|-----------|-------|-------------|
| **Related Links** | 15 | Cross-references between work items |
| **Dependency Links** | 10 | Predecessor/Successor relationships |
| **Bug-to-Test Case** | 10 | Bugs linked to test cases |
| **Parent/Child** | Multiple | Hierarchical epic→feature→story→task |
| **Comments** | 10 | Comments added with context |

---

### **8. WIKI & COLLABORATION**

**Wiki Pages**: 4+ pages
- Home (Welcome and quick links)
- Getting Started (Prerequisites, setup)
- Architecture (System components, diagrams)
- Testing Guide (Test procedures)

**Dashboards**: 2-3 dashboards
- Team Dashboard (Burndown, Velocity charts)
- Overview Dashboard (Work item status)
- Test Results Dashboard (Test execution metrics)

**Queries**: Multiple shared queries
- Active Work Items
- My Work
- Blocked Items
- Test Results
- Query folders organized by team

---

### **9. SERVICE CONNECTIONS** - **Total: 6 endpoints (documented)**

| Connection | Type | Purpose |
|------------|------|---------|
| Azure-Service-Connection-Dev | Azure RM | Development environment |
| Azure-Service-Connection-Prod | Azure RM | Production environment |
| GitHub-Service-Connection | GitHub | Code and packages |
| Docker-Registry-Connection | Docker | Container images |
| SonarCloud-Connection | SonarCloud | Code quality analysis |
| NPM-Registry-Connection | NPM | JavaScript packages |

**Variable Groups**: 4+ groups (documented)
- Dev-Environment-Variables
- QA-Environment-Variables
- Staging-Environment-Variables
- Production-Environment-Variables

---

### **10. ARTIFACT FEEDS** - **Total: 4 feeds (documented)**

**Feeds with Upstream Sources**:
1. MyApp-NuGet-Feed (NuGet packages with upstream to nuget.org)
2. MyApp-NPM-Feed (NPM packages with upstream to npmjs.org)
3. MyApp-Universal-Feed (Universal packages for artifacts)
4. Shared-Libraries-Feed (Shared components)

**Sample Packages**: ~10 packages documented
- NuGet: MyApp.Core, MyApp.Data, MyApp.Services
- NPM: @myapp/ui-components, @myapp/utils
- Universal: deployment-packages, build-artifacts

---

### **11. SECURITY & GOVERNANCE**

**Security Groups**: 6 groups (documented)
1. MyApp-Developers (Read, Contribute, Create Branch, Pull Requests)
2. MyApp-QA-Team (Read, View Builds/Releases, Test Management)
3. MyApp-DevOps-Team (Build Queue, Releases, Deployments)
4. MyApp-Release-Managers (Release Management, Approvals)
5. MyApp-ReadOnly-Stakeholders (Read-only project access)
6. MyApp-Security-Team (Audit Log, Permissions Management)

**Service Hooks/Webhooks**: Multiple documented
- GitHub integration
- Slack notifications
- Microsoft Teams notifications
- Email notifications

**Permissions**: Role-based access control
- User permission assignments
- Group membership
- Direct permissions

---

## 📊 **COMPLETE INVENTORY SUMMARY**

| **Category** | **Count** | **Status** |
|-------------|-----------|------------|
| **Projects** | 1 | ✅ Created |
| **Teams** | 4 | ✅ Created |
| **Area Paths** | 4 | ✅ Created |
| **Iterations/Sprints** | 12 | ✅ Created |
| **Work Items Total** | **71** | ✅ Created |
| - Epics | 3 | ✅ |
| - Features | 8 | ✅ |
| - User Stories | 20 | ✅ |
| - Tasks | 30 | ✅ |
| - Bugs | 10 | ✅ |
| **Test Cases** | 15 | ✅ Created |
| **Test Plans** | 5 | 📝 Documented* |
| **Test Runs** | 10 | 📝 Documented* |
| **Test Configurations** | 3 | 📝 Documented* |
| **Repositories** | 6 | ✅ Created |
| **Build Pipelines (YAML)** | **12** | ✅ Created |
| **Reusable Templates** | **4** | ✅ Created |
| **Release Pipelines (Classic)** | 5 | 📝 Documented |
| **Total Pipelines** | **17** | **Mixed** |
| **Work Item Links** | 35+ | ✅ Created |
| **Wiki Pages** | 4+ | ✅ Created |
| **Dashboards** | 2-3 | ✅ Created |
| **Queries** | Multiple | ✅ Created |
| **Service Connections** | 6 | 📝 Documented |
| **Variable Groups** | 4+ | 📝 Documented |
| **Artifact Feeds** | 4 | 📝 Documented |
| **Packages** | ~10 | 📝 Documented |
| **Security Groups** | 6 | 📝 Documented |
| **Service Hooks** | Multiple | 📝 Documented |
| | | |
| **TOTAL OBJECTS** | **~200+** | **Mixed** |

**Legend**:
- ✅ = Actually created in Azure DevOps
- 📝 = Documented/Configured (requires additional permissions or licenses)
- \* Test Plans, Suites, and Runs require Azure Test Plans license

---

### **Cross-Object Relationships**
- ✓ Work items linked hierarchically (Parent/Child)
- ✓ Test cases linked to requirements (TestedBy/Tests)
- ✓ Commits linked to work items (via commit messages)
- ✓ Bugs linked to test cases
- ✓ Comments with @mentions across work items
- ✓ Attachments on epics, features, and user stories

## 📋 Prerequisites

### Required
- **Azure DevOps Organization** with project creation permissions
- **Personal Access Token (PAT)** with the following scopes:
  - Project and Team: Read, Write, & Manage
  - Work Items: Read, Write, & Manage
  - Code: Read, Write, & Manage
  - Build: Read & Execute
  - Release: Read, Write, & Manage
  - Test Management: Read & Write
  - Wiki: Read & Write
  - Graph: Read
- **PowerShell 7.0+** (recommended)
- **Internet Connection** for REST API calls

### Optional
- **Git** (if running repository creation locally)
- **Visual Studio Code** for viewing/editing scripts

## 🚀 Quick Start

### 1. Clone or Download This Repository
```powershell
git clone <repository-url>
cd ADO-Sample-Generation
```

### 2. Configure Your Settings
Edit `utils/config.json` with your details:

```json
{
  "organization": "YOUR_ORG_NAME",
  "project": "ADO-Migration-Test",
  "pat": "YOUR_PERSONAL_ACCESS_TOKEN",
  "processTemplate": "Agile",
  "users": [
    "user1@example.com",
    "user2@example.com"
  ]
}
```

**Important:** Keep your PAT secure! Never commit `config.json` with real credentials to source control.

### 3. Run the Setup
Execute the master orchestration script:

```powershell
.\Run-All.ps1
```

This will execute all setup scripts in sequence and create the complete project (estimated time: 15-30 minutes).

### 4. Verify the Results
Navigate to your Azure DevOps project:
```
https://dev.azure.com/{YOUR_ORG}/{PROJECT_NAME}
```

## 📖 Detailed Usage

### Running Individual Scripts
You can run scripts individually if needed:

```powershell
# Create project only
.\scripts\setup\01-create-project.ps1

# Create work items only
.\scripts\setup\03-create-work-items.ps1

# Create test management objects
.\scripts\setup\04-create-test-management.ps1
```

### Skipping Project Creation
If the project already exists:

```powershell
.\Run-All.ps1 -SkipProjectCreation
```

### Verbose Output
For detailed logging:

```powershell
.\Run-All.ps1 -Verbose
```

### Custom Configuration Path
```powershell
.\Run-All.ps1 -ConfigPath "C:\path\to\custom-config.json"
```

## 📁 Project Structure

```
ADO-Sample-Generation/
├── Run-All.ps1                      # Master orchestration script
├── AGENTS.md                         # AI agent instructions
├── README.md                         # This file
├── IMPLEMENTATION.md                 # Architecture documentation
├── scripts/
│   ├── setup/
│   │   ├── 01-create-project.ps1           # Create ADO project
│   │   ├── 02-setup-teams-areas-iterations.ps1  # Teams and iterations
│   │   ├── 03-create-work-items.ps1        # Work items (epics to bugs)
│   │   ├── 04-create-test-management.ps1   # Test plans and cases
│   │   ├── 05-create-repositories.ps1      # Git repos with code
│   │   ├── 06-create-pipelines.ps1         # CI/CD pipelines
│   │   ├── 07-link-objects.ps1             # Create relationships
│   │   └── 08-create-wiki-dashboards.ps1   # Wiki and dashboards
│   └── sample-data/
│       ├── work-items.json                  # Work item templates
│       ├── test-cases.json                  # Test case templates
│       └── pipeline-definitions.yaml        # Pipeline templates
└── utils/
    ├── ado-api-helper.ps1                   # Reusable REST API functions
    └── config.json                          # Configuration settings
```

## 🔧 Configuration Options

### config.json Structure

```json
{
  "organization": "YOUR_ORG",           // ADO organization name
  "project": "ADO-Migration-Test",      // Project name to create
  "pat": "YOUR_PAT",                    // Personal Access Token
  "processTemplate": "Agile",           // Agile, Scrum, or CMMI
  "visibility": "private",              // private or public
  "users": [...],                       // User emails for assignments
  "teams": [...],                       // Team configurations
  "iterations": {...},                  // Sprint/iteration settings
  "workItemCounts": {...},              // How many of each work item type
  "repositories": [...],                // Repository configurations
  "pipelines": {...}                    // Pipeline settings
}
```

See the full schema in [utils/config.json](utils/config.json).

## 🎭 Migration Testing Checklist

After running this tool, your ADO project will have comprehensive data for testing these migration scenarios:

- ✅ All work item types and states
- ✅ Work item hierarchies and relationships
- ✅ Attachments and rich text content
- ✅ Comments and @mentions
- ✅ Custom fields and tags
- ✅ Area and iteration paths
- ✅ Test plans, suites, cases, and results
- ✅ Git repositories with full history
- ✅ Branch policies and pull requests
- ✅ Build and release pipelines (Classic and YAML)
- ✅ Variable groups and service connections
- ✅ Wiki pages with markdown content
- ✅ Dashboards and queries
- ✅ Team configurations
- ✅ Cross-object links (commits to work items, etc.)

## 🛠️ Troubleshooting

### Authentication Errors
- Verify your PAT token is valid and has not expired
- Ensure all required scopes are granted
- Try regenerating the PAT token

### Permission Errors
- Check that you have project creation permissions
- Verify organization-level permissions for certain operations
- Some features (like dashboards) may require admin rights

### Rate Limiting
- The scripts include retry logic with delays
- If you hit rate limits, increase delays in `ado-api-helper.ps1`
- Consider running scripts individually with pauses

### Object Already Exists
- Most scripts check for existing objects and skip creation
- Use `-SkipProjectCreation` flag to skip project creation step
- Delete the project and re-run if you want a fresh start

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📚 Additional Resources

- [Azure DevOps REST API Documentation](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [Azure DevOps CLI Reference](https://learn.microsoft.com/en-us/cli/azure/devops)
- [Work Item Types and Fields](https://learn.microsoft.com/en-us/azure/devops/boards/work-items/guidance/choose-process)
- [Pipeline YAML Schema](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/)
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Detailed architecture guide

## 📄 License

This project is provided as-is for testing and development purposes.

## 🙋 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [IMPLEMENTATION.md](IMPLEMENTATION.md) for architecture details
3. Examine script comments for specific functionality
4. Open an issue in the repository

---

**Note:** This tool creates a significant amount of data in Azure DevOps. Always use a test organization or project to avoid impacting production environments.
