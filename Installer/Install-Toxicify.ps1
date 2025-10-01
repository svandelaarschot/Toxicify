# Toxicify Addon Installer - PowerShell Version
# Advanced installation tool with GUI and error handling

param(
    [string]$WoWPath = "",
    [switch]$Silent = $false,
    [switch]$Force = $false
)

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to find WoW installations
function Find-WoWInstallations {
    $commonPaths = @(
        # Retail WoW paths
        "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns",
        "C:\Program Files\World of Warcraft\_retail_\Interface\AddOns",
        "D:\World of Warcraft\_retail_\Interface\AddOns",
        "E:\World of Warcraft\_retail_\Interface\AddOns",
        "F:\World of Warcraft\_retail_\Interface\AddOns",
        # Classic WoW paths
        "C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns",
        "C:\Program Files\World of Warcraft\_classic_\Interface\AddOns",
        "D:\World of Warcraft\_classic_\Interface\AddOns",
        "E:\World of Warcraft\_classic_\Interface\AddOns",
        "F:\World of Warcraft\_classic_\Interface\AddOns",
        # Classic Era WoW paths
        "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns",
        "C:\Program Files\World of Warcraft\_classic_era_\Interface\AddOns",
        "D:\World of Warcraft\_classic_era_\Interface\AddOns",
        "E:\World of Warcraft\_classic_era_\Interface\AddOns",
        "F:\World of Warcraft\_classic_era_\Interface\AddOns"
    )
    
    $foundPaths = @()
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    return $foundPaths
}

# Function to validate WoW AddOns path
function Test-WoWAddOnsPath {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    # Check if it looks like a WoW AddOns directory
    $expectedFiles = @("Blizzard_*.lua", "*.toc")
    $hasWoWFiles = $false
    
    foreach ($pattern in $expectedFiles) {
        if (Get-ChildItem -Path $Path -Filter $pattern -ErrorAction SilentlyContinue) {
            $hasWoWFiles = $true
            break
        }
    }
    
    return $hasWoWFiles
}

# Function to install addon
function Install-ToxicifyAddon {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )
    
    try {
        Write-ColorOutput "Installing Toxicify addon..." "Yellow"
        
        # Create target directory if it doesn't exist
        if (-not (Test-Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }
        
        # Copy all files
        Copy-Item -Path "$SourcePath\*" -Destination $TargetPath -Recurse -Force
        
        # Verify installation
        $requiredFiles = @("Toxicify.toc", "Core.lua", "Events.lua", "Player.lua")
        $missingFiles = @()
        
        foreach ($file in $requiredFiles) {
            if (-not (Test-Path "$TargetPath\$file")) {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -gt 0) {
            throw "Missing required files: $($missingFiles -join ', ')"
        }
        
        # Set file permissions
        try {
            icacls $TargetPath /grant Everyone:F /T /Q | Out-Null
        } catch {
            Write-ColorOutput "Warning: Could not set file permissions" "Yellow"
        }
        
        return $true
    } catch {
        Write-ColorOutput "Error installing addon: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main installation logic
function Start-Installation {
    Write-ColorOutput "`n========================================" "Cyan"
    Write-ColorOutput "    Toxicify Addon Installer" "Cyan"
    Write-ColorOutput "    PowerShell Version" "Cyan"
    Write-ColorOutput "========================================`n" "Cyan"
    
    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-ColorOutput "Warning: Not running as administrator. Some operations may fail." "Yellow"
        if (-not $Silent) {
            $continue = Read-Host "Continue anyway? (y/n)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                exit 1
            }
        }
    }
    
    # Get script directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $sourcePath = Join-Path $scriptDir "Toxicify"
    
    # Check if source directory exists
    if (-not (Test-Path $sourcePath)) {
        Write-ColorOutput "Error: Toxicify source directory not found: $sourcePath" "Red"
        Write-ColorOutput "Please make sure this installer is in the same folder as the Toxicify addon." "Red"
        exit 1
    }
    
    # Determine target path
    $targetPath = ""
    
    if ($WoWPath -ne "") {
        # Use provided path
        if (Test-WoWAddOnsPath $WoWPath) {
            $targetPath = Join-Path $WoWPath "Toxicify"
        } else {
            Write-ColorOutput "Error: Invalid WoW AddOns path: $WoWPath" "Red"
            exit 1
        }
    } else {
        # Find WoW installations
        $foundPaths = Find-WoWInstallations
        
        if ($foundPaths.Count -eq 0) {
            Write-ColorOutput "No standard WoW installations found." "Yellow"
            if (-not $Silent) {
                $customPath = Read-Host "Please enter the full path to your WoW AddOns folder"
                if (Test-WoWAddOnsPath $customPath) {
                    $targetPath = Join-Path $customPath "Toxicify"
                } else {
                    Write-ColorOutput "Error: Invalid WoW AddOns path: $customPath" "Red"
                    exit 1
                }
            } else {
                Write-ColorOutput "Error: No WoW installation found and no path provided." "Red"
                exit 1
            }
        } elseif ($foundPaths.Count -eq 1) {
            # Only one installation found
            $targetPath = Join-Path $foundPaths[0] "Toxicify"
            Write-ColorOutput "Found WoW installation: $($foundPaths[0])" "Green"
        } else {
            # Multiple installations found
            Write-ColorOutput "Multiple WoW installations found:" "Yellow"
            for ($i = 0; $i -lt $foundPaths.Count; $i++) {
                Write-ColorOutput "[$($i + 1)] $($foundPaths[$i])" "White"
            }
            
            if (-not $Silent) {
                $choice = Read-Host "Please select your WoW installation (1-$($foundPaths.Count)) or 'c' for custom path"
                
                if ($choice -eq "c" -or $choice -eq "C") {
                    $customPath = Read-Host "Please enter the full path to your WoW AddOns folder"
                    if (Test-WoWAddOnsPath $customPath) {
                        $targetPath = Join-Path $customPath "Toxicify"
                    } else {
                        Write-ColorOutput "Error: Invalid WoW AddOns path: $customPath" "Red"
                        exit 1
                    }
                } else {
                    $index = [int]$choice - 1
                    if ($index -ge 0 -and $index -lt $foundPaths.Count) {
                        $targetPath = Join-Path $foundPaths[$index] "Toxicify"
                    } else {
                        Write-ColorOutput "Error: Invalid choice." "Red"
                        exit 1
                    }
                }
            } else {
                # Silent mode - use first found path
                $targetPath = Join-Path $foundPaths[0] "Toxicify"
            }
        }
    }
    
    # Check if addon already exists
    if ((Test-Path $targetPath) -and -not $Force) {
        Write-ColorOutput "Toxicify addon already exists at: $targetPath" "Yellow"
        if (-not $Silent) {
            $overwrite = Read-Host "Overwrite existing installation? (y/n)"
            if ($overwrite -ne "y" -and $overwrite -ne "Y") {
                Write-ColorOutput "Installation cancelled." "Yellow"
                exit 0
            }
        } else {
            Write-ColorOutput "Use -Force parameter to overwrite existing installation." "Yellow"
            exit 1
        }
    }
    
    # Install the addon
    Write-ColorOutput "`nInstalling Toxicify to: $targetPath" "Yellow"
    
    if (Install-ToxicifyAddon -SourcePath $sourcePath -TargetPath $targetPath) {
        Write-ColorOutput "`n========================================" "Green"
        Write-ColorOutput "    Installation Complete!" "Green"
        Write-ColorOutput "========================================`n" "Green"
        
        Write-ColorOutput "Toxicify has been successfully installed to:" "Green"
        Write-ColorOutput $targetPath "Cyan"
        
        Write-ColorOutput "`nInstalled files:" "White"
        Get-ChildItem -Path $targetPath -Name | ForEach-Object { Write-ColorOutput "  - $_" "Gray" }
        
        if (-not $Silent) {
            $openFolder = Read-Host "`nWould you like to open the addon folder? (y/n)"
            if ($openFolder -eq "y" -or $openFolder -eq "Y") {
                Invoke-Item $targetPath
            }
        }
        
        Write-ColorOutput "`nThank you for using Toxicify!" "Green"
    } else {
        Write-ColorOutput "`nInstallation failed!" "Red"
        exit 1
    }
}

# Run the installation
Start-Installation
