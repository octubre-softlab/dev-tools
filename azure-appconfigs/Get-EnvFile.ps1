function ConvertTo-Env {
    [CmdletBinding(RemotingCapability='None')]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [hashtable] ${InputObject}
    )
    process
    {
        $sb = [System.Text.StringBuilder]::new()
        $InputObject.Keys | ForEach-Object {
            $key = $_.Replace(":","__")
            $value = $InputObject[$_].Replace("`n","\n")
            [void]$sb.AppendLine("${key}=`"${value}`"")
        }
        return $sb.ToString()
    }
}


$AppConfigStoreName = $args[0]
If(-Not $AppConfigStoreName) {
    $AppConfigStoreName = Read-host "Ingrese el Azure App Configuration Store name"
}


# az login

az configure --defaults appconfig_auth_mode="login"

Write-Output "Cargando..."

$keyvalues = az appconfig kv list -n $AppConfigStoreName --fields key label --all | ConvertFrom-Json

# Seleccionar app

$apps = @($keyvalues | ForEach-Object { 
                        ($_.key -Split ":")[0] 
                    } | Select-Object -Unique)

Write-Output ""
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

Write-Output "Aplicación seleccionada: "
Write-Host "$selectedApp" -ForegroundColor Green

If($selectedApp -Eq "webapi") {

    # Seleccionar tenant
    Write-Output ""
    Write-Output "Tenants:"
    $tenants = @($keyvalues | Where-Object { $_.key -Like "${selectedApp}:*" }
                          | ForEach-Object {  ($_.key -Split ":")[1] } 
                          | Select-Object -Unique)

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

    Write-Output "Tenant seleccionado:"
    Write-Host "$selectedApp $selectedTenant" -ForegroundColor Green


    $selectedApp = "${selectedApp}:${selectedTenant}"
}

# Seleccionar environment

Write-Output ""
Write-Output "Ambientes:"

$environments = @($keyvalues | Where-Object { $_.key -Like "${selectedApp}:*" }
                          | ForEach-Object { $_.label } 
                          | Select-Object -Unique)

$environments | ForEach-Object {
    $index = $environments.IndexOf($_)
    $envName = (Get-Culture).TextInfo.ToTitleCase($_)
    $optionNumber = $index + 1
    Write-Output "$optionNumber. $envName"
}


do {
    try {
        $numOk = $true
        [int]$chosenNumber = Read-host "Seleccione un ambiente"
    } # end try
    catch {
        $numOK = $false
    }
} # end do 
until (($chosenNumber -ge 1 -and $chosenNumber -le $environments.Count) -and $numOK)

$selectedEnv = $environments[$chosenNumber - 1]

Write-Output "Environment seleccionado:"
Write-Host "$selectedApp $selectedEnv" -ForegroundColor Green

Write-Output ""
Write-Output "Cargando secrets y configs..."

$tenantKeyvalues = az appconfig kv list `
                        --name $AppConfigStoreName `
                        --key "${selectedApp}:*" `
                        --label "$selectedEnv",\0 `
                        --resolve-keyvault `
                        --all
                    | ConvertFrom-Json

$result = @{}

If($selectedApp -Like "webapi:*") { 
    $commonTenantKeyvalues = az appconfig kv list `
                        --name $AppConfigStoreName `
                        --key "webapi:Common:*" `
                        --label "$selectedEnv",\0 `
                        --resolve-keyvault `
                        --all
                    | ConvertFrom-Json

    $commonTenantKeyvalues | Sort-Object -Property Label | ForEach-Object {
        $entryName = $_.Key.Replace("webapi:Common:","")
        $result[$entryName] = $_.Value
    }
}

$tenantKeyvalues | Sort-Object -Property Label | ForEach-Object {
    $entryName = $_.Key.Replace("${selectedApp}:","")
    $result[$entryName] = $_.Value
}

$json = $result | ConvertTo-Json

$envFile = $result | ConvertTo-Env


Write-Output ""
Write-Host "JSON File" -ForegroundColor Green
Write-Output $json

Write-Output ""
Write-Host "Env File" -ForegroundColor Green
Write-Output $envFile