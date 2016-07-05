#!/bin/bash
#################################################################################
#     Script de atualizacao de chaves SSH										#
#     Desenvolvido por:     Giovane Nunes Carillo								#
#                           Silro												#
#     Criado:               02 / 08 / 2014										#
#     Ult. Alteracao:       06 / 01 / 2015										#
#     Colaboradores: Giovane NUNES												#
#################################################################################

#########################################################################################################
#		Configuracao para fazer debug - SHELL				  											#
#-v: Mostra a linha de entrada que esta sendo lida pelo shell.											#
#-x: Mostra as variaveis ja substituidas, comandos e seus argumentos no momento de sua execucao.        #
# para configurar o debug set -vx : Ativa o modo debug completo | set +vx: Desativa o modo debug        #
#########################################################################################################

#################################################################################
#     Definicao de Variaveis													#
#     Criado:               02 / 08 / 2014										#
#     Ult. Alteracao:       03 / 09 / 2014										#
#################################################################################

#Repositorio Principal
WORKDIR="/home/suporte/repo"

#Repositorio das Chaves
KEYD="/home/suporte/repo/key"

#Repositorio das Lista de Servidores
SERV="$KEYD/list_server.txt"

#################################################################################
#     Funcoes                                                                   #
#     Criado:               02 / 08 / 2014                                      #
#     Ult. Alteracao:       03 / 09 / 2014                                      #
#################################################################################

#function LOG(){
#LOGDIR="${KEYD}/log"
#SESSION_LOG=${LOGDIR}/$$.log
#LOGFILE=${LOGDIR}/keys.log
#DATE=$(date +"%Y-%m-%d_%H:%M:%S")
#DATA=$(date +"%Y-%m-%d %H:%M:%S")
#echo ${DATA} $1 | tee -a ${SESSION_LOG}
#logger -t 'KEYS' $1
#log -t 'KEYS' $1
#}

function LOG(){

##SESSION_LOG=${WORKDIR}/$$.log
##SESSION_TMP=${WORKDIR}/TMP-$$.log
##LOGFILE=${WORKDIR}/keys.log
##DATE=$(date +"%Y-%m-%d_%H:%M:%S")
##HR=`date +%H%M`
##DT=`date +%Y%m%d`
#data=$(date +"%d-%m-%Y")

NAME="RENEW-KEYD"
DATE=$(date +"%d-%m-%Y")
LOGDIR="${KEYD}/log"
LOGFILE="$NAME-$DATE.log"

log="$LOGDIR/$LOGFILE"

#Verifica se a pasta de log existe
if [ ! -d "$LOGDIR" ]; then
	mkdir "$LOGDIR"
fi
}

xValues() {
	LOG
	clear
	echo -e '\e[36;1m## INICIANDO PROCESSO DE TRANSFERENCIA DE CHAVE ##\e[m' | tee -a $log
	echo " " | tee -a $log
	for i in $( cat $SERV );
	do
		client=$(echo $i | cut -d : -f1)
		serv=$(echo $i | cut -d : -f2)
		port=$(echo $i | cut -d : -f3)
		variaveis="$1 $serv $port $client"
		xValidaConex $variaveis
		
		if [ $VALCX = "OK" ]; then
		
			xValidaUser $variaveis
		
			if [ $VALUS = $1 ]; then
				xRunChangeKeys $variaveis
				#xSudoers $variaveis
			else
				echo -e '\e[31;1m . . . USUARIO NAO EXISTE. \e[m' | tee -a $log
			fi
			
		else
		
			echo -e '\e[31;1m . . . CONEXAO COM O SERVIDOR INDISPONIVEL. \e[m' | tee -a $log
		
		fi
		
		echo " " | tee -a $log
		echo " " | tee -a $log
		echo ". . . . . . . . . . . . .. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ." | tee -a $log
	done
	echo " " | tee -a $log
	echo -e '\e[36;1m## PROCESSO DE TRANSFERENCIA DE CHAVES CONCLUIDO ##\e[m' | tee -a $log
}

