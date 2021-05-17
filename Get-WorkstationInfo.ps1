function Get-WorkstationInfo
{
    param
    (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)] [Object[]] $ComputerList,
		[System.Management.Automation.PSCredential] $credential
    )
	begin
	{
		$computerInfo = @()
		$computerTable = @()
	}
    
	process
	{
		$computerName = $psitem.name
		Write-Progress -Activity "Getting information from: $computerName" -Status "Testing Connection" 
		if(Test-Connection -ComputerName $psitem.name -Quiet -Count 1)
        {
			Write-Progress -Activity "Getting information from: $computerName" -Status "Test Succeeded, Creating CIM Session" 
			
			if($credential)
			{
				$cimSession = New-CimSession -ComputerName $psitem.name -Credential $credential
			}
			
			else
			{
				$cimSession = New-CimSession -ComputerName $psitem.name
			}
			Write-Progress -Activity "Getting information from: $computerName" -Status "CIM Session Created.  Getting Information"
			$computerInfo = get-ciminstance -ClassName win32_bios -CimSession $cimSession
            $computerInfo | Add-Member -MemberType NoteProperty -Name ComputerName -Value $psitem.name
            $computerTable += $computerInfo        
        }
        else
        {
			Write-Progress -Activity "Getting information from: $computerName" -Status "Unable to Connect"
            Write-Host $psitem.name "Not Available"
        }		
		
		 
        #$serialNumber = (Get-CimInstance -Class win32_bios -ComputerName $computer.name -Credential $credential).serialNumber
		#$ModelInfo = (Get-CimInstance -Class win32_computerSystem -property Username -ComputerName $computer.name -Credential $credential).Model	
	}
	end
	{
		return $ComputerTable
	}
}