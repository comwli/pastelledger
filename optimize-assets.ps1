# assets/original 의 원본 → assets 에 앱용 사본 생성 (아이콘 256px·가장자리 조각 제거, empty 800x600·회색 막 제거, 앱 아이콘 1024px)
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Collections.Generic;
public static class Px {
  public static Bitmap Fit(Image src, int w, int h) {
    var b = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(b)) { g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
      g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality; g.DrawImage(src, 0, 0, w, h); }
    return b;
  }
  static byte[] Get(Bitmap b, out BitmapData d) { d = b.LockBits(new Rectangle(0,0,b.Width,b.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    var a = new byte[d.Stride * b.Height]; System.Runtime.InteropServices.Marshal.Copy(d.Scan0, a, 0, a.Length); return a; }
  static void Put(Bitmap b, BitmapData d, byte[] a) { System.Runtime.InteropServices.Marshal.Copy(a, 0, d.Scan0, a.Length); b.UnlockBits(d); }
  // 알파 max 이하 픽셀을 완전 투명으로
  public static int ClearFaint(Bitmap b, int max) { BitmapData d; var a = Get(b, out d); int n = 0;
    for (int i = 3; i < a.Length; i += 4) if (a[i] > 0 && a[i] <= max) { a[i] = 0; n++; } Put(b, d, a); return n; }
  // 가장자리에 닿고 전체의 ratio 미만인 작은 덩어리 제거
  public static int DropEdgeBits(Bitmap b, double ratio) { BitmapData d; var a = Get(b, out d); int w = b.Width, h = b.Height, s = d.Stride;
    var lab = new int[w*h]; var sizes = new List<int>{0}; var edge = new List<bool>{false}; int total = 0;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) { if (lab[y*w+x] != 0 || a[y*s+x*4+3] < 16) continue;
      int id = sizes.Count, cnt = 0; bool e = false; var st = new Stack<int>(); st.Push(y*w+x); lab[y*w+x] = id;
      while (st.Count > 0) { int p = st.Pop(), px = p % w, py = p / w; cnt++; if (px == 0 || py == 0 || px == w-1 || py == h-1) e = true;
        for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) { int nx = px+dx, ny = py+dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue; int q = ny*w+nx;
          if (lab[q] == 0 && a[ny*s+nx*4+3] >= 16) { lab[q] = id; st.Push(q); } } }
      sizes.Add(cnt); edge.Add(e); total += cnt; }
    int removed = 0;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) { int id = lab[y*w+x];
      bool drop = id == 0 ? a[y*s+x*4+3] > 0 && (x == 0 || y == 0 || x == w-1 || y == h-1) : edge[id] && sizes[id] < total * ratio;
      if (drop) { a[y*s+x*4+3] = 0; removed++; } }
    Put(b, d, a); return removed; }
}
"@
$root = $PSScriptRoot; $src = Join-Path $root "assets\original"; $dst = Join-Path $root "assets"
foreach ($f in Get-ChildItem $src -Filter "cat-*.png") {
  $img = [System.Drawing.Image]::FromFile($f.FullName); $b = [Px]::Fit($img, 256, 256); $img.Dispose()
  $n = [Px]::DropEdgeBits($b, 0.02)
  $b.Save((Join-Path $dst $f.Name), [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
  if ($n -gt 0) { Write-Output "$($f.Name): edge pixels removed $n" }
}
$img = [System.Drawing.Image]::FromFile((Join-Path $src "empty.png")); $b = [Px]::Fit($img, 800, 600); $img.Dispose()
Write-Output ("empty.png: faint pixels cleared " + [Px]::ClearFaint($b, 40))
$b.Save((Join-Path $dst "empty.png"), [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
$img = [System.Drawing.Image]::FromFile((Join-Path $src "icon-1024.png")); $b = [Px]::Fit($img, 1024, 1024); $img.Dispose()
$b.Save((Join-Path $dst "icon-1024.png"), [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
Write-Output "done"
