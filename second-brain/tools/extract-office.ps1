# extract-office.ps1 — Windows/PowerShell port of extract-office.sh
# Extract readable text from PPTX/DOCX. Native .NET zip reader — no unzip/grep needed.
# Usage:  pwsh -File second-brain\tools\extract-office.ps1 raw\MyFile.pptx
# Output: plain text to stdout.

param([Parameter(Mandatory = $true)][string]$File)

if (-not (Test-Path -LiteralPath $File)) { Write-Error "File not found: $File"; exit 1 }
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ext = ([System.IO.Path]::GetExtension($File)).TrimStart('.').ToLower()
try { $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $File).Path) }
catch { Write-Error "Could not open $File - is it a valid Office file?"; exit 1 }

try {
    switch ($ext) {
        'pptx' {
            $slides = $zip.Entries |
                Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' } |
                Sort-Object { [int]([regex]::Match($_.Name, '\d+').Value) }
            foreach ($s in $slides) {
                $reader = New-Object System.IO.StreamReader($s.Open())
                $xml = $reader.ReadToEnd(); $reader.Close()
                $texts = [regex]::Matches($xml, '<a:t>([^<]*)</a:t>') |
                    ForEach-Object { $_.Groups[1].Value } | Where-Object { $_.Trim() }
                if ($texts) {
                    $num = [regex]::Match($s.Name, '\d+').Value
                    Write-Output "-- Slide $num --"
                    Write-Output ($texts -join ' ')
                    Write-Output ""
                }
            }
        }
        'docx' {
            $doc = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' } | Select-Object -First 1
            if ($doc) {
                $reader = New-Object System.IO.StreamReader($doc.Open())
                $xml = $reader.ReadToEnd(); $reader.Close()
                # <w:t ...> may carry attributes (e.g. xml:space="preserve")
                [regex]::Matches($xml, '<w:t[^>]*>([^<]*)</w:t>') |
                    ForEach-Object { $_.Groups[1].Value } |
                    Where-Object { $_.Trim() } |
                    ForEach-Object { Write-Output $_ }
            }
        }
        default { Write-Error "Unsupported format .$ext (supported: pptx, docx)"; exit 1 }
    }
} finally { $zip.Dispose() }
