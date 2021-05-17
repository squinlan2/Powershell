function find-duplicatefiles
{
    param
    (
        $path,
        $outpath
    )

    $fileHashList = [System.Collections.Concurrent.ConcurrentStack[object]]::new()
    $fileHashList.Clear()
    $fileht = @{}

    try
    {
        Get-ChildItem -Path $path -Recurse -Attributes !Directory -OutVariable filelist | select fullname, LastWriteTime, LastAccessTime, Length 
    }
    catch [System.Io.FileNotFoundException]{
        write-host "File not Found."
        break
    }

    write-host "Total Files" $fileList.count
    
    $fileht = $fileList | Group-Object -Property Length -AsHashTable
    
    foreach($key in $fileht.Keys){
        if($fileht.$key.count -gt 1){
            $fileht.$key | foreach-object -ThrottleLimit 10 -parallel{
                $_ | Add-Member -MemberType NoteProperty -Name "Hash" -Value "Unknown" 
		$fhl = $using:filehashlist
                $filehash = get-filehash -Path $_.fullname -Algorithm MD5
                write-host "Processed: $($_.fullname) Hash: $($filehash.Hash)" -ForegroundColor Blue
		if($filehash.length -ne 0){
                     $_.Hash = $filehash.Hash 
                     $fhl.Push($_)
		}
            }
        }
        else{
            write-host $fileht.$key.fullname "is not duplicated" -ForegroundColor Green
        }
    }

    $hashesList = $fileHashList.GetEnumerator() | Group-Object -Property Hash -AsHashTable
    
    $duplicatesList = $hashesList.GetEnumerator() | where-object{($_.value).count -gt 1}
    
    $outputList = @()
    foreach($group in $duplicatesList){
        foreach($item in $group.value){
            $outputList += $item | select fullname, hash, lastWriteTime, lastaccesstime, Length
        }
    }
    write-host $OutputList.count -ForegroundColor Yellow -NoNewline
    write-host " Duplicates Found" -ForegroundColor Green
    $outputList | Out-GridView

    if($outpath){
        $outputList | export-csv -path $outpath
    }

    return $filehashlist.getenumerator()
}
