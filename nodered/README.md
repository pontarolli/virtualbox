# Flows de exemplo do Node-RED (laboratório de Redes)

Quatro abas prontas para aula, cada uma com um serviço da stack da VM, mais
três abas extras de MySQL: duas contra o container `mysql` da própria VM
(mais um serviço da stack) e uma pessoal/opcional que conecta ao MySQL do
próprio PC Windows (fora da VM — veja o aviso na seção correspondente, mais
abaixo). Todas já estão instaladas no Node-RED da VM
(<http://localhost:1880>); os arquivos abaixo servem para os alunos
importarem e para reinstalar.

| Arquivo | Aba no Node-RED | Assunto |
|---|---|---|
| `flow-blocos-basicos.json` | **Blocos básicos** | `function`, `change`, `switch`, `template`, `split`/`join`, `delay` |
| `flow-mqtt.json` | **MQTT** | publicar e assinar no Mosquitto, curingas `#` e `+` |
| `flow-sql-cheatsheet.json` | **SQL cheat sheet** | 27 consultas em três níveis, contra o MySQL da VM, para consulta rápida |
| `flow-influxdb.json` | **InfluxDB** | gravar séries temporais e consultar com Flux |
| `flow-mysql-vm.json` | **MySQL VM** | listar bancos, tamanhos e tabelas do MySQL da própria VM (container `mysql`) |
| `flow-mysql-host.json` | **MySQL** *(opcional, PC próprio)* | listar bancos, tamanhos e tabelas do MySQL do PC Windows |
| `flow-crud-mysql-vm.json` | **CRUD MySQL** | CRUD (`authors`/`books`) no MySQL da VM, num schema novo e isolado |
| `subir-flow.ps1` | — | envia os flows para o Node-RED da VM |

Sugestão de ordem em aula: **Blocos básicos → MQTT → InfluxDB → SQL cheat
sheet**. Os três primeiros se encadeiam (a aba InfluxDB tem uma ponte que
grava o que for publicado por MQTT); o cheat sheet é material de consulta
que o aluno volta a abrir depois. As três abas de MySQL ficam de fora dessa
sequência principal: **MySQL VM** e **CRUD MySQL** são bons extras para ver
o mesmo SGBD sem sair da VM; **MySQL** só faz sentido para quem já tem um
MySQL instalado no próprio PC.

## Instalar na VM

A VM precisa estar ligada, com a regra de NAT `nodered` (`1880` → `1880`).

**Pelo navegador (o que o aluno faz):** abra <http://localhost:1880>, menu
☰ → **Import** → **select a file to import** → escolha o `.json` →
**Import** → **Deploy**. Depois preencha as credenciais nos nós de
configuração (veja a tabela no fim deste arquivo) — o Node-RED **nunca**
exporta senhas junto com o flow.

**Pelo PowerShell (já com as senhas):** na pasta deste README,

```powershell
powershell -ExecutionPolicy Bypass -File .\subir-flow.ps1
```

Envia todos os `flow-*.json`. Para um só: `-Arquivo .\flow-mqtt.json`.

> **Credenciais diferentes por nó de configuração.** O script decide pelo
> `host` e pelo `db` do nó `MySQLdatabase`: se `host` for `10.0.2.2` (o
> MySQL do PC, fora da VM — aba **MySQL**), usa `-UsuarioMySQLHost`/
> `-SenhaMySQLHost` (padrão `root`/`root`); dentro da VM, o banco `lab_mysql`
> (pré-criado, aba **SQL cheat sheet**) usa a conta comum `user`; qualquer
> outro banco da VM — o banco de sistema `mysql` ou um schema novo como
> `lab_nodered_crud` (abas **MySQL VM** e **CRUD MySQL**) — usa `root`, por
> precisar criar/derrubar tabelas e schemas. Se o MySQL do seu PC tiver
> outro usuário ou senha, passe os parâmetros: `-UsuarioMySQLHost meuUsuario
> -SenhaMySQLHost minhaSenha`.

---

## Aba: Blocos básicos

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

## Aba: MQTT

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

## Aba: SQL cheat sheet

Material de consulta: 27 exemplos de SQL em três níveis, sobre um esquema de
escola (`cursos`, `alunos`, `matriculas` — 8 alunos, 4 cursos, 16
matrículas). **Rode o inject 0 primeiro**, para criar e popular as tabelas;
depois clique em qualquer exemplo, em qualquer ordem. No Debug, o `topic`
mostra o SQL executado e o `payload` mostra o resultado — é o que faz a aba
servir como cola.

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
> ordem. Por isso o inject 0 usa o padrão "próximo comando": só envia o
> seguinte depois que o anterior voltou. Pelo mesmo motivo, transações
> (`START TRANSACTION`/`COMMIT`) não funcionam bem por aqui — para isso, use
> uma *stored procedure* e chame com `CALL`.

## Aba: InfluxDB

Banco de **série temporal**: cada ponto tem horário, *fields* (valores
medidos) e *tags* (rótulos para filtrar e agrupar).

1. Inject **2** grava 20 leituras espalhadas nos últimos 20 minutos.
2. Inject **3** consulta com Flux e mostra as linhas no Debug.
3. Inject **4** calcula a média por sensor — a conta roda **no banco**.
4. Volte na aba MQTT e clique no inject 2: a leitura publicada cai no
   Influx pela ponte no rodapé da aba, sem ninguém chamar o banco.

Pontos a explicar: o formato da escrita é
`msg.payload = [ {fields}, {tags} ]`; o Flux é um *pipeline*
(`from` → `range` → `filter` → agregação), bem diferente de SQL, e a janela
de tempo em `range` é obrigatória. Vale contrastar com a aba SQL cheat
sheet: o Influx guarda medições ao longo do tempo, o MySQL guarda cadastros
e relações.

### Fechando o ciclo no Grafana

Há um dashboard de exemplo pronto em
<http://localhost:3000/d/lab-sensores> (login `root` / `Standard@123`), com
cinco painéis sobre o bucket `lab`: temperatura e umidade por sensor ao
longo do tempo, última leitura, média do período e uma tabela das últimas 20
leituras. Atualiza a cada 10 s.

A ideia a passar para a turma é que **ninguém liga o Node-RED ao Grafana**:
o Node-RED escreve no InfluxDB, o Grafana lê do InfluxDB, e o banco é o
ponto de encontro. Dá para demonstrar ao vivo — deixe o dashboard aberto,
volte ao Node-RED, clique no inject 2 da aba InfluxDB (ou publique pela aba
MQTT) e veja o ponto aparecer no gráfico.

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

## Aba: MySQL VM

MySQL Server rodando como **mais um container da stack** (`mysql:8.0`,
serviço `mysql` no `lab-stack/docker-compose.yml`), na mesma rede `lab-net`
que todos os outros. É a mesma ideia da aba **MySQL** (abaixo), só que sem
sair da VM.

Três injects independentes, todos usando `information_schema`:

| Inject | O que mostra |
|---|---|
| 1 | `SHOW DATABASES` — nomes de todos os bancos |
| 2 | tamanho (MB) e nº de tabelas de cada banco |
| 3 | todas as tabelas de todos os bancos (exceto `information_schema`, `mysql`, `performance_schema`, `sys`) |

O container já vem com um banco de exemplo, `lab_mysql` (criado pelas
variáveis `MYSQL_DATABASE`/`MYSQL_USER` do `docker-compose.yml`), só para a
lista não aparecer vazia na primeira vez.

### Por que o host é só `mysql`

Diferente da aba **MySQL** (do PC Windows, abaixo), aqui não tem NAT nem
endereço especial: o container `mysql` está na mesma rede Docker `lab-net`
que o Node-RED, então vale a regra normal da stack — containers se
encontram pelo **nome do serviço**. É `mysql:3306`, do mesmo jeito que as
outras abas já usam `influxdb:8086` ou `mosquitto:1883`.

### Acesso de fora da VM (opcional)

O container também publica a porta `3306` (guest) → `3306` (host da VM),
então de **dentro da VM** dá pra inspecionar com `mysql -h127.0.0.1 -P3306
-uroot -p`. Isso também pode ser aberto no **PC Windows** (ex.: MySQL
Workbench, `localhost:3306`) — regra `mysql` de Port Forwarding, opcional,
no Anexo "Acesso pelo seu PC via Port Forwarding" do README da pasta acima.

## Aba: CRUD MySQL

Exemplo `bookstore` (tabelas `authors` e `books`), rodando no container
`mysql` da própria VM (mesmo servidor da aba **MySQL VM**, acima) — mas
**num schema novo e isolado**, `lab_nodered_crud`, para não mexer no banco
`lab_mysql` que a aba **SQL cheat sheet** usa.

Clique nos injects **na ordem de 0 a 9**:

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
`Standard@123` — diferente da aba **SQL cheat sheet** (conta comum `user`),
aqui é preciso criar e derrubar tabelas e o próprio schema, algo que a
conta comum não tem permissão para fazer.

> **Cuidado com o `props` do inject quando o SQL vai no `topic`.** O nó
> `inject` só manda para a mensagem as propriedades listadas em `props`; se
> o SQL estiver no campo Topic do inject mas `topic` não estiver marcado em
> `props`, o `msg.topic` sai vazio e o `mysql` não executa nada — sem erro
> visível. Foi exatamente o bug do passo 0 na primeira versão desta aba.
> Compare os injects 2, 3, 4, 5 e 7 (SQL direto no `topic`, `props` inclui
> `topic`) com os passos 0, 1 e 9 (passam por um `function`, que monta o
> `msg.topic` sozinho — aí o `props` do inject só precisa do `payload`, só
> para disparar).

## Aba: MySQL *(opcional, PC próprio)*

Diferente de todas as outras abas, esta **não** conecta a um container da
VM: conecta ao MySQL que roda no **PC Windows** de quem está usando o
Node-RED. É opcional — só faz sentido para quem já tem um MySQL local para
explorar.

Três injects independentes, todos usando `information_schema`:

| Inject | O que mostra |
|---|---|
| 1 | `SHOW DATABASES` — nomes de todos os bancos |
| 2 | tamanho (MB) e nº de tabelas de cada banco |
| 3 | todas as tabelas de todos os bancos (exceto `information_schema`, `mysql`, `performance_schema`, `sys`) |

### Por que o host é `10.0.2.2`

Dentro do container do Node-RED, `localhost` é o próprio container — nunca
o PC de fora. Como o Adapter 1 da VM é **NAT**, o VirtualBox reserva
`10.0.2.2` como apelido fixo para a máquina hospedeira, visto de dentro da
VM. Não é preciso descobrir IP nem criar regra de Port Forwarding nesse
sentido (VM → PC): esse acesso já vem liberado pelo próprio NAT. O tráfego
chega ao MySQL do Windows como se fosse `127.0.0.1`, então um usuário como
`root`, que só tem permissão a partir de `localhost`, funciona sem precisar
mudar nada no MySQL nem no Firewall do Windows.

### Pré-requisitos no MySQL do Windows

- Escutando em todas as interfaces: `bind-address = *` (ou `0.0.0.0`), não
  só `127.0.0.1`.
- Porta padrão `3306` aberta e o serviço rodando.
- Um usuário/senha válidos (aqui, `root` / `root` — senha fraca aceitável
  só por ser o MySQL local do próprio PC).

---

## Credenciais usadas pelos flows

| Nó de configuração | Endereço | Credencial |
|---|---|---|
| MySQL lab (SQL cheat sheet) | `mysql:3306`, banco `lab_mysql` | `user` / `Standard@123` |
| Mosquitto lab (cliente 1 e 2) | `mosquitto:1883` | sem autenticação |
| InfluxDB lab | `http://influxdb:8086`, org `lab`, bucket `lab` | token `Standard@123` |
| MySQL (container VM) | `mysql:3306`, banco `mysql` | `root` / `Standard@123` |
| MySQL VM - bootstrap / lab (CRUD MySQL) | `mysql:3306`, bancos `mysql` e `lab_nodered_crud` | `root` / `Standard@123` |
| MySQL do PC (host) | `10.0.2.2:3306`, banco `mysql` | `root` / `root` |

Os endereços dos cinco primeiros são **nomes de serviço** do
`docker-compose.yml`: dentro da rede `lab-net` os containers se encontram
pelo nome. Não use `localhost` nesses campos — dentro de um container,
`localhost` é o próprio container. Já `10.0.2.2` é o apelido do VirtualBox
para a máquina hospedeira, usado só pela aba **MySQL** do PC (veja a
explicação na seção dessa aba, acima).

Para conferir os dados fora do Node-RED, dentro da VM:

```bash
docker exec -it mysql mysql -u user -p'Standard@123' lab_mysql -e "SELECT * FROM alunos"
docker exec -it mysql mysql -uroot -p'Standard@123' -e "SHOW DATABASES"
docker exec mosquitto mosquitto_sub -h mosquitto -t 'lab/#' -v -W 10
```

Para conferir os dados do MySQL do PC, no próprio Windows (fora da VM):

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -uroot -proot -h127.0.0.1 -e "SHOW TABLES FROM lab_nodered_crud"
```

> Se estes flows devem vir prontos no `.ova` distribuído à turma, instale-os
> na VM mestre e exporte o appliance de novo (Anexo A.5 do README da pasta
> acima). Os dados do Node-RED ficam no volume Docker `nodered_data`, então
> os flows sobrevivem a reinicializações da VM.
