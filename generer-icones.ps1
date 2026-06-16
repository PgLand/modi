# Genere les icones PNG pour l'installation PWA
$iconsDir = Join-Path $PSScriptRoot "icons"
New-Item -ItemType Directory -Force -Path $iconsDir | Out-Null

Add-Type -AssemblyName System.Drawing

function New-BrvmIcon {
    param([int]$Size, [string]$OutputPath, [bool]$Maskable = $false)

    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    if ($Maskable) {
        $g.Clear([System.Drawing.Color]::FromArgb(79, 70, 229))
    } else {
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Rectangle 0, 0, $Size, $Size),
            [System.Drawing.Color]::FromArgb(79, 70, 229),
            [System.Drawing.Color]::FromArgb(5, 150, 105),
            45
        )
        $g.FillRectangle($brush, 0, 0, $Size, $Size)
        $brush.Dispose()
    }

    $pad = [math]::Round($Size * 0.18)
    $chartRect = New-Object System.Drawing.Rectangle $pad, $pad, ($Size - 2 * $pad), ($Size - 2 * $pad)

    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ([math]::Max(2, $Size / 32))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    $x1 = $chartRect.Left + [math]::Round($chartRect.Width * 0.1)
    $x2 = $chartRect.Left + [math]::Round($chartRect.Width * 0.35)
    $x3 = $chartRect.Left + [math]::Round($chartRect.Width * 0.55)
    $x4 = $chartRect.Left + [math]::Round($chartRect.Width * 0.85)
    $yBase = $chartRect.Bottom - [math]::Round($chartRect.Height * 0.15)

    $g.DrawLine($pen, $x1, $yBase - [math]::Round($chartRect.Height * 0.25), $x2, $yBase - [math]::Round($chartRect.Height * 0.55))
    $g.DrawLine($pen, $x2, $yBase - [math]::Round($chartRect.Height * 0.55), $x3, $yBase - [math]::Round($chartRect.Height * 0.35))
    $g.DrawLine($pen, $x3, $yBase - [math]::Round($chartRect.Height * 0.35), $x4, $yBase - [math]::Round($chartRect.Height * 0.75))

    $fontSize = [math]::Max(10, [math]::Round($Size * 0.16))
    $font = New-Object System.Drawing.Font "Segoe UI", $fontSize, ([System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Far
    $textRect = New-Object System.Drawing.RectangleF 0, 0, $Size, ($Size - $pad * 0.4)
    $g.DrawString("BRVM", $font, [System.Drawing.Brushes]::White, $textRect, $sf)

    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose(); $bmp.Dispose(); $pen.Dispose(); $font.Dispose()
    Write-Host "Cree : $OutputPath"
}

New-BrvmIcon -Size 192 -OutputPath (Join-Path $iconsDir "icon-192.png")
New-BrvmIcon -Size 512 -OutputPath (Join-Path $iconsDir "icon-512.png")
New-BrvmIcon -Size 512 -OutputPath (Join-Path $iconsDir "icon-maskable.png") -Maskable $true

Write-Host "Icones PWA generees avec succes."
