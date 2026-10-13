# Envia os flows de exemplo para o Node-RED da VM.
#
#   powershell -ExecutionPolicy Bypass -File .\subir-flow.ps1
#   powershell -ExecutionPolicy Bypass -File .\subir-flow.ps1 -Arquivo .\flow-mqtt.json
#
# Cada arquivo vira uma ABA NOVA no Node-RED (nao apaga os flows existentes).
# A VM precisa estar ligada e a regra de NAT "nodered" (1880 -> 1880) ativa.
#
# A aba MySQL (cheat sheet de SQL + listagens + CRUD) conecta so no MySQL da
# propria VM (sem depender de ninguem ter MySQL instalado no PC) - veja a
# guia Info da aba pra uma nota de como conectar no MySQL do seu PC, se
# quiser, por conta propria.

param(
    [string]$NodeRed          = "http://localhost:1880",
    [string]$Arquivo          = "",                      # vazio = envia todos os flow-*.json da pasta
    [string]$SenhaLab         = "Standard@123",
    [string]$InfluxToken      = "Standard@123"
)

$ErrorActionPreference = "Stop"

$arquivos = if ($Arquivo) { @((Resolve-Path $Arquivo).Path) }
            else { Get-ChildItem -Path $PSScriptRoot -Filter "flow-*.json" | Select-Object -ExpandProperty FullName }

if (-not $arquivos) { throw "Nenhum arquivo flow-*.json encontrado em $PSScriptRoot" }

# Algumas abas compartilham o mesmo no de configuracao (ex.: o broker MQTT
# usado tanto pela aba MQTT quanto pela aba InfluxDB) - o Node-RED rejeita
# com "duplicate id" se tentarmos recriar um config que ja existe. Aqui
# buscamos os ids ja presentes no servidor e vamos atualizando essa lista
# a cada aba enviada, para nunca reenviar um config repetido.
$idsConhecidos = [System.Collections.Generic.HashSet[string]]::new()
try {
    $flowsAtuais = Invoke-RestMethod -Uri "$NodeRed/flows" -Headers @{ "Node-RED-API-Version" = "v2" }
    $itensAtuais = if ($flowsAtuais.flows) { $flowsAtuais.flows } else { $flowsAtuais }
    foreach ($it in $itensAtuais) { [void]$idsConhecidos.Add($it.id) }
} catch {
    Write-Warning "Nao foi possivel listar os flows existentes (seguindo mesmo assim): $_"
}

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
                if ($c.db -eq "lab_mysql") {
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

    # So manda configs que o servidor ainda nao tem (evita "duplicate id"
    # quando uma config e compartilhada com uma aba ja enviada antes).
    $configsNovos = @($configs | Where-Object { -not $idsConhecidos.Contains($_.id) })

    $corpo = [pscustomobject]@{
        label   = $tab.label
        info    = $tab.info
        nodes   = @($nodes)
        configs = $configsNovos
    } | ConvertTo-Json -Depth 30

    Write-Host "Enviando '$($tab.label)' ($(Split-Path $caminho -Leaf)) para $NodeRed ..."
    $resp = Invoke-RestMethod -Uri "$NodeRed/flow" -Method Post -Body $corpo `
            -ContentType "application/json" -Headers @{ "Node-RED-API-Version" = "v2" }
    Write-Host "  OK - aba criada com id $($resp.id)"

    [void]$idsConhecidos.Add($tab.id)
    foreach ($n in $nodes)        { [void]$idsConhecidos.Add($n.id) }
    foreach ($c in $configsNovos) { [void]$idsConhecidos.Add($c.id) }
}

Write-Host ""
Write-Host "Pronto. Abra $NodeRed e use as abas criadas."
