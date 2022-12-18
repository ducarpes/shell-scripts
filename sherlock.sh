#!/usr/bin/env bash 
#
# sherlock.sh - Realiza a busca por resultado de diversos tipos de LOGS do servidor.
# 
# Autor:      Eduardo C. Souza 
# Manutenção: Eduardo C. Souza 
# 
# ------------------------------------------------------------------------ # 
#   Este script utiliza os logs maillog, access_log, exim_mainlog e outros para localizar logs conforme necessidade.
#  
# 
#  Exemplos: 
# 
# 
# 
#     
# 
#
# ------------------------------------------------------------------------ # 
# Histórico: 
# 
#   v1.0 11/06/2022, Eduardo: 
# ------------------------------------------------------------------------ # 

# ------------------------------- VARIÁVEIS ----------------------------------------- #

#CORES
VERMELHO="\033[31;1m"
VERDE="\033[32;1m"
AMARELO="\033[33;1m"
COLOR_OFF="\033[0m"
RED_SINAL="[$VERMELHO ! $COLOR_OFF]"
GREEN_SINAL="[$VERDE ! $COLOR_OFF]"
YELLOW_SINAL="[$AMARELO ! $COLOR_OFF]"

FLAG=$1
USUARIO=$2
HELP_KEY=0

# ------------------------------- FUNÇÕES GERAIS ----------------------------------------- #
#SOLICITA A ENTRADA DE UMA CONTA DE E-MAIL E DE UM TERMO PARA PESQUISA NOS LOGS (ASSUNTO, DESTINATÁRIO, REMETENTE)
mail-select1(){
read -p "$(echo -e "$GREEN_SINAL - Insira o endereço de e-mail de origem: ")" EMAIL
read -p "$(echo -e "$GREEN_SINAL - Insira uma termo chave para pesquisa (deixe em branco para obter o log total): ")" EMAIL_GREP
}

#SOLICITA A ENTRADA DE UMA CONTA DE E-MAIL PARA PESQUISA NOS LOGS
mail-select2(){
read -p "$(echo -e "$GREEN_SINAL - Insira o endereço de e-mail de origem: ")" EMAIL
}

#FUNÇÃO QUE SOLICITA A ENTRADA DE UM DOMÍNIO PARA PESQUISA NOS LOGS
domain-select(){
read -p "$(echo -e "$GREEN_SINAL - Insira o domínio principal da conta que deseja pesquisar: 
(Deixe em branco para pesquisar somente por usuário): ")" DOMINIO
}

#FUNÇÃO QUE INFORMA CASO NENHUM LOG SEJA ENCONTRADO NA PESQUISA.
log-null(){
if [ "$MAIN_LOG" = "" ]
then
    echo -e "$RED_SINAL -$AMARELO Nenhum log foi encontrado para esta pesquisa! $COLOR_OFF"
    exit 0
fi    
}

check-root(){
if [ "$USUARIO" == "root" ];
then
    echo -e "$RED_SINAL -$VERDE Este comando não é destinado para verificar logins do usuário root. Pesquise um usuário de Cpanel! $COLOR_OFF"
    exit 0
fi
}

# ------------------------------- FUNÇÃO HELP ----------------------------------------- #

help(){
echo -e "
Bem vindo ao menu de Ajuda da ferramenta de verificação de Logs!

"
echo -e "SINTAXE:

bash sherlok.sh [OPÇÃO] [USUÁRIO]
"
echo -e "EXEMPLO:

bash sherlok.sh del-mail hgtransf
"
echo -e "OPÇÕES DISPONÍVEIS:
-------------------------
01 - add-mail        --> Verificar contas de e-mails adicionados no Cpanel;
-------------------------
02 - del-mail        --> Verificar contas de e-mails removidas do Cpanel;
-------------------------
03 - add-sql         --> Verificar bancos de dados adicionados no Cpanel;
-------------------------
04 - del-sql         --> Verificar bancos de dados removidos no Cpanel;
-------------------------
05 - cpanel_fail      --> Verificar logins inválidos realizados;
-------------------------
06 - cpanel_login   --> Verificar logins realizados com sucesso;
-------------------------
07 - add-domain      --> Verificar domínios adicionados no cpanel;
-------------------------
08 - del-domain      --> Verificar domínios removidos do cpanel;
-------------------------
09 - add-subdomain   --> Verificar subdomínios adicionados no cpanel;
-------------------------
10 - del-subdomain   --> Verificar subdomínios removidos do cpanel;
-------------------------
11 - add-ftp         --> Verificar usuários de FTP adicionados ao Cpanel;
-------------------------
12 - del-ftp         --> Verificar usuários de FTP removidos do Cpanel;
-------------------------
13 - dns-zone        --> Verificar alterações realizadas na zona de DNS no CPANEL;
-------------------------
14 - mail-mainlog    --> Verificar Logs de envios e recebimentos de e-mails (exim_mainlog);
-------------------------
15 - mail-pop3       --> Verificar conexões POP3 realizadas por uma conta de e-mail (maillog);
-------------------------
16 - mail-imap       --> Verificar conexões IMAP realizadas por uma conta de e-mail (maillog);
-------------------------
17 - mail-deleted    --> Verificar Exclusão de mensagens de contas de e-mail (maillog);
-------------------------
18 - acct-log        --> Verificar a criação e exclusão de contas de Cpanel no servidor (accounting.log);
-------------------------
19 - ftp-login     --> Verifica as conexões FTP realizadas no usuário selecionado;
-------------------------
20 - ssh-login     --> Verifica as conexões SSH realizadas no usuário selecionado;
-------------------------
21 - sftp-login    --> Verifica as conexões SFTP realizadas no usuário selecionado;
-------------------------
22 - passwd-mail     --> Verifica as alterações de senhas de e-mail realizadas
-------------------------
23 - cm-dropped      --> Verifica bloqueios de Cloudmark no histórico de logs 
-------------------------
24 - cpanel-session    --> Verifica logins realizados através de API (WHMLOGIN)
-------------------------
25 - whm-login    --> Verifica logins realizados no WHM
-------------------------
26 - whm-fail    --> Verifica logins inválidos realizados no WHM
-------------------------
27 - whm-session    --> Verifica logins ao WHM realizados através de API 
-------------------------
" 
}

# ------------------------------- CHAMADA DO HELP E VERIFICAÇÃO DE OPÇÕES DIGITADAS----------------------------------------- # 
if [ "$1" = "help" ]
            then
            HELP_KEY=1
        fi

if [ $HELP_KEY -eq 1 ]
then
    help | less
    exit 0
else
    if [ $# -ne 2 ]; 
    then
        echo -e "$RED_SINAL -$AMARELO Opções inválidas! Digite a opção para o tipo de log que deseja verificar e em seguida o nome do usuário desejado! $COLOR_OFF"
        exit 1
    fi
fi

# ------------------------------- FUNÇÕES ACCESS_LOG ----------------------------------------- #

# CONTAS DE E-MAILS ADICIONADOS PELO CPANEL
add-mail(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de e-mails criadas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual e-mail foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "add_pop" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4'} | tr -d "[")
echo "$MAIN_LOG"
log-null
}

# CONTAS DE E-MAILS REMOVIDAS PELO CPANEL
del-mail(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de e-mails excluídas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual e-mail foi removido! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "delete_pop" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4'} | tr -d "[")
echo "$MAIN_LOG"
log-null
}

# BANCOS DE DADOS ADICIONADOS PELO CPANEL
add-sql(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de bancos de dados criados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual banco de dados foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addb.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4'} | tr -d "[")
echo "$MAIN_LOG"
log-null
}

# BANCOS DE DADOS REMOVIDOS PELO CPANEL
del-sql(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de bancos de dados excluídos na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "deldb.html?db=" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | grep -v "cPanel_magic_revision" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " BANCO DE DADOS: " $7'} | tr -d "[" | sed 's/\/cpsess.*=//')
echo "$MAIN_LOG"
log-null
}

# DOMÍNIOS ADICIONAIS ADICIONADOS PELO CPANEL
add-domain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de domínios adicionais adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual domínio foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addon/doadddomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4'} | tr -d "[")
echo "$MAIN_LOG"
log-null
}

# DOMÍNIOS ADICIONAIS REMOVIDOS PELO CPANEL
del-domain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de domínios adicionais adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual domínio foi removido! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addon/dodeldomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4'} | tr -d "[")
echo "$MAIN_LOG"
log-null
}

# SUBDOMÍNIOS ADICIONADOS PELO CPANEL
add-subdomain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Subdomínios adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "subdomain/doadddomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7'} | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG"
log-null
}

# SUBDOMÍNIOS REMOVIDOS PELO CPANEL
del-subdomain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Subdomínios removidos na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "subdomain/dodeldomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7'} | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG"
log-null
}

# CONTAS DE FTP ADICIONADOS PELO CPANEL
add-ftp(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de FTP criadas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "add_ftp?user" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7'} | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/&domain=/./' | sed 's/&pass.*$//')
echo "$MAIN_LOG"
log-null
}

# CONTAS DE FTP REMOVIDAS PELO CPANEL
del-ftp(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de FTP removidas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "delete_ftp?user" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7'} | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/%40/@/' | sed 's/&cache_fix=.*$//')
echo "$MAIN_LOG"
log-null
}

