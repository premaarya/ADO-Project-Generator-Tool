# YAML CI Pipelines with Reusable Templates

This directory contains 12 Azure DevOps YAML CI pipeline definitions that leverage reusable templates to promote code reuse and maintainability.

## Architecture

### Reusable Templates (`templates/`)

The solution includes 4 reusable YAML templates that encapsulate common build patterns:

#### 1. **dotnet-build-template.yaml**
- **Purpose**: Build .NET applications (C#)
- **Features**:
  - Configurable .NET SDK version
  - NuGet package restoration
  - Solution build with multiple configurations
  - Unit test execution with code coverage
  - Test results and coverage publishing
  - Artifact creation and publishing
- **Parameters**:
  - `buildConfiguration` (default: 'Release')
  - `dotnetVersion` (default: '8.x')
  - `projectPath` (default: '**/*.csproj')
  - `testProjectPath` (default: '**/*Tests.csproj')
  - `runTests` (default: true)
  - `publishArtifacts` (default: true)

#### 2. **node-build-template.yaml**
- **Purpose**: Build Node.js/JavaScript applications
- **Features**:
  - Configurable Node.js version
  - NPM dependency installation
  - ESLint code quality checks
  - Unit and integration tests
  - Test results and coverage publishing
  - Build artifact creation
- **Parameters**:
  - `nodeVersion` (default: '20.x')
  - `workingDirectory` (default: '.')
  - `runLint` (default: true)
  - `runTests` (default: true)
  - `buildCommand` (default: 'npm run build')
  - `publishArtifacts` (default: true)

#### 3. **python-build-template.yaml**
- **Purpose**: Build Python applications
- **Features**:
  - Configurable Python version
  - Pip dependency management
  - Code quality checks (black, flake8, pylint)
  - Pytest test execution with coverage
  - Test results publishing
  - Wheel package creation
- **Parameters**:
  - `pythonVersion` (default: '3.11')
  - `workingDirectory` (default: '.')
  - `requirementsFile` (default: 'requirements.txt')
  - `runQualityChecks` (default: true)
  - `runTests` (default: true)
  - `publishArtifacts` (default: true)

#### 4. **docker-build-template.yaml**
- **Purpose**: Build and push Docker container images
- **Features**:
  - Docker image building
  - Security scanning with Trivy
  - Multi-tag support
  - Container registry push
  - Configurable build context
- **Parameters**:
  - `dockerfilePath` (default: 'Dockerfile')
  - `imageName` (required)
  - `containerRegistry` (optional)
  - `runSecurityScan` (default: true)
  - `buildContext` (default: '.')
  - `additionalTags` (array, default: [])

## CI Pipeline Definitions

The solution generates **12 YAML CI pipelines**, each specialized for different application components:

### .NET Pipelines (4)

1. **Main-Web-App-CI**
   - Main web application
   - Full .NET build with tests
   - Publishes web artifacts

2. **API-Gateway-CI**
   - API Gateway service
   - .NET Core build
   - Ubuntu build agent

3. **Mobile-Backend-CI**
   - Mobile backend service
   - .NET build with tests
   - Cross-platform support

4. **Payment-Service-CI**
   - Payment processing service
   - Critical service with hotfix branch support
   - Enhanced test coverage

### Node.js Pipelines (4)

5. **Auth-Service-CI**
   - Authentication microservice
   - Node.js 20.x
   - Linting and testing

6. **User-Service-CI**
   - User management service
   - Full test suite
   - Coverage reporting

7. **Frontend-App-CI**
   - React/Angular frontend
   - Production build configuration
   - Feature branch support

8. **API-Docs-CI**
   - API documentation generator
   - No tests (documentation only)
   - Builds static documentation site

### Python Pipelines (3)

9. **Notification-Service-CI**
   - Notification microservice
   - Python 3.11
   - Quality checks and tests

10. **Analytics-Service-CI**
    - Analytics and reporting service
    - Data processing capabilities
    - Comprehensive testing

11. **Data-Processing-CI**
    - Batch data processing service
    - ETL pipelines
    - Quality assurance

### Container Pipeline (1)

12. **Container-WebApp-CI**
    - Containerized web application
    - Docker build and scan
    - Multi-tag versioning
    - Container registry push

## Pipeline Structure

Each pipeline follows a consistent structure:

```yaml
name: <Pipeline-Name>

trigger:
  branches:
    include:
    - main
    - develop
    - feature/*  # Where applicable
  paths:
    include:
    - <service-path>/*

pool:
  vmImage: '<os>-latest'

variables:
  <pipeline-specific-variables>

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: Build
    steps:
    - template: templates/<template-name>.yaml
      parameters:
        <template-parameters>
```

## Benefits of This Architecture

### 1. **Code Reuse**
- Templates eliminate duplication across pipelines
- Common build patterns defined once
- Easy to maintain and update

### 2. **Consistency**
- All pipelines of the same type follow identical patterns
- Standardized test execution and reporting
- Uniform artifact publishing

### 3. **Flexibility**
- Parameters allow customization per pipeline
- Easy to add new pipelines using existing templates
- Support for different configurations

### 4. **Maintainability**
- Changes to build patterns update all pipelines
- Templates are versioned with the repository
- Clear separation of concerns

### 5. **Best Practices**
- Code coverage collection
- Test result publishing
- Security scanning (for containers)
- Artifact versioning

## Usage

### Adding a New Pipeline

1. Determine which template fits your application type
2. Create a new YAML file in the `pipelines/` directory
3. Reference the appropriate template with parameters
4. Configure triggers and variables

Example:

```yaml
name: New-Service-CI

trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  nodeVersion: '20.x'

stages:
- stage: Build
  jobs:
  - job: Build
    steps:
    - template: templates/node-build-template.yaml
      parameters:
        nodeVersion: $(nodeVersion)
        workingDirectory: 'services/new-service'
        runLint: true
        runTests: true
```

### Modifying a Template

To modify build behavior across multiple pipelines:

1. Edit the template file in `templates/`
2. Update parameters if needed
3. Test changes with one pipeline first
4. Commit changes to apply across all pipelines using that template

## Migration Coverage

These pipelines provide comprehensive test coverage for ADO-to-GitHub migrations:

- ✅ YAML pipeline definitions
- ✅ Reusable templates
- ✅ Multi-stage pipelines
- ✅ Multiple trigger types
- ✅ Path and branch filters
- ✅ Variable usage
- ✅ Template parameters
- ✅ Conditional execution
- ✅ Test result publishing
- ✅ Code coverage
- ✅ Artifact publishing
- ✅ Multi-platform builds (Windows, Linux)
- ✅ Multiple tech stacks (.NET, Node.js, Python, Docker)

## File Structure

```
repository/
├── pipelines/
│   ├── main-web-app-ci.yaml
│   ├── api-gateway-ci.yaml
│   ├── auth-service-ci.yaml
│   ├── user-service-ci.yaml
│   ├── notification-service-ci.yaml
│   ├── analytics-service-ci.yaml
│   ├── frontend-app-ci.yaml
│   ├── mobile-backend-ci.yaml
│   ├── data-processing-ci.yaml
│   ├── payment-service-ci.yaml
│   ├── api-docs-ci.yaml
│   └── container-webapp-ci.yaml
└── templates/
    ├── dotnet-build-template.yaml
    ├── node-build-template.yaml
    ├── python-build-template.yaml
    └── docker-build-template.yaml
```

## Technical Details

### Template Syntax

Templates use Azure DevOps YAML template syntax:

- `parameters`: Define input parameters with types and defaults
- `steps`: Define reusable step sequences
- `${{ }}`: Template expression syntax for parameter substitution
- Conditional execution: `${{ if eq(parameters.x, true) }}`

### Pipeline Creation

The `06-create-pipelines.ps1` script:

1. Defines 12 pipeline configurations
2. Generates appropriate YAML content per type
3. Creates 4 reusable template files
4. Commits all files to the repository
5. Creates pipeline definitions via REST API
6. Links pipelines to YAML files in the repo

### API Endpoints Used

- `POST /_apis/git/repositories/{id}/pushes` - Commit YAML files
- `POST /_apis/pipelines` - Create pipeline definitions
- `GET /_apis/git/repositories/{id}/refs` - Get branch references

## Best Practices Demonstrated

1. **Template Parameterization**: Flexible, reusable components
2. **Conditional Steps**: Execute steps based on parameters
3. **Working Directory**: Support for monorepo structures
4. **Test Publishing**: Unified test result format
5. **Code Coverage**: Track quality metrics
6. **Artifact Management**: Consistent artifact naming
7. **Security Scanning**: Container vulnerability detection
8. **Multi-stage Builds**: Organized pipeline structure
9. **Version Tagging**: Build ID and custom tags
10. **Error Handling**: Continue-on-error for non-critical steps

## Troubleshooting

### Template Not Found
- Ensure templates are committed to the repository
- Verify the template path in the pipeline YAML
- Check that templates are in the `templates/` directory

### Parameter Errors
- Validate parameter types match expectations
- Ensure required parameters are provided
- Check default values are appropriate

### Pipeline Creation Fails
- Verify repository exists
- Check PAT permissions
- Ensure YAML syntax is valid
- Review API version compatibility

## References

- [Azure Pipelines YAML Schema](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/)
- [Template Types](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/templates)
- [Pipeline REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/)
