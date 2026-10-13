# Cria e instala automaticamente a VM mestre "lab" no VirtualBox, sem
# passar pelas telas do instalador na mao (idioma, teclado, particionamento,
# usuario e senha). Reproduz o Anexo A.2/A.3 do README com o recurso nativo
# "VBoxManage unattended install" do VirtualBox (7.0+). Tambem ja cria as
# regras de Port Forwarding (criar-regras-nat.ps1) e instala Docker +
# docker-compose (via debian-preseed.template), com "user" ja no grupo
# docker. A VM sai pronta para SSH (porta 2222) e para "docker compose up"
# assim que a instalacao terminar.
#
# Uso (PowerShell, na pasta deste arquivo):
#   .\criar-vm-debian.ps1 -Iso "C:\Users\ricar\Downloads\debian-13.7.0-amd64-netinst.iso"
#
# Parametros opcionais (defaults = valores do Anexo A do README):
#   -Vm nome-da-vm        (default: lab)
#   -MemoriaMB 2048        -Cpus 2        -DiscoMB 20480
#   -SemGui                para instalar "as escuras" (sem abrir a janela da VM)
#   -Manual                pula a instalacao desatendida: so cria a VM (disco,
#                          NAT, Port Forwarding, ISO montado) e abre a janela
#                          para voce clicar no instalador do Debian na mao.
#                          Evita o bug do tasksel/desktop do modo automatico
#                          (veja MANUTENCAO.md) - depois rode
#                          pos-instalacao-manual.sh pelo SSH para instalar
#                          sudo/Docker/docker-compose.
#
# Ao final, a VM fica instalada e desligada (reiniciou sozinha ao terminar),
# ja com NAT + Port Forwarding configurados. Falta so o resto do Anexo A:
# A.4 (Docker + stack) e A.5 (exportar para .ova).
param(
  [Parameter(Mandatory = $true)][string]$Iso,
  [string]$Vm = "lab",
  [int]$MemoriaMB = 2048,
  [int]$Cpus = 2,
  [int]$DiscoMB = 20480,
  [switch]$SemGui,
  [switch]$Manual
)

# Nao usamos $ErrorActionPreference = "Stop" aqui: o VBoxManage escreve o
# progresso de operacoes longas (ex.: createmedium) no stderr, e com "Stop"
# isso e tratado como erro fatal mesmo quando o comando tem sucesso (exit
# code 0). Os erros reais sao verificados explicitamente via $LASTEXITCODE.
$vb = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $vb)) { Write-Error "VBoxManage nao encontrado em $vb"; exit 1 }
if (-not (Test-Path $Iso)) { Write-Error "ISO nao encontrado em: $Iso"; exit 1 }

if ((& $vb list vms) -match ('"' + [regex]::Escape($Vm) + '"')) {
  Write-Error "Ja existe uma VM chamada '$Vm'. Apague-a antes (VirtualBox > botao direito > Remove > Delete all files) ou rode de novo com -Vm outro-nome."
  exit 1
}

if (-not $Manual) {
  $templatePreseed = Join-Path $PSScriptRoot "debian-preseed.template"
  if (-not (Test-Path $templatePreseed)) { Write-Error "Template de preseed nao encontrado em $templatePreseed"; exit 1 }
}

$scriptRegrasNat = Join-Path $PSScriptRoot "criar-regras-nat.ps1"
if (-not (Test-Path $scriptRegrasNat)) { Write-Error "criar-regras-nat.ps1 nao encontrado em $scriptRegrasNat"; exit 1 }

Write-Host "`n== A.2: criando a maquina virtual '$Vm' =="
& $vb createvm --name $Vm --ostype "Debian13_64" --register
& $vb modifyvm $Vm --memory $MemoriaMB --cpus $Cpus --vram 16
& $vb modifyvm $Vm --nic1 nat

Write-Host "`n== Port Forwarding: criando as regras de NAT (porta 2222 -> 22, etc.) =="
& $scriptRegrasNat -Vm $Vm
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao criar as regras de Port Forwarding."; exit 1 }