# ZONA DE DNS MODIFICADA
dns-zone(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de alterações realizadas na zona de DNS na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual domínio ou alteração especificamente foi realizada na zona de DNS! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "/DNS/mass_edit_zone" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4'} | tr -d "[")
echo "$MAIN_LOG"
log-null
}

# ALTERAÇÕES DE SENHAS DE E-MAILS 
passwd-mail(){ 
echo -e "$GREEN_SINAL -$VERDE Verificando logs alterações de senhas de contas de e-mail do usuário $USUARIO! $COLOR_OFF" 
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual e-mail foi modificado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a 'passwd_pop' /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | grep -v "proxy" | awk -F " " {'print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4'} | tr -d "[")
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES EXIM_MAINLOG ----------------------------------------- #

# TRÁFEGO DE E-MAILS GERAL DE UMA CONTA DE E-MAIL
mail-mainlog(){
mail-select1
echo -e "$GREEN_SINAL -$VERDE Verificando logs de tráfego de e-mails da conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(exigrep "$EMAIL" /var/log/exim_mainlog* | exigrep "$EMAIL_GREP")
echo "$MAIN_LOG"
log-null
}

# VERIFICAR LOGS DE E-MAILS DROPADOS COMO SPAM - BLOQUEIO CLOUDMARK
cm-dropped(){
domain-select
echo -e "$GREEN_SINAL -$VERDE Verificando por bloqueios de cloudmark para os e-mails do domínio: $DOMINIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep $DOMINIO /var/log/exim_mainlog | grep -i "dropped" | awk -F" " {'print"hamlookup " $3'} | uniq)
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES MAILLOG ----------------------------------------- #

#PESQUISA CONEXÕES POP3 REALIZADAS
mail-pop3(){
mail-select2
echo -e "$GREEN_SINAL -$VERDE Verificando logs de conexões POP3 realizadas na conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(zgrep -i "$EMAIL" /var/log/maillog* | grep -v -i "Aborted" | grep -i "pop3-login" | awk -F " " {'print "DATA: " $1 "-" $2 " - HORA: " $3 " - " $6 " - " $8 " - " $10'} | tr -d "/<>," | sed 's/varlog.*maillog://' | sed 's/rip=/IP: /' | sed 's/user=/EMAIL: /' | sed 's/varlogmaillog-//' | sed 's/202[0-9].*[0-9][0-9][0-9][0-9]://' | sort -k2M)
echo "$MAIN_LOG"
log-null
}

#PESQUISA CONEXÕES IMAP REALIZADAS
mail-imap(){
mail-select2
echo -e "$GREEN_SINAL -$VERDE Verificando logs de conexões IMAP realizadas na conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(zgrep -i "$EMAIL" /var/log/maillog* | grep -v -i "Aborted" | grep -i "imap-login" | tr -d "/<>," | awk -F " " {'print "DATA: " $1 "/" $2 " - HORA: " $3 " - " $6 " - " $8 " - " $10'} | sed 's/varlog.*maillog://' | sed 's/rip=/IP: /' | sed 's/user=/EMAIL: /' | sed 's/varlogmaillog-//' | sed 's/202[0-9].*[0-9][0-9][0-9][0-9]://' | sort -k2M)
echo "$MAIN_LOG"
log-null
}

#PESQUISA POR MENSAGENS DE E-MAILS EXCLUÍDAS DE DETERMINADAS CONTAS.
mail-deleted(){
mail-select2
echo -e "$GREEN_SINAL -$VERDE Verificando logs de emails removidos da conta $EMAIL! Aguarde... $COLOR_OFF"
POP3_LOG=$(grep "$EMAIL" /home/simulado/maillog | egrep -v 'del=0' | egrep -i 'del=' | grep "pop3" | awk -F " " {'print"\033[32;1m""POP3 - ""DATA: ""\033[0m" $1" "$2" "$3"\033[32;1m"" - APAGADOS: ""\033[0m"$12"\033[32;1m"" - EMAIL: ""\033[0m"$6'} | tr -d "," | sed 's/pop3.*(//' | sed 's/).*://' ) 
IMAP_LOG=$(grep "$EMAIL" /home/simulado/maillog | egrep -v 'deleted=0|expunged=0|trashed=0' | egrep -i 'deleted=|expunged=|trashed=' | grep "imap" | sed 's/)<.*deleted//' | sed 's/=/ /' | sed 's/imap.*(//' | awk -F " " {'print"\033[32;1m""IMAP - ""DATA: ""\033[0m" $1" "$2" "$3"\033[32;1m"" - APAGADOS: ""\033[0m""deleted="$7" "$8" "$9"\033[32;1m"" - EMAIL: ""\033[0m"$6'})
echo "$POP3_LOG"
echo "$IMAP_LOG"  
}

# ------------------------------- FUNÇÕES ACCOUNTING.LOG ----------------------------------------- #

#REALIZA A VERIFICAÇÃO DA CRIAÇÃO E EXCLUSÃO DE CONTAS DE CPANEL NO SERVIDOR.
acct-log(){
domain-select
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas criadas/removidas com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep -w $DOMINIO /var/cpanel/accounting.log | grep -i $DOMINIO | tr ":" " " | awk -F " " {'print "DATA: "$3"/"$2"/"$7" - HORA: "$4":"$5":"$6 " - AÇÃO: " $8 " - AUTOR: " $9"/"$10 " - DOMÍNIO: "$11 " - IP-LOCAL/USUÁRIO: " $12 "/" $13'}) 
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES /VAR/LOG/MESSAGES ----------------------------------------- #

ftp-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de acessos FTP realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "ftpd" /var/log/messages | grep "$USUARIO" | grep "is now logged in" | awk -F " " {'print "DATA: " $1"/"$2 " - HORA: " $3 " - SERVIÇO: " $5 " - IP: " $6 '} | tr -d "()?@") 
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES /VAR/LOG/SECURE ----------------------------------------- #

