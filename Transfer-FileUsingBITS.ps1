function Transfer-FileUsingBits
{
    param(
	[switch]$easy,
        [String]$sourceFile,
        [String]$destinationDirectory,
        [securestring]$credential
    )
    if($easy)
    {
    	add-type -AssemblyName System.Windows.Forms
	$sourceFileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
	$null = $sourceFileBrowser.showdialog()
	$sourceFile = $sourceFileBrowser.FileName

	$destinationFolderBrowser = new-object System.Windows.Forms.FolderBrowserDialog 
	$null = $destinationFolderBrowser.showDialog()
	$destinationDirectory = $destinationFolderBrowser.selectedPath
    }

    if(test-path $sourceFile)
    {
        if(Test-Path $destinationDirectory)
	{
             $transferJob = Start-BitsTransfer -Source $sourceFile -Destination $destinationDirectory -Asynchronous -RetryInterval 60 -Priority HIGH
        }
        else
	{
            Write-Host "Could not find/reach destination directory."
        }
    }
    else
    {
        write-host "Could not find source file." -ForegroundColor Red
    }
    while((Get-bitsTransfer).jobState -ne "Transferred")
    {
        $transferJobStatus = Get-bitsTransfer -name $transferJob.Name
        $MBytesTransferred = ($transferJob.bytesTransfered / 1MB)
        $MBBytesTotal = ($transferJob.bytesTotal / 1MB) + 1MB
        $currentOperation = $transferJob.jobState + " :" + $MBytesTransferred + " of " + $MBBytesTotal + " Transferred."
        #$percentComplete = 100 * ($MBBytesTransferred / $MBytesTotal)
        Write-Progress -Activity "Transferring File" -currentOperation $currentOperation #-percentComplete $percentComplete
    }

    if((Get-bitsTransfer).jobState -eq "Transferred")
    {
        powershell.exe "Get-bitsTransfer | complete-bitsTransfer"
    }
    write-host "Transfer Completed" -ForegroundColor Green
}