$pastaVm = Split-Path (& $vb showvminfo $Vm --machinereadable | Select-String '^CfgFile=').ToString().Split('=', 2)[1].Trim('"')
$discoPath = Join-Path $pastaVm "$Vm.vdi"

& $vb createmedium disk --filename $discoPath --size $DiscoMB --format VDI
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao criar o disco virtual."; exit 1 }
& $vb storagectl $Vm --name "SATA" --add sata --controller IntelAhci
& $vb storageattach $Vm --storagectl "SATA" --port 0 --device 0 --type hdd --medium $discoPath
& $vb storagectl $Vm --name "IDE" --add ide
& $vb storageattach $Vm --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium $Iso
& $vb modifyvm $Vm --boot1 dvd --boot2 disk --boot3 none --boot4 none

if ($Manual) {
  Write-Host "`n== Modo manual: abrindo a VM para voce instalar o Debian na mao =="
  & $vb startvm $Vm --type gui
  if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao ligar a VM."; exit 1 }

  Write-Host @"

A janela da VM abriu com o instalador do Debian pronto para rodar. Na tela:

  1. Escolha "Install" (modo texto, nao "Graphical install").
  2. Idioma/localizacao/teclado: como preferir (o teclado fica 'us' por
     padrao no layout do instalador se voce escolher English).
  3. Hostname: lab
  4. Dominio: (deixe em branco ou "lan")
  5. Senha do root: DEIXE EM BRANCO (nos dois campos) - o instalador entende
     que nao vai ter conta root separada e ja coloca o usuario comum no
     grupo sudo sozinho, sem precisar de nenhum passo extra depois.
  6. Usuario comum: nome "user", usuario "user", senha "user"
  7. Particionamento: "Guided - use entire disk" (disco todo, uma particao)
  8. Selecao de software (tasksel) - a tela mais importante:
       [ ] Debian desktop environment   <- DESMARQUE (é o que causa o bug)
       [ ] ... (GNOME, Xfce, etc, se aparecerem como sub-itens do desktop)
       [*] SSH server                    <- deixe marcado
       [*] standard system utilities     <- deixe marcado (ou desmarque
                                              tambem, se quiser o minimo)
  9. GRUB: "Yes" para instalar no disco principal.
  10. Ao reiniciar, remova o .iso da unidade otica se o instalador nao
      fizer isso sozinho (Settings > Storage, com a VM desligada).

Quando terminar e aparecer o prompt de login em modo texto, confirme que o
SSH ja responde do seu PC:

    ssh -p 2222 user@localhost

Depois disso, rode o pos-instalacao-manual.sh (veja MANUTENCAO.md) com
"sudo sh pos-instalacao-manual.sh" para instalar Docker e docker-compose -
a instalacao manual do Debian NAO inclui isso sozinha (sudo em si ja vem
pronto, por ter deixado a senha do root em branco no passo 5).
"@
  exit 0
}

Write-Host "`n== A.3: instalacao desatendida (idioma en_US, teclado us, fuso America/Sao_Paulo, usuario/senha, particionamento automatico) =="
$startType = if ($SemGui) { "headless" } else { "gui" }
& $vb unattended install $Vm `
  --iso="$Iso" `
  --user=user --user-password=user --full-user-name=user `
  --admin-password=root `
  --hostname=lab.lan `
  --locale=en_US --country=US --time-zone=America/Sao_Paulo `
  --package-selection-adjustment=minimal `
  --script-template="$templatePreseed" `
  --start-vm=$startType

if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao iniciar a instalacao desatendida."; exit 1 }

Write-Host "`nInstalacao iniciada. A VM vai particionar o disco, instalar o sistema (SSH server + sudo + Docker + docker-compose, sem ambiente grafico) e reiniciar sozinha ao terminar - isso leva alguns minutos (depende da internet, o instalador baixa pacotes)."
Write-Host "Acompanhe pela janela da VM$(if ($SemGui) { ' (rodando sem GUI - use VirtualBox > mostrar para abrir a tela quando quiser)' })."
Write-Host "`nDepois de pronta, falta so copiar a lab-stack/ e rodar 'docker compose up -d' (Anexo A.4) e depois exportar para .ova (Anexo A.5)."
