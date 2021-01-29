$f1 = $args[0]
$f2 = $args[1]
$f3 = $args[2]

#$f1 = "master1.csv"
#$f2 = "master2.csv"
#$f3 = "diff.csv"

if($args.Length -ne 3) {
    Write-Host "Usage: ",$PSCommandPath," <early_file.csv> <later_file.csv> <output_file.csv>"
    exit
}

$data1 = @{}
$data2 = @{}

$csvfile = Import-Csv -Path $f1
$data1=@{}
foreach($r in $csvfile)
{
    $data1[$r.Groups] = $r.ExistingUsers
}

$csvfile = Import-Csv -Path $f2
$data2=@{}
foreach($r in $csvfile)
{
    $data2[$r.Groups] = $r.ExistingUsers
}

$changes = @{}

# find differences
$allkeys = $data2.Keys + $data1.Keys
$allkeys = $allkeys | select -Unique

foreach($g in $allkeys) {
    $d1 = $data1[$g].Split(",") | sort
    $d1 = $d1 -join ","
    
    $d2 = $data2[$g].Split(",") | sort
    $d2 = $d2 -join ","

    if($d1 -ne $d2) {
        $changes[$g] = @{"UsersTobeAdded"=[System.Collections.ArrayList]@(); "UsersTobeRemoved"=[System.Collections.ArrayList]@()}
    }
}

foreach($g in $changes.Keys) {
    # find users to add
    foreach($u in $data2[$g].Split(",")) {
        if($data1[$g].Split(",").Contains($u)) {
        } else {
            $changes[$g]["UsersTobeAdded"] += $u
        }
    }
    
    # find users to remove
    foreach($u in $data1[$g].Split(",")) {
        if($data2[$g].Split(",").Contains($u)) {
        } else {
            $changes[$g]["UsersTobeRemoved"] += $u
        }
    }
}

$groups = $changes.Keys | sort
$output = @()

foreach($g in $groups) {
    $output += [PSCustomObject][Ordered]@{
        Groups = $g
        UsersTobeAdded = $changes[$g]["UsersTobeAdded"] -join ","
        UsersTobeRemoved = $changes[$g]["UsersTobeRemoved"] -join ","
    }
}

if (Test-Path $f3) {
  Remove-Item $f3
}

$output | Export-Csv -NoTypeInformation $f3
