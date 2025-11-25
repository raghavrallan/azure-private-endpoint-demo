# PowerShell deployment script for Windows
# Exit on error
$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Azure Private Endpoint Deployment" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check if required tools are installed
Write-Host "`nChecking prerequisites..." -ForegroundColor Blue
$tools = @("az", "terraform", "docker")
foreach ($tool in $tools) {
    if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "$tool is required but not installed. Aborting." -ForegroundColor Red
        exit 1
    }
}

# Check if logged in to Azure
Write-Host "Checking Azure authentication..." -ForegroundColor Blue
try {
    az account show | Out-Null
} catch {
    Write-Host "Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

Write-Host "Prerequisites check passed!" -ForegroundColor Green

# Step 1: Initialize and apply Terraform
Write-Host "`nStep 1: Deploying infrastructure with Terraform..." -ForegroundColor Blue
Set-Location terraform

if (!(Test-Path "terraform.tfvars")) {
    Write-Host "terraform.tfvars not found. Please create it from terraform.tfvars.example" -ForegroundColor Red
    exit 1
}

Write-Host "Initializing Terraform..."
terraform init

Write-Host "Planning Terraform deployment..."
terraform plan -out=tfplan

Write-Host "Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
Write-Host "`nGetting Terraform outputs..." -ForegroundColor Blue
$ACR_NAME = terraform output -raw container_registry_name
$ACR_LOGIN_SERVER = terraform output -raw container_registry_login_server
$CONTAINER_APP_URL = terraform output -raw container_app_url

Write-Host "Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "ACR Name: $ACR_NAME"
Write-Host "ACR Login Server: $ACR_LOGIN_SERVER"
Write-Host "Container App URL: $CONTAINER_APP_URL"

Set-Location ..

# Step 2: Build and push Docker image
Write-Host "`nStep 2: Building and pushing Docker image..." -ForegroundColor Blue
Set-Location app

Write-Host "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME

Write-Host "Building Docker image..."
docker build -t "${ACR_LOGIN_SERVER}/api-app:latest" .

Write-Host "Pushing Docker image..."
docker push "${ACR_LOGIN_SERVER}/api-app:latest"

Write-Host "Docker image pushed successfully!" -ForegroundColor Green

Set-Location ..

# Step 3: Update Container App with new image
Write-Host "`nStep 3: Updating Container App..." -ForegroundColor Blue
Set-Location terraform

Write-Host "Triggering Container App revision update..."
terraform apply -auto-approve

Write-Host "Container App updated successfully!" -ForegroundColor Green

# Final output
Write-Host "`n======================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Container App URL: $CONTAINER_APP_URL"
Write-Host ""
Write-Host "Test the endpoints:"
Write-Host "  Health Check:       ${CONTAINER_APP_URL}/"
Write-Host "  Cosmos DB Test:     ${CONTAINER_APP_URL}/test-cosmos"
Write-Host "  Storage Test:       ${CONTAINER_APP_URL}/test-storage"
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
