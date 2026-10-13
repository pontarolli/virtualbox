# Laboratório Redes de Computadores — Servidor local (VirtualBox)

Esta VM é de uso coletivo (compartilhada pela turma): ela já vem pronta, num
arquivo `.ova`, e você só precisa importá-la no seu VirtualBox. **O uso é
inteiramente pelo terminal e pelo navegador do seu próprio PC** — a VM roda
em modo texto, sem interface gráfica (propositalmente, para ficar leve), e
você nunca precisa abrir a janela dela: conecta por SSH e abre os serviços em
`http://localhost:porta` como se fossem do seu próprio computador. O acesso
já vem pronto, sem nenhuma configuração extra de rede (seção 4).

| Item | Valor |
|---|---|
| Hipervisor | Oracle VirtualBox |
| Sistema operacional da VM | Debian 13 (x86_64), instalação `netinst`, modo texto (sem interface gráfica) |
| Rede da VM | **NAT**, com *Port Forwarding* já configurado (seção 4) |
| Usuário do sistema (login via SSH) | `user` |
| Senha do usuário `user` | `user` |
| Conta `root` | desabilitada — administração é só via `sudo` com o usuário `user` |
| Containers Docker | Portainer, Node-RED, Mosquitto (MQTT), MySQL Server, InfluxDB e Grafana (seção 5) |

> Mesmo sistema operacional e arquitetura da VM na nuvem (veja a pasta
> `../cloud`): Debian x86_64. Assim os comandos que você aprender aqui
> funcionam sem alteração na VM da Oracle Cloud.

## O que tem nesta pasta

| Caminho | O que é |
|---|---|
| `README.md` | este arquivo: importar, ligar, usar e manter a VM |
| `vm-padrao/lab.ova` | a VM pronta, para importar no VirtualBox |
| `criar-regras-nat.ps1` | recria as regras de *Port Forwarding*, caso não venham no `.ova` (seção 4) |
| `criar-vm-debian.ps1` | cria e instala a VM mestre automaticamente, sem telas manuais do instalador (`MANUTENCAO.md`, Anexo A.2-A.3) |
| `debian-preseed.template` | preseed usado por `criar-vm-debian.ps1` (cópia do template padrão do VirtualBox, editável) |
| `pos-instalacao-manual.sh` | instala sudo/Docker/docker-compose depois de uma instalação manual do Debian (`MANUTENCAO.md`, Anexo A.2-A.3 alternativa) |
| `teste.sh` | script opcional de teste de verificação por SSH (login, SO, arquitetura) |
| `lab-stack/` | o `docker-compose.yml` e a configuração de todos os containers |
| `db-stack/` | stack mínima (só MySQL) para a disciplina de Banco de Dados |
| `lab-stack/telegraf/` | configuração do Telegraf (métricas da VM — seção 5.1) |
| `lab-stack/grafana/provisioning/` | *data sources* e painéis do Grafana, carregados automaticamente |
| `nodered/` | as abas de exemplo do Node-RED e o roteiro de aula (seção 6) |
| `debian-13.7.0-amd64-netinst.iso` | instalador usado para montar a VM mestre (`MANUTENCAO.md`, Anexo A.1) |
| `MANUTENCAO.md` | notas de manutenção e como a VM mestre foi criada (referência, só para o professor) |

## 1. Copiar o arquivo .ova da pasta compartilhada do laboratório

Copie o arquivo `lab.ova` de:

`[CAMINHO_DA_PASTA_COMPARTILHADA]`

para uma pasta no seu computador (ex.: `Documentos\lab-redes\`).

> **Como esse `.ova` foi gerado (referência, você não precisa repetir isso):**
> a VM mestre foi criada e o Debian instalado normalmente no VirtualBox e,
> depois de pronta, exportada em **File > Export Appliance...**, selecionando
> a VM, formato **OVA 2.0**, e clicando em **Export**. Os detalhes completos
> de como a VM mestre foi montada estão em [`MANUTENCAO.md`](MANUTENCAO.md).

## 2. Importar a VM no VirtualBox

No VirtualBox, **File > Import Appliance...**:

1. Clique no ícone de pasta e selecione o arquivo `lab.ova` copiado no
   passo anterior.
2. Clique em **Next**, confira as configurações sugeridas (nome, memória,
   disco) e clique em **Import**.
3. Aguarde a importação terminar — a VM `lab` aparece na lista à
   esquerda do VirtualBox.
4. Antes de ligar, confira em **Settings > Network > Adapter 1** que está
   marcado **Enabled** e **Attached to: NAT** (é o padrão do `.ova`, não
   deve ser preciso mexer em nada). O *Port Forwarding* já vem configurado —
   veja a seção 4.

## 3. Ligar a VM

Inicie a VM (**Start**) e aguarde de 1 a 2 minutos: o Debian liga e os
containers sobem sozinhos. A VM abre numa janela própria, com um prompt de
login em modo texto — pode deixar essa janela minimizada. Daqui em diante
você trabalha pelo terminal e navegador do seu PC (seção 4), não precisa
digitar nada direto nessa janela.

## 4. Acessar a VM pelo seu PC (SSH e navegador)

A VM já vem com as regras de *Port Forwarding* configuradas no Adapter 1
(NAT), então basta usar `localhost` e as portas abaixo, direto do terminal e
do navegador do seu PC:

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

Se alguma dessas regras não vier no `.ova` (confira em **Settings > Network >
Adapter 1 > Advanced > Port Forwarding**), rode no PowerShell, na pasta deste
README (com a VM ligada ou desligada), o script que cria todas de uma vez:

```powershell
powershell -ExecutionPolicy Bypass -File .\criar-regras-nat.ps1
```

> Se algum programa do seu PC já usa uma dessas portas (por exemplo, um
> MySQL local na `3306` ou um Mosquitto local na `1883`), troque só a
> **Host Port** dessa regra por outra (ex.: `13306`) e use a nova porta nos
> endereços do roteiro.

### Conectar via SSH

```bash
ssh -p 2222 user@localhost
```

Digite a senha `user`. Se conectar sem erro, a VM está pronta. Para sair, use
`exit`. É por aqui que você digita os comandos das seções seguintes (`docker
ps`, etc.).

> Se aparecer o aviso `REMOTE HOST IDENTIFICATION HAS CHANGED`, é porque você
> já conectou em outra VM pela mesma porta `2222` (chave diferente). Limpe o
> registro antigo com `ssh-keygen -R "[localhost]:2222"` e tente de novo.

> Atalho opcional: `./teste.sh localhost user 2222` (o terceiro argumento é a
> porta SSH) confere pelo seu PC se a VM é mesmo um Debian 13 x86_64
> acessível via SSH, sem precisar digitar nada manualmente na VM.

### Abrir os serviços no navegador

Com as regras acima, os endereços da seção 5 funcionam iguais no navegador do
seu PC (`http://localhost:1880`, etc.) — não precisa abrir a janela da VM.

## 5. Serviços da VM (containers Docker)

A VM já vem com o Docker, o Docker Compose e sete containers prontos. Seis
ficam na mesma rede Docker (`lab-net`) e um, o Telegraf, roda na rede da
própria VM (veja a seção 5.1). Eles iniciam sozinhos quando a VM liga — leva
1 a 2 minutos depois de ligar para tudo ficar pronto.

Abra no navegador **do seu PC** (seção 4):

| Serviço | Para que serve | Endereço (no seu PC) | Login |
|---|---|---|---|
| Node-RED | Fluxos de automação | `http://localhost:1880` | sem login |
| Grafana | Painéis e gráficos | `http://localhost:3000` | `root` / `Standard@123` |
| Portainer | Gerenciar os containers pelo navegador | `http://localhost:9000` | `admin` / `Standard@123` |
| InfluxDB 2 | Banco de séries temporais | `http://localhost:8086` | `root` / `Standard@123` |
| MySQL Server | Banco relacional | `localhost:3306` | `root` / `Standard@123` (admin) ou `user` / `Standard@123` (banco `lab_mysql`) |
| Mosquitto | Broker MQTT | `localhost:1883` (WebSocket: `9001`) | sem login |

Dados do InfluxDB: organização `lab`, bucket `lab`, token `Standard@123`
(mesma senha usada nos outros serviços). Estas senhas são só para o
laboratório.

O MySQL Server é o único banco relacional da stack (`mysql:8.0`). Dentro da
VM, pela rede `lab-net`, os outros containers o alcançam pelo nome `mysql`
na porta `3306` — é assim que a aba **MySQL** do Node-RED se conecta a ele
(veja [`nodered/README.md`](nodered/README.md)).

O Grafana já vem com dois painéis prontos (menu **Dashboards**):

| Painel | O que mostra |
|---|---|
| **Laboratório de Redes — VM (Telegraf)** | CPU, memória, disco, rede e uso por container, da própria VM |
| **Laboratório de Redes — Sensores (InfluxDB)** | as leituras que o Node-RED gravar, por MQTT ou direto |

### 5.1 Telegraf — as métricas da VM

O sétimo container é o **Telegraf**: a cada 10 segundos ele lê CPU, memória,
disco, rede, uptime e o consumo de cada container, e grava tudo no mesmo
bucket `lab` do InfluxDB. Não tem interface própria — você o vê pelo painel
*VM (Telegraf)* no Grafana.

Ele é a exceção da stack, e isso rende boa discussão em aula:

- **`network_mode: host`** — fica na rede da própria VM, não na `lab-net`. É
  o que faz as métricas de rede serem da interface real da VM (`enp0s3`, o
  NAT) em vez das do container. Como consequência, o endereço do InfluxDB no
  `telegraf.conf` é `localhost:8086` e não `influxdb:8086` — o oposto da
  regra que vale para os outros containers.
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

### Comandos úteis (via SSH, logado como `user`)

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

## 6. Materiais de aula prontos na VM

A VM já vem com quatro abas de exemplo no Node-RED e dois painéis no
Grafana. Tudo está versionado nesta pasta, então dá para reinstalar ou
levar para outra VM.

### Node-RED — quatro abas (<http://localhost:1880>)

| Aba | Assunto | Como usar |
|---|---|---|
| **Blocos básicos** | `function`, `change`, `switch`, `template`, `split`/`join`, `delay` | seis exemplos independentes; clique no inject e compare entrada e saída no Debug |
| **MQTT** | publicar e assinar no Mosquitto, curingas `#` e `+` | publicadores em cima, assinantes embaixo |
| **InfluxDB** | gravar séries temporais e consultar com Flux | inclui uma ponte MQTT → InfluxDB |
| **MySQL** | cheat sheet de SQL (27 consultas em três níveis), listar bancos/tamanhos/tabelas e um CRUD completo (`authors`/`books`) — tudo contra o container `mysql` da própria VM | cheat sheet: rode o inject **0** primeiro, depois qualquer exemplo em qualquer ordem; listagens: três injects independentes; CRUD: injects **na ordem de 0 a 9** |

Cada aba tem a explicação completa na sua própria guia **Info** (painel da
direita no Node-RED). Os arquivos `.json`, o roteiro de aula detalhado e o
script de instalação estão em [`nodered/`](nodered/README.md).

> A aba **MySQL** conecta sempre ao container `mysql` da própria stack
> (seção 5) — nome do serviço, sem NAT nem endereço especial — então
> funciona para qualquer um assim que o `docker-compose.yml` for aplicado.
> A guia **Info** da aba traz, só como anotação de referência (não é um nó
> configurado), como conectar opcionalmente ao MySQL do seu próprio PC
> Windows em vez do da VM, para quem quiser explorar isso por conta
> própria. Detalhes completos em [`nodered/README.md`](nodered/README.md).

Sugestão de ordem: **Blocos básicos → MQTT → InfluxDB → MySQL**. Os dois
primeiros se encadeiam.

### Grafana — dois painéis (<http://localhost:3000>)

| Painel | O que mostra |
|---|---|
| [**VM (Telegraf)**](http://localhost:3000/d/lab-vm) | CPU, memória, disco, rede e consumo por container, da própria VM |
| [**Sensores (InfluxDB)**](http://localhost:3000/d/lab-sensores) | as leituras que o Node-RED gravar, por MQTT ou direto, **e também** uma tabela direto do MySQL — a prova de que InfluxDB e MySQL convivem no mesmo dashboard |

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

O mesmo painel *Sensores* também tem uma tabela ligada ao **MySQL**
(`data source` **MySQL**, já configurado): rode o inject **0** do cheat
sheet de SQL (aba MySQL) para criar e popular `cursos`/`alunos`/
`matriculas`, clique em Refresh no painel, e a tabela aparece ao lado dos
gráficos do InfluxDB. A ideia a passar para a turma: o Grafana não é só
para séries temporais — qualquer *data source* configurado (relacional,
série temporal, o que for) pode virar painel na mesma tela.

## Observações

- Se algum serviço da seção 5 não abrir no navegador, confira os containers com
  `docker ps` (via SSH). A VM tem 2 GB de RAM, então dê 1 a 2 minutos
  depois de ligar antes de tentar.
- Como a VM é de uso coletivo, evite alterar a senha de `user` ou desligar o
  serviço SSH — outros colegas também vão importar e usar o mesmo `.ova`.
- Problemas de acesso pelo seu PC (SSH ou `localhost` não abrindo) costumam
  ser do *Port Forwarding* — veja a seção 4, em especial a checagem das
  regras e o `criar-regras-nat.ps1`.

---

Para o professor: notas de manutenção da stack e o passo a passo de como a VM
mestre foi criada (para remontá-la ou atualizá-la) estão em
[`MANUTENCAO.md`](MANUTENCAO.md).
