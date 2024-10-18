param (
    [Parameter(Mandatory=$true)]
    [string]$vmName,

    [Parameter(Mandatory=$true)]
    [int]$additionalAdapters
)

$switches = Get-VMSwitch

if ($switches.Count -eq 0) {
    Write-Error "No virtual switches found. Please create a virtual switch before running this script."
    exit
}

Write-Output "Available Virtual Switches:"
for ($i = 0; $i -lt $switches.Count; $i++) {
    Write-Output "$($i + 1). $($switches[$i].Name)"
}

if ($additionalAdapters -ge 1) {
    for ($i = 1; $i -le $additionalAdapters; $i++) {
        $selectedSwitchIndex = Read-Host "Enter the number of the virtual switch to use for adapter $i"
        $index = [int]$selectedSwitchIndex - 1

        if ($index -ge 0 -and $index -lt $switches.Count) {
            $switchName = $switches[$index].Name

            $baseName = "Network Adapter eth"
            $adapterExists = $true
            $counter = 0

            while ($adapterExists) {
                $adapterName = "$baseName$counter"
                $adapterExists = Get-VMNetworkAdapter -VMName $vmName | Where-Object { $_.Name -eq $adapterName }
                if ($adapterExists) {
                    $counter++
                } else {
                    $adapterExists = $false
                }
            }

            Add-VMNetworkAdapter -VMName $vmName -Name $adapterName -SwitchName $switchName
            Write-Output "Added Network Adapter: $adapterName to $vmName on switch $switchName"
        } else {
            Write-Error "Invalid switch selection for adapter $i. Exiting script."
            exit
        }
    }
}
