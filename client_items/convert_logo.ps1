$bytes = [System.IO.File]::ReadAllBytes("c:\Users\misal\OneDrive\Documents\I like it\I-Like-It\client_items\App iconn.png")
$b64 = [System.Convert]::ToBase64String($bytes)
Write-Output "Length: $($b64.Length)"
Write-Output $b64
