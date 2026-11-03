# Flows de exemplo do Node-RED (laboratório de Redes)

Sete abas prontas para aula, cada uma claramente marcada como **Prática**
(exploração livre, sem efeito no projeto) ou **Projeto** (fica ligada —
é o que alimenta o painel do Grafana). Todas já estão instaladas no
Node-RED da VM (<http://localhost:1880>); os arquivos abaixo servem para os
alunos importarem e para reinstalar.

| # | Arquivo | Aba no Node-RED | Tipo | Assunto |
|---|---|---|---|---|
| 0 | `flow-0-comece-aqui.json` | **0 - Comece aqui** | guia | roteiro numerado com links clicáveis para o Node-RED, o InfluxDB e o Grafana |
| 1 | `flow-blocos-basicos.json` | **1 - Prática: Blocos básicos** | Prática | `function`, `change`, `switch`, `template`, `split`/`join`, `delay` |
| 2 | `flow-mqtt.json` | **2 - Prática: MQTT** | Prática | publicar e assinar no Mosquitto, curingas `#` e `+` |
| 3 | `flow-sensor-continuo.json` | **3 - Projeto: Sensor automático** | Projeto | publica a leitura da `sala-01` sozinho, a cada 10 s |
| 4 | `flow-influxdb-ponte.json` | **4 - Projeto: Ponte → InfluxDB** | Projeto | assina `lab/sensor/+` e grava cada leitura no InfluxDB, sozinha |
| 5 | `flow-influxdb-pratica.json` | **5 - Prática: InfluxDB** | Prática | gravar manualmente, consultar e agregar com Flux |
| 6 | `flow-mysql.json` | **6 - Extra: MySQL** | extra | cheat sheet de SQL, listagens e um CRUD completo — tudo no MySQL da própria VM |
| — | `subir-flow.ps1` | — | — | envia todos os flows acima para o Node-RED da VM |

**Por que duas abas de InfluxDB?** A aba **4 - Projeto** é só a ponte —
três nós, sem interface, que ficam ouvindo o Mosquitto e gravando no banco.
Ela precisa estar sempre ligada, mas não tem nada para o aluno clicar. A
aba **5 - Prática** é onde se aprende InfluxDB de verdade (gravar, consultar,
agregar em Flux) e pode ser ligada e desligada à vontade sem afetar o
projeto.

## O painel "0 - Comece aqui"

A primeira aba do Node-RED não é um fluxo de dados: é um roteiro. Abra a
aba, clique no node de comentário **"COMECE AQUI"** e olhe o painel
**Info** à direita (ícone <kbd>i</kbd>, ou <kbd>Ctrl+I</kbd> depois de
clicar em um node) — ele mostra uma lista numerada (1 a 9) com links
clicáveis para abrir o InfluxDB e o Grafana numa aba nova do navegador, na
mesma ordem do livro. As abas **4 - Projeto** e **3 - Projeto** também têm
um atalho pequeno com os mesmos dois links, para não precisar voltar até a
aba 0 toda vez.

## Instalar na VM

A VM precisa estar ligada, com a regra de NAT `nodered` (`1880` → `1880`).

**Pelo navegador (o que o aluno faz):** abra <http://localhost:1880>, menu
☰ → **Import** → **select a file to import** → escolha o `.json` →
**Import** → **Deploy**. Depois preencha as credenciais nos nós de
configuração (veja a tabela no fim deste arquivo) — o Node-RED **nunca**
exporta senhas junto com o flow.

> **"Some of the nodes you are importing already exist in your
> workspace."** Isso é esperado se a aba já estiver instalada (a VM da
> turma já vem com todas) e você está reimportando como referência ou para
> recuperar algo que estragou. Clique em **Import copy**: o Node-RED cria
> uma cópia nova, com ids diferentes, numa aba separada — nada do que já
> existia é apagado ou alterado. Depois é só comparar as duas abas e
> apagar a que não quiser. Testado nesta VM antes de entrar neste guia.

**Pelo PowerShell (já com as senhas):** na pasta deste README,

```powershell
powershell -ExecutionPolicy Bypass -File .\subir-flow.ps1
```

Envia todos os `flow-*.json`. Para um só: `-Arquivo .\flow-mqtt.json`.

> **Credenciais diferentes por nó de configuração.** O script decide pelo
> `db` do nó `MySQLdatabase`: o banco `lab_mysql` (pré-criado, usado pelo
> cheat sheet dentro da aba **MySQL**) usa a conta comum `user`; qualquer
> outro banco — o banco de sistema `mysql` ou o schema novo
> `lab_nodered_crud` (listagens e CRUD, também na aba **MySQL**) — usa
> `root`, por precisar criar/derrubar tabelas e schemas.
>
> **Cada arquivo tem seus próprios nós de broker/InfluxDB, com ids
> exclusivos.** Diferente de uma versão anterior deste material, nenhum
> `.json` distribuído aqui compartilha o `id` de um nó de configuração com
> outro arquivo — mesmo que dois arquivos conectem no mesmo Mosquitto ou
> InfluxDB. Isso significa que você pode importar qualquer combinação deles,
> em qualquer ordem, sem risco de um "duplicate id" travar o deploy. Na VM
> já pronta da turma, por simplicidade, essas abas compartilham um único nó
> de configuração por serviço (é mais limpo de olhar); ao importar os
> arquivos avulsos, cada um traz sua própria cópia, funcionalmente
> idêntica.

---

## Aba 1 Prática: Blocos básicos

Seis exemplos independentes, um por linha. Clique no `inject` e compare o
que entrou com o que saiu, na aba **Debug**.

| # | Nó | O que mostra |
|---|---|---|
| 1 | `function` | JavaScript: transforma `msg` e retorna |
| 2 | `change` | set / move / delete de propriedades, **sem código** |
| 3 | `switch` | roteia por saídas diferentes conforme uma condição |
| 4 | `template` | monta texto com `{{mustache}}` |
| 5 | `split` + `join` | quebra uma lista em várias mensagens e junta de volta |
| 6 | `delay` | atrasa (e sabe limitar a vazão de) mensagens |

A ideia central é a **mensagem**: tudo que anda pelos fios é um objeto
`msg`, com os dados em `msg.payload` e o assunto em `msg.topic`. O contraste
`change` × `function` costuma render discussão: prefira o `change` quando
for só mexer em campos, e o `function` quando precisar de lógica.

## Aba 2 Prática: MQTT

Publicadores em cima (`mqtt out`), assinantes embaixo (`mqtt in`). Broker:
container `mosquitto` da stack.

1. Inject **1** publica texto em `lab/teste` → chega no debug **A**.
2. Inject **2** publica um JSON em `lab/sensor/sala-01` → chega em **A** e
   em **B**.

Pontos a explicar: o tópico pode estar configurado no nó (inject 1) ou vir
de `msg.topic` (inject 2); `#` casa com qualquer número de níveis e `+` com
exatamente um; publicação e assinatura são desacopladas.

> **Por que dois nós de broker?** Quando um mesmo cliente MQTT tem dois
> filtros que casam com o mesmo tópico (`lab/#` e `lab/sensor/+`), o broker
> entrega **uma cópia por filtro** e a mensagem apareceria duplicada. Por
> isso o assinante `lab/#` usa uma segunda conexão. Cada assinante é um
> cliente MQTT independente, como seria na vida real.

## Aba 3 Projeto: Sensor automático

É o início do projeto: o mesmo sensor da aba **2 - Prática: MQTT**
(Fluxo 2), só que publicando sozinho a cada 10 segundos, em vez de esperar
um clique no `inject`. Um único fluxo, três nós:

1. `inject` **"Sensor automático (repete a cada 10s)"** — dispara uma vez ao
   dar Deploy e depois se repete a cada 10 s (campo *Repeat*);
