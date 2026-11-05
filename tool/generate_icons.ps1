Add-Type -AssemblyName System.Drawing
$srcPath = Join-Path (Get-Location) 'assets\images\vargani_logo.png'
$srcImg = [System.Drawing.Image]::FromFile($srcPath)

$sizes = @{
    'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' = 48
    'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' = 72
    'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' = 96
    'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' = 144
    'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' = 192
}

foreach ($dest in $sizes.Keys) {
    $dim = $sizes[$dest]
    $destBmp = New-Object System.Drawing.Bitmap($dim, $dim)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $dim, $dim)
    $g.Dispose()

    $fullDest = Join-Path (Get-Location) $dest
    $destDir = [System.IO.Path]::GetDirectoryName($fullDest)
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $destBmp.Save($fullDest, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Generated $dim x $dim -> $dest"
}

$srcImg.Dispose()
Write-Host 'All Android launcher icons generated successfully!'

