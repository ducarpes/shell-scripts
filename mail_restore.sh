#!/usr/bin/env bash 
#
# sherlock.sh - Realiza a busca por resultado de diversos tipos de LOGS do servidor.
# 
# Autor:      Eduardo C. Souza 
# Manutenção: Eduardo C. Souza 
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
VERMELHO="\033[31;1m"
VERDE="\033[32;1m"
AMARELO="\033[33;1m"
COLOR_OFF="\033[0m"
RED_SINAL="[$VERMELHO ! $COLOR_OFF]"
GREEN_SINAL="[$VERDE ! $COLOR_OFF]"
YELLOW_SINAL="[$AMARELO ! $COLOR_OFF]"

#VARIÁVEIS DE ENTRADA:
FLAG=$1
USUARIO=$2
ARCHIVE=$3

#CHAVES:
HELP_KEY=0
ZIP_KEY=0

# ------------------------------- FUNÇÕES GERAIS ----------------------------------------- #
#SOLICITA A ENTRADA DE UMA CONTA DE E-MAIL E DE UM TERMO PARA PESQUISA NOS LOGS (ASSUNTO, DESTINATÁRIO, REMETENTE)
mail-select1(){
EMAIL=""
EMAIL_GREP=""
while [ "$EMAIL" == "" ]
do 
    read -p "$(echo -e "$GREEN_SINAL - Insira o endereço de e-mail de origem: ")" EMAIL
done
while [ "$EMAIL_GREP" == "" ]
do
    read -p "$(echo -e "$GREEN_SINAL - Insira uma termo chave para pesquisa: ")" EMAIL_GREP
done
}

#SOLICITA A ENTRADA DE UMA CONTA DE E-MAIL PARA PESQUISA NOS LOGS
mail-select2(){
EMAIL=""
while [ "$EMAIL" == "" ]
do
    read -p "$(echo -e "$GREEN_SINAL - Insira o endereço de e-mail de origem: ")" EMAIL
done
}

#FUNÇÃO QUE SOLICITA A ENTRADA DE UM DOMÍNIO PARA PESQUISA NOS LOGS
domain-select(){
DOMINIO=""
while [ "$DOMINIO" == "" ]
do 
    read -p "$(echo -e "$GREEN_SINAL - Insira o domínio principal da conta que deseja pesquisar: ")" DOMINIO
done
}

#FUNÇÃO QUE INFORMA CASO NENHUM LOG SEJA ENCONTRADO NA PESQUISA:
log-null(){

if [ "$ZIP_KEY" -eq 1 ]
then
    if [ "$MAIN_LOG_ZIP" = "" ]
    then
    echo -e "$RED_SINAL -$AMARELO Nenhum registro foi encontrado para esta pesquisa nos logs arquivados! $COLOR_OFF"
    exit 0
    fi
fi

if [ "$MAIN_LOG" = "" ]
then
        echo -e "$RED_SINAL -$AMARELO Nenhum registro foi encontrado para esta pesquisa nos logs recentes! $COLOR_OFF"
        exit 0  
fi
}

#FUNÇÃO PARA VERIFICAR SE O USUÁRIO SELECIONADO É ROOT OU HGTRANSFER:
check-root(){
if [ "$USUARIO" == "root" ] || [ "$USUARIO" == "hgtransfer" ];
then
    echo -e "$RED_SINAL -$VERDE O usuário escolhido não é autorizado. Pesquise um usuário de Cpanel! $COLOR_OFF"
    exit 0
fi
}

#FUNÇÃO PARA VERIFICAR SE O USUÁRIO SELECIONADO EXISTE NO SERVIDOR:
check-user(){
HOME_USUARIO=$(grep $USUARIO /etc/passwd|cut -f6 -d":")
id -u "$USUARIO" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    if [ ! -d "$HOME_USUARIO" ]
    then
        echo -e "$RED_SINAL -$AMARELO O usuário $VERMELHO$USUARIO$AMARELO não foi encontrado neste servidor! $COLOR_OFF"
        echo -e "$YELLOW_SINAL - Certifique-se que o usuário $VERMELHO$USUARIO$COLOR_OFF possui uma conta de CPANEL no servidor $HOSTNAME"
        exit 1
    fi
else
    echo -e "$RED_SINAL -$AMARELO O usuário $VERMELHO$USUARIO$AMARELO não foi encontrado neste servidor! $COLOR_OFF"
    echo -e "$YELLOW_SINAL - Certifique-se que o usuário $VERMELHO$USUARIO$COLOR_OFF possui uma conta de CPANEL no servidor $VERMELHO$HOSTNAME$COLOR_OFF"
    exit 1
fi
}

check-hg(){
if [[  $(hostname) =~ .*hostgator* ]] || [[  $(hostname) =~ .*prodns*  ]] && [[  -e /opt/hgctrl/.zengator ]] 
then
    echo -e "$YELLOW_SINAL - Não é possível executar este script no servidor: $HOSTNAME"
    exit 1
fi
}
# ------------------------------- FUNÇÃO HELP ----------------------------------------- #

help(){
echo -e "
Bem vindo ao menu de ajuda da ferramenta de verificação de logs!

"
echo -e "SINTAXE:

./sherlok.sh [LOG] [USUÁRIO] [-l | -a]

-a -> Verificar logs arquivados.
-l -> Verificar somente logs recentes.
USUÁRIO: Usuário do CPANEL que será pesquisado.
LOG -> Tipo de logo que deseja buscar.

"
echo -e "EXEMPLO:

./sherlok.sh del-mail username -l

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

# -------------------------------VALIDAÇÃO DE SERVIDORES DA MARCA----------------------------------------- # 

check-hg

# ------------------------------- CHAMADA DO HELP E VERIFICAÇÃO DE OPÇÕES DIGITADAS----------------------------------------- # 

#HELP SERÁ CHAMADO CASO NÃO HAJA NENHUM ARGUMENTO DIIGTADO:
if [ "$#" -eq 0 ]
then
    help | less
fi  

# SE O PRIMEIRO ARGUMENTO FOR --help, -h OU help SERÁ ATIVADA A KEY PARA HELP:
if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]
    then
    HELP_KEY=1
fi

# SE A KEY DO HELP ESTIVER ATIVA, SERÁ CHAMADO O HELP, SE NÃO, VAI VERIFICAR SE POSSUI OS 3 ARGUMENTOS OBRIGATÓRIOS:
if [ $HELP_KEY -eq 1 ]
then
    help | less
    exit 0
else
    if [ $# -eq 3 ]; 
    then
        case $ARCHIVE in  
            "-a")
                ZIP_KEY=1
                ;;
            "-l")
                ZIP_KEY=0
                ;;
            *)
                echo -e "$RED_SINAL -$AMARELO Opções inválidas! Digite a opção para o tipo de log que deseja verificar e em seguida o nome do usuário desejado! $COLOR_OFF"
                echo -e "$RED_SINAL -$AMARELO Acesse o --help para verificar a sintaxe adequada! $COLOR_OFF"
                exit 1
                ;;
        esac
    else
        echo -e "$RED_SINAL -$AMARELO Opções inválidas! Digite a opção para o tipo de log que deseja verificar e em seguida o nome do usuário desejado! $COLOR_OFF"
        echo -e "$RED_SINAL -$AMARELO Acesse o --help para verificar a sintaxe adequada! $COLOR_OFF"
        exit 1
    fi
fi 

# ------------------------------- FUNÇÕES ACCESS_LOG ----------------------------------------- #

# CONTAS DE E-MAILS ADICIONADOS PELO CPANEL
add-mail(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de e-mails criadas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual e-mail foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "add_pop" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "add_pop" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")  
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null

}

# CONTAS DE E-MAILS REMOVIDAS PELO CPANEL
del-mail(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de e-mails excluídas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual e-mail foi removido! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "delete_pop" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "delete_pop" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# BANCOS DE DADOS ADICIONADOS PELO CPANEL
add-sql(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de bancos de dados criados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual banco de dados foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addb.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "addb.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# BANCOS DE DADOS REMOVIDOS PELO CPANEL
del-sql(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de bancos de dados excluídos na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "deldb.html?db=" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | grep -v "cPanel_magic_revision" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " BANCO DE DADOS: " $7}' | tr -d "[" | sed 's/\/cpsess.*=//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "deldb.html?db=" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | grep -v "cPanel_magic_revision" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " BANCO DE DADOS: " $7}' | tr -d "[" | sed 's/\/cpsess.*=//')
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# DOMÍNIOS ADICIONAIS ADICIONADOS PELO CPANEL
add-domain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de domínios adicionais adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual domínio foi adicionado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addon/doadddomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "addon/doadddomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# DOMÍNIOS ADICIONAIS REMOVIDOS PELO CPANEL
del-domain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de domínios adicionais adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual domínio foi removido! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "addon/dodeldomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "addon/dodeldomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# SUBDOMÍNIOS ADICIONADOS PELO CPANEL
add-subdomain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Subdomínios adicionados na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!"
MAIN_LOG=$(grep -a "subdomain/doadddomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "subdomain/doadddomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# SUBDOMÍNIOS REMOVIDOS PELO CPANEL
del-subdomain(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Subdomínios removidos na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!$COLOR_OFF"
MAIN_LOG=$(grep -a "subdomain/dodeldomain.html" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "subdomain/dodeldomain.html" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - SUBDOMÍNIO: "$7}' | tr -d "[" | sed 's/\/cpsess.*?domain=//' | sed 's/&rootdomain=/./' | sed 's/&dir.*Create//')
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# CONTAS DE FTP ADICIONADOS PELO CPANEL
add-ftp(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de FTP criadas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada$COLOR_OFF!"
MAIN_LOG=$(grep -a "add_ftp?user" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/&domain=/@/' | sed 's/&pass.*$//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "add_ftp?user" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/&domain=/@/' | sed 's/&pass.*$//')
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# CONTAS DE FTP REMOVIDAS PELO CPANEL
del-ftp(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas de FTP removidas na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: A data deste log é 3 horas adiantada!$COLOR_OFF"
MAIN_LOG=$(grep -a "delete_ftp?user" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/%40/@/' | sed 's/&cache_fix=.*$//')
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "delete_ftp?user" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4 " - CONTA FTP: "$7}' | tr -d "[" | sed 's/\/cpsess.*?user=//' | sed 's/%40/@/' | sed 's/&cache_fix=.*$//')
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# ZONA DE DNS MODIFICADA
dns-zone(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de alterações realizadas na zona de DNS na conta do usuário $USUARIO! $COLOR_OFF"
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual domínio ou alteração especificamente foi realizada na zona de DNS! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a "/DNS/mass_edit_zone" /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep "/DNS/mass_edit_zone" /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
log-null
}

# ALTERAÇÕES DE SENHAS DE E-MAILS 
passwd-mail(){ 
echo -e "$GREEN_SINAL -$VERDE Verificando logs alterações de senhas de contas de e-mail do usuário $USUARIO! $COLOR_OFF" 
echo -e "$GREEN_SINAL -$AMARELO ATENÇÃO: O Log não informa qual e-mail foi modificado! A data deste log é 3 horas adiantada! $COLOR_OFF"
MAIN_LOG=$(grep -a 'passwd_pop' /usr/local/cpanel/logs/access_log | grep -w "$USUARIO" | grep -v "proxy" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG"
#ZIPADO
if [ $ZIP_KEY -eq 1 ];
then
echo -e "$GREEN_SINAL -$VERDE Verificando logs arquivados. A pesquisa pode demorar alguns minutos! Aguarde... $COLOR_OFF"
MAIN_LOG_ZIP=$(zgrep 'passwd_pop' /usr/local/cpanel/logs/archive/access_log-* | grep -w "$USUARIO" | grep -v "proxy" | awk -F " " '{print"IP DE ACESSO: "$1" - USUARIO: "$3 " - DATA: " $4}' | tr -d "[")
echo "$MAIN_LOG_ZIP" | sed 's/\/.*gz://'
fi
#SE VAZIO:
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
MAIN_LOG=$(grep $DOMINIO /var/log/exim_mainlog | grep -i "dropped" | awk -F" " '{print"hamlookup " $3}' | uniq)
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES MAILLOG ----------------------------------------- #

#PESQUISA CONEXÕES POP3 REALIZADAS
mail-pop3(){
mail-select2
echo -e "$GREEN_SINAL -$VERDE Verificando logs de conexões POP3 realizadas na conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(zgrep -i "$EMAIL" /var/log/maillog* | grep -v -i "Aborted" | grep -i "pop3-login" | grep -v "Disconnected:" | awk -F " " '{print "DATA: " $1 "-" $2 " - HORA: " $3 " - " $6 " - " $8 " - " $10}' | tr -d "/<>," | sed 's/varlog.*maillog://' | sed 's/rip=/IP: /' | sed 's/user=/EMAIL: /' | sed 's/varlogmaillog-//' | sed 's/202[0-9].*[0-9][0-9][0-9][0-9]://' | sort -k2M)
echo "$MAIN_LOG"
log-null
}

#PESQUISA CONEXÕES IMAP REALIZADAS
mail-imap(){
mail-select2
echo -e "$GREEN_SINAL -$VERDE Verificando logs de conexões IMAP realizadas na conta $EMAIL! Aguarde... $COLOR_OFF"
MAIN_LOG=$(zgrep -i "$EMAIL" /var/log/maillog* | grep -v -i "Aborted" | grep -i "imap-login" | grep -v "Disconnected:" | tr -d "/<>," | awk -F " " '{print "DATA: " $1 "/" $2 " - HORA: " $3 " - " $6 " - " $8 " - " $10}' | sed 's/varlog.*maillog://' | sed 's/rip=/IP: /' | sed 's/user=/EMAIL: /' | sed 's/varlogmaillog-//' | sed 's/202[0-9].*[0-9][0-9][0-9][0-9]://' | sort -k2M)
echo "$MAIN_LOG"
log-null
}

#PESQUISA POR MENSAGENS DE E-MAILS EXCLUÍDAS DE DETERMINADAS CONTAS.
mail-deleted(){
mail-select2
echo -e "$GREEN_SINAL -$VERDE Verificando logs de emails removidos da conta $EMAIL! Aguarde... $COLOR_OFF"
POP3_LOG=$(grep "$EMAIL" /var/log/maillog | egrep -v 'del=0' | egrep -i 'del=' | grep "pop3" | awk -F " " {'print"\033[32;1m""POP3 - ""DATA: ""\033[0m" $1" "$2" "$3"\033[32;1m"" - APAGADOS: ""\033[0m"$12"\033[32;1m"" - EMAIL: ""\033[0m"$6'} | tr -d "," | sed 's/pop3.*(//' | sed 's/).*://' ) 
IMAP_LOG=$(grep "$EMAIL" /var/log/maillog | egrep -v 'deleted=0|expunged=0|trashed=0' | egrep -i 'deleted=|expunged=|trashed=' | grep "imap" | sed 's/)<.*deleted//' | sed 's/=/ /' | sed 's/imap.*(//' | awk -F " " '{print"\033[32;1m""IMAP - ""DATA: ""\033[0m" $1" "$2" "$3"\033[32;1m"" - APAGADOS: ""\033[0m""deleted="$7" "$8" "$9"\033[32;1m"" - EMAIL: ""\033[0m"$6}')
echo "$POP3_LOG"
echo "$IMAP_LOG"  
}

# ------------------------------- FUNÇÕES ACCOUNTING.LOG ----------------------------------------- #

#REALIZA A VERIFICAÇÃO DA CRIAÇÃO E EXCLUSÃO DE CONTAS DE CPANEL NO SERVIDOR.
acct-log(){
domain-select
echo -e "$GREEN_SINAL -$VERDE Verificando logs de contas criadas/removidas com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep -w $USUARIO /var/cpanel/accounting.log | grep -i $DOMINIO | tr ":" " " | awk -F " " '{print "DATA: "$3"/"$2"/"$7" - HORA: "$4":"$5":"$6 " - AÇÃO: " $8 " - AUTOR: " $9"/"$10 " - DOMÍNIO: "$11 " - IP-LOCAL/USUÁRIO: " $12 "/" $13}') 
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES /VAR/LOG/MESSAGES ----------------------------------------- #

ftp-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de acessos FTP realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "ftpd" /var/log/messages | grep "$USUARIO" | grep "is now logged in" | awk -F " " '{print "DATA: " $1"/"$2 " - HORA: " $3 " - SERVIÇO: " $5 " - IP: " $6 }' | tr -d "()?@") 
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES /VAR/LOG/SECURE ----------------------------------------- #

ssh-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de acessos SSH realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "Starting session" /var/log/secure | grep "$USUARIO" | grep -v "sftp" | awk -F " " '{print "DATA: " $1 "/" $2 " - HORA: "$3 " - USUARIO: " $12 " - IP: " $14 " - PROTOCOLO: ssh"}') 
echo "$MAIN_LOG"
log-null
}

sftp-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de acessos SFTP realizado com o usuário: $USUARIO! Aguarde... $COLOR_OFF"
MAIN_LOG=$(grep "Starting session" /var/log/secure | grep "$USUARIO" | grep "sftp" | awk -F " " '{print "DATA: " $1 "/" $2 " - HORA: "$3 " - USUARIO: " $11 " - IP: " $13 " - PROTOCOLO: " $9}' | tr -d "'")
echo "$MAIN_LOG"
log-null
}

# ------------------------------- FUNÇÕES /usr/local/cpanel/logs/session_log ----------------------------------------- #

# LOGINS REALIZADOS COM SUCESSO NO CPANEL
cpanel-login(){
check-root
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loginsuccess" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS CRIADOS VIA API NO CPANEL
cpanel-session(){
check-root
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loadsession" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS INVALIDOS NO CPANEL
cpanel-fail(){
check-root
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins inválidos realizados na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "cpaneld" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "badpass" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[cpaneld/cpanel/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS REALIZADOS COM SUCESSO NO WHM
whm-login(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loginsuccess" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS CRIADOS VIA API NO WHM
whm-session(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "loadsession" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}

# LOGINS INVALIDOS NO WHM
whm-fail(){
echo -e "$GREEN_SINAL -$VERDE Verificando logs de Logins realizados com sucesso na conta do usuário $USUARIO! $COLOR_OFF"
MAIN_LOG=$(grep "whostmgrd" /usr/local/cpanel/logs/session_log | grep "$USUARIO" | grep "badpass" | awk -v username=$USUARIO -F" " '{print "\033[32;1m" "DATA: " "\033[0m" $1 " " $2 "\033[32;1m" " - IP DE ACESSO: " "\033[0m" $6 "\033[32;1m" " - PAINEL: " "\033[0m" $5 "\033[32;1m" " - USUÁRIO: " "\033[0m"  username}' | tr -d "]" | sed 's/\[whostmgrd/WHM/' | sed 's/\[2/2/')
echo "$MAIN_LOG"
log-null
}
# ------------------------------- EXECUÇÃO ----------------------------------------- #
check-root
check-user
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
#fi
