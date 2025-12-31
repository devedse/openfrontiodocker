#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local PowerShell script to build OpenFrontIO Docker image
.DESCRIPTION
    Builds the Docker image which clones and builds OpenFrontIO internally.
.PARAMETER Tag
    Custom tag for the image (default: latest)
.PARAMETER Push
    Push the image to Docker Hub after building
.PARAMETER MultiPlatform
    Build for multiple platforms (linux/amd64,linux/arm64)
.EXAMPLE
    .\build-local.ps1
    .\build-local.ps1 -Tag "v1.0.0"
    .\build-local.ps1 -Push -MultiPlatform
#>

param(
    [string]$Tag = "latest",
    [string]$DockerHubUser = "devedse",
    [switch]$Push,
    [switch]$MultiPlatform
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
if ($MultiPlatform) {
    Write-Host "Platforms: linux/amd64, linux/arm64" -ForegroundColor Green
} else {
    Write-Host "Platform: Current platform only" -ForegroundColor Yellow
}
Write-Host "Note: Dockerfile will clone OpenFrontIO during build" -ForegroundColor Yellow

# Check if buildx is available for multi-platform builds
if ($MultiPlatform) {
    $buildxExists = docker buildx version 2>$null
    if (-not $buildxExists) {
        Write-Error "Docker buildx is required for multi-platform builds but not available"
        exit 1
    }
    
    # Create or use existing builder
    Write-Host "Setting up buildx builder..." -ForegroundColor Yellow
    docker buildx create --use --name openfrontio-builder 2>$null
    if ($LASTEXITCODE -ne 0) {
        # Builder might already exist, try to use it
        docker buildx use openfrontio-builder 2>$null
    }
}

# Build the image
try {
    if ($MultiPlatform) {
        $pushFlag = if ($Push) { "--push" } else { "" }
        if (-not $Push) {
            Write-Warning "Multi-platform builds cannot be loaded locally. Use -Push to push to registry, or remove -MultiPlatform for local builds."
            Write-Host "Building with --push flag automatically enabled for multi-platform..." -ForegroundColor Yellow
            $pushFlag = "--push"
        }
        
        docker buildx build `
            --platform linux/amd64,linux/arm64 `
            -t "${imageName}:${versionTag}" `
            -t "${imageName}:latest" `
            $pushFlag `
            .
    } else {
        docker build `
            -t "${imageName}:${versionTag}" `
            -t "${imageName}:latest" `
            .
        
        if ($LASTEXITCODE -eq 0 -and $Push) {
            Write-Host "Pushing images to Docker Hub..." -ForegroundColor Yellow
            docker push "${imageName}:${versionTag}"
            docker push "${imageName}:latest"
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    
    Write-Host "✅ Docker image built successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to build Docker image: $_"
    exit 1
}

Write-Header "Build Complete"
Write-Host "Image: ${imageName}:${versionTag}" -ForegroundColor Green
Write-Host "Image: ${imageName}:latest" -ForegroundColor Green
if ($Push) {
    Write-Host "✅ Images pushed to Docker Hub" -ForegroundColor Green
}
