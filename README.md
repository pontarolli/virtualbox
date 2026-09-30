# Laboratório Redes de Computadores — Servidor local (VirtualBox)

Esta VM é de uso coletivo (compartilhada pela turma): ela já vem pronta, num
arquivo `.ova`, e você só precisa importá-la no seu VirtualBox. **O uso
principal é pela própria tela da VM** — depois de importar e instalar um
ambiente gráfico leve (passo 4), você abre o navegador, o terminal e os
editores **dentro da VM**, sem precisar configurar nada na rede do seu PC. A
VM também fica visível na rede do laboratório (segundo adaptador, em
Bridge), para o professor acompanhar o seu trabalho (seção 7). Se preferir
acessar os serviços pelo navegador do seu próprio PC em vez da tela da VM,
isso também é possível — veja o Anexo **"Acesso pelo seu PC via Port
Forwarding"**, ao final deste arquivo.

| Item | Valor |
|---|---|
| Hipervisor | Oracle VirtualBox |
| Sistema operacional da VM | Debian 13 (x86_64), instalação `netinst`, sem interface gráfica por padrão (o passo 4 instala uma) |
| Rede da VM | **Adaptador 1: NAT** (saída à internet) e **Adaptador 2: Bridge** (IP da rede do laboratório, para o professor) |
| Usuário do sistema (login na tela da VM ou SSH) | `user` |
| Senha do usuário `user` | `user` |
| Senha do `root` | `root` |
| Containers Docker | Portainer, Node-RED, Mosquitto (MQTT), MySQL Server, InfluxDB e Grafana (seção 6) |

> Mesmo sistema operacional e arquitetura da VM na nuvem (veja a pasta
> `../cloud`): Debian x86_64. Assim os comandos que você aprender aqui
> funcionam sem alteração na VM da Oracle Cloud.

## O que tem nesta pasta

| Caminho | O que é |
|---|---|
| `README.md` | este arquivo: importar, ligar, usar e manter a VM |
| `vm-padrao/debian.ova` | a VM pronta, para importar no VirtualBox |
| `criar-regras-nat.ps1` | cria as regras de Port Forwarding para acesso pelo seu PC (opcional — ver Anexo) |
| `teste.sh` | teste de verificação por SSH (opcional — ver Anexo) |
| `lab-stack/` | o `docker-compose.yml` e a configuração de todos os containers |
| `lab-stack/telegraf/` | configuração do Telegraf (métricas da VM — seção 6.1) |
| `lab-stack/grafana/provisioning/` | *data sources* e painéis do Grafana, carregados automaticamente |
| `nodered/` | as abas de exemplo do Node-RED e o roteiro de aula (seção 8) |
| `debian-13.7.0-amd64-netinst.iso` | instalador usado para montar a VM mestre (Anexo A.1) |

## 1. Copiar o arquivo .ova da pasta compartilhada do laboratório

Copie o arquivo `debian.ova` de:

`[CAMINHO_DA_PASTA_COMPARTILHADA]`

para uma pasta no seu computador (ex.: `Documentos\lab-redes\`).

> **Como esse `.ova` foi gerado (referência, você não precisa repetir isso):**
> a VM mestre foi criada e o Debian instalado normalmente no VirtualBox e,
> depois de pronta, exportada em **File > Export Appliance...**, selecionando
> a VM, formato **OVA 2.0**, e clicando em **Export**. Os detalhes completos
> de como a VM mestre foi montada estão no Anexo, ao final deste arquivo.

## 2. Importar a VM no VirtualBox

No VirtualBox, **File > Import Appliance...**:

1. Clique no ícone de pasta e selecione o arquivo `debian.ova` copiado no
   passo anterior.
2. Clique em **Next** e confira as configurações sugeridas (nome, memória,
   disco). Na mesma tela, confira se **Reinitialize the MAC address of all
   network cards** está marcada (em *MAC Address Policy*, ou na caixa de
   seleção no rodapé, conforme a versão do VirtualBox) e clique em **Import**.

   > **Sobre o MAC:** o `.ova` já foi exportado **sem os endereços MAC** (veja
   > o Anexo A.5), então cada importação gera MACs novos e as VMs dos alunos
   > **não devem repetir o MAC**. Mesmo assim, vale conferir a opção: no
   > Adaptador 2 (Bridge) a VM entra na rede do laboratório, e se duas VMs
   > ficarem com o **mesmo MAC** nessa rede, o DHCP entrega o mesmo IP para
   > elas e uma derruba a outra (sintoma: perda de conexão, `ping` e SSH
   > intermitentes). Se isso acontecer, importe de novo com a opção marcada.
3. Aguarde a importação terminar — a VM `debian` aparece na lista à
   esquerda do VirtualBox.
4. Antes de ligar, confira as duas placas em **Settings > Network**:

   - **Adapter 2**: **Attached to** em **Bridged Adapter** e, em **Name**,
     selecione o adaptador que o seu computador usa para acessar a rede: o
     **Wi-Fi** ou o **Ethernet** (cabo). **Faça isso mesmo que já apareça algum
     nome selecionado**: ele veio do computador onde a VM foi criada e pode não
     existir no seu (nesse caso o VirtualBox dá erro ao ligar a VM). Em computadores
     com Hyper-V/WSL, o adaptador pode aparecer como `Hyper-V Virtual Ethernet
     Adapter #2` (o *External Switch* ligado ao Wi-Fi): escolha o que estiver
     **Up** e tiver o IP da sua rede (confira com `ipconfig`).
   - **Adapter 1**: deixe em **NAT** (o padrão) — não precisa mexer em nada
     aqui nem configurar *Port Forwarding* agora. O acesso principal daqui
     em diante é pela própria tela da VM (passo 4). Se mais tarde você
     também quiser abrir os serviços pelo navegador do seu PC, isso é
     opcional e está no Anexo **"Acesso pelo seu PC via Port Forwarding"**.

## 3. Ligar a VM

Inicie a VM (**Start**) e aguarde de 1 a 2 minutos: o Debian liga e os
containers sobem sozinhos. A VM abre numa janela própria, com um prompt de
login em modo texto (ainda sem interface gráfica) — é nela que você vai
trabalhar a partir de agora.

## 4. Instalar o ambiente gráfico (XFCE)

A VM vem sem interface gráfica por padrão (Anexo A.3), pensada para instalar
só o essencial e deixar você escolher o resto. Como o uso principal daqui em
diante é pela própria tela da VM, este é o primeiro passo depois de ligar:
um ambiente desktop leve por cima do Debian já instalado, para abrir
navegador, terminal e editores direto na janela da VM.

Clique dentro da janela da VM: você verá o prompt de login em modo texto do
passo anterior. Entre com `user` / `user` — é ali, **direto nessa tela, sem
precisar de SSH**, que os comandos abaixo são digitados.

> **Por que XFCE e não GNOME:** a VM roda com pouca RAM (2 GB, já dividida com
> os containers da seção 6). O GNOME consome sozinho cerca de 800 MB–1,2 GB só
> de desktop parado, enquanto o XFCE fica na faixa de 200–300 MB — diferença
> grande o suficiente para a VM engasgar com GNOME nesse tamanho de RAM.

### Antes de instalar: tire um snapshot

Instalar e depois remover um ambiente gráfico inteiro pode deixar pacotes
órfãos e arquivos de configuração para trás mesmo depois de um `apt purge`. A
forma limpa de garantir a volta exata ao estado atual (sem GUI) é um snapshot
do VirtualBox, e não confiar só no purge:

No VirtualBox, com a VM selecionada: **Snapshot > Take**, dê um nome como
`antes-xfce`. Se não gostar do resultado depois, **Snapshot > Restore** nesse
snapshot desfaz tudo em segundos, sem sobra de arquivos.

### Instalar o XFCE

Ainda na janela da VM, logado como `root` (`su -`, senha `root`; esta VM não
tem `sudo`):

```bash
su -
apt update
apt install -y task-xfce-desktop
reboot
```

Depois de reiniciar, a VM passa a abrir numa tela de login gráfico (LightDM),
direto na própria janela. Entre com o usuário `user` / senha `user`.

> Aumente a RAM da VM em **Settings > System > Motherboard** se notar
> lentidão (de `2048 MB` para, por exemplo, `3072` ou `4096 MB`) — o XFCE por
> si só é leve, mas soma com os containers da seção 6 e com apps como o MySQL
> Workbench abertos ao mesmo tempo.

### Instalar o Guest Additions (tela integrada, redimensionável, clipboard)

Com o XFCE (Xorg) já instalado, adicione o Guest Additions para a janela da VM
redimensionar sozinha, recortar/colar entre o PC e a VM e arrastar arquivos —
é o que torna dispensável qualquer VNC/RDP para usar a GUI.

> **Não existe pacote `apt` para isso no Debian 13.** Os pacotes
> `virtualbox-guest-x11` e `virtualbox-guest-utils` foram **removidos do
> repositório oficial do Debian** a partir do trixie (o VirtualBox inteiro
> saiu do arquivo, inclusive de `contrib`) — `apt install` desses pacotes
> sempre vai dar `Unable to locate package`, mesmo com `apt update` em dia.
> O caminho certo agora é instalar a partir do `.iso` de Guest Additions que
> já vem junto com o VirtualBox do seu PC.

1. Instale as dependências de compilação, ainda direto na tela da VM
   (`su -`, senha `root`):

   ```bash
   su -
   apt update
   apt install -y build-essential dkms linux-headers-amd64
   ```

   > **Se o `apt update` trouxer uma atualização de kernel** (mensagem tipo
   > `1 package can be upgraded`), o `linux-headers-amd64` instala os headers
   > da versão **nova**, mas a VM continua rodando a versão **antiga** até
   > reiniciar. Nesse caso, dê `reboot` **antes** do passo 3 — senão o DKMS
   > tenta compilar contra um kernel que não é o que está rodando, falha
   > silenciosamente e o Guest Additions "instala" sem gerar módulo nenhum.
   > Confira com `uname -r` vs. `dpkg -l | grep linux-headers-[0-9]` se os
   > dois batem antes de seguir.

2. Com a VM ligada e a janela dela em foco, no menu do VirtualBox (no seu PC):
   **Devices > Insert Guest Additions CD image...**. Isso "insere" o `.iso`
   na unidade óptica virtual da VM (não precisa baixar nada à parte).

3. De volta na tela da VM, monte a unidade e rode o instalador:

   ```bash
   mkdir -p /mnt/cdrom
   mount /dev/cdrom /mnt/cdrom
   sh /mnt/cdrom/VBoxLinuxAdditions.run
   ```

   Ignore avisos sobre módulos gráficos "legacy" — o essencial é a mensagem
   final confirmando que os módulos do kernel foram instalados.

   > **Erro esperado no módulo `vboxvideo`:** nos kernels mais novos do
   > Debian 13, o módulo de vídeo legado que vem no instalador do Guest
   > Additions pode falhar ao compilar (`error: implicit declaration of
   > function 'drm_fb_helper_alloc_info'` ou parecido) — é uma incompatibilidade
   > entre a versão do instalador e a API de DRM do kernel novo. **Não é
   > motivo de preocupação:** o próprio kernel do Debian já traz um driver
   > `vboxvideo` nativo (in-tree), que assume a parte de vídeo sozinho. Os
   > módulos que realmente importam para o dia a dia (`vboxguest`,
   > `vboxsf` — clipboard, drag-and-drop, pastas compartilhadas) compilam
   > normalmente. Confirme com `lsmod | grep vbox`: se aparecerem
   > `vboxguest`, `vboxsf` e `vboxvideo` na lista, está tudo certo.

4. Desmonte, ejete o `.iso` e reinicie:

   ```bash
   umount /mnt/cdrom
   reboot
   ```

   Depois de reiniciar, em **Devices** no menu do VirtualBox, confira se
   **Insert Guest Additions CD image...** já não está mais marcado (ou remova
   manualmente em **Settings > Storage**, se a VM estiver desligada).

5. Com o módulo já carregado (confira com `lsmod | grep vboxguest`), habilite
   redimensionamento, recortar/colar e arrastar arquivos — **essas três
   opções vêm desligadas por padrão**, mesmo com o Guest Additions instalado.
   Na janela da VM, no menu do VirtualBox (no seu PC):

   - **View > Auto-resize Guest Display** — marque. A tela passa a acompanhar
     o tamanho da janela sozinha.
   - **Devices > Shared Clipboard > Bidirectional** — marque. Passa a dar
     para copiar num lado (PC ou VM) e colar no outro, nos dois sentidos.
   - **Devices > Drag and Drop > Bidirectional** — marque. Passa a dar para
     arrastar arquivos entre o PC e a janela da VM.

   > É normal precisar marcar essas três de novo depois de reiniciar a VM (o
   > VirtualBox nem sempre preserva a escolha entre sessões). Se quiser
   > deixar fixo, desligue a VM e configure direto em **Settings > General >
   > Advanced**, nos campos **Shared Clipboard** e **Drag'n'Drop** (escolha
   > **Bidirectional** nos dois) — assim já vem marcado toda vez que a VM
   > ligar.

   Teste redimensionando a janela da VM: se a tela acompanhar, o Guest
   Additions está funcionando.

### MySQL Workbench (opcional)

Baixe o `.deb` oficial em
[dev.mysql.com/downloads/workbench](https://dev.mysql.com/downloads/workbench/)
e instale direto na VM (o `apt` resolve as dependências gráficas sozinho a
partir do arquivo local):

```bash
su -
apt update
apt install -y /home/user/Downloads/mysql-workbench_26.7.0-1_amd64.deb
```

> Ajuste o nome do arquivo para a versão que você baixou. O Workbench abre
> pelo menu de aplicativos do XFCE ou por `mysql-workbench` num terminal.
> Para conectar no banco da própria VM (seção 6), use `127.0.0.1` (não
> `localhost`, para forçar TCP em vez de socket Unix) porta `3306`, com os
> usuários/senhas da tabela da seção 6.

### VS Code (opcional)

Comando usado para instalar (repositório oficial da Microsoft), com os
detalhes completos no Anexo A.6:

```bash
su -
apt install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt update
apt install -y code
```

### Desinstalar o XFCE

```bash
su -
apt purge -y task-xfce-desktop xfce4* lightdm* xserver-xorg*
apt autoremove --purge -y
apt autoclean
systemctl set-default multi-user.target
reboot
```

Confira depois com `systemctl get-default` — deve mostrar `multi-user.target`
(a VM volta a abrir em modo texto, como originalmente).

## 5. Teste de verificação

Depois que a VM reiniciar (final do passo 4), você verá a tela de login
gráfica do XFCE. Entre com `user` / `user`.

Abra um terminal (ícone na barra de tarefas do XFCE, ou clique direito na
área de trabalho > **Open Terminal Here**) e confira se a VM é mesmo o que
se espera:

```bash
cat /etc/os-release
uname -m
```

### Resultado esperado

```
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.7
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
x86_64
```

O que importa é que `PRETTY_NAME` mostre Debian 13 e o segundo comando
mostre `x86_64`. Se algo destoar disso, revise os passos acima e as
Observações mais abaixo.

### Sua saída

Cole a saída completa dos dois comandos abaixo:

```
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.7
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
x86_64
```

> Prefere verificar pelo terminal do seu PC em vez da tela da VM? O Anexo
> **"Acesso pelo seu PC via Port Forwarding"** mostra como rodar o mesmo
> teste por SSH, com o script `teste.sh`.

## 6. Serviços da VM (containers Docker)

A VM já vem com o Docker, o Docker Compose e sete containers prontos. Seis
ficam na mesma rede Docker (`lab-net`) e um, o Telegraf, roda na rede da
própria VM (veja a seção 6.1). Eles iniciam sozinhos quando a VM liga — leva
1 a 2 minutos depois de ligar para tudo ficar pronto.

Abra no navegador **da própria VM** (dentro do XFCE, instalado no passo 4):

| Serviço | Para que serve | Endereço (dentro da VM) | Login |
|---|---|---|---|
| Node-RED | Fluxos de automação | `http://localhost:1880` | sem login |
| Grafana | Painéis e gráficos | `http://localhost:3000` | `root` / `Standard@123` |
| Portainer | Gerenciar os containers pelo navegador | `http://localhost:9000` | `admin` / `Standard@123` |
| InfluxDB 2 | Banco de séries temporais | `http://localhost:8086` | `root` / `Standard@123` |
| MySQL Server | Banco relacional | `localhost:3306` | `root` / `Standard@123` (admin) ou `user` / `Standard@123` (banco `lab_mysql`) |
| Mosquitto | Broker MQTT | `localhost:1883` (WebSocket: `9001`) | sem login |

Dados do InfluxDB: organização `lab`, bucket `lab`, token
`lab-influx-token-1234`. Estas senhas são só para o laboratório.

> Prefere abrir esses endereços do navegador do seu PC em vez da tela da VM?
> Funciona igual, mas precisa configurar o Port Forwarding primeiro — veja o
> Anexo **"Acesso pelo seu PC via Port Forwarding"**.

O MySQL Server é o único banco relacional da stack (`mysql:8`). Dentro da
VM, pela rede `lab-net`, os outros containers o alcançam pelo nome `mysql`
na porta `3306` — é assim que a aba **MySQL VM** do Node-RED se conecta a
ele (veja [`nodered/README.md`](nodered/README.md)).

O Grafana já vem com dois painéis prontos (menu **Dashboards**):

| Painel | O que mostra |
|---|---|
| **Laboratório de Redes — VM (Telegraf)** | CPU, memória, disco, rede e uso por container, da própria VM |
| **Laboratório de Redes — Sensores (InfluxDB)** | as leituras que o Node-RED gravar, por MQTT ou direto |

### 6.1 Telegraf — as métricas da VM

O sétimo container é o **Telegraf**: a cada 10 segundos ele lê CPU, memória,
disco, rede, uptime e o consumo de cada container, e grava tudo no mesmo
bucket `lab` do InfluxDB. Não tem interface própria — você o vê pelo painel
*VM (Telegraf)* no Grafana.

Ele é a exceção da stack, e isso rende boa discussão em aula:

- **`network_mode: host`** — fica na rede da própria VM, não na `lab-net`. É
  o que faz as métricas de rede serem das interfaces reais (`enp0s3`, o NAT,
  e `enp0s8`, a bridge) em vez das do container. Como consequência, o
  endereço do InfluxDB no `telegraf.conf` é `localhost:8086` e não
  `influxdb:8086` — o oposto da regra que vale para os outros containers.
- **`/:/hostfs:ro` + variáveis `HOST_*`** — o Telegraf lê `/proc`, `/sys` e
  os discos da VM em vez dos do container. Sem isso ele mediria a si mesmo.
- **`group_add`** — o usuário `telegraf` precisa entrar no grupo dono de
  `/var/run/docker.sock` para coletar métricas dos containers. O número está
  fixo em `104` no `docker-compose.yml`; confira com `getent group docker` se
  algum dia não funcionar.

Para conferir se está coletando:

```bash
docker logs --tail 20 telegraf
```

### Como os containers conversam entre si

Dentro da rede `lab-net`, cada container é encontrado pelo **nome do serviço**
(não use `localhost` nem o IP da VM entre containers — `localhost` dentro de um
container é ele mesmo). Por exemplo, no Node-RED:

| Para acessar | Use o endereço |
|---|---|
| Broker MQTT | `mosquitto` porta `1883` |
| Banco MySQL | `mysql` porta `3306` |
| InfluxDB | `http://influxdb:8086` |

O Grafana já vem com os *data sources* **InfluxDB** e **MySQL** configurados
(Connections > Data sources). O Node-RED já tem instalados os nós
`node-red-contrib-influxdb` e `node-red-node-mysql`, além dos nós de MQTT.

### Comandos úteis (dentro da VM, logado como `user`)

```bash
docker ps                                  # containers em execução
cd ~/lab-stack && docker compose ps        # estado da stack
docker compose logs -f nodered             # logs de um serviço (Ctrl+C sai)
docker compose restart grafana             # reiniciar um serviço
docker compose down                        # parar tudo (os dados são mantidos)
docker compose up -d                       # iniciar tudo novamente
```

Exemplo de teste do MQTT (publica e recebe uma mensagem entre containers):

```bash
docker exec mosquitto sh -c "mosquitto_sub -h mosquitto -t lab/teste -C 1 -W 5 & sleep 1; mosquitto_pub -h mosquitto -t lab/teste -m ola; wait"
```

Deve imprimir `ola`. Os arquivos da stack estão em `~/lab-stack/` na VM e uma
cópia está na pasta `lab-stack/` deste repositório.

## 7. Acesso pela rede do laboratório (Adaptador 2 — Bridge)

Além da própria tela da VM, ela tem um segundo adaptador em **Bridge**: por
ele ela recebe um IP da rede do laboratório (ex.: `192.168.0.188`) e pode ser
acessada de **outros computadores** — é assim que o professor consegue abrir o
Node-RED, o Grafana etc. da sua VM para acompanhar o seu trabalho. Você não
precisa fazer nada além de escolher o adaptador certo no passo 4 da seção 2.

Para ver o IP da sua VM (por exemplo, para passar ao professor), na própria
tela da VM (ou um terminal do XFCE) rode:

```bash
ip -4 -br a
```

O IP da rede do laboratório é o da interface **`enp0s8`** (ignore o `/24`):

```
lo               UNKNOWN        127.0.0.1/8
enp0s3           UP             10.0.2.15/24         <- NAT (uso interno, ignore)
enp0s8           UP             192.168.0.188/24     <- este é o IP na rede do lab
```

Com esse IP, de qualquer computador da mesma rede (inclusive o seu, se
preferir o terminal do PC), usa-se o **IP no lugar de `localhost`** e as
**portas originais** (sem encaminhamento nenhum):

```bash
ssh user@192.168.0.188
```

E no navegador: `http://192.168.0.188:1880` (Node-RED), `:3000` (Grafana),
`:9000` (Portainer), `:8086` (InfluxDB).

Se a `enp0s8` aparecer **sem IP**, a VM não recebeu endereço da rede: confira o
adaptador escolhido no Adapter 2 e reinicie a VM. O IP vem do DHCP da rede e
pode mudar quando a VM fica desligada por muito tempo.

> **Atenção:** qualquer pessoa na mesma rede consegue abrir os serviços da sua
> VM e entrar por SSH com `user` / `user` (e o Portainer dá controle total dos
> containers). Use só o que é do laboratório: nada de dados ou senhas pessoais
> na VM, e desligue-a quando não estiver usando.

### Acessar por nome em vez do IP (opcional)

Se a rede do laboratório resolver nomes, dá para usar um nome no lugar do IP.
Como todas as VMs vêm com o mesmo nome (`debian`), cada aluno deve trocar o seu
por um nome **único**, por exemplo `debian-1`, `debian-2`... (o número que o
professor indicar; só letras minúsculas, números e hífen). Na tela da VM,
entre como `root` (`su -`, senha `root`) e rode, trocando `debian-1` pelo seu
nome:

```bash
su -
hostnamectl set-hostname debian-1
sed -i 's/^127\.0\.1\.1.*/127.0.1.1	debian-1/' /etc/hosts
reboot
```

Depois que a VM ligar, teste de outro computador da rede com `ping debian-1`.
Se responder, use o nome onde usaria o IP (`ssh user@debian-1`,
`http://debian-1:1880`...). Isso só funciona se o roteador/DNS da rede registrar
o nome das máquinas; se o `ping` não encontrar o host, continue usando o IP.

## 8. Materiais de aula prontos na VM

A VM já vem com quatro abas de exemplo no Node-RED e dois painéis no Grafana.
Tudo está versionado nesta pasta, então dá para reinstalar ou levar para
outra VM.

### Node-RED — quatro abas (<http://localhost:1880>)

| Aba | Assunto | Como usar |
|---|---|---|
| **Blocos básicos** | `function`, `change`, `switch`, `template`, `split`/`join`, `delay` | seis exemplos independentes; clique no inject e compare entrada e saída no Debug |
| **MQTT** | publicar e assinar no Mosquitto, curingas `#` e `+` | publicadores em cima, assinantes embaixo |
| **SQL cheat sheet** | 27 consultas em três níveis (iniciante, médio, avançado), contra o MySQL da VM | rode o inject **0** primeiro; depois, qualquer exemplo em qualquer ordem |
| **InfluxDB** | gravar séries temporais e consultar com Flux | inclui uma ponte MQTT → InfluxDB |

Cada aba tem a explicação completa na sua própria guia **Info** (painel da
direita no Node-RED). Os arquivos `.json`, o roteiro de aula detalhado e o
script de instalação estão em [`nodered/`](nodered/README.md).

### Node-RED — três abas extras: MySQL (PC e VM)

Além das quatro acima (que só usam serviços de dentro da VM), há três abas
de MySQL — uma pessoal/opcional (conecta ao MySQL do **PC Windows**, fora da
VM) e duas que já são parte da stack (conectam ao container `mysql` da
própria VM, seção 6).

| Aba | Onde conecta | Assunto | Como usar |
|---|---|---|---|
| **MySQL** | PC Windows (opcional) | listar todos os bancos do MySQL do PC, seu tamanho e suas tabelas | três injects independentes |
| **CRUD MySQL** | container `mysql` da VM | exemplo `bookstore` (tabelas `authors` e `books`), num schema novo e isolado (`lab_nodered_crud`) | clique nos injects **na ordem de 0 a 9** |
| **MySQL VM** | container `mysql` da VM | as mesmas três consultas da aba MySQL, agora contra o MySQL de dentro da VM | três injects independentes |

> **Só a aba MySQL é pessoal — não faz parte da stack da VM.** Ela depende
> de haver um MySQL rodando no PC Windows de quem usa o Node-RED (aqui,
> MySQL 8.0, usuário `root` / senha `root`, escutando em todas as
> interfaces). Se a VM for redistribuída para a turma (`.ova`, Anexo A.5),
> essa aba só funciona para quem tiver um MySQL local equivalente — os
> outros alunos podem simplesmente ignorá-la ou apagá-la. **CRUD MySQL** e
> **MySQL VM** não têm essa restrição: conectam a um container da própria
> stack (seção 6), então funcionam para qualquer um assim que o
> `docker-compose.yml` com o serviço `mysql` for aplicado. Detalhes de como
> tudo isso funciona (o endereço `10.0.2.2` da aba MySQL vs. o nome do
> container `mysql` das outras duas, por quê o schema novo evita mexer nos
> bancos que já existiam) estão na guia **Info** de cada aba e em
> [`nodered/README.md`](nodered/README.md).

Sugestão de ordem: **Blocos básicos → MQTT → InfluxDB → SQL cheat sheet**. Os
três primeiros se encadeiam.

### Grafana — dois painéis (<http://localhost:3000>)

| Painel | O que mostra |
|---|---|
| [**VM (Telegraf)**](http://localhost:3000/d/lab-vm) | CPU, memória, disco, rede e consumo por container, da própria VM |
| [**Sensores (InfluxDB)**](http://localhost:3000/d/lab-sensores) | as leituras que o Node-RED gravar, por MQTT ou direto |

Os dois painéis ficam em `lab-stack/grafana/provisioning/dashboards/`, junto
com o `dashboards.yml` que manda o Grafana carregar qualquer `.json` daquela
pasta. Essa pasta já é montada no container pelo `docker-compose.yml`, então
não é preciso mexer no compose para acrescentar um painel novo: basta soltar
o `.json` ali e reiniciar o Grafana.

### A demonstração que amarra tudo

Deixe o painel *Sensores* aberto, vá ao Node-RED e clique no inject 2 da aba
**MQTT**. A leitura é publicada no broker, a ponte da aba **InfluxDB** grava
no banco, e o ponto aparece no gráfico sozinho.

O que se quer que a turma perceba é que **ninguém liga o Node-RED ao
Grafana**: um escreve no InfluxDB, o outro lê do InfluxDB. O banco é o ponto
de encontro. É o mesmo desacoplamento do MQTT, uma camada acima.

## 9. Notas de manutenção (para o professor)

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

**Como reinstalar os materiais em uma VM nova** (do seu PC, assume o Port
Forwarding do Anexo já configurado):

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
(Anexo A.5).

## Observações

- Se algum serviço da seção 6 não abrir no navegador, confira os containers com
  `docker ps` (dentro da VM). A VM tem 2 GB de RAM, então dê 1 a 2 minutos
  depois de ligar antes de tentar.
- Se a VM não ligar e o VirtualBox reclamar de uma interface de rede (ex.:
  `Could not find host interface`), o adaptador do **Adapter 2** (Bridge) não
  existe no seu computador: escolha o Wi-Fi ou o Ethernet dele em **Settings >
  Network > Adapter 2 > Name** (passo 4 da seção 2).
- Como a VM é de uso coletivo, evite alterar a senha de `user`/`root` ou
  desligar o serviço SSH — outros colegas também vão importar e usar o mesmo
  `.ova`.
- Problemas de acesso pelo seu PC (SSH ou `localhost` não abrindo) são do
  Port Forwarding — veja a seção de troubleshooting no Anexo **"Acesso pelo
  seu PC via Port Forwarding"**.

---

## Anexo — Acesso pelo seu PC via Port Forwarding (opcional)

Todo o fluxo principal deste README funciona **inteiramente dentro da tela da
VM** (navegador, terminal, editores — passo 4). Esta seção é só para quem
prefere também abrir os serviços da VM, ou conectar por SSH, a partir do
terminal/navegador do próprio PC, em vez de usar a janela da VM.

### Regras de Port Forwarding

No VirtualBox, **Settings > Network > Adapter 1 > Advanced > Port
Forwarding**, estas regras (Protocolo `TCP`, Host IP `127.0.0.1`, Guest IP
em branco):

| Nome | Porta no seu PC (Host Port) | Porta na VM (Guest Port) |
|---|---|---|
| ssh | `2222` | `22` |
| nodered | `1880` | `1880` |
| grafana | `3000` | `3000` |
| portainer | `9000` | `9000` |
| influxdb | `8086` | `8086` |
| mysql | `3306` | `3306` |
| mqtt | `1883` | `1883` |
| mqttws | `9001` | `9001` |

Se a lista estiver vazia, rode no PowerShell, na pasta deste README (com a
VM ligada ou desligada), o script que cria todas de uma vez:

```powershell
powershell -ExecutionPolicy Bypass -File .\criar-regras-nat.ps1
```

> Se algum programa do seu PC já usa uma dessas portas (por exemplo, um
> MySQL local na `3306` ou um Mosquitto local na `1883`), troque só a
> **Host Port** dessa regra por outra (ex.: `13306`) e use a nova porta nos
> endereços do roteiro.

Com essas regras, os endereços da seção 6 funcionam iguais no navegador do
seu PC (`http://localhost:1880`, etc.).

### Conectar via SSH a partir do seu PC

```bash
ssh -p 2222 user@localhost
```

Digite a senha `user`. Se conectar sem erro, a VM está pronta. Para sair, use
`exit`.

> Se aparecer o aviso `REMOTE HOST IDENTIFICATION HAS CHANGED`, é porque você
> já conectou em outra VM pela mesma porta `2222` (chave diferente). Limpe o
> registro antigo com `ssh-keygen -R "[localhost]:2222"` e tente de novo.

### Teste de verificação via SSH

Volte para esta pasta no seu PC e rode (o terceiro argumento é a porta SSH):

```bash
./teste.sh localhost user 2222
```

O `ssh` vai pedir a senha do usuário (`user`). Digite-a e tecle Enter (ela não
aparece na tela enquanto você digita). A saída esperada é a mesma dos dois
comandos do passo 5, só que coletada automaticamente pelo script, terminando
em `TESTE PASSOU: VM pronta (Debian x86_64, acessível via SSH).`.

### Troubleshooting

- Se `ssh` recusar a conexão, confira se a VM já terminou de ligar (aguarde 1
  a 2 minutos) e se a regra `ssh` (`2222` → `22`) existe em **Settings >
  Network > Advanced > Port Forwarding**. Na tela da VM, o serviço pode ser
  verificado com `su -` (senha `root`) e depois `systemctl status ssh`.
- Se um endereço `localhost` não abre mas a VM está no ar, confira se a regra
  daquela porta existe (tabela acima) e se outro programa do PC não está
  usando a mesma porta.

---

## Anexo — Como a VM mestre foi criada (referência, não é necessário para o aluno)

Estes passos foram usados para montar a VM antes de exportá-la em `.ova`.
Ficam aqui só como referência, caso a VM mestre precise ser refeita.

### A.0 Instalar o VirtualBox

Baixe e instale em [virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
(versão para Windows). O aluno também precisa do VirtualBox instalado para
importar o `.ova` (passo 2 do fluxo principal, acima) — normalmente já vem
instalado nos computadores do laboratório.

### A.1 Baixar a imagem do Debian

Instalador `netinst` **amd64** (x86_64) em:
[debian.org/distrib/netinst](https://www.debian.org/distrib/netinst)

Arquivo típico: `debian-13.x.x-amd64-netinst.iso`.

### A.2 Criar a máquina virtual

No VirtualBox, **Machine > New**:

1. Nome: `debian`. Type: `Linux`. Version: `Debian (64-bit)`.
2. Memória: `2048 MB` (os containers da seção 6 precisam de mais que 1 GB) e
   `1` CPU (mais, se o computador permitir).
3. Disco: crie um disco virtual novo, pelo menos `20 GB` (as imagens Docker
   ocupam cerca de 2,5 GB).
4. Antes de iniciar, em **Settings > Storage**, monte o `.iso` baixado no
   passo A.1 na unidade óptica.
5. Em **Settings > Network**, configure duas placas:
   - **Adapter 1**: deixe **NAT** (o padrão) e crie as regras de *Port
     Forwarding* da tabela do Anexo **"Acesso pelo seu PC via Port
     Forwarding"**, acima. O jeito mais rápido é o script
     `criar-regras-nat.ps1` desta pasta (pode rodar com a VM ainda
     desligada). Ficam pré-configuradas no `.ova` para os alunos que
     quiserem usar esse caminho opcional, sem precisar rodar o script.
   - **Adapter 2**: marque **Enable Network Adapter**, **Attached to**
     **Bridged Adapter** e, em **Name**, o adaptador Wi-Fi ou Ethernet do
     computador. Pela linha de comando:
     `VBoxManage modifyvm debian --nic2 bridged --bridgeadapter2 "<nome do adaptador>"`.

### A.3 Instalar o Debian

1. Escolha **Install** (modo texto) — não precisa do modo gráfico.
2. Idioma, localização e teclado: como preferir.
3. Hostname: `debian`.
4. Crie a senha de `root` e um usuário comum (`user`).
5. Particionamento: **Guided - use entire disk** é suficiente.
6. **Seleção de software (`tasksel`):** desmarque **Debian desktop
   environment** e qualquer ambiente gráfico. Marque apenas:
   - `SSH server`
   - `standard system utilities`

   O `.ova` distribuído sai assim, sem interface gráfica — é o próprio aluno
   quem instala o XFCE, no passo 4 do fluxo principal.
7. Finalize a instalação e reinicie (remova o `.iso` da unidade óptica em
   **Settings > Storage** antes de reiniciar, se o instalador não fizer isso
   automaticamente).

### A.4 Configurar a segunda placa, instalar o Docker e subir a stack

**Segunda placa de rede (Bridge).** O Debian só configura sozinho a primeira
placa (`enp0s3`, o NAT). A segunda (`enp0s8`, o Bridge) aparece desligada e sem
IP: com a VM ligada, entre como root (`su -`) e acrescente ao final de
`/etc/network/interfaces`:

```
allow-hotplug enp0s8
iface enp0s8 inet dhcp
```

Depois rode `ifup enp0s8` e confira com `ip -4 -br a` (a `enp0s8` deve ter um IP
da rede). Fica ativa em todo boot. A saída para a internet continua pela placa
NAT (a rota padrão da `enp0s3` tem prioridade), então a VM acessa a internet
mesmo que a rede do laboratório não dê saída.

**Docker e stack.** Com a VM ligada e as regras de NAT criadas, copie a pasta `lab-stack/` deste
repositório para `/home/user/lab-stack` na VM (a partir do seu PC, na pasta do
README; note o `-P` maiúsculo do `scp` para a porta):

```bash
scp -P 2222 -r lab-stack user@localhost:~
```

Na VM, entre como root com **`su -`** (com o hífen; sem ele o PATH não inclui
`/usr/sbin` e o `usermod` falha) e instale o Docker:

```bash
su -
apt update
apt install -y docker.io docker-compose ca-certificates curl
usermod -aG docker user
systemctl enable --now docker
exit
```

Saia da sessão e entre de novo como `user` (para o grupo `docker` valer). Suba
a stack e instale os nós do Node-RED para InfluxDB e MySQL:

```bash
cd ~/lab-stack
docker compose up -d
docker exec nodered npm install --prefix /data node-red-contrib-influxdb node-red-node-mysql
docker restart nodered
```

Confira com `docker ps` (7 containers) e abra os endereços da seção 6. Os
containers têm `restart: unless-stopped` e o Docker fica habilitado, então tudo
sobe sozinho quando a VM liga.

### A.5 Exportar para .ova

Com a VM instalada, testada e desligada (deixe o **Adapter 1** em **NAT** com
as regras de *Port Forwarding* e o **Adapter 2** em **Bridged Adapter**):

1. **File > Export Appliance...**
2. Selecione a VM `debian` e clique em **Next**.
3. Formato do arquivo: **OVA 2.0** (mais simples de distribuir, um arquivo só).
4. Escolha o destino e clique em **Next** para ver as opções do appliance
   (os nomes podem variar um pouco conforme a versão do VirtualBox):
   - **MAC Address Policy:** escolha **Strip all network adapter MAC
     addresses**. O `.ova` sai sem MAC, e cada aluno que importa recebe um
     MAC novo. É isso que evita MACs repetidos entre as VMs da turma (veja a
     nota do passo 2 do fluxo principal).
   - **Write Manifest file:** **marque**. Grava os hashes (SHA) dos arquivos,
     e o VirtualBox confere na importação se o `.ova` chegou íntegro (útil ao
     copiar pela pasta compartilhada ou pendrive).
   - **Include ISO image files:** **não marque**. A unidade óptica da VM já
     deve estar vazia, e incluir o `.iso` do instalador só aumentaria o
     arquivo.
5. Clique em **Export**.
6. Copie o `.ova` gerado para a pasta compartilhada do laboratório, de onde
   os alunos vão copiá-lo (passo 1 do fluxo principal, acima). Copie também o
   `criar-regras-nat.ps1`, para o caso de as regras de *Port Forwarding* não
   virem dentro do `.ova`.
7. **Teste a importação** antes de distribuir: importe o `.ova` como uma VM
   nova (por exemplo `debian-teste`), confira em **Settings > Network >
   Advanced > Port Forwarding** se as 8 regras vieram, escolha o adaptador do
   **Adapter 2** (Bridge) e, depois de ligar, confira se `localhost:1880` abre e
   se a `enp0s8` recebeu um IP (`ip -4 -br a`). Depois apague a VM de teste em
   **Remove > Delete all files**.

### A.6 Instalar o VS Code (opcional)

Com o XFCE já instalado (passo 4 do fluxo principal), dá para usar o VS Code
direto na VM, pela própria tela, sem editor remoto nem SSH. Comando usado
(repositório oficial da Microsoft — precisa da VM ter saída à internet pela
NAT):

```bash
su -
apt update
apt install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
rm -f /tmp/packages.microsoft.gpg
apt update
apt install -y code
```

> Por vir de repositório (não de um `.deb` avulso), `apt upgrade` mantém o
> VS Code atualizado junto com o resto do sistema — diferente do MySQL
> Workbench (passo 4), que precisa baixar um `.deb` novo a cada versão.
> Abre pelo menu de aplicativos do XFCE ou digitando `code` num terminal.
