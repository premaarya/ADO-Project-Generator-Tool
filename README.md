# ADO Sample Project Generator

A comprehensive PowerShell-based solution for generating complete Azure DevOps (ADO) projects with realistic sample data. This tool creates all ADO object types including work items, test plans, repositories, pipelines, and more - perfect for testing ADO-to-GitHub migration tools.

## 🎯 Purpose

This project generates a fully-populated Azure DevOps project that covers **ALL** possible ADO configurations and object types, providing comprehensive seed data to validate migration tools that convert ADO projects to GitHub.

## ✨ What Gets Created

### Work Items (200+ total)
- **5 Epics** with business value and risk assessment
- **15 Features** linked to epics with effort estimates
- **50 User Stories** with acceptance criteria and story points
- **100 Tasks** with time tracking and activity types
- **30 Bugs** with severity levels and repro steps
- **40 Test Cases** as work items

### Test Management
- **5 Test Plans** (Integration, Regression, UAT, Performance, Security)
- **Multiple Test Suites** (Static, Requirement-based, Query-based)
- **40+ Detailed Test Cases** with steps and parameters
- **Test Runs and Results** with Pass/Fail/Blocked states
- **Bug Associations** with failed tests

### Repositories
- **3-5 Git Repositories** with realistic code
- **Multiple Branches** (main, develop, feature/*, hotfix/*, release/*)
  - Feature branches: user-authentication, api-integration, logging-improvements, bugfix/fix-null-reference
- **Sample Code** in C#, Python, JavaScript
- **Commit History** with actual source files (Program.cs, tests, README)
- **Pull Requests** (4 per repo)
  - Source: feature branches → Target: main
  - Detailed descriptions with checklists
  - Linked work items
- **Review Comments** (2-3 per PR)
  - Realistic feedback: LGTM, test requests, documentation updates
- **PR Approvals** with voting status (Approved/Waiting/Rejected)
- **Tags and Releases**

### CI/CD Pipelines
- **5+ Build Pipelines** (Classic and YAML)
  - .NET Core builds
  - Node.js/NPM builds
  - Docker image builds
  - Python application builds
- **5+ Release Pipelines** with multi-stage deployments
  - Dev → QA → Staging → Production
  - Approvals and gates
  - Environment-specific variables

### Additional Objects
- **Team Structure** (4-5 teams with area paths)
- **Sprint Iterations** (12 sprints configured)
- **Project Wiki** with multiple pages
- **Dashboards** with widgets (Burndown, Velocity, Work Item charts)
- **Shared Queries** and query folders
- **Service Connections** and Variable Groups

### Cross-Object Relationships
- Work items linked hierarchically (Parent/Child)
- Test cases linked to requirements
- Commits linked to work items
- Builds/Releases linked to work items
- Bugs linked to test results

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
