# ADO Sample Project Generator - Quick Reference

## 🎯 What This Solution Does

Generates a **complete Azure DevOps project** with 200+ work items, test management, repositories, pipelines, and more using PowerShell and REST API.

## 📦 Complete Solution Structure

```
ADO-Sample-Generation/
│
├── 📄 Run-All.ps1                    ⭐ START HERE - Master orchestrator
├── 📘 AGENTS.md                       AI agent instructions & requirements
├── 📗 README.md                       User guide & quick start
├── 📕 IMPLEMENTATION.md               Architecture & technical details
│
├── 📁 scripts/
│   ├── 📁 setup/                     ⭐ 8 Sequential Setup Scripts
│   │   ├── 01-create-project.ps1            Project creation
│   │   ├── 02-setup-teams-areas-iterations.ps1  Organizational structure
│   │   ├── 03-create-work-items.ps1         Epics → Tasks (200+ items)
│   │   ├── 04-create-test-management.ps1    Test plans & cases
│   │   ├── 05-create-repositories.ps1       Git repos with code
│   │   ├── 06-create-pipelines.ps1          CI/CD pipelines
│   │   ├── 07-link-objects.ps1              Cross-object relationships
│   │   └── 08-create-wiki-dashboards.ps1    Wiki & dashboards
│   │
│   └── 📁 sample-data/               Data templates & examples
│       ├── work-items.json                  Work item templates
│       ├── test-cases.json                  Test case templates
│       └── pipeline-definitions.yaml        Pipeline YAML examples
│
└── 📁 utils/
    ├── ado-api-helper.ps1            ⭐ Core REST API functions
    └── config.json                    ⭐ Configuration (EDIT THIS)
```

## 🚀 Usage Flow

### Step 1: Configure
```powershell
# Edit utils/config.json
{
  "organization": "YOUR_ORG_NAME",
  "project": "ADO-Migration-Test",
  "pat": "YOUR_PAT_TOKEN"
}
```

### Step 2: Execute
```powershell
# Run everything
.\Run-All.ps1

# Or run individual scripts
.\scripts\setup\03-create-work-items.ps1
```

### Step 3: Verify
```
https://dev.azure.com/{YOUR_ORG}/ADO-Migration-Test
```

## 📊 What Gets Created

| Category | Count | Details |
|----------|-------|---------|
| **Work Items** | 200+ | Epics (5), Features (15), Stories (50), Tasks (100), Bugs (30) |
| **Test Management** | 5 Plans | 40+ test cases, multiple suites, test runs with results |
| **Repositories** | 3-5 | Multi-branch structure, sample code in C#/Python/JS |
| **Build Pipelines** | 5+ | Classic & YAML (.NET, Node.js, Docker, Python) |
| **Release Pipelines** | 5+ | Multi-stage (Dev→QA→Staging→Prod) with approvals |
| **Teams** | 4 | With distinct area paths and sprint assignments |
| **Iterations** | 12 | 2-week sprints configured |
| **Wiki Pages** | 5+ | Documentation, architecture, testing guides |
| **Dashboards** | 4 | One per team with widgets |
| **Queries** | 7+ | Shared queries and folders |

## 🔑 Key Components

### Run-All.ps1 (Orchestrator)
- Executes all 8 scripts in sequence
- Tracks progress and errors
- Generates execution summary
- Estimated time: 15-30 minutes

### ado-api-helper.ps1 (Core Utilities)
```powershell
Get-AdoHeaders        # Authentication headers
Invoke-AdoRestApi     # REST API wrapper with retry logic
New-AdoUri            # URL construction
Get-AdoConfig         # Configuration loader
ConvertTo-JsonDepth   # Deep JSON serialization
```

### config.json (Configuration)
All settings in one place:
- Organization & project details
- PAT authentication
- User assignments
- Team definitions
- Object count targets
- Repository configurations

## 🎭 Migration Testing Coverage

This project creates comprehensive data for testing ADO→GitHub migrations:

✅ All work item types and states  
✅ Hierarchical relationships (Parent/Child)  
✅ Attachments & rich content  
✅ Comments with @mentions  
✅ Custom fields & tags  
✅ Area/iteration paths  
✅ Test plans, suites, cases, results  
✅ Git repos with full history  
✅ Branch policies & pull requests  
✅ Build & release pipelines (Classic + YAML)  
✅ Variable groups & service connections  
✅ Wiki pages with markdown  
✅ Dashboards & queries  
✅ Team configurations  
✅ Cross-object links  

## 🛠️ Prerequisites

| Requirement | Details |
|-------------|---------|
| **Azure DevOps** | Organization with project creation permissions |
| **PAT Token** | Full access to Project, Work Items, Code, Build, Release, Test, Wiki |
| **PowerShell** | 7.0+ recommended (5.1+ supported) |
| **Network** | Internet connection for REST API calls |

## 📚 Documentation Guide

### For Quick Start
👉 Read: **README.md**
- Installation steps
- Configuration guide
- Troubleshooting

### For Deep Dive
👉 Read: **IMPLEMENTATION.md**
- Architecture diagrams
- API patterns
- Design decisions
- Extension points

### For AI Agents
👉 Read: **AGENTS.md**
- Complete requirements
- Object specifications
- API examples

## 🔧 Common Commands

```powershell
# Run everything
.\Run-All.ps1

# Skip project creation (if exists)
.\Run-All.ps1 -SkipProjectCreation

# Verbose output for debugging
.\Run-All.ps1 -Verbose

# Custom config file
.\Run-All.ps1 -ConfigPath "C:\path\to\config.json"

# Run specific script
.\scripts\setup\03-create-work-items.ps1
```

## 🐛 Troubleshooting Quick Fixes

| Issue | Solution |
|-------|----------|
| Authentication errors | Verify PAT token validity and scopes |
| Permission errors | Check project creation rights |
| Rate limiting | Increase delays in ado-api-helper.ps1 |
| Object already exists | Use -SkipProjectCreation or delete project |
| Script failures | Run individual scripts from /scripts/setup/ |

## 📈 Execution Timeline

```
[Run-All.ps1] ──────────────────────── 18-33 minutes total
  │
  ├─ [01-create-project] ────────────── 30-60 seconds
  ├─ [02-teams-areas] ───────────────── 1-2 minutes
  ├─ [03-work-items] ────────────────── 5-10 minutes ⏱️ Longest
  ├─ [04-test-management] ───────────── 3-5 minutes
  ├─ [05-repositories] ──────────────── 2-4 minutes
  ├─ [06-pipelines] ─────────────────── 3-5 minutes
  ├─ [07-link-objects] ──────────────── 2-4 minutes
  └─ [08-wiki-dashboards] ───────────── 2-3 minutes
```

## 🎯 Success Indicators

After completion, you should see:
- ✅ Project visible in Azure DevOps
- ✅ 200+ work items in Boards
- ✅ 5 test plans in Test Plans
- ✅ 3-5 repositories in Repos
- ✅ 10+ pipelines in Pipelines
- ✅ Wiki with multiple pages
- ✅ 4 team dashboards
- ✅ Cross-links between objects

## 🔗 Quick Links

- [Azure DevOps REST API Docs](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [JSON Patch RFC 6902](https://tools.ietf.org/html/rfc6902)

## 📞 Support

1. Check [README.md](README.md) troubleshooting section
2. Review [IMPLEMENTATION.md](IMPLEMENTATION.md) for technical details
3. Examine script comments for specific functionality
4. Validate config.json format and values

---

**Last Updated**: January 2026  
**Version**: 1.0  
**Purpose**: ADO-to-GitHub migration testing
