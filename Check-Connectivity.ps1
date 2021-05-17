function Check-Connectivity
{
	param
	(
		[switch]$daily,
		[string]$filter,
	 	[Object[]]$List,
		[ValidateSet("Online", "Offline", "All", "NoDNS")]
		[String]$filterResults
	)
	if($daily)
	{
		$computers = get-adcomputer -properties name -filter {OperatingSystem -notlike '*server*'} -searchbase "OU=ITTN,DC=ITTN,DC=Navy" 
	}
	elseif($filter)
	{
		$computers = get-adcomputer -properties name -filter * | where-object -property name -like $filter
	}
	elseif($computerList){
		$computers = $computerList | select-object @{Name="Name";Expression={$_.computer}}
	}

	$threadSafeStack = [System.Collections.Concurrent.ConcurrentStack[object]]::new()
    $threadSafeStack.clear()
    $count = $computers.count
		
    $computers | foreach-object -ThrottleLimit 20 -parallel{
	    $stack = $using:threadSafeStack
		try
		{
			$connectivityStatus = (Test-Connection -ComputerName $psitem.name -count 1 -BufferSize 8 -quiet -ErrorAction Stop)
			if(!$connectivityStatus)
			{
				$connectivityStatus = (Test-Connection -ComputerName $psitem.name -count 2 -BufferSize 8 -quiet -ErrorAction Stop)
            }
		}
		catch [System.Management.Automation.ActionPreferenceStopException] 
		{		
			$connectivityStatus = "NoDNS"
        }
		$record = new-object -TypeName psobject -Property @{
			Name = $psitem.name 
			Status = $connectivityStatus
		}
        $stack.Push($record)
		$percentComplete = [Math]::round(100*($stack.count/$using:count),0)
		write-host $percentComplete $psitem.name
	}

	if($filterResults -eq "Offline")
	{
		return $threadSafeStack | Where-Object {$_.status -like '*false*'}
	}
	elseif($filterResults -eq "Online")
	{
		return $threadSafeStack | Where-Object {$_.status -like '*true*'}
	}
	elseif($filterResults -eq "NoDNS")
	{
		return $threadSafeStack | Where-Object {$_.status -like '*noDNS*'}
	}
	elseif($filterResults -eq "All")
	{
		return $threadSafeStack
	}
}