Function Check-InstalledSoftware
{
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$filter,
		[string]$outfile,
		[string]$program,
		[switch]$chrome,
		[switch]$firefox,
		[switch]$AdobeReader,
		[switch]$java,
		[switch]$VmwareWorkstation,
		[switch]$windowsVersion, #intended for when I need to query the version of windows 10 on the machine
		[string]$computerName	
	)
	
	$computerTable = [System.Collections.Concurrent.ConcurrentStack[object]]::new()
	$computerTable.clear()
	
	if($chrome){$program = "chrome"}
	elseif($firefox){$program = "firefox"}
	elseif($AdobeReader){$program = "Acrobat"}
	elseif($java){$program = "java"}
	elseif($VmwareWorkstation){$program = "workstation"}	
	
	elseif($filter)
	{
		$computerList = get-adcomputer -filter * | where-object -property name -like $filter
		$computerList | foreach-object -throttlelimit 15 -parallel{
			$computerName = $psitem.name
			write-host "Starting " $computerName
			if(test-connection -computerName $computerName -count 1 -quiet)
			{
				try
				{
					$localTable = $using:computerTable
					$computerInfo = (invoke-command -computerName $computerName -scriptBlock{
						param($computerName, $program)
						$keyList = Get-ChildItem -Path HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall -Recurse | 
							Get-ItemProperty | 
							Where-Object{$_.DisplayName -match "$($program)"} |
							Select-Object @{Name = 'ComputerName'; Expression = {$using:computerName}}, DisplayName, DisplayVersion, Comments, UninstallString     
							return $keyList
					} -argumentList $using:computerName, $using:Program) | select * -ExcludeProperty runspaceID, PSComputerName
				
					foreach ($key in $computerInfo)
					{
						$localTable.Push($key) | out-null
					}
				}
				catch [System.Exception]
				{
					$err = $computerName + " " + $_
					$err
					add-content -path 'C:\Users\Stephen.Quinlan.WA\Desktop\failurelist.txt' -Value $err
				}
			}
			else
			{
				$err = $computerName + " Ping failed" 
				add-content -path 'C:\Users\Stephen.Quinlan.WA\Desktop\failurelist.txt' -Value $err
			}
		}
	}
	write-host $computerTable.count "machines in this scope have $program installed" -foregroundColor Yellow
	<#$computerTable.keys | Select-Object * -exclude RunspaceID, PSShowComputerName, PSComputerName  | Sort-Object computerName | format-table
	
	if($outfile){
		$computerTable.keys | Select-Object * -exclude RunspaceID, PSShowComputerName, PSComputerName | Sort-Object computerName | export-csv -Path $outfile -Append -notypeinformation
	}
	write-host $computerTable.count "machines in this scope have $program installed" -foregroundColor Yellow#>
	return $computerTable
}