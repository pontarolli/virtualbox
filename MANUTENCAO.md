# Manutenção — notas para o professor

Este arquivo é referência: o aluno não precisa dele para usar a VM (isso está
todo no [`README.md`](README.md)). Aqui ficam as notas de manutenção da stack
e o passo a passo de como a VM mestre foi montada, para o caso de precisar
remontá-la ou atualizá-la.

## Notas de manutenção

Coisas que custaram a descobrir e que é bom não redescobrir. Várias delas dão
boa aula.

**Node-RED não exporta senhas.** Um flow exportado em `.json` vem sem as
credenciais dos nós de configuração — é proposital. Quem importar pelo
navegador precisa preencher usuário e senha à mão. O `nodered/subir-flow.ps1`
injeta as credenciais na hora de enviar pela API, justamente para evitar esse
passo.

**O nó `mysql` pode executar comandos fora de ordem.** Ele usa um *pool* de
conexões: se várias mensagens chegam juntas, cada uma pode sair por uma
conexão diferente e a ordem não é garantida — o que quebra um DDL. Por isso
os passos de preparação usam o padrão "próximo comando": só enviam o seguinte
depois que o anterior voltou. Pelo mesmo motivo, transações
(`START TRANSACTION` / `COMMIT`) não funcionam bem nesse nó; para isso, use
uma *stored procedure* e chame com `CALL`.

**MQTT entrega uma cópia por filtro que casa.** Se um mesmo cliente assina
`lab/#` e `lab/sensor/+`, uma mensagem em `lab/sensor/sala-01` chega
**duas vezes** — uma por assinatura. Não é bug do Node-RED, é o protocolo.
Na aba MQTT cada assinante usa sua própria conexão para evitar isso.

**Telegraf precisa do grupo do socket do Docker.** Sem `group_add` com o GID
do grupo `docker` (104 nesta VM), o container sobe e morre em loop com
*permission denied*. E não adianta montar o socket como `:ro`: escrever no
socket faz parte do protocolo do Docker.

**Telegraf mede o container, não a VM, se você deixar.** Na rede `lab-net`
ele reportava a interface do próprio container. Com `network_mode: host` +
`/:/hostfs:ro` + variáveis `HOST_*`, passa a medir a VM de verdade. O efeito
colateral vale ser mostrado em aula: esse container fala com o InfluxDB por
`localhost:8086`, o oposto da regra que vale para todos os outros.

**`portainer --admin-password-file` quer a senha em texto puro, não um hash
pronto.** `lab-stack/portainer/admin_password` continha um hash bcrypt de
`Standard@123` (o padrão documentado pela própria Portainer, gerado com
`htpasswd -nbB`). Na prática, com o Portainer CE 2.45.2, isso faz o container
tratar o **hash inteiro como se fosse a senha** e hasheá-lo de novo por
cima — a "senha real" vira o texto do hash, não `Standard@123`. Login com a
senha certa dá `401/422 Invalid credentials`; login colando o hash inteiro
como senha funciona (foi assim que descobrimos). A correção é simples: o
arquivo precisa conter só `Standard@123` em texto puro, sem quebra de linha
no final. Se isso acontecer de novo (ex.: Portainer mudar de versão outra
vez), o diagnóstico é testar via `curl -X POST .../api/auth` com a senha
esperada — `Invalid credentials` com tudo certo aponta pra esse mesmo
problema. Depois de corrigir o arquivo, é preciso recriar o volume
(`docker compose rm -sf portainer && docker volume rm lab_portainer_data &&
docker compose up -d portainer`), porque o Portainer só lê esse arquivo na
**primeira** inicialização do volume.

**`tasksel/first` no preseed é ignorado nesta instalação — não dá para
prevenir, só remover depois.** Testamos `d-i tasksel/first multiselect
ssh-server` (sem "desktop" na lista) e também `multiselect none` (nenhuma
tarefa): nos dois casos o instalador instalou um GNOME completo (LibreOffice,
Firefox, Evolution, GDM, `cups-server-common`, tudo) assim mesmo. Isso é um
bug/comportamento **antigo e documentado** do `tasksel` com preseed —
[Debian bug #815344](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=815344),
de 2016, com o mesmíssimo sintoma, ainda presente no Trixie. Não é bug deste
projeto nem specífico do VirtualBox, e não há combinação conhecida de
`tasksel/first` que resolva isso de forma confiável — por isso não vale
perder tempo tentando outras variantes dessa chave. A correção que funciona é
**remover o desktop depois**: o `preseed/late_command` roda `tasksel remove
desktop` + `apt-get purge` dos pacotes GNOME ao final da instalação, antes do
primeiro boot real. Se um dia quiser confirmar se o problema ainda ocorre
(ex.: numa versão nova do VirtualBox ou do Debian), o diagnóstico rápido é
tirar um screenshot da VM em andamento (`VBoxManage controlvm debian
screenshotpng arquivo.png`, funciona mesmo sem Guest Additions) durante a
fase "Select and install software" do instalador — se aparecerem pacotes como
`cups-*`, `gnome-*` ou `gdm3` sendo desempacotados, é o mesmo problema.

**Disco dinâmico não encolhe sozinho.** Depois que o desktop acima foi
instalado e removido numa mesma instalação, o `.vdi` ficou em 7+ GB mesmo com
a VM usando só ~2 GB de verdade — os blocos ficam "alocados" no arquivo até
alguém mandar liberar. O truque de zerar o espaço livre + `VBoxManage
modifymedium disk arquivo.vdi --compact` (com a VM desligada) resolve; é
exatamente o que a seção "Deixando a VM leve antes de exportar" do A.4 faz.

**Como reinstalar os materiais em uma VM nova** (do seu PC, assume o Port
Forwarding do `README.md`, seção 4, já configurado):

```bash
scp -P 2222 -r lab-stack user@localhost:~
ssh -p 2222 user@localhost "cd ~/lab-stack && docker compose up -d"
```

```powershell
# e os flows do Node-RED
powershell -ExecutionPolicy Bypass -File .\nodered\subir-flow.ps1
```

**Como redistribuir para a turma.** Os flows do Node-RED ficam no volume
Docker `nodered_data` e os painéis do Grafana vêm do `lab-stack/`, então
ambos sobrevivem a reinicializações. Mas, para que tudo isso chegue pronto
aos alunos, é preciso **exportar o `.ova` de novo** a partir da VM mestre
(Anexo A.5, abaixo).

---

## Anexo — Como a VM mestre foi criada

Estes passos foram usados para montar a VM antes de exportá-la em `.ova`.
Ficam aqui só como referência, caso a VM mestre precise ser refeita.

### A.0 Instalar o VirtualBox

Baixe e instale em [virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
(versão para Windows). O aluno também precisa do VirtualBox instalado para
importar o `.ova` (`README.md`, seção 2) — normalmente já vem instalado nos
computadores do laboratório.

### A.1 Baixar a imagem do Debian

Instalador `netinst` **amd64** (x86_64) em:
[debian.org/distrib/netinst](https://www.debian.org/distrib/netinst)

Arquivo típico: `debian-13.x.x-amd64-netinst.iso`.

### A.2-A.3 Criar e instalar a VM com um comando

A VM é criada e instalada inteiramente pelo script `criar-vm-debian.ps1`
desta pasta — sem passar pelas telas de idioma, teclado, usuário e senha do
instalador. Ele usa o recurso nativo do VirtualBox 7
`VBoxManage unattended install`, que gera e injeta um preseed
(`debian-preseed.template`) automaticamente a partir do `.iso`.

**1. Pré-requisitos**

- VirtualBox instalado (A.0).
- O `.iso` do Debian já baixado (A.1) — anote o caminho completo do arquivo.
- Nenhuma VM com o nome `lab` já cadastrada no VirtualBox (se houver, apague-a antes: botão direito na VM > **Remove** > **Delete all files** — ou rode o script com `-Vm outro-nome`).

**2. Rodar o script**

Abra o PowerShell **na pasta do `README.md`** (a mesma do
`criar-vm-debian.ps1`) e rode, trocando o caminho pelo do seu `.iso`:

```powershell
.\criar-vm-debian.ps1 -Iso "C:\Users\seu-usuario\Downloads\debian-13.7.0-amd64-netinst.iso"
```

**3. O que o script faz, na ordem**

1. Confere se o VBoxManage, o `.iso` e o `criar-regras-nat.ps1` existem e se
   não há VM `lab` já criada.
2. Cria a VM `lab` (2048 MB RAM, 2 CPUs) e configura a placa de rede
   (Adapter 1, NAT).
3. Chama o `criar-regras-nat.ps1` (com a VM ainda desligada) para já deixar
   as 8 regras de Port Forwarding da seção 4 do `README.md` configuradas —
   não é mais preciso rodar esse script à parte depois.
4. Cria o disco (20 GB) e monta o `.iso` na unidade óptica.
5. Dispara a instalação desatendida usando `debian-preseed.template`: idioma
   `en_US`, teclado `us`, fuso `America/Sao_Paulo`, hostname `lab`,
   usuário `user`/senha `user` (já com `sudo` funcional, no grupo `sudo` e no
   grupo `docker`), root/`root`, particionamento automático (disco todo, uma
   partição), e instala `openssh-server` + `sudo` + `docker.io` +
   `docker-compose` — sem ambiente gráfico. O Docker já sai instalado e
   habilitado; falta só subir a stack (A.4).
6. Abre a janela da VM (`-SemGui` para rodar sem abrir janela) e você
   acompanha o instalador rodando sozinho.

**4. O que esperar**

A instalação roda sem pedir nada — demora de alguns minutos a ~15-20 min,
dependendo da velocidade da sua internet (o instalador baixa pacotes pelo
espelho do Debian). Ao terminar, a VM **reinicia sozinha** e para na tela de
login em modo texto (`lab login:`). Se preferir não ver a janela, rode
com `-SemGui` e acompanhe depois pelo VirtualBox (**Mostrar**, ou
`VBoxManage.exe showvminfo lab`/ligando a tela pela interface gráfica).

**5. Confirmar que deu certo**

Com a VM ligada, faça login como `user` (senha `user`) na própria tela da
VM e confira:

```bash
hostname          # deve responder "lab"
ip -4 -br a       # enp0s3 (NAT) deve ter um IP tipo 10.0.2.x
```

Ou, já que o Port Forwarding foi criado no passo 3, direto do seu PC:

```bash
ssh -p 2222 user@localhost
```

**6. Problemas comuns**

- **"Ja existe uma VM chamada 'lab'"** — apague a VM antiga antes ou use `-Vm`.
- **Teclado errado dentro da VM** — o instalador usa layout `us` fixo (bom para teclados como o Logitech K380). Para mudar, edite `debian-preseed.template` (linhas `console-setup/layoutcode` e `keyboard-configuration/xkb-keymap`) antes de rodar o script de novo.
- **Travou/sem rede durante a instalação** — confira se o seu PC tem internet (o instalador precisa baixar pacotes pelo NAT).

**7. Próximo passo**

Com a VM instalada e reiniciada, siga a partir do **A.4** abaixo (subir a
stack) e depois o **A.5** (exportar para `.ova`).

### A.2-A.3 Alternativa: instalar o Debian na mão (sem o bug do tasksel)

Como o `tasksel/first` do preseed é ignorado nesta instalação (veja a nota
nas "Notas de manutenção", acima), uma alternativa é deixar só a **tela do
instalador** manual — tudo o resto (criar a VM, disco, NAT, Port Forwarding,
montar o `.iso`) continua automático:

```powershell
.\criar-vm-debian.ps1 -Iso "C:\caminho\debian-13.7.0-amd64-netinst.iso" -Manual
```

Isso abre a janela da VM já pronta para o instalador. Siga as telas
normalmente: **Install** (modo texto, não "Graphical install"), hostname
`lab` (ou outro nome, mas mantenha igual ao nome da VM no VirtualBox, pra
facilitar — veja a nota abaixo), usuário `user`/senha `user`, particionamento
**Guided - use entire disk**, e na tela de seleção de software (`tasksel`)
**desmarque "Debian desktop environment"** e deixe **SSH server** marcado
(instalação manual interativa não tem o bug do preseed — desmarcar aqui
funciona de verdade).

> O **nome da VM no VirtualBox** (usado em `-Vm`, `showvminfo`, etc.) e o
> **hostname dentro do Linux** (o que `hostname` mostra, o que aparece no
> prompt `user@...`) são duas coisas independentes — nada impede que
> fiquem diferentes, mas é mais fácil de acompanhar se forem o mesmo nome.

**Senha do root: deixe em branco (nos dois campos).** Esse é o ponto chave —
sem senha de root, o próprio instalador desativa o login do root e já coloca
`user` no grupo `sudo` sozinho, sem precisar de nenhum passo extra depois
(é o mesmo caminho que o instalador do Ubuntu usa por padrão).

Depois que a VM reiniciar e o SSH responder (`ssh -p 2222 user@localhost`),
copie e rode o `pos-instalacao-manual.sh` desta pasta — ele instala Docker e
`docker-compose` e coloca `user` no grupo `docker` (isso a instalação manual
não traz sozinha):

```bash
scp -P 2222 pos-instalacao-manual.sh user@localhost:~
ssh -p 2222 user@localhost "sudo sh pos-instalacao-manual.sh"
```

> Se em vez disso você definiu uma senha de root na instalação, rode como
> root (`su -`, senha do root) antes de `sh pos-instalacao-manual.sh` — o
> script também bloqueia o login do root no final, nesse caso.
> No final, o script **reinicia a VM sozinho** (assim o grupo `docker` já
> vale de cara no próximo login, sem precisar sair e reconectar à mão) — a
> conexão SSH cai nesse momento, é esperado.

Depois disso, aguarde a VM reiniciar e siga normalmente a partir do A.4.

### A.4 Subir a stack

Com a VM ligada e as regras de NAT criadas, copie a pasta `lab-stack/` deste
repositório para `/home/user/lab-stack` na VM (a partir do seu PC, na pasta do
README; note o `-P` maiúsculo do `scp` para a porta):

```bash
scp -P 2222 -r lab-stack user@localhost:~
```

O Docker, o `docker-compose` e o grupo `docker` do usuário `user` já saem
prontos do `debian-preseed.template` (pacotes `docker.io docker-compose` no
`pkgsel/include`, e `usermod -aG docker user` no `preseed/late_command`) —
não precisa instalar nada nem reconectar a sessão, só subir a stack:

```bash
cd ~/lab-stack
docker compose up -d
docker exec nodered npm install --prefix /data node-red-contrib-influxdb node-red-node-mysql
docker restart nodered
```

Confira com `docker ps` (7 containers) e abra os endereços do `README.md`,
seção 5. Os containers têm `restart: unless-stopped` e o Docker fica
habilitado, então tudo sobe sozinho quando a VM liga.

#### Deixando a VM leve antes de exportar

Sem interface gráfica, o grosso do tamanho final do `.ova` vem do sistema
base do Debian e das imagens Docker (`mysql:8.0`, `grafana/grafana-oss`,
`influxdb:2`, `nodered/node-red`, `portainer-ce`, `telegraf`, somadas,
ocupam a maior parte do disco usado). Antes de exportar (A.5), vale limpar o
que não é necessário e compactar o disco virtual:

```bash
sudo apt clean
docker image prune -f
sudo rm -f /debian-13*.iso      # se tiver copiado o instalador para dentro da VM
sudo journalctl --vacuum-size=10M
```

Depois, zere o espaço livre do disco (ajuda o VirtualBox a compactar melhor
na exportação — o comando demora alguns minutos e o arquivo é apagado no
final):

```bash
sudo dd if=/dev/zero of=/ZERO bs=1M || true
sudo rm -f /ZERO
```

Desligue a VM (`sudo shutdown -h now`) antes de exportar.

Opcionalmente, do seu PC (com a VM desligada), compacte o `.vdi` de verdade —
isso não é necessário para a exportação em si (o zero-fill acima já ajuda o
`.ova` a sair pequeno), mas é útil se quiser conferir o tamanho real do disco
antes de exportar:

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifymedium disk "C:\Users\<voce>\VirtualBox VMs\lab\lab.vdi" --compact
```

### A.5 Exportar para .ova

Com a VM instalada, testada e desligada (deixe o **Adapter 1** em **NAT** com
as regras de *Port Forwarding*):

1. **File > Export Appliance...**
2. Selecione a VM `lab` e clique em **Next**.
3. Formato do arquivo: **OVA 2.0** (mais simples de distribuir, um arquivo só).
4. Escolha o destino e clique em **Next** para ver as opções do appliance
   (os nomes podem variar um pouco conforme a versão do VirtualBox):
   - **MAC Address Policy:** escolha **Strip all network adapter MAC
     addresses**. O `.ova` sai sem MAC, e cada aluno que importa recebe um
     MAC novo.
   - **Write Manifest file:** **marque**. Grava os hashes (SHA) dos arquivos,
     e o VirtualBox confere na importação se o `.ova` chegou íntegro (útil ao
     copiar pela pasta compartilhada ou pendrive).
   - **Include ISO image files:** **não marque**. A unidade óptica da VM já
     deve estar vazia, e incluir o `.iso` do instalador só aumentaria o
     arquivo.
5. Clique em **Export**.
6. Copie o `.ova` gerado para a pasta compartilhada do laboratório, de onde
   os alunos vão copiá-lo (`README.md`, seção 1). Copie também o
   `criar-regras-nat.ps1`, para o caso de as regras de *Port Forwarding* não
   virem dentro do `.ova`.
7. **Teste a importação** antes de distribuir: importe o `.ova` como uma VM
   nova (por exemplo `lab-teste`), confira em **Settings > Network >
   Advanced > Port Forwarding** se as 8 regras vieram e, depois de ligar,
   confira se `localhost:1880` abre (com a regra `nodered` já configurada).
   Depois apague a VM de teste em **Remove > Delete all files**.

> **Tamanho esperado:** mesmo sem GUI e com a limpeza do passo anterior, a
> soma das imagens Docker da stack (`README.md`, seção 5) costuma deixar o
> `.ova` na faixa de alguns GB — bem menor do que com XFCE instalado, mas não
> necessariamente abaixo de 2-3 GB com todos os sete serviços. Se o
> tamanho final importa mais do que ter todos os serviços, vale reavaliar
> com o professor quais containers são realmente necessários para a turma
> antes de exportar.
