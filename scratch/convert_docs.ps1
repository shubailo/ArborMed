$ErrorActionPreference = "Stop"
$bookDir = "C:\Users\shuba\Desktop\ArborMed\Pathophys_book"
$outDir = "C:\Users\shuba\Desktop\ArborMed\Pathophys_book\md"

if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false

    Get-ChildItem $bookDir -Filter "*.doc" | ForEach-Object {
        $docPath = $_.FullName
        $baseName = $_.BaseName
        $outPath = Join-Path $outDir "$baseName.md"

        Write-Host "Converting: $($_.Name) ..."
        
        $doc = $word.Documents.Open($docPath, $false, $true)
        
        # Extract all paragraph text
        $lines = @()
        foreach ($para in $doc.Paragraphs) {
            $text = $para.Range.Text.Trim()
            # Clean up weird Word characters
            $text = $text -replace [char]11, "`n"  # vertical tab -> newline
            $text = $text -replace [char]13, ""     # carriage return
            $text = $text -replace '\x0B', "`n"
            if ($text -ne "") {
                $lines += $text
            }
        }
        
        $doc.Close($false)
        
        $content = $lines -join "`n`n"
        [System.IO.File]::WriteAllText($outPath, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  -> Saved: $baseName.md ($($lines.Count) paragraphs)"
    }

    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    Write-Host "`n✅ All .doc files converted to markdown in $outDir"
}
catch {
    Write-Error "Conversion failed: $_"
    if ($word) { try { $word.Quit() } catch {} }
}
