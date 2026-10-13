# Cria as regras de Port Forwarding (NAT) da VM do laboratorio.
# Uso (PowerShell, na pasta deste arquivo):   .\criar-regras-nat.ps1
#   ou, se a VM tiver outro nome:             .\criar-regras-nat.ps1 -Vm nome-da-vm
# Pode ser executado com a VM ligada ou desligada. Pode repetir sem problema.
param([string]$Vm = "lab")

# Independente do $ErrorActionPreference do chamador (ex.: criar-vm-debian.ps1
# usa "Stop"): este script trata seus proprios erros via $LASTEXITCODE, entao
# fixamos "Continue" aqui para que o stderr das chamadas "delete" (esperado
# falhar quando a regra ainda nao existe) nao vire um erro fatal.
$ErrorActionPreference = "Continue"

$vb = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $vb)) { Write-Error "VBoxManage nao encontrado em $vb"; exit 1 }

# nome = @(porta no Windows, porta na VM)
$regras = [ordered]@{
  ssh        = @(2222, 22)
  nodered    = @(1880, 1880)
  grafana    = @(3000, 3000)
  portainer  = @(9000, 9000)
  influxdb   = @(8086, 8086)
  mysql      = @(3306, 3306)
  mqtt       = @(1883, 1883)
  mqttws     = @(9001, 9001)
}

$rodando = [bool]((& $vb list runningvms) -match ('"' + [regex]::Escape($Vm) + '"'))
if (-not $rodando) { & $vb modifyvm $Vm --nic1 nat }   # so com a VM desligada

$erro = $false
foreach ($n in $regras.Keys) {
  $regra = "$n,tcp,127.0.0.1,$($regras[$n][0]),,$($regras[$n][1])"
  if ($rodando) {
    & $vb controlvm $Vm natpf1 delete $n 2>$null | Out-Null   # remove se ja existir
    & $vb controlvm $Vm natpf1 $regra
  } else {
    & $vb modifyvm $Vm --natpf1 delete $n 2>$null | Out-Null
    & $vb modifyvm $Vm --natpf1 $regra
  }
  if ($LASTEXITCODE -ne 0) { Write-Warning "Falhou: $regra"; $erro = $true }
}

if ($erro) { Write-Host "Algumas regras falharam (veja os avisos acima)."; exit 1 }
Write-Host "Regras criadas para a VM '$Vm':"
& $vb showvminfo $Vm --machinereadable | Select-String '^Forwarding'