2. `function` **"simula sensor oscilando (seno)"** — gera temperatura e
   umidade variando em **onda** (`Math.sin`/`Math.cos`), não só em ruído
   aleatório, para o gráfico do Grafana mostrar uma curva visível subindo e
   descendo, em vez de picos sem padrão;
3. `mqtt out` **"publica lab/sensor/sala-01"** — mesmo tópico da aba MQTT
   (tópico vem de `msg.topic`).

Sozinha, esta aba não grava nada em banco algum — ela só publica no
Mosquitto. Quem grava é a aba **4 - Projeto: Ponte → InfluxDB**, a seguir.
Dê Deploy nas duas e deixe ambas ligadas: é a combinação que faz o painel
**Sensores (InfluxDB)** do Grafana oscilar sozinho.

**Testado nesta VM** (`lab.ova`): depois do Deploy, quatro leituras
consecutivas gravadas no InfluxDB a ~10 s de intervalo
(`25.5 → 24.1 → 22.8 → 21.6 °C`), confirmando a oscilação automática antes
deste flow ser distribuído.

> Para voltar ao modo manual (clique a clique), basta desligar esta aba
> (clique direito na aba → **Disable Flow**); a aba MQTT continua
> publicando do mesmo jeito, sem depender desta.

## Aba 4 Projeto: Ponte → InfluxDB

Três nós, sem nada para clicar: um `mqtt in` assina `lab/sensor/+`, um
`function` converte o payload do MQTT para o formato que o InfluxDB espera
e um `influxdb out` grava. Esta aba é a peça que faz o projeto funcionar —
deixe-a **sempre ligada**. Ela grava tanto o que a aba **3 - Projeto:
Sensor automático** publica sozinha quanto qualquer clique manual no
inject 2 da aba **2 - Prática: MQTT**.

Banco de **série temporal**: cada ponto tem horário, *fields* (valores
medidos) e *tags* (rótulos para filtrar e agrupar). O formato da escrita é
`msg.payload = [ {fields}, {tags} ]`.

### Fechando o ciclo no Grafana

Há um dashboard de exemplo pronto em
<http://localhost:3000/d/lab-sensores> (login `root` / `Standard@123`), com
cinco painéis sobre o bucket `lab`: temperatura e umidade por sensor ao
longo do tempo, última leitura, média do período e uma tabela das últimas 20
leituras. Atualiza a cada 10 s. Mais abaixo no mesmo dashboard tem ainda uma
sexta tabela, agora contra o MySQL — veja "Dá pra misturar bancos no mesmo
painel?", na seção da aba **6 - Extra: MySQL**.

A ideia a passar para a turma é que **ninguém liga o Node-RED ao Grafana**:
o Node-RED escreve no InfluxDB, o Grafana lê do InfluxDB, e o banco é o
ponto de encontro. Dá para demonstrar ao vivo — deixe o dashboard aberto,
deixe a aba **3 - Projeto: Sensor automático** ligada (ou clique no inject
2 da aba **2 - Prática: MQTT**) e veja o ponto aparecer no gráfico.

O dashboard está versionado em
`../lab-stack/grafana/provisioning/dashboards/`, junto com o
`dashboards.yml` que manda o Grafana carregar todo `.json` daquela pasta.
Essa pasta já é montada no container pelo `docker-compose.yml`, então para
instalar em uma VM nova basta copiar o `lab-stack/` e reiniciar o Grafana:

```bash
scp -P 2222 -r lab-stack user@localhost:~
ssh -p 2222 user@localhost "cd ~/lab-stack && docker compose restart grafana"
```

> Os painéis apontam para o *data source* pelo `uid`
> (`P951FEA4DE68E13C5`), que o Grafana gera a partir do nome `InfluxDB` do
> `datasources.yml` — é estável entre instalações iguais. Se em alguma VM o
> painel aparecer vazio com erro de data source, confira o `uid` em
> **Connections → Data sources → InfluxDB** e ajuste no `.json`.

## Aba 5 Prática: InfluxDB (consultas Flux)