ssh-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de acessos SSH realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "Starting session" /var/log/secure | grep "$USUARIO" | grep -v "sftp" | awk -F " " {'print "DATA: " $1 "/" $2 " - HORA: "$3 " - USUARIO: " $12 " - IP: " $14 " - PROTOCOLO: ssh"'}) 
echo "$MAIN_LOG"
log-null
}

sftp-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de acessos SFTP realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "Starting session" /var/log/secure | grep "$USUARIO" | grep "sftp" | awk -F " " {'print "DATA: " $1 "/" $2 " - HORA: "$3 " - USUARIO: " $11 " - IP: " $13 " - PROTOCOLO: " $9'} | tr -d "'")
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES /usr/local/cpanel/logs/session_log ----------------------------------------- #

# LOGINS REALIZADOS COM SUCESSO NO CPANEL
cpanel-login(){
check-root
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loginsuccess" | awk -v username=$USUARIO -F" " {'print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username'} | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS CRIADOS VIA API NO CPANEL
cpanel-session(){
check-root
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loadsession" | awk -v username=$USUARIO -F" " {'print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username'} | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS INVALIDOS NO CPANEL
cpanel-fail(){
check-root
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins inválidos realizados na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "badpass" | awk -v username=$USUARIO -F" " {'print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username'} | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS REALIZADOS COM SUCESSO NO WHM
whm-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loginsuccess" | awk -v username=$USUARIO -F" " {'print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username'} | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS CRIADOS VIA API NO WHM
whm-session(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loadsession" | awk -v username=$USUARIO -F" " {'print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username'} | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS INVALIDOS NO WHM
whm-fail(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "badpass" | awk -v username=$USUARIO -F" " {'print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username'} | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}
# ------------------------------- EXECUÇÃO ----------------------------------------- #

case $FLAG in  
    "add-mail")
        add-mail
        ;;

    "del-mail")
        del-mail
        ;;
    
    "add-sql")
        add-sql
        ;;

    "del-sql")
        del-sql
        ;;

    "cpanel-login")
        cpanel-login
        ;;

    "cpanel-session")
        cpanel-session
        ;;    

    "cpanel-fail")
        cpanel-fail
        ;;
    
    "whm-login")
        whm-login
        ;;

    "whm-session")
        whm-session
        ;; 

    "whm-fail")
        whm-fail
        ;;

    "add-domain")
        add-domain
        ;;
        
    "del-domain")
        del-domain
        ;;  

    "add-subdomain")
        add-subdomain
        ;;  

    "del-subdomain")
        del-subdomain
        ;;  

    "add-ftp")
        add-ftp
        ;;  

    "del-ftp")
        del-ftp
        ;;  

    "dns-zone")
        dns-zone
        ;;

    "mail-mainlog")
        mail-mainlog
        ;;

    "mail-pop3")
        mail-pop3
        ;;  

    "mail-imap")
        mail-imap
        ;;
    "mail-deleted")
        mail-deleted
        ;;

    "acct-log")
        acct-log
        ;;            

    "ftp-login")
        ftp-login
        ;;

    "ssh-login")
        ssh-login
        ;;     
    "sftp-login")
        sftp-login
        ;;

    "cm-dropped")
        cm-dropped
        ;;
    
    "passwd-mail") 
        passwd-mail
        ;;

    *)
        echo -e "$RED_SINAL -$AMARELO A opção selecionada é inválida$COLOR_OFF!"
        echo -e "$YELLOW_SINAL - Certifique-se de utilizar uma opção válida!"
        exit 1
        ;;  
esac
