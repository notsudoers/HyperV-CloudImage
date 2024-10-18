param (
    [Parameter(Mandatory=$true)]
    [string]$vmName
)

$basePath = "E:\Hyper-V\Instances\Disks\"

function Get-BlockDeviceName {
    param (
        [string]$vhdPath
    )
    return [System.IO.Path]::GetFileNameWithoutExtension($vhdPath) -replace "^$vmName`_", ""
}

$attachedDisks = Get-VM -Name $vmName | Get-VMHardDiskDrive

$attachedDiskPaths = @()
foreach ($disk in $attachedDisks) {
    $vhdPath = $disk.Path
    $blockDeviceName = Get-BlockDeviceName -vhdPath $vhdPath
    $attachedDiskPaths += [PSCustomObject]@{
        BlockDeviceName = $blockDeviceName
        VhdPath = $vhdPath
        ControllerType = $disk.ControllerType
        ControllerNumber = $disk.ControllerNumber
        ControllerLocation = $disk.ControllerLocation
    }
}

Write-Output "Available VHDs:"
$attachedDiskPaths | Format-Table -Property BlockDeviceName, VhdPath

$selectedDrives = $null
while ($selectedDrives -eq $null -or $selectedDrives.Count -eq 0) {
    $input = Read-Host -Prompt "Enter the block device names to delete (comma-separated, e.g., 'sdb,sdc')"
    $selectedDrives = $input -split ',' | ForEach-Object { $_.Trim() }

    if ($selectedDrives.Count -eq 0) {
        Write-Warning "No block device names provided. Please enter at least one block device name."
    } elseif ($selectedDrives | Where-Object { $_ -notin $attachedDiskPaths.BlockDeviceName }) {
        Write-Warning "One or more of the specified block device names are invalid. Please check and try again."
        $selectedDrives = $null
    }
}

foreach ($driveName in $selectedDrives) {
    $diskToRemove = $attachedDiskPaths | Where-Object { $_.BlockDeviceName -eq $driveName }

    if ($diskToRemove) {
        Remove-VMHardDiskDrive -VMName $vmName -ControllerType $diskToRemove.ControllerType -ControllerNumber $diskToRemove.ControllerNumber -ControllerLocation $diskToRemove.ControllerLocation
        Write-Output "$driveName has been removed from the VM."
 
        Remove-Item -Path $diskToRemove.VhdPath -Force
        Write-Output "$driveName has been deleted."
    } else {
        Write-Warning "No VHD found for block device name $driveName."
    }
}
