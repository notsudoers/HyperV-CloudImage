param (
    [Parameter(Mandatory=$true)]
    [string]$vmName,

    [Parameter(Mandatory=$true)]
    [string]$size,

    [Parameter(Mandatory=$true)]
    [int]$drive
)

$basePath = "E:\Hyper-V\Instances\Disks\"

function Convert-SizeToBytes {
    param (
        [string]$size
    )

    $size = $size.ToUpper()
    $sizeValue = [regex]::Match($size, '\d+').Value
    $sizeUnit = $size -replace '\d+', ''

    switch ($sizeUnit) {
        'G' { return [long]$sizeValue * 1GB }
        'M' { return [long]$sizeValue * 1MB }
        'K' { return [long]$sizeValue * 1KB }
        default { throw "Invalid size unit. Use 'G' for GB, 'M' for MB, or 'K' for KB." }
    }
}

try {
    $vhdSize = Convert-SizeToBytes -size $size
} catch {
    Write-Error "Invalid size value. Please specify a valid size (e.g., '10G')."
    exit
}

if ($drive -lt 1 -or $drive -gt 26) {
    Write-Error "The drive number $drive is out of valid range. Please specify a number between 1 and 26."
    exit
}

$existingDisks = Get-VM -Name $vmName | Get-VMHardDiskDrive
$existingBlockDeviceNames = $existingDisks | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Path) -replace "^$vmName`_", "" }

$createdDrives = 0
$letter = 98

while ($createdDrives -lt $drive -and $letter -le 122) {  
    $driveLetter = [char]$letter
    $blockDeviceName = "sd$driveLetter"
    $vhdPath = Join-Path -Path $basePath -ChildPath "$vmName`_$blockDeviceName.vhdx"

    if (-not ($existingBlockDeviceNames -match $blockDeviceName)) {
        
        New-VHD -Dynamic -SizeBytes $vhdSize -Path $vhdPath
        
        Write-Output "Created VHD: $vhdPath"
        
        Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath
        
        Write-Output "Added New VHD to $vmName"
        
        $createdDrives++
    }
    
    $letter++
}

if ($createdDrives -lt $drive) {
    Write-Output "Not enough available drive letters to create all requested VHDs."
}
