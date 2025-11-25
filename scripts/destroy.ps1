# PowerShell cleanup script for Windows
$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Azure Private Endpoint Cleanup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`nWARNING: This will destroy all resources created by Terraform!" -ForegroundColor Red
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled."
    exit 0
}

Set-Location terraform

Write-Host "`nDestroying infrastructure..." -ForegroundColor Blue
terraform destroy -auto-approve

Write-Host "`nAll resources destroyed successfully!" -ForegroundColor Green