xValidaUser() {
	VALUS="0"
	VUSER="cat /etc/passwd | cut -d : -f1 | grep $1"
	VALUS=$(ssh -l root -p $3 $2 $VUSER)
}

xValidaConex() {
	VALCX="0"
	CONEX="echo OK"
	VALCX=$(ssh -l root -p $3 $2 $CONEX)
}

xValidConection() {
	LOG
	clear
	echo -e '\e[36;1m## PROCESSO DE TESTE DE CONEXAO INICIANDO ##\e[m' | tee -a $log
	echo " " | tee -a $log
	for i in $( cat $SERV );
	do
		#Separa as variaveis do arquivo como cliente,servidor e porta de conexao		
		client=$(echo $i | cut -d : -f1) 
		serv=$(echo $i | cut -d : -f2)
		port=$(echo $i | cut -d : -f3)
		
		#cria as variaveis para gerar o teste de conexao		
		VALCX="0"
		CONEX="echo OK"
		VALCX2=$(ssh -l root -p $port $serv $CONEX)
		
			if [ $VALCX2 = 'OK' ]; then
				echo -e '\e[33;3m . . . CONEXAO COM O SERVIDOR '$client' DISPONIVEL. \e[m' | tee -a $log
			else 
				echo -e '\e[31;1m . . . CONEXAO COM O SERVIDOR '$client' INDISPONIVEL. \e[m' | tee -a $log
			fi
	done
	echo " " | tee -a $log
	echo -e '\e[36;1m## PROCESSO DE TESTE DE CONEXAO CONCLUIDO ##\e[m' | tee -a $log
}

xRunChangeKeys() {
	LOG
	echo " " | tee -a $log
	if [ $1 = 'root' ]; then
		HOM=""
	else
		HOM="/home"
	fi

	echo -ne "\e[33;3m>>> Iniciando atualizacao de acessos de \e[m" | tee -a $log
	echo -ne "\e[36;1m $1 \e[m" | tee -a $log
	echo -ne "\e[33;3m em \e[m" | tee -a $log
	echo -ne "\e[36;1m $2 \e[m" | tee -a $log
	echo " " | tee -a $log
	TMPDIR="/tmp/keys"
	RMCMD="rm -f $TMPDIR/*"
	MKCMD="mkdir $TMPDIR"
	VERIFICA="if [ -d $TMPDIR ]; then echo -e '\e[32;1m . . . Diretorio Limpo. \e[m' && $RMCMD; else echo -e '\e[32;1m . . . Diretorio Criado. \e[m' && $MKCMD; fi"
	
	#Verifica se o diretorio ".ssh" existe, se nao existir ele cria 
	MKSSH="mkdir $HOM/$1/.ssh"
	PERSSH="chmod 700 $HOM/$1/.ssh"
	VERIFICASSH="if [ -d $HOM/$1/.ssh ]; then echo -e '\e[32;1m . . . Diretorio Existe. \e[m'; else $MKSSH && echo -e '\e[32;1m . . . Diretorio Criado. \e[m'; fi"

	#Verifica se a Permissao do "authorized_keys", se nao estiver correta ele atualiza 
	
	PERUSER="chown -R $1:$1 $HOM/$1/.ssh"
	VERIFICAUSER="$PERUSER && echo -e '\e[32;1m . . . Permissao Atualizada. \e[m'"
	
	PERAUTH="chmod 600 $HOM/$1/.ssh/authorized_keys"
	VERIFICAPERM="$PERSSH && $PERAUTH && echo -e '\e[32;1m . . . Permissao Atualizada. \e[m'"
		
	SUB="cat /tmp/keys/authorized_keys.$1 > $HOM/$1/.ssh/authorized_keys"
	
	echo -n ". . Verificando a existencia do arquivo temporario de chave" | tee -a $log
	ssh -l root -p $3 $2 $VERIFICA
	
	echo -n ". . Verificando a existencia da pasta .ssh para copiar a chave" | tee -a $log
	ssh -l root -p $3 $2 $VERIFICASSH

	echo -n ". . Copiando novo arquivo de chaves para root@$2:/tmp/keys/authorized_keys.$1" | tee -a $log
	cop="$(scp -P $3 $KEYD/authorized_keys.$1 root@$2:/tmp/keys/authorized_keys.$1)"
	if [ -z $cop ]; then
		echo -e '\e[32;1m . . . CONCLUIDO. \e[m'
	else
		echo -e '\e[31;1m . . . ERROR: $cop. \e[m'
	fi
	echo -n ". . Transferindo arquivo de /tmp/keys/authorized_keys.$1 para $HOM/$1/.ssh/authorized_keys" | tee -a $log
	trs="$(ssh -l root -p $3 $2 $SUB)"
	if [ -z $trs ]; then
		echo -e '\e[32;1m . . . CONCLUIDO. \e[m' | tee -a $log
	else
		echo -e '\e[31;1m . . . ERROR: $trs. \e[m' | tee -a $log
	fi
	
	echo -n ". . Atualizando Dono da pasta e arquivos" | tee -a $log
	ssh -l root -p $3 $2 $VERIFICAUSER	
		
	echo -n ". . Verificando a permissao da pasta e arquivo authorized_keys" | tee -a $log
	ssh -l root -p $3 $2 $VERIFICAPERM
}

xSudoers() {
	LOG
	clear
	echo -ne '\e[33;3m>>> Atualizado arquivos de acesso.\e[m' | tee -a $log
	if [ $1 = "root" ]; then
	
		echo -ne '\e[33;3m ##NADA A FAZER## \e[m' | tee -a $log
		echo " "
		
	else
			VUS='for 'y' in $(ls -l /etc/sudoers.d | grep '$1' | rev | cut -d " " -f1 | rev); do rm -f /etc/sudoers.d/$y; done'
			ssh -l root -p $3 $2 $VUS
		
		#apagar o arquivo existente em /tmp
		V1="if [ -e /tmp/sudoers.ori ]; then rm /tmp/sudoers.ori; fi"
		V2="if [ -e /tmp/99-$1 ]; then rm /tmp/99-$1; fi"
		# remover permissao arquivo de destino
		CHL="chmod 750 /etc/sudoers && if [ -e /etc/sudoers.d/99-$1 ]; then chmod 750 /etc/sudoers.d/99-$1; fi"
		# restaurar permissao do arquivo de destino
		CHR="chmod 440 /etc/sudoers && if [ -e /etc/sudoers.d/99-$1 ]; then chmod 440 /etc/sudoers.d/99-$1; fi"
		# atualizar arquivo de destino
		CP0="cat /tmp/sudoers.ori > /etc/sudoers && cat /tmp/99-$1 > /etc/sudoers.d/99-$1"

		ssh -l root -p $3 $2 $V1
		ssh -l root -p $3 $2 $V2
	
		cp="$(scp -P $3 $KEYD/sudoers.ori root@$2:/tmp/sudoers.ori)"
		cp="$(scp -P $3 $KEYD/99-$1 root@$2:/tmp/99-$1)"
	
		ssh -l root -p $3 $2 $CHL	
		ssh -l root -p $3 $2 $CP0
		ssh -l root -p $3 $2 $CHR
		echo -ne '\e[32;1m ##CONCLUIDO## \e[m' | tee -a $log
		
	fi	
}

###################################################################################
#     Processo                                                                    #
#     Criado:               02 / 08 / 2014                                        #
#     Ult. Alteracao:       02 / 08 / 2014                                        #
###################################################################################
case $1 in
  jboss)
	xValues $1
  ;;
  suporte)
	xValues $1
  ;;
  root)
	xValues $1
  ;;
  ALL)
	for x in "jboss suporte"
	do
		xValues $x
	done
  ;;
  validaconexao)
  	xValidConection	 
  ;;
  *)
    echo "Usage: $0 {jboss|suporte|root|ALL(jboss e suporte)|validaconexao}"
    exit 1
  ;;
esac

exit 0
