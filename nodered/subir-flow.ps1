# Envia os flows de exemplo para o Node-RED da VM.
#
#   powershell -ExecutionPolicy Bypass -File .\subir-flow.ps1
#   powershell -ExecutionPolicy Bypass -File .\subir-flow.ps1 -Arquivo .\flow-mqtt.json
#
# Cada arquivo vira uma ABA NOVA no Node-RED (nao apaga os flows existentes).
# A VM precisa estar ligada e a regra de NAT "nodered" (1880 -> 1880) ativa.
#
# A aba MySQL usa outra credencial (usuario/senha do MySQL do seu PC, fora
# da VM) - se nao for "root"/"root", passe -UsuarioMySQLHost e
# -SenhaMySQLHost.

param(
    [string]$NodeRed          = "http://localhost:1880",
    [string]$Arquivo          = "",                      # vazio = envia todos os flow-*.json da pasta
    [string]$SenhaLab         = "Standard@123",
    [string]$InfluxToken      = "Standard@123",
    [string]$UsuarioMySQLHost = "root",              # abas MySQL / CRUD MySQL (host = 10.0.2.2, fora da VM)
    [string]$SenhaMySQLHost   = "root"
)

$ErrorActionPreference = "Stop"

$arquivos = if ($Arquivo) { @((Resolve-Path $Arquivo).Path) }
            else { Get-ChildItem -Path $PSScriptRoot -Filter "flow-*.json" | Select-Object -ExpandProperty FullName }

if (-not $arquivos) { throw "Nenhum arquivo flow-*.json encontrado em $PSScriptRoot" }

foreach ($caminho in $arquivos) {
    $todos   = Get-Content $caminho -Raw -Encoding UTF8 | ConvertFrom-Json
    $tab     = $todos | Where-Object { $_.type -eq "tab" }
    $configs = $todos | Where-Object { $_.type -in @("MySQLdatabase", "mqtt-broker", "influxdb") }
    $nodes   = $todos | Where-Object { $_.type -notin @("tab", "MySQLdatabase", "mqtt-broker", "influxdb") }

    # As senhas nao ficam no arquivo exportado (o Node-RED nunca exporta
    # credenciais). Elas sao injetadas aqui, na hora de enviar.
    foreach ($c in $configs) {
        $cred = switch ($c.type) {
            "MySQLdatabase" {
                if ($c.host -eq "10.0.2.2") {
                    # MySQL do PC do aluno (fora da VM) - aba MySQL
                    [pscustomobject]@{ user = $UsuarioMySQLHost; password = $SenhaMySQLHost }
                } elseif ($c.db -eq "lab_mysql") {
                    # MySQL da VM, banco de app pre-criado (MYSQL_DATABASE) - conta comum "user"
                    [pscustomobject]@{ user = "user"; password = $SenhaLab }
                } else {
                    # MySQL da VM, qualquer outro banco (system "mysql", ou schema novo
                    # tipo lab_nodered_crud) - precisa criar/derrubar tabelas e schema, usa root
                    [pscustomobject]@{ user = "root"; password = $SenhaLab }
                }
            }
            "influxdb"      { [pscustomobject]@{ token = $InfluxToken } }
            default         { $null }   # mosquitto do lab nao exige autenticacao
        }
        if ($cred) { $c | Add-Member -NotePropertyName credentials -NotePropertyValue $cred -Force }
    }

    $corpo = [pscustomobject]@{
        label   = $tab.label
        info    = $tab.info
        nodes   = @($nodes)
        configs = @($configs)
    } | ConvertTo-Json -Depth 30

    Write-Host "Enviando '$($tab.label)' ($(Split-Path $caminho -Leaf)) para $NodeRed ..."
    $resp = Invoke-RestMethod -Uri "$NodeRed/flow" -Method Post -Body $corpo `
            -ContentType "application/json" -Headers @{ "Node-RED-API-Version" = "v2" }
    Write-Host "  OK - aba criada com id $($resp.id)"
}

Write-Host ""
Write-Host "Pronto. Abra $NodeRed e use as abas criadas."