Fluxos manuais para aprender o banco por conta própria. Nada aqui precisa
ficar ligado para o projeto funcionar — quem faz isso é a aba **4 -
Projeto: Ponte → InfluxDB**, anterior.

1. Inject **1** grava uma única leitura, na hora do clique.
2. Inject **2** grava 20 leituras espalhadas nos últimos 20 minutos
   (sensor `sala-02`, para o gráfico ter duas linhas).
3. Inject **3** consulta com Flux e mostra as linhas no Debug.
4. Inject **4** calcula a média por sensor — a conta roda **no banco**.

O Flux é um *pipeline* (`from` → `range` → `filter` → agregação), bem
diferente de SQL, e a janela de tempo em `range` é obrigatória. Vale
contrastar com a aba MySQL: o Influx guarda medições ao longo do tempo, o
MySQL guarda cadastros e relações.

## Aba 6 Extra: MySQL

MySQL Server rodando como **mais um container da stack** (`mysql:8.0`,
serviço `mysql` no `lab-stack/docker-compose.yml`), na mesma rede `lab-net`
que todos os outros. A aba tem três partes: um cheat sheet de SQL,
listagens rápidas e um CRUD completo.

### Cheat sheet de SQL (injects 0, e 1.1 a 3.10)

Material de consulta: 27 exemplos de SQL em três níveis, sobre um esquema de
escola (`cursos`, `alunos`, `matriculas` — 8 alunos, 4 cursos, 16
matrículas), num banco próprio, `lab_mysql`. **Rode o inject 0 primeiro**,
para criar e popular as tabelas; depois clique em qualquer exemplo, em
qualquer ordem. No Debug, o `topic` mostra o SQL executado e o `payload`
mostra o resultado — é o que faz a aba servir como cola.

| Nível | O que cobre |
|---|---|
| **1 · Iniciante** (9) | `SELECT` + `WHERE`, `LIKE`/`BETWEEN`/`IN`/`IS NULL`, `ORDER BY` + `LIMIT`, `DISTINCT`, `COUNT`/`MIN`/`MAX`, `INSERT`, `UPDATE`, `DELETE` |
| **2 · Médio** (8) | `INNER JOIN` de 3 tabelas, `LEFT JOIN` + `IS NULL`, `GROUP BY`, `HAVING`, subconsulta no `WHERE` e na lista de colunas, `CASE WHEN`, funções de texto/data/nulo |
| **3 · Avançado** (10) | CTE (`WITH`), `RANK() OVER (PARTITION BY)`, `AVG() OVER`, `NOT EXISTS`, `GROUP_CONCAT`/`JSON_ARRAYAGG`, upsert, `VIEW`, índice e `EXPLAIN` |

Os dados foram montados para os exemplos terem o que mostrar: *Heitor Pinto*
não tem matrícula (aparece no `LEFT JOIN`) e duas matrículas estão sem nota
(aparecem no `IS NULL` e no `COALESCE`). O inject 0 derruba e recria tudo, então
a aula pode ser repetida à vontade. A aba *Info* traz ainda cinco exercícios
propostos.

Dois pontos que valem destaque: `WHERE` filtra **linhas** e `HAVING` filtra
**grupos** — por isso `HAVING` pode usar `AVG()` e `WHERE` não; e funções de
janela (`OVER`) agregam **sem** colapsar as linhas, que é o que permite
ranquear e comparar cada linha com a média do próprio grupo.

> **Ordem de execução:** o nó `mysql` executa uma instrução por mensagem, e
> quando várias chegam juntas o *pool* de conexões pode executá-las fora de
> ordem. Por isso o inject 0 do cheat sheet usa o padrão "próximo comando":
> só envia o seguinte depois que o anterior voltou. Pelo mesmo motivo,
> transações (`START TRANSACTION`/`COMMIT`) não funcionam bem por aqui —
> para isso, use uma *stored procedure* e chame com `CALL`.

### Dá pra misturar bancos no mesmo painel?

