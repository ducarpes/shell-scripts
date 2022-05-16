#!/usr/bin/env bash 
# 
# check_backup_domains.sh - Verifica quais domínios estão vinculados a um arquivo de backup
# 
# Autor:      Eduardo C. Souza 
# Manutenção: Eduardo C. Souza 
# 
# ------------------------------------------------------------------------ # 
#  Este Script verifica quais domíníos estão vinculados ao arquivo de backup especificado
# 
#  Exemplos: 
#      $ ./check_backup_domains.sh backup-5.13.2022_17-17-36_simulado.tar.gz
#      Neste exemplo o Script vai listar quais domínios estão vinculados no backup backup-5.13.2022_17-17-36_simulado.tar.gz
# ------------------------------------------------------------------------ # 
# Histórico: 
# 
#   v1.0 13/05/2022, Eduardo: 
# ------------------------------------------------------------------------ # 
# ------------------------------- VARIÁVEIS ----------------------------------------- #
#CORES
VERMELHO="\033[31;1m"
VERDE="\033[32;1m"
AMARELO="\033[33;1m"
COLOR_OFF="\033[0m"

BACKUP_NAME=$(echo $1 | sed s/.tar.gz//)

#VERIFICAR USUÁRIO DO BACKUP
if [ -f $PWD/$1 ];
then    
    case $1 in
        *"backup"*)
            USUARIO=$( echo $BACKUP_NAME | sed 's/backup.*_//' )
            ;;

        *"cpmove"*)
            USUARIO=$( echo $BACKUP_NAME | awk -F"." {'print$1'} | sed s/cpmove-// )
            ;;
        *)
            echo "Arquivo Inválido";
            exit
            ;;
    esac
else
echo -e "O arquivo $AMARELO $1 $COLOR_OFF não foi localizado neste diretório!";
exit
fi;
# ------------------------------------------------------------------------ # 
# ------------------------------- TESTES ----------------------------------------- # 
# ------------------------------------------------------------------------ # 
# ------------------------------- FUNÇÕES ----------------------------------------- # 
# ------------------------------------------------------------------------ # 
# ------------------------------- EXECUÇÃO ----------------------------------------- # 

tar -xf $1 $BACKUP_NAME/cp/$USUARIO;
if [ -d $BACKUP_NAME/cp/ ];
then
DOMINIOS=$(cat $BACKUP_NAME/cp/$USUARIO | grep "DNS" | sed 's/backup.*=//' | grep -v "backup" | sed 's/DNS.*=//');
rm -rf $BACKUP_NAME;
else
echo -e "$VERMELHO O Backup está corrompido. $COLOR_OFF 
 O arquivo $AMARELO $BACKUP_NAME/cp/$USUARIO $COLOR_OFF não foi localizado neste backup";
exit 1;
fi;

for LINE in $DOMINIOS;
    do echo -e $AMARELO"Domínio: $VERDE $LINE $COLOR_OFF";
done;
# ------------------------------------------------------------------------ #
