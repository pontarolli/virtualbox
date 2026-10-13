#!/bin/bash
set -e

# Um banco e um usuario por aluno, isolados entre si (so o proprio GRANT).
for i in $(seq -f "%02g" 1 "${NUM_ALUNOS:-40}"); do
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`aluno${i}\`;
    CREATE USER IF NOT EXISTS 'aluno${i}'@'%' IDENTIFIED BY '${LAB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`aluno${i}\`.* TO 'aluno${i}'@'%';
EOSQL
done

# Professor: banco proprio + acesso total ao banco de cada aluno (correcao/supervisao).
mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
  CREATE DATABASE IF NOT EXISTS \`professor\`;
  CREATE USER IF NOT EXISTS 'professor'@'%' IDENTIFIED BY '${PROFESSOR_PASSWORD}';
  GRANT ALL PRIVILEGES ON \`professor\`.* TO 'professor'@'%';
  GRANT ALL PRIVILEGES ON \`aluno%\`.* TO 'professor'@'%';
EOSQL

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