Sim. O dashboard **Sensores (InfluxDB)** (seção da aba InfluxDB, acima) tem
uma tabela a mais, ligada ao *data source* **MySQL** (também já configurado
em Connections → Data sources), rodando a mesma consulta do exemplo 2.3 do
cheat sheet (matrículas e média por curso) direto no banco `lab_mysql`.
Rode o inject **0** do cheat sheet primeiro, para criar e popular as
tabelas, depois clique em **Refresh** no dashboard — a tabela do MySQL
aparece ao lado dos gráficos do InfluxDB, na mesma tela. É a demonstração de
que o Grafana não serve só para séries temporais: qualquer *data source*
configurado pode virar painel, InfluxDB e MySQL inclusive, lado a lado.

### Listar bancos (injects 1 a 3)

Três injects independentes, todos usando `information_schema`:

| Inject | O que mostra |
|---|---|
| 1 | `SHOW DATABASES` — nomes de todos os bancos |
| 2 | tamanho (MB) e nº de tabelas de cada banco |
| 3 | todas as tabelas de todos os bancos (exceto `information_schema`, `mysql`, `performance_schema`, `sys`) |

O container já vem com um banco de exemplo, `lab_mysql` (criado pelas
variáveis `MYSQL_DATABASE`/`MYSQL_USER` do `docker-compose.yml`), só para a
lista não aparecer vazia na primeira vez.

### CRUD bookstore (injects 0 a 9)

Exemplo `bookstore` (tabelas `authors` e `books`), **num schema novo e
isolado**, `lab_nodered_crud`, para não mexer no banco `lab_mysql` que o
cheat sheet (acima) usa. Clique nos injects **na ordem de 0 a 9**:

| Passo | Operação | SQL |
|---|---|---|
| 0 | preparar | `CREATE DATABASE IF NOT EXISTS lab_nodered_crud` |
| 1 | preparar | `DROP TABLE` + `CREATE TABLE authors` e `books` |
| 2 | **C**reate | `INSERT INTO authors` (Franz Kafka) |
| 3 | **C**reate | `INSERT INTO books` — 4 livros de uma vez |
| 4 | **R**ead | `SELECT ... JOIN authors USING (author_id) WHERE ...` |
| 5 | **U**pdate | `UPDATE books SET title` — *America* vira *Amerika* |
| 6 | **R**ead | confere o UPDATE |
| 7 | **D**elete | `DELETE FROM books` — remove *The Trial* |
| 8 | **R**ead | confere o DELETE (sobram 3 livros) |
| 9 | limpar | `DROP TABLE` — o schema `lab_nodered_crud` fica, só as tabelas somem |

O passo 0 usa uma conexão à parte, apontada para o banco `mysql` (que
sempre existe) — não dá para criar um schema estando "dentro" dele antes de
ele existir. Os passos 1 a 9 usam uma segunda conexão, já apontada direto
para `lab_nodered_crud`. As duas conexões autenticam como `root` /
`Standard@123` — diferente das listagens e do cheat sheet (conta comum
`user`), aqui é preciso criar e derrubar tabelas e o próprio schema, algo
que a conta comum não tem permissão para fazer.

> **Cuidado com o `props` do inject quando o SQL vai no `topic`.** O nó
> `inject` só manda para a mensagem as propriedades listadas em `props`; se
> o SQL estiver no campo Topic do inject mas `topic` não estiver marcado em
> `props`, o `msg.topic` sai vazio e o `mysql` não executa nada — sem erro
> visível. Foi exatamente o bug do passo 0 na primeira versão desta aba.
> Compare os injects 2, 3, 4, 5 e 7 (SQL direto no `topic`, `props` inclui
> `topic`) com os passos 0, 1 e 9 (passam por um `function`, que monta o
> `msg.topic` sozinho — aí o `props` do inject só precisa do `payload`, só
> para disparar).

### Por que o host é só `mysql`

