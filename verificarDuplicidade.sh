#!/bin/bash
FOLDER="$1"
FILEDUPL="/tmp/md5dupl.txt"

function criarTables(){
	PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "create table md5s (md5sum varchar , pathfile varchar(300));"
}

function criarTablesmd5Duplicados(){
	PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "DROP TABLE md5duplicados;" > /dev/null
	PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "create table md5duplicados (md5sum varchar);" > /dev/null
}

function deleteTables(){
	PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "drop table md5s ;" > /dev/null
}

function inserirInfo(){
	PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "INSERT INTO md5s VALUES ('$1','$2' );" > /dev/null
}

function inserirmd5Duplicados(){
	PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "INSERT INTO md5duplicados SELECT md5sum from md5s group by md5sum having COUNT(md5sum)>1;" > /dev/null 
}

function respostaFinal(){
	PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "SELECT md5s.md5sum, md5s.pathfile FROM md5s INNER JOIN md5duplicados ON md5duplicados.md5sum = md5s.md5sum;" 
}

deleteTables
criarTables
echo "::: Processando :::"
find  ${FOLDER} -type f > /tmp/files.full
NUMETOTAL=`wc -l /tmp/files.full`
while read linha; do
	#echo "$linha"
	NUMEROPREV=`PGPASSWORD=pass psql -h 172.17.0.2 -U user db -c "SELECT count(0) FROM md5s" -tA`
	inserirInfo `md5sum -t "$linha" | awk '{print $1}'` "$linha" 
	#md5sum "$linha" >> /tmp/md5.file 
	echo "::: Processando: ${NUMEROPREV}/${NUMETOTAL}"
done < /tmp/files.full 
rm /tmp/files.full
echo "" > ${FILEDUPL}
cat /tmp/md5.file | awk '{print $1}' | sort | uniq -d > ${FILEDUPL}

criarTablesmd5Duplicados
inserirmd5Duplicados
echo "Arquivos duplicados::: "
respostaFinal
