# assets/icon-1024.png 로 홈 화면 아이콘(180/192/512) 생성. 원본이 없으면 레몬색 임시 아이콘
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$src = Join-Path $root "assets\icon-1024.png"
$out = Join-Path $root "icons"
New-Item -ItemType Directory -Force $out | Out-Null

foreach ($size in 180, 192, 512) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = "AntiAlias"; $g.InterpolationMode = "HighQualityBicubic"; $g.PixelOffsetMode = "HighQuality"
    if (Test-Path $src) {
        $img = [System.Drawing.Image]::FromFile($src)
        $g.DrawImage($img, 0, 0, $size, $size)
        $img.Dispose()
    } else {
        $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#FEF1A2"))
        $s = $size / 100
        $pen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#FDDB4F")), (6 * $s)
        $white = [System.Drawing.Brushes]::White
        $g.FillRectangle($white, 22 * $s, 38 * $s, 56 * $s, 42 * $s)
        $g.DrawRectangle($pen, 22 * $s, 38 * $s, 56 * $s, 42 * $s)
        $g.FillEllipse($white, 36 * $s, 18 * $s, 28 * $s, 28 * $s)
        $g.DrawEllipse($pen, 36 * $s, 18 * $s, 28 * $s, 28 * $s)
        $pen.Dispose()
    }
    $bmp.Save((Join-Path $out "icon-$size.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}
Write-Output "icons: $(if (Test-Path $src) {'원본으로 생성'} else {'임시 아이콘 생성'})"
