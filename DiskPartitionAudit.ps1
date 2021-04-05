param(
    [Parameter(Mandatory=$true)]
    [string]$Target,
    [Parameter(Mandatory=$false)]
    [boolean]$DisplayResults = $true,
    [Parameter(Mandatory=$true)]
    [boolean]$ExportToCsv,
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = $pwd
)

$Result = New-Object System.Collections.Generic.List[System.Object]
$LineBreak = "------------------------------------------------"
$DeviceOfflineMsg = "Offline"
$PSSessionErrorMsg = "Error Establishing PSSession"
$QueryErrorMsg = "Error Querying Device"

Clear-Host

$LogPath = ("$pwd\Logs\")
If(!(test-path $LogPath)){
    New-Item -ItemType Directory -Force -Path $LogPath > $null
    Write-Host "[Info] Created directory $LogPath" -ForegroundColor Gray
}

$CurrentDate = (Get-Date).ToString('MM-dd-yyyy hh-mm-ss tt')

Start-Transcript -Path ($LogPath + "$CurrentDate.txt") > $null


<#
====================================================================================================
                                        Get Devices
====================================================================================================
#>
try{
    Write-Host "[Info] Fetching devices from $Target... " -ForegroundColor Gray -NoNewline
    $Devices = @()
    
    if (Test-Path $Target -PathType Leaf){
        if ([System.IO.Path]::GetExtension($Target) -eq ".txt"){ 
            $Devices += Get-Content $Target -ErrorAction Stop
            $NumDevices = $Devices.Count
            Write-Host "Success" -ForegroundColor Green
        }else{
            Write-Host "`nOnly text files are supported." -ForegroundColor Red
            Exit
        }
    }else{
        Write-Host "`nThe file '$Target' does not exist." -ForegroundColor Red
        Exit
    }
}catch{
    Write-Host "`nAn error occurred." -ForegroundColor Red
    Write-Host $Error[0] -ForegroundColor Red
    Exit
}

Write-Host "[Info] Running on " -ForegroundColor Gray -NoNewline
Write-Host $NumDevices -ForegroundColor Cyan -NoNewline
if($NumDevices -eq 1){
    Write-Host " device." -ForegroundColor Gray
}else{
    Write-Host " devices." -ForegroundColor Gray
}

<#
====================================================================================================
                                   Compile Disk Information
====================================================================================================
#>
$Count = 1
foreach($Device in $Devices){
    Write-Host $LineBreak
    Write-Host "Running on $Device ($Count of $NumDevices)"

    Write-Host "`tChecking device status... " -NoNewline
    if(Test-Connection -ComputerName $Device -Count 1 -Quiet){
        Write-Host "Online" -ForegroundColor Green
    }else{
        Write-Host "Offline" -ForegroundColor Red
        $Result.Add(
            [PSCustomObject]@{
                "Computer Name"    = $Device
                "BIOS"             = $DeviceOfflineMsg
                "Operating System" = $DeviceOfflineMsg
                "Version"          = $DeviceOfflineMsg
                "Disk Number"      = $DeviceOfflineMsg
                "Size (GB)"        = $DeviceOfflineMsg
                "Partition Type"   = $DeviceOfflineMsg
            }
        )
        Continue
    }

    Write-Host "`tEstablishing remote connection... " -NoNewline
    try{
        $Session = New-PSSession $Device -ErrorAction Stop
        Write-Host "Success" -ForegroundColor Green
    }catch{
        Write-Host "Failed" -ForegroundColor Red
        $Result.Add(
            [PSCustomObject]@{
                "Computer Name"    = $Device
                "BIOS"             = $PSSessionErrorMsg
                "Operating System" = $PSSessionErrorMsg
                "Version"          = $PSSessionErrorMsg
                "Disk Number"      = $PSSessionErrorMsg
                "Size (GB)"        = $PSSessionErrorMsg
                "Partition Type"   = $PSSessionErrorMsg
            }
        )
        Continue
    }

    Write-Host "`tCompiling device information... " -NoNewline
    try{
        $Cmd = Invoke-Command -Session $Session -ScriptBlock{
            Get-Disk | Foreach-Object{
                [PSCustomObject]@{
                    "Computer Name"    = $env:COMPUTERNAME
                    "BIOS"             = if (Test-Path HKLM:\System\CurrentControlSet\control\SecureBoot\State) {"UEFI"} else {"Legacy"}
                    "Operating System" = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
                    "Version"          = [Environment]::OSVersion | Select-Object -ExpandProperty Version
                    "Disk Number"      = $_.number
                    "Size (GB)"        = [int]($_.size/1GB)
                    "Partition Type"   = $_.PartitionStyle
                }
            }
        
        } -ErrorAction Stop
        $Result.AddRange($Cmd)
        Write-Host "Success" -ForegroundColor Green
    }catch{
        Write-Host "Failed" -ForegroundColor Red
        $Result.Add(
            [PSCustomObject]@{
                "Computer Name"    = $Device
                "BIOS"             = $QueryErrorMsg
                "Operating System" = $QueryErrorMsg
                "Version"          = $QueryErrorMsg
                "Disk Number"      = $QueryErrorMsg
                "Size (GB)"        = $QueryErrorMsg
                "Partition Type"   = $QueryErrorMsg
            }
        )
        Continue
    }finally{
        Remove-PSSession $Session
        Write-Host "`tConnection terminated." -ForegroundColor Yellow
    }
    $Count++
}

Write-Host $LineBreak
Write-Host "Complete" -ForegroundColor Green
Write-Host ""

<#
====================================================================================================
                                     Display/Save Results
====================================================================================================
#>
$Result = $Result | Select * -ExcludeProperty RunspaceId,PSComputerName,PSShowComputerName
if($DisplayResults){
    $Result | ft -a
}

if($ExportToCsv){
    $File = $OutputDirectory + "\DiskPartitionAudit $CurrentDate.csv"
    try{
        $Result | Export-Csv -Path $File -NoTypeInformation -ErrorAction Stop
        Write-Host "Report saved to '$File'"
    }catch{
        Write-Host "An error occurred while saving the file '$File'" -ForegroundColor Red
        Write-Host $Error[0] -ForegroundColor Red
    }
}
Stop-Transcript > $null
