# Create proper ICO file from PNG
Add-Type -AssemblyName System.Drawing

$pngPath = "logo.png"
$icoPath = "logo.ico"

if (Test-Path $pngPath) {
    # Load the PNG image
    $img = [System.Drawing.Image]::FromFile($pngPath)
    
    # Create a new bitmap with proper icon dimensions
    $iconSize = 32
    $bitmap = New-Object System.Drawing.Bitmap($iconSize, $iconSize)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Draw the image scaled to icon size
    $graphics.DrawImage($img, 0, 0, $iconSize, $iconSize)
    
    # Save as ICO
    $bitmap.Save($icoPath, [System.Drawing.Imaging.ImageFormat]::Icon)
    
    # Cleanup
    $graphics.Dispose()
    $bitmap.Dispose()
    $img.Dispose()
    
    Write-Host "Created $icoPath from $pngPath"
} else {
    Write-Host "PNG file not found: $pngPath"
}
