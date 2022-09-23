# az login

az configure --defaults appconfig_auth_mode="login"

Write-Output "Cargando..."

$keyvalues = az appconfig kv list -n "appcs-sharedconf-prd-ue" --fields key label --all | ConvertFrom-Json

# Seleccionar app

$apps = $keyvalues | ForEach-Object { 
                        ($_.key -Split ":")[0] 
                    } | Select-Object -Unique

Write-Output "Aplicaciones:"

$apps | ForEach-Object {
    $index = $apps.IndexOf($_)
    $appName = (Get-Culture).TextInfo.ToTitleCase($_)
    $optionNumber = $index + 1
    Write-Output "$optionNumber. $appName"
}


do {
    try {
        $numOk = $true
        [int]$chosenNumber = Read-host "Seleccione una aplicación"
    } # end try
    catch {
       $numOK = $false
    }
} # end do 
until (($chosenNumber -ge 1 -and $chosenNumber -le $apps.Count) -and $numOK)

$selectedApp = $apps[$chosenNumber - 1];

Write-Output "Aplicación seleccionada: $selectedApp"

If($selectedApp -Eq "webapi") {

    # Seleccionar tenant
    Write-Output "Tenants:"
    $tenants = $keyvalues | Where-Object { $_.key -Like "${selectedApp}:*" }
                          | ForEach-Object {  ($_.key -Split ":")[1] } 
                          | Select-Object -Unique

    $tenants = $tenants | Where-Object { $_ -inotmatch "@" -And $_ -Ne "Common" }

    $tenants | ForEach-Object {
        $index = $tenants.IndexOf($_)
        $tenantName = $_
        $optionNumber = $index + 1
        Write-Output "$optionNumber. $tenantName"
    }

    do {
        try {
            $numOk = $true
            [int]$chosenNumber = Read-host "Seleccione un tenant"
        } # end try
        catch {
           $numOK = $false
        }
    } # end do 
    until (($chosenNumber -ge 1 -and $chosenNumber -le $tenants.Count) -and $numOK)

    $selectedTenant = $tenants[$chosenNumber - 1];

    Write-Output "Tenant seleccionado: $selectedApp $selectedTenant"

    $selectedApp = "${selectedApp}:${selectedTenant}"
}

# Seleccionar environment

$environments = $keyvalues | Where-Object { $_.key -Like "${selectedApp}:*" }
                          | ForEach-Object { $_.label } 
                          | Select-Object -Unique

$environments | ForEach-Object {
    $index = $environments.IndexOf($_)
    $envName = (Get-Culture).TextInfo.ToTitleCase($_)
    $optionNumber = $index + 1
    Write-Output "$optionNumber. $envName"
}


do {
    try {
        $numOk = $true
        [int]$chosenNumber = Read-host "Seleccione un environment"
    } # end try
    catch {
        $numOK = $false
    }
} # end do 
until (($chosenNumber -ge 1 -and $chosenNumber -le $environments.Count) -and $numOK)

$selectedEnv = $environments[$chosenNumber - 1]

Write-Output "Environment seleccionado: $selectedApp $selectedEnv"

Write-Output "Cargando secrets y configs..."

$tenantKeyvalues = az appconfig kv list `
                        --name "appcs-sharedconf-prd-ue" `
                        --key "${selectedApp}:*" `
                        --label "$selectedEnv",\0 `
                        --resolve-keyvault `
                        --all
                    | ConvertFrom-Json

$result = @{}

$tenantKeyvalues | ForEach-Object {
    $entryName = $_.Key.Replace("${selectedApp}:","")
    $result[$entryName] = $_.Value
}

$json = $result | ConvertTo-Json

Write-Output $json