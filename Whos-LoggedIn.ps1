function Whos-LoggedIn
{
	param
    (
		[String]$filter,
	  	[String]$search,
	  	[Switch]$unused,
	  	[Switch]$moreInfo
	)
	
	$computers = get-adcomputer -filter * | where-object -property name -like $filter
	write-host $computers.count "computers to check"
	#create concurrent stack allowing parallel execution of code later.
	$computerList = [System.Collections.Concurrent.ConcurrentStack[object]]::new()

	$hashFilter = @{
        LogName = 'Security'
        StartTime = (Get-Date).addDays(-30)
        ID = 4800, 4801, 4647
    }
	
	$computers | ForEach-Object -throttlelimit 20  -parallel{
		$compList = $using:computerList
		$computerName = $psitem.name
		$classroom = $computerName.substring(5, 4)
		$hashFilter = $using:hashFilter
		Add-Member -InputObject $psitem -NotePropertyName 'Classroom' -NotePropertyValue $classroom -Force
		
		if(test-connection -computername $computername -BufferSize 16 -Quiet -Count 1)
		{
			try
			{
				$LoggedInUser = (Get-CimInstance -ClassName win32_computersystem -Property username -ComputerName $computername -ErrorAction stop -OperationTimeoutSec 10).username
				if ($null -eq $LoggedInUser)
				{
					Add-Member -InputObject $psitem -NotePropertyName 'LoggedInUser' -NotePropertyValue "NONE" -Force
				}
				else
				{
					Add-Member -InputObject $psitem -NotePropertyName 'LoggedInUser' -NotePropertyValue $LoggedInUser -Force
				}
				
				$info = Get-WinEvent -ComputerName $computerName -FilterHashtable $hashFilter | select -first 1

				if($info.id -eq '4800'){
					$status = "Locked"
				}
				elseif($info.id -eq '4801'){
					$status = "Unlocked"
				}
				elseif($info.id -eq '4647'){
					$status = "Logged Off"
				}
				add-member -InputObject $psitem -NotePropertyName 'LockStatus' -NotePropertyValue $status
				add-member -InputObject $psitem -NotePropertyName 'EventTime' -NotePropertyValue $info.timeCreated
				add-member -InputObject $psitem -NotePropertyName 'Remarks' -NotePropertyValue null
				if($psitem.loggedinuser -eq "None" -and $psitem.LockStatus -eq "locked"){
					$info = get-winevent -ComputerName $psitem.name -LogName System  | where-object {$_.id -eq '41' -or $_.id -eq '1074' -or $_.id -eq '6006' -or $_.id -eq '6008'} | select -first 1
					
					if($info.id -eq '41'){
						$psitem.Remarks = $info.id + " Critical Power Off"
					}
					else{
						$psitem.Remarks = "$($info.id) $($info.timecreated)"
					}					
				}

			}
			catch [System.Exception]
			{
				$_.Exception | out-null
				Add-Member -InputObject $psitem -NotePropertyName 'LoggedInUser' -NotePropertyValue "ERROR" -Force
			}
		}
		else
		{
			$psitem | Add-Member -NotePropertyName 'LoggedInUser' -NotePropertyValue "NOT CONNECT" -Force
		}
		
		write-host $computerName
		$compList.push($psitem) | out-null
	}	
	if($search)
	{
		$computerList | select-object Classroom, Name, LoggedInUser | where-object {$_.LoggedInUser -like $search}
	}
	elseif($unused)
	{
		$computerList | select-object 
	}
	else
	{
		$computerList | select-object Classroom, Name, LoggedInUser, lockstatus, EventTime | Sort-Object Name 
	}
}
