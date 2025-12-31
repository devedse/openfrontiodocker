#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local PowerShell script to build OpenFrontIO Docker image
.DESCRIPTION
    Builds the Docker image which clones and builds OpenFrontIO internally.
.PARAMETER Tag
    Custom tag for the image (default: latest)
.EXAMPLE
    .\build-local.ps1
    .\build-local.ps1 -Tag "v1.0.0"
#>

param(
    [string]$Tag = "latest",
    [string]$DockerHubUser = "devedse"
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

# Configuration
$imageName = "${DockerHubUser}/openfrontio"

Write-Header "OpenFrontIO Docker Build Script"

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH"
    exit 1
}

# Generate version tag if using latest
if ($Tag -eq "latest") {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $versionTag = $timestamp
} else {
    $versionTag = $Tag
}

Write-Header "Building Docker Image"
Write-Host "Image name: $imageName" -ForegroundColor Green
Write-Host "Version tag: $versionTag" -ForegroundColor Green
Write-Host "Note: Dockerfile will clone OpenFrontIO during build" -ForegroundColor Yellow

# Build Docker image (Dockerfile handles cloning OpenFrontIO)
docker build `
    --tag "${imageName}:${versionTag}" `
    --tag "${imageName}:latest" `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed"
    exit 1
}

Write-Host "✅ Docker image built successfully!" -ForegroundColor Green

Write-Header "Build Complete"
Write-Host "Image: ${imageName}:${versionTag}" -ForegroundColor Green
Write-Host "Image: ${imageName}:latest" -ForegroundColor Green
