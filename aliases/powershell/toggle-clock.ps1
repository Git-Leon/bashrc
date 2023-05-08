$currentDate = Get-Date
$hoursToAdd = if ($currentDate.ToString("tt") -eq "AM") { 12 } else { -12 }
$timeSpan = New-TimeSpan -Hours $hoursToAdd
Set-Date -Adjust $timeSpan
