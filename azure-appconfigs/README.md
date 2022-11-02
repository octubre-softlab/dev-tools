Este script sirve para obtener secret.json o .env files a partir

1. Descargar script

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object -TypeName System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/octubre-softlab/dev-tools/main/azure-appconfigs/Get-EnvFile.ps1", "$PWD/Get-EnvFile.ps1")
```

2. Hacer login en azure: `az login`

3. Ejecutar script `./Get-EnvFile.ps1 appcs-aaa-prd-ue`

```
.\Get-EnvFile.ps1
Cargando...

Aplicaciones:
1. Hola
2. Webapi
Seleccione una aplicación: 2
Aplicación seleccionada: 
webapi

Tenants:
1. Arrabaleros
2. ElTrineo
3. FATERYH
4. GUAU
5. ISSA
6. MEPADIP
7. OctubreOSPERYH
8. OctubreOSPERYHRA2
9. OctubreOSPERYHRA
10. SERACARH
11. SIGA
12. SUTERH
Seleccione un tenant: 1
Tenant seleccionado:
webapi Arrabaleros

Ambientes:
1. Production
2. Test
Seleccione un ambiente: 2
Environment seleccionado:
webapi:Arrabaleros Test

Cargando secrets y configs...
```