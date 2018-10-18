import sqlite3
import hashlib
import os
import sys, getopt
import datetime

VAR_DB='.\clientes.db'
VAR_LOCAL="."

def removerbd():
	try:
		os.remove(VAR_DB);
	except:
		print("Nao há database para deletar.");

def criarTables():
	cursor.execute("""
		CREATE TABLE md5s (md5sum varchar , pathfile varchar(300));
	""")
	cursor.execute("""CREATE TABLE md5duplicados (md5sum varchar);""")
	deletemd5s()

def inserirInfo(v1,v2):
	cursor.execute("""INSERT INTO md5s VALUES (?,?);""",(v1,v2))
	conn.commit()

def deletemd5s():
	cursor.execute("""DELETE FROM md5s;""")
	
def inserirmd5Duplicados():
	cursor.execute("""
		INSERT INTO md5duplicados SELECT md5sum from md5s group by md5sum having COUNT(md5sum)>1;
	""")

def respostaFinal():
	cursor.execute("""
		SELECT md5s.md5sum, md5s.pathfile FROM md5s INNER JOIN md5duplicados ON md5duplicados.md5sum = md5s.md5sum ORDER BY md5s.md5sum;
	""")
	print('::: MD5 DUPLICADOS:')
	for tabela in cursor.fetchall():
		print(tabela)


def md5file(fname):
	try:
	    hash_md5 = hashlib.md5()
	    with open(fname, "rb") as f:
	        for chunk in iter(lambda: f.read(4096), b""):
	            hash_md5.update(chunk)
	    return hash_md5.hexdigest()
	except:
		print("Ignorar...", fname)

removerbd()
conn = sqlite3.connect(VAR_DB)
cursor = conn.cursor()
print("::: Processando :::", datetime.datetime.now())
print("::: PASTA: ", VAR_LOCAL)
criarTables();

for root, dirs, files in os.walk(VAR_LOCAL):  
    for filename in files:
    	caminho=root+"\\"+filename
    	try:
    		md5fileName=md5file(caminho)
    		inserirInfo(md5fileName,caminho)
    	except:
    		print("Arquivo nao encontrado: ",(caminho))
    		raise

inserirmd5Duplicados()
conn.commit()
respostaFinal()
conn.commit()
print("::: Acabou :::", datetime.datetime.now())
conn.close()
removerbd()