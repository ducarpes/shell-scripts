#!/usr/bin/env bash 
#
# sherlock.sh - Realiza a busca por resultado de diversos tipos de LOGS do servidor.
# 
# Autor:      Eduardo C. Souza
# 
# ------------------------------------------------------------------------ # 
#   Este script utiliza os logs maillog, access_log, exim_mainlog e outros para localizar registros conforme necessidade.
# ------------------------------------------------------------------------ # 
# Histórico: 
# 
#   v1.0 30/12/2022, Eduardo: 
#
#   v1.1 25/01/2023, Eduardo: 
#   - Corrigido opções de acesso ao Help (--help, -h, help e "nenhum argumento" agora abrem a função help)
#   - Adicionado validação do usuário hgtransfer junto ao usuário root
#   - Adicionada validação do usuário selecionado. Para verificar se existe no servidor.
#   - Alterada a posição das aspas nos comandos "AWK" para fora das chaves. Ex '{print}'
#
# ------------------------------------------------------------------------ # 

# ------------------------------- VARIÁVEIS ----------------------------------------- #

#CORES:
RED="\033[31;1m"
GREEN="\033[32;1m"
YELLOW="\033[33;1m"
COLOR_OFF="\033[0m"
RED_SINAL="[$RED ! $COLOR_OFF]"
GREEN_SINAL="[$GREEN ! $COLOR_OFF]"
YELLOW_SINAL="[$YELLOW ! $COLOR_OFF]"

#CHAVES:
ZIP_KEY=0

# ------------------------------- FUNÇÕES GERAIS ----------------------------------------- #

#SOLICITA A ENTRADA DE UMA CONTA DE E-MAIL E DE UM TERMO PARA PESQUISA NOS LOGS (ASSUNTO, DESTINATÁRIO, REMETENTE) 
_mailSelect1(){

EMAIL=""
EMAIL_GREP=""

while [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
do 
    read -p "$(echo -e "$GREEN_SINAL - Insira o endereço de e-mail de origem: ")" EMAIL
    if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
    then
        echo -e "$RED_SINAL -$YELLOW O valor digitado não é um endereço de e-mail! $COLOR_OFF"
    fi
done

while [ "$EMAIL_GREP" == "" ]
do
    read -p "$(echo -e "$GREEN_SINAL - Insira uma termo chave para pesquisa: ")" EMAIL_GREP
done
}

#SOLICITA A ENTRADA DE UMA CONTA DE E-MAIL PARA PESQUISA NOS LOGS
_mailSelect2(){

EMAIL=""

while [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
do
    read -p "$(echo -e "$GREEN_SINAL - Insira o endereço de e-mail de origem: ")" EMAIL
    if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
    then
        echo -e "$RED_SINAL -$YELLOW O valor digitado não é um endereço de e-mail! $COLOR_OFF"
    fi
done
}

#FUNÇÃO QUE SOLICITA A ENTRADA DE UM DOMÍNIO PARA PESQUISA NOS LOGS
_domainSelect(){

DOMINIO=""

while [[ ! "$DOMINIO" =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$ ]]
do 
    read -p "$(echo -e "$GREEN_SINAL - Insira o domínio principal da conta que deseja pesquisar: ")" DOMINIO
    if [[ ! "$DOMINIO" =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$ ]]
    then
        echo -e "$RED_SINAL -$YELLOW O valor digitado $RED($DOMINIO)$YELLOW não é um endereço de domínio Válido! $COLOR_OFF"
    fi
done
}

#FUNÇÃO QUE INFORMA CASO NENHUM LOG SEJA ENCONTRADO NA PESQUISA:
_logNull(){

if [ "$ZIP_KEY" -eq 1 ]
then
    if [ "$MAIN_LOG_ZIP" = "" ]
    then
        echo -e "$RED_SINAL -$YELLOW Nenhum registro foi encontrado para esta pesquisa nos logs arquivados! $COLOR_OFF"
        exit 0
    fi
fi

if [ "$MAIN_LOG" = "" ]
then
    echo -e "$RED_SINAL -$YELLOW Nenhum registro foi encontrado para esta pesquisa nos logs recentes! $COLOR_OFF"
    exit 0  
fi
}

#FUNÇÃO PARA VERIFICAR USUÁRIOS NÃO AUTORIZADOS:
_checkRoot(){

if [ "$USUARIO" == "root" ] || [ "$USUARIO" == "hgtransfer" ] || [ -z "$USUARIO" ] ;
then
    echo -e "$RED_SINAL -$YELLOW O usuário escolhido não é autorizado ou não foi especificado. $COLOR_OFF"
    echo -e "$YELLOW_SINAL - Certifique-se de utilizar um usuário válido!"
    exit 0
fi
}

# FUNÇÃO PARA VERIFICAR SE O USUÁRIO SELECIONADO EXISTE NO SERVIDOR:
_checkUser(){
CHECK_USER=$(whmapi1 listaccts search="$USUARIO" searchtype=user | grep "user:" | awk -F " " '{print$2}')

if [ ! "$CHECK_USER" == "$USUARIO" ]
then
    echo -e "$YELLOW_SINAL -$YELLOW  O Usuário $RED$USUARIO$YELLOW não existe no servidor: $HOSTNAME $COLOR_OFF"
    exit 0
fi
}

# FUNÇÃO PARA PROIBIR QUE SEJA EXECUTADO EM SERVIDORES DA HOSTGATOR USA E OUTRAS MARCAS:
_checkHostgatorLatam(){

sharedHostnames=(hostgator.com hostgator.in hostgator.com.tr websitewelcome.com bluehost.com webhostingservices.com justhost.com)

for hosts in "${sharedHostnames[@]}"
do
	if [[ "$hosts" == $(hostname | cut -d. -f2-) ]]; 
	then
        echo -e "$YELLOW_SINAL -$YELLOW Não é possível executar este script no servidor: $HOSTNAME $COLOR_OFF"
        exit 0
    fi
done
}

# ------------------------------- FUNÇÃO HELP ----------------------------------------- #

_help(){
echo -e "
Bem vindo ao menu de ajuda da ferramenta de filtragem de logs!

"
echo -e "SINTAXE:

./sherlok.sh <-u USUARIO> <-l LOG> [-z]

-u -> INSIRA O USUÁRIO
-l -> INSIRA O LOG QUE DESEJA FILTRAR
-z -> VERIFICA OS LOGS ZIPADOS
-h -> ACIONA O MENU DE AJUDA

"
echo -e "EXEMPLO:

./sherlok.sh -u USUARIO -l add-mail -z

"
echo -e "OPÇÕES DISPONÍVEIS PARA O ARGUMENTO <LOG>:
-------------------------
01 - add-mail        --> Verificar contas de e-mails adicionados no Cpanel;
-------------------------
02 - del-mail        --> Verificar contas de e-mails removidas do Cpanel;
-------------------------
03 - add-sql         --> Verificar bancos de dados adicionados no Cpanel;
-------------------------
04 - del-sql         --> Verificar bancos de dados removidos no Cpanel;
-------------------------
05 - cpanel_fail     --> Verificar tentativas de logins inválidos realizadas;
-------------------------
06 - cpanel_login    --> Verificar tentativas de logins realizados com sucesso;
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
17 - mail-deleted    --> Verificar exclusão de mensagens de contas de e-mail (maillog);
-------------------------
18 - acct-log        --> Verificar a criação e exclusão de contas de Cpanel no servidor (accounting.log);
-------------------------
19 - ftp-login       --> Verifica as conexões FTP realizadas no usuário selecionado;
-------------------------
20 - ssh-login       --> Verifica as conexões SSH realizadas no usuário selecionado;
-------------------------
21 - sftp-login      --> Verifica as conexões SFTP realizadas no usuário selecionado;
-------------------------
22 - passwd-mail     --> Verifica as alterações de senhas de e-mail realizadas
-------------------------
23 - cm-dropped      --> Verifica bloqueios de Cloudmark no histórico de logs 
-------------------------
24 - cpanel-session  --> Verifica logins realizados através de API (WHMLOGIN)
-------------------------
25 - whm-login       --> Verifica logins realizados no WHM
-------------------------
26 - whm-fail        --> Verifica logins inválidos realizados no WHM
-------------------------
27 - whm-session     --> Verifica logins ao WHM realizados através de API 
-------------------------
" 
}

# -------------------------------VALIDAÇÕES ----------------------------------------- # 

# CHAMADA DAS FUNÇÕES DE OPÇÕES,CHECAGEM E VALIDAÇÃO

if [ $# -gt 5 ] || [ $# -eq 0 ]
then
    _help | less
    exit 0
fi

while getopts "l:u:zh" optget
do
	case "$optget" in
        l) 
            FLAG=${OPTARG}
		    ;;
		u) 
            USUARIO=${OPTARG}
		    ;;
		z)
            ZIP_KEY=1
		    ;;
        h|*) 
            _help | less
            exit 0
	esac
done  

_checkRoot
_checkUser
_checkHostgatorLatam

# ------------------------------- FUNÇÕES ACCESS_LOG ----------------------------------------- #

# PESQUISA CONTAS DE E-MAILS ADICIONADOS PELO CPANEL
add-mail(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de contas de e-mails criadas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: O Log não informa qual e-mail foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "add_pop" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "add_pop" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")  
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA CONTAS DE E-MAILS REMOVIDAS PELO CPANEL
del-mail(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de contas de e-mails excluídas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: O Log não informa qual e-mail foi removido! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "delete_pop" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "delete_pop" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA BANCOS DE DADOS ADICIONADOS PELO CPANEL
add-sql(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de bancos de dados criados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: O Log não informa qual banco de dados foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addb.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "addb.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA BANCOS DE DADOS REMOVIDOS PELO CPANEL
del-sql(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de bancos de dados excluídos na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "deldb.html?db=" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | grep -v "cPanel_magic_revision" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " BANCO DE DADOS: " $7}' | tr -d "[" | sed 's/\/cpsess.*=//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "deldb.html?db=" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | grep -v "cPanel_magic_revision" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " BANCO DE DADOS: " $7}' | tr -d "[" | sed 's/\/cpsess.*=//')
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA DOMÍNIOS ADICIONAIS ADICIONADOS PELO CPANEL
add-domain(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de domínios adicionais adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: O Log não informa qual domínio foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addon/doadddomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "addon/doadddomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA DOMÍNIOS ADICIONAIS REMOVIDOS PELO CPANEL
del-domain(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de domínios adicionais adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: O Log não informa qual domínio foi removido! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addon/dodeldomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "addon/dodeldomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA SUBDOMÍNIOS ADICIONADOS PELO CPANEL
add-subdomain(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Subdomínios adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "subdomain/doadddomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "subdomain/doadddomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA SUBDOMÍNIOS REMOVIDOS PELO CPANEL
del-subdomain(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Subdomínios removidos na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: A data deste log é 3 horas adiantada!$COLOR_OFF"
MAIN_LOG=$(grep -a "subdomain/dodeldomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "subdomain/dodeldomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA CONTAS DE FTP ADICIONADOS PELO CPANEL
add-ftp(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de contas de FTP criadas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: A data deste log é 3 horas adiantada$COLOR_OFF!"
MAIN_LOG=$(grep -a "add_ftp?user" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/&domain=/@/' | sed 's/&pass.*$//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "add_ftp?user" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/&domain=/@/' | sed 's/&pass.*$//')
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA CONTAS DE FTP REMOVIDAS PELO CPANEL
del-ftp(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de contas de FTP removidas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: A data deste log é 3 horas adiantada!$COLOR_OFF"
MAIN_LOG=$(grep -a "delete_ftp?user" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/%40/@/' | sed 's/&cache_fix=.*$//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "delete_ftp?user" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/%40/@/' | sed 's/&cache_fix=.*$//')
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA ZONA DE DNS MODIFICADA
dns-zone(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de alterações realizadas na zona de DNS na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: O Log não informa qual domínio ou alteração especificamente foi realizada na zona de DNS! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "/DNS/mass_edit_zone" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep "/DNS/mass_edit_zone" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# PESQUISA ALTERAÇÕES DE SENHAS DE E-MAILS 
passwd-mail(){ 
echo -e "$GREEN_SINAL -$GREEN Verificando logs alterações de senhas de contas de e-mail do usuário $USUARIO! $COLOR_OFF" 
echo -e "$GREEN_SINAL -$YELLOW ATENÇÃO: O Log não informa qual e-mail foi modificado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a 'passwd_pop' /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | grep -v "proxy" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
    echo -e "$GREEN_SINAL -$GREEN Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
    MAIN_LOG_ZIP=$(zgrep 'passwd_pop' /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | grep -v "proxy" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
    echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
_logNull
}

# ------------------------------- FUNÇÕES EXIM_MAINLOG ----------------------------------------- #

# PESQUISA TRÁFEGO DE E-MAILS GERAL DE UMA CONTA DE E-MAIL
mail-mainlog(){
_mailSelect1
echo -e "$GREEN_SINAL -$GREEN Verificando logs de tráfego de e-mails da conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(exigrep "$EMAIL" /var/log/exim_mainlog* | exigrep "$EMAIL_GREP")
echo "$MAIN_LOG"
_logNull
}

# PESQUISA LOGS DE E-MAILS DROPADOS COMO SPAM - BLOQUEIO CLOUDMARK
cm-dropped(){
_domainSelect
echo -e "$GREEN_SINAL -$GREEN Verificando por bloqueios de cloudmark para os e-mails do domínio: $DOMINIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep $DOMINIO /var/log/exim_mainlog | grep -i "dropped" | awk -F" " '{print"hamlookup " $3}' | uniq)
echo "$MAIN_LOG"
_logNull
}

# ------------------------------- FUNÇÕES MAILLOG ----------------------------------------- #

# PESQUISA CONEXÕES POP3 REALIZADAS
mail-pop3(){
_mailSelect2
echo -e "$GREEN_SINAL -$GREEN Verificando logs de conexões POP3 realizadas na conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(zgrep -i "$EMAIL" /var/log/maillog* | grep -v -i "Aborted" | grep -i "pop3-login" | grep -v "Disconnected:" | awk -F " " '{print "DATA: " $1 "-" $2 " - HORA: " $3 " - " $6 " - " $8 " - " $10}' | tr -d "/<>," | sed 's/varlog.*maillog://' | sed 's/rip=/IP: /' | sed 's/user=/EMAIL: /' | sed 's/varlogmaillog-//' | sed 's/202[0-9].*[0-9][0-9][0-9][0-9]://' | sort -k2M)
echo "$MAIN_LOG"
_logNull
}

# PESQUISA CONEXÕES IMAP REALIZADAS
mail-imap(){
_mailSelect2
echo -e "$GREEN_SINAL -$GREEN Verificando logs de conexões IMAP realizadas na conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(zgrep -i "$EMAIL" /var/log/maillog* | grep -v -i "Aborted" | grep -i "imap-login" | grep -v "Disconnected:" | tr -d "/<>," | awk -F " " '{print "DATA: " $1 "/" $2 " - HORA: " $3 " - " $6 " - " $8 " - " $10}' | sed 's/varlog.*maillog://' | sed 's/rip=/IP: /' | sed 's/user=/EMAIL: /' | sed 's/varlogmaillog-//' | sed 's/202[0-9].*[0-9][0-9][0-9][0-9]://' | sort -k2M)
echo "$MAIN_LOG"
_logNull
}

# PESQUISA MENSAGENS DE E-MAILS EXCLUÍDAS EM DETERMINADAS CONTAS DE E-MAIL.
mail-deleted(){
_mailSelect2
echo -e "$GREEN_SINAL -$GREEN Verificando logs de emails removidos da conta $EMAIL! Aguarde... $COLOR_OFF"
POP3_LOG=$(grep "$EMAIL" /var/log/maillog | egrep -v 'del=0' | egrep -i 'del=' | grep "pop3" | awk -F " " '{print"\033[32;1m""POP3 - ""DATA: ""\033[0m" $1" "$2" "$3"\033[32;1m"" - APAGADOS: ""\033[0m"$12"\033[32;1m"" - EMAIL: ""\033[0m"$6}' | tr -d "," | sed 's/pop3.*(//' | sed 's/).*://' ) 
IMAP_LOG=$(grep "$EMAIL" /var/log/maillog | egrep -v 'deleted=0|expunged=0|trashed=0' | egrep -i 'deleted=|expunged=|trashed=' | grep "imap" | sed 's/)<.*deleted//' | sed 's/=/ /' | sed 's/imap.*(//' | awk -F " " '{print"\033[32;1m""IMAP - ""DATA: ""\033[0m" $1" "$2" "$3"\033[32;1m"" - APAGADOS: ""\033[0m""deleted="$7" "$8" "$9"\033[32;1m"" - EMAIL: ""\033[0m"$6}')
echo "$POP3_LOG"
echo "$IMAP_LOG"  
}

# ------------------------------- FUNÇÕES ACCOUNTING.LOG ----------------------------------------- #

# PESQUISA A CRIAÇÃO E EXCLUSÃO DE CONTAS DE CPANEL NO SERVIDOR.
acct-log(){
_domainSelect
echo -e "$GREEN_SINAL -$GREEN Verificando logs de contas criadas/removidas com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep -w $USUARIO /var/cpanel/accounting.log | grep -i $DOMINIO | tr ":" " " | awk -F " " '{print "DATA: "$3"/"$2"/"$7" - HORA: "$4":"$5":"$6 " - AÇÃO: " $8 " - AUTOR: " $9"/"$10 " - DOMÍNIO: "$11 " - IP-LOCAL/USUÁRIO: " $12 "/" $13}') 
echo "$MAIN_LOG"
_logNull
}

# ------------------------------- FUNÇÕES /VAR/LOG/MESSAGES ----------------------------------------- #

# PESQUISA LOGS DE CONEXÃO FTP:
ftp-login(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de acessos FTP realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "ftpd" /var/log/messages | grep "$USUARIO" | grep "is now logged in" | awk -F " " '{print "DATA: " $1"/"$2 " - HORA: " $3 " - SERVIÇO: " $5 " - IP: " $6 }' | tr -d "()?@") 
echo "$MAIN_LOG"
_logNull
}

# ------------------------------- FUNÇÕES /VAR/LOG/SECURE ----------------------------------------- #

# PESQUISA LOGS DE CONEXÃO SSH:
ssh-login(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de acessos SSH realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "Starting session" /var/log/secure | grep "$USUARIO" | grep -v "sftp" | awk -F " " '{print "DATA: " $1 "/" $2 " - HORA: "$3 " - USUARIO: " $12 " - IP: " $14 " - PROTOCOLO: ssh"}') 
echo "$MAIN_LOG"
_logNull
}

# PESQUISA LOGS DE CONEXÃO SFTP:
sftp-login(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de acessos SFTP realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "Starting session" /var/log/secure | grep "$USUARIO" | grep "sftp" | awk -F " " '{print "DATA: " $1 "/" $2 " - HORA: "$3 " - USUARIO: " $11 " - IP: " $13 " - PROTOCOLO: " $9}' | tr -d "'")
echo "$MAIN_LOG"
_logNull
}

# ------------------------------- FUNÇÕES /usr/local/cpanel/logs/session_log ----------------------------------------- #

# PESQUISA LOGINS REALIZADOS COM SUCESSO NO CPANEL
cpanel-login(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loginsuccess" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
_logNull
}

# PESQUISA LOGINS CRIADOS VIA API NO CPANEL
cpanel-session(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loadsession" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
_logNull
}

# PESQUISA LOGINS INVALIDOS NO CPANEL
cpanel-fail(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Logins inválidos realizados na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "badpass" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
_logNull
}

# PESQUISA LOGINS REALIZADOS COM SUCESSO NO WHM
whm-login(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loginsuccess" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
_logNull
}

# PESQUISA LOGINS CRIADOS VIA API NO WHM
whm-session(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loadsession" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
_logNull
}

# PESQUISA LOGINS INVALIDOS NO WHM
whm-fail(){
echo -e "$GREEN_SINAL -$GREEN Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "badpass" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
_logNull
}

# ------------------------------- EXECUÇÃO ----------------------------------------- #

#FUNÇÃO PARA CHAMADA DAS FUNÇÕES DE LOG:
_logFunctions(){
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
    echo -e "$RED_SINAL -$YELLOW A opção de LOG selecionada é inválida!$COLOR_OFF"
    echo -e "$YELLOW_SINAL - Certifique-se de utilizar uma opção de LOG válida!"
    exit 1
    ;;  
esac
}

#CHAMADA DA FUNÇÃO DE LOG SELECIONADO
 _logFunctions

#FIM DO SCRIPT