Aqui não tem NAT nem endereço especial: o container `mysql` está na mesma
rede Docker `lab-net` que o Node-RED, então vale a regra normal da stack —
containers se encontram pelo **nome do serviço**. É `mysql:3306`, do mesmo
jeito que as outras abas já usam `influxdb:8086` ou `mosquitto:1883`.

### Acesso de fora da VM (opcional)

O container também publica a porta `3306` (guest) → `3306` (host da VM),
então de **dentro da VM** dá pra inspecionar com `mysql -h127.0.0.1 -P3306
-uroot -p`. Isso também pode ser aberto no **PC Windows** (ex.: MySQL
Workbench, `localhost:3306`) — regra `mysql` de Port Forwarding, opcional,
no Anexo "Acesso pelo seu PC via Port Forwarding" do README da pasta acima.

### Quer conectar no MySQL do seu próprio PC em vez do da VM? (opcional)

Isso não vem configurado por padrão — depende de cada aluno ter um MySQL
local rodando, o que nem todo mundo tem. Para quem quiser mesmo assim,
basta criar um nó de configuração MySQL próprio (arraste um nó `mysql`
novo) apontando para:

- **Host:** `10.0.2.2` — apelido fixo que o VirtualBox dá para o PC
  hospedeiro, visto de dentro da VM, quando o Adapter 1 está em NAT (não
  precisa de regra de Port Forwarding nesse sentido, VM → PC já vem
  liberado pelo próprio NAT; o tráfego chega como se fosse `127.0.0.1`, o
  que também destrava usuários como `root`, que só aceitam conexões
  locais).
- **Porta:** `3306` (requer MySQL do Windows escutando em todas as
  interfaces — `bind-address = *` ou `0.0.0.0`, não só `127.0.0.1` — e o
  serviço rodando).
- **Usuário/senha:** os do MySQL instalado no próprio PC.

Isso é só uma anotação de referência — não existe nenhum nó configurado com
esse endereço nesta aba (veja também a guia *Info* da aba, dentro do
Node-RED).

---

## Credenciais usadas pelos flows

| Nó de configuração | Endereço | Credencial |
|---|---|---|
| MySQL lab (cheat sheet, aba MySQL) | `mysql:3306`, banco `lab_mysql` | `user` / `Standard@123` |
| Mosquitto lab (cliente 1 e 2) | `mosquitto:1883` | sem autenticação |
| InfluxDB lab | `http://influxdb:8086`, org `lab`, bucket `lab` | token `Standard@123` |
| MySQL (container VM, listagens, aba MySQL) | `mysql:3306`, banco `mysql` | `root` / `Standard@123` |
| MySQL VM - bootstrap / lab (CRUD, aba MySQL) | `mysql:3306`, bancos `mysql` e `lab_nodered_crud` | `root` / `Standard@123` |

Todos os endereços acima são **nomes de serviço** do `docker-compose.yml`:
dentro da rede `lab-net` os containers se encontram pelo nome. Não use
`localhost` nesses campos — dentro de um container, `localhost` é o
próprio container. (`10.0.2.2`, o apelido do VirtualBox para o PC
hospedeiro, só entra em cena se você mesmo configurar a conexão opcional
com o MySQL do seu PC — veja a seção da aba **MySQL**, acima; não há nó
algum apontando para lá por padrão.)

Para conferir os dados fora do Node-RED, dentro da VM:

```bash
docker exec -it mysql mysql -u user -p'Standard@123' lab_mysql -e "SELECT * FROM alunos"
docker exec -it mysql mysql -uroot -p'Standard@123' -e "SHOW DATABASES"
docker exec mosquitto mosquitto_sub -h mosquitto -t 'lab/#' -v -W 10
```

> Se estes flows devem vir prontos no `.ova` distribuído à turma, instale-os
> na VM mestre e exporte o appliance de novo (Anexo A.5 do README da pasta
> acima). Os dados do Node-RED ficam no volume Docker `nodered_data`, então
> os flows sobrevivem a reinicializações da VM.
