param (
    [Parameter(Mandatory=$true)]
    [string]$vmName
)

$networkAdapters = Get-VMNetworkAdapter -VMName $vmName

if ($networkAdapters.Count -eq 0) {
    Write-Output "No network adapters found for VM '$vmName'."
    exit
}

Write-Output "Network Adapters for VM '$vmName':"
for ($i = 0; $i -lt $networkAdapters.Count; $i++) {
    $adapter = $networkAdapters[$i]
    $switchName = (Get-VMSwitch -Id $adapter.SwitchId).Name
    Write-Output "$($i + 1). $($adapter.Name) - Switch: $switchName"
}

$selectionInput = Read-Host "Enter the numbers of the network adapters to remove (comma-separated)"

if ($selectionInput) {

    $selectedNumbers = $selectionInput -split ",\s*"

    foreach ($number in $selectedNumbers) {
        $index = [int]$number - 1

        if ($index -ge 0 -and $index -lt $networkAdapters.Count) {
            
            $adapter = $networkAdapters[$index]

            Remove-VMNetworkAdapter -VMNetworkAdapter $adapter
            Write-Output "Removed Network Adapter: $($adapter.Name) from $vmName"
        } else {
            Write-Warning "Invalid selection number '$number'."
        }
    }
} else {
    Write-Error "No selection numbers provided for removal."
}
