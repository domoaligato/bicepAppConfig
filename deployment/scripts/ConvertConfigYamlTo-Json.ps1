$Files = Get-ChildItem -Path "..\config" -File -Filter "*.yaml" | Select-Object FullName, Directory, BaseName, Extension
Remove-Item -Path "$($file.Directory.FullName)\*.json"

foreach($file in $Files){
    $inputFile = "$($file.Directory.FullName)\$($file.BaseName)$($file.Extension)"
    $outputFile = "$($file.Directory.FullName)\$($file.BaseName).json"

    $inputFile
    Get-Content -Path $inputFile
    $outputFile
    Get-Content -Path $inputFile | ConvertFrom-Yaml | ConvertTo-Json | Out-File -FilePath $outputFile -Force
    Get-Content -Path $outputFile
}