# Quick Start: Testing YAML CI Pipelines

This guide helps you verify that the 12 YAML CI pipelines with reusable templates are working correctly.

## Prerequisites

- Azure DevOps project created and configured
- Pipelines script executed successfully (`06-create-pipelines.ps1`)
- Access to Azure DevOps UI

## Verification Steps

### 1. Check Pipeline Creation

Navigate to **Pipelines** → **Pipelines** in your Azure DevOps project.

You should see **12 YAML CI pipelines**:

#### .NET Pipelines (4)
- ✅ Main-Web-App-CI
- ✅ API-Gateway-CI
- ✅ Mobile-Backend-CI
- ✅ Payment-Service-CI

#### Node.js Pipelines (4)
- ✅ Auth-Service-CI
- ✅ User-Service-CI
- ✅ Frontend-App-CI
- ✅ API-Docs-CI

#### Python Pipelines (3)
- ✅ Notification-Service-CI
- ✅ Analytics-Service-CI
- ✅ Data-Processing-CI

#### Docker Pipeline (1)
- ✅ Container-WebApp-CI

### 2. Check Repository Files

Navigate to **Repos** → **Files** in the main-app repository.

Verify the following structure exists:

```
main-app/
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

### 3. Verify Template Content

Click on `templates/dotnet-build-template.yaml` and verify:
- ✅ Contains `parameters:` section
- ✅ Defines steps with template expressions `${{ }}`
- ✅ Has conditional execution blocks
- ✅ Uses parameterized values

### 4. Verify Pipeline YAML

Click on `pipelines/main-web-app-ci.yaml` and verify:
- ✅ Has `name:` field
- ✅ Contains `trigger:` section with branches
- ✅ Defines `pool:` and `variables:`
- ✅ Uses `template:` reference: `- template: templates/dotnet-build-template.yaml`
- ✅ Passes `parameters:` to the template

### 5. Test Pipeline Execution (Optional)

To test that pipelines actually work:

1. Select a pipeline (e.g., "Main-Web-App-CI")
2. Click **Run pipeline**
3. Expected behavior:
   - Pipeline may fail on actual task execution (no real code)
   - Should successfully resolve the template
   - Should show stages and jobs from the template

**Note**: Pipelines will fail during execution because there's no actual application code, but the structure and template resolution should work.

### 6. Verify Pipeline Definition

For each pipeline:
1. Click on the pipeline name
2. Click **Edit** (top right)
3. Verify:
   - ✅ YAML file path is correct
   - ✅ Repository is linked correctly
   - ✅ Branch is "main"

### 7. Check Template Parameters

Open any pipeline and look for the template call:

```yaml
steps:
- template: templates/dotnet-build-template.yaml
  parameters:
    buildConfiguration: $(buildConfiguration)
    dotnetVersion: '8.x'
    projectPath: '**/*.csproj'
    testProjectPath: '**/*Tests.csproj'
    runTests: true
    publishArtifacts: true
```

Verify parameters are properly passed.

## Common Issues & Solutions

### Issue: Pipeline Not Found
**Solution**: 
- Check `scripts/output/pipelines-info.json` for created pipeline IDs
- Verify the pipeline creation script completed successfully
- Re-run `06-create-pipelines.ps1` if needed

### Issue: Template File Not Found
**Solution**:
- Ensure templates were committed to repository
- Check that templates are in `templates/` directory at repo root
- Verify first pipeline (Main-Web-App-CI) ran, which creates templates

### Issue: YAML Syntax Error
**Solution**:
- Templates use Azure DevOps YAML schema
- Check for proper indentation (2 spaces)
- Verify template expressions use `${{ }}` not `$()`

### Issue: Pipeline Won't Run
**Solution**:
- Check triggers are configured correctly
- Verify repository has commits
- Ensure PAT has pipeline execution permissions

## Success Criteria

✅ All 12 pipelines visible in Azure DevOps UI  
✅ All 12 YAML files exist in repository  
✅ 4 template files exist in repository  
✅ Pipelines reference templates correctly  
✅ Templates are parameterized  
✅ No YAML syntax errors

## Migration Testing Checklist

When testing ADO-to-GitHub migration:

- [ ] All 12 pipelines migrate successfully
- [ ] Template files are included in migration
- [ ] Template references are preserved or converted
- [ ] Pipeline parameters are maintained
- [ ] Triggers and paths are migrated
- [ ] Variables are preserved
- [ ] Multi-stage structure is maintained
- [ ] Conditional execution logic works
- [ ] Different technology stacks (.NET, Node, Python, Docker) all work

## Output Files

Check these files for pipeline information:

- **pipelines-info.json**: Contains IDs and names of created pipelines
- **repositories-info.json**: Contains repository IDs used by pipelines

## API Verification

You can also verify via REST API:

```powershell
# List all pipelines
$org = "YOUR_ORG"
$project = "YOUR_PROJECT"
$pat = "YOUR_PAT"

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
}

$uri = "https://dev.azure.com/$org/$project/_apis/pipelines?api-version=7.1-preview.1"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET

$response.value | Select-Object id, name | Format-Table
```

Expected output: 12 YAML pipelines listed.

## Next Steps

After verification:
1. Review [YAML-PIPELINES-README.md](YAML-PIPELINES-README.md) for detailed documentation
2. Proceed to script 07 for linking objects
3. Run full migration test with your ADO-to-GitHub tool
4. Compare migrated pipelines with originals

## Support

If you encounter issues:
- Check PowerShell script output logs
- Review [IMPLEMENTATION.md](IMPLEMENTATION.md) for technical details
- Verify configuration in `utils/config.json`
- Check Azure DevOps REST API limits

## Pipeline Statistics

Expected creation summary:
- **Total Pipelines**: 12 YAML CI pipelines
- **Templates**: 4 reusable templates
- **.NET Pipelines**: 4
- **Node.js Pipelines**: 4
- **Python Pipelines**: 3
- **Docker Pipelines**: 1

All pipelines demonstrate:
- ✅ Template usage
- ✅ Parameterization
- ✅ Multi-stage builds
- ✅ Test execution
- ✅ Code coverage
- ✅ Artifact publishing
- ✅ Best practices
