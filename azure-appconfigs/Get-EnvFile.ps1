function ConvertTo-PortainerEnv {
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
            $value = $InputObject[$_].Replace("`n","\n").Replace("$","$$").Replace("%","%%")
            [void]$sb.AppendLine("${key}=`"${value}`"")
        }
        return $sb.ToString()
    }
}

function Get-Selected {
    [CmdletBinding(RemotingCapability='None')]
    param(
        [Parameter(Mandatory)]
        [Object[]]${InputList},
        [String]${Message}
    )
    begin
    {
        $InputList | ForEach-Object {
            $index = $InputList.IndexOf($_)
            $appName = (Get-Culture).TextInfo.ToTitleCase($_)
            $optionNumber = $index + 1
            Write-Host "$optionNumber. $appName"
        }
        
        
        do {
            try {
                $numOk = $true
                [int]$chosenNumber = Read-host ${Message}
            } # end try
            catch {
               $numOK = $false
            }
        } # end do 
        until (($chosenNumber -ge 1 -and $chosenNumber -le $InputList.Count) -and $numOK)

        $selected = $InputList[$chosenNumber - 1]

        return $selected
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

$selectedApp = Get-Selected $apps "Seleccione una aplicación"

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

    $selectedTenant = Get-Selected $tenants "Seleccione un tenant"

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

$selectedEnv = Get-Selected $environments "Seleccione un ambiente"

Write-Output "Ambiente seleccionado:"
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

$envFile = $result | ConvertTo-PortainerEnv


Write-Output ""
Write-Host "JSON File" -ForegroundColor Green
Write-Output $json

Write-Output ""
Write-Host "Portainer Env File" -ForegroundColor Green
Write-Output $envFile
