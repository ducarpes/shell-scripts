#!/usr/bin/env bash 
#
# restore-mail.sh - Realiza restauração de e-mails em arquivo de backup de cpanel.
# 
# Autor:      Eduardo C. Souza 
# Manutenção: Eduardo C. Souza 
# 
# ------------------------------------------------------------------------ # 
#  Este Script verifica quais Emails estão disponíveis no arquivo de backup especificado e permite escolher um banco para realizar 
#  a restauração ou realizar a restauração de todos os e-mails
# 
#  Exemplos: 
#      $ ./restore-mail.sh backup-5.13.2022_17-17-36_simulado.tar.gz -a
#      Neste exemplo o Script vai restaurar todos os e-mails existentes no arquivo de backup
#      
#      $ ./restore-mail.sh backup-5.13.2022_17-17-36_simulado.tar.gz domínio.com.br
#      Neste exemplo o Script vai exibir os e-mails do domínio inserido e solicitar para escolher apenas 1 para ser restaurado
#
# ------------------------------------------------------------------------ # 
# Histórico: 
# 
#   v1.0 11/06/2022, Eduardo: 
# ------------------------------------------------------------------------ # 
# ------------------------------- VARIÁVEIS ----------------------------------------- #

#GERAIS
BACKUP_NAME=$(echo $1 | sed s/.tar.gz//)
DOMINIO_INPUT=$2
ARQUIVO_INPUT=$1
DATA_BACKUP=$(date +'%d-%m-%Y')
HORA_BACKUP=$(date +'%H-%M-%S')

#CORES
VERMELHO="\033[31;1m"
VERDE="\033[32;1m"
AMARELO="\033[33;1m"
COLOR_OFF="\033[0m"
RED_SINAL="[$VERMELHO ! $COLOR_OFF]"
GREEN_SINAL="[$VERDE ! $COLOR_OFF]"
YELLOW_SINAL="[$AMARELO ! $COLOR_OFF]"

#CONTADORES E CHAVES
EMAIL_CHAVE=0
DOMINIO_CHAVE=0
COMPLETO_CHAVE=0
LOOP_KEY=0
# ------------------------------------------------------------------------ # 

# ------------------------------- FUNÇÕES ----------------------------------------- #

#--help
ajuda(){

echo -e "
$VERMELHO[AJUDA]$COLOR_OFF
 
1 - Não utilize o caminho absoluto para designar o arquivo de backup;
2 - Execute o comando detro do mesmo diretório que arquivo que deseja restaurar;
3 - O usuário do backup deverá ser o mesmo usuário do Cpanel.

$VERMELHO[SINTAXE]$COLOR_OFF

./restore-mail.sh $AMARELO <ARQUIVO_DE_BACKUP> <DOMÍNIO | -a> $COLOR_OFF

$VERDE [EXEMPLO]: $COLOR_OFF ./restore-mail.sh $AMARELO backup-6.7.2022_17-02-55_exemplo.tar.gz exemplo.com.br $COLOR_OFF

$VERMELHO[OPÇÔES]$COLOR_OFF

-a -> REALIZA RESTAURAÇÃO DE TODOS OS E-MAILS
$VERDE [EXEMPLO]: $COLOR_OFF ./restore-mail.sh $AMARELO backup-6.7.2022_17-02-55_exemplo.tar.gz -a $COLOR_OFF

--help -> EXIBE AJUDA
$VERDE [EXEMPLO]: $COLOR_OFF ./restore-mail.sh $AMARELO --help $COLOR_OFF
"
exit
}

# ------------------------------------------------------------------------ # 

# ------------------------------- TESTES ----------------------------------------- # 

if [ "$PWD" = "/" ]
    then 
        echo -e "$RED_SINAL -$AMARELO Não é possível executar este script diretamente dentro do diretório raiz (/).$COLOR_OFF"
        echo -e "$YELLOW_SINAL - Execute o Script em outro diretório."
        exit 1
fi

#VERIFICAR SE A AJUDA FOI CHAMADA (--help)
if [ "$1" = "--help" ] || [ "$2" = "--help" ]; 
    then
        ajuda
fi

#VERIFICAR SE A RESTAURAÇÃO DO BACKUP É COMPLETA
if [ "$2" = "-a" ]; 
    then
        COMPLETO_CHAVE=1
fi

#VERIFICAR QUANTIDADE DE ARGUMENTOS/OPÇÕES DECLARADAS
if [ $# -ne 2 ]; 
    then
        echo -e "$RED_SINAL -$AMARELO Argumentos inválidos! Digite o nome do arquivo de backup do Cpanel e o domínio que deseja verificar! $COLOR_OFF"
        ajuda
        exit 1
fi


#VERIFICAR NOME DO USUÁRIO DE CPANEL ATRAVÉS DO ARQUIVO DE BACKUP E VALIDAR QUE O ARQUIVO DE BACKUP EXISTE NESTE DIRETÓRIO
if [ -f $PWD/$1 ];
    then    
        case $1 in
            *"backup"*)
                USUARIO=$( echo $BACKUP_NAME | sed 's/backup.*_//' )
                ;;

            *"cpmove"*)
                USUARIO=$( echo $BACKUP_NAME | awk -F"." {'print$1'} | sed s/cpmove-// )
                ;;
            
            *".tar.gz"*)
                USUARIO=$( echo $BACKUP_NAME | awk -F"." {'print$1'} )
                ;;
            
            *)
                echo -e "$RED_SINAL -$AMARELO O Arquivo $VERMELHO$1$AMARELO é inválido$COLOR_OFF!"
                echo -e "$YELLOW_SINAL - Certifique-se de utilizar um backup completo de Cpanel válido!"
                exit 1
                ;;  
        esac

        #VERIFICAR SE O USUÁRIO É VÁLIDO (EVITAR QUE O USUÁRIO SEJA O ROOT) (EVITAR CONFLITO COM ARQUIVOS DE MESMO NOME)
        if [ -f $PWD/$BACKUP_NAME ]
        then
            echo -e "$RED_SINAL -$AMARELO Já existe um diretório chamado $VERMELHO$BACKUP_NAME$AMARELO dentro deste diretório atual. Não é possível realizar a extração!$COLOR_OFF"
            echo -e "$YELLOW_SINAL - Se possível Remova ou renomeie o diretório existente ou mova o backup para outro diretório!"
            #Atualização para o futuro: implementar utilização de um diretório temporário para extração dos arquivos
            exit 1
        fi
        if [ $USUARIO = "root" ]
        then
            echo -e "$RED_SINAL -$AMARELO Não é possível restaurar um backup do usuário $VERMELHO$USUARIO$AMARELO! $COLOR_OFF"
            exit 1
        fi
    else
    echo -e "$RED_SINAL - $AMARELO O arquivo $VERMELHO$1$AMARELO não foi localizado neste diretório! $COLOR_OFF";
    exit 1;
fi;

#VERIFICAR SE O USUÁRIO EXISTE NO SERVIDOR ONDE O BACKUP ESTÁ SENDO RESTAURADO
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


# ------------------------------------------------------------------------ # 

# ------------------------------- EXECUÇÃO - RESTAURAÇÃO COMPLETA (flag -a) ----------------------------------------- #

#REALIZA A RESTAURAÇÂO DE TODA A PASTA /MAIL CASO A OPÇÃO -a SEJA UTILIZADA E FINALIZA O SCRIPT
if [ $COMPLETO_CHAVE -eq 1 ]; then
    read -p "$(echo -e "$YELLOW_SINAL Este procedimento realiza a restauração de backup completo de e-mails. Deseja prosseguir? (s/n):")" RESTORE_ALL_INPUT
    if [ "$RESTORE_ALL_INPUT" = "s" ]; then
        echo -e "$GREEN_SINAL - O Usuário $VERDE$USUARIO$COLOR_OFF existe neste servidor!"
        echo -e "$GREEN_SINAL - O backup de todos os e-mails será restaurado:"
        echo -e "$GREEN_SINAL - Extraindo conteúdo dos e-mails..."
        tar -xf $1 $BACKUP_NAME/homedir/mail --warning=no-timestamp 2>/dev/null
        tar -xf $1 $BACKUP_NAME/homedir/etc --warning=no-timestamp 2>/dev/null
        if [ $? -eq 0 ]
        then
            echo -e "$GREEN_SINAL - Restaurando e-mails com Rsync..."
            if [ ! -d $HOME_USUARIO/mail ]
            then
                mkdir -p $HOME_USUARIO/mail/
                
            fi
            if [ ! -d $HOME_USUARIO/etc ]
            then 
                mkdir -p $HOME_USUARIO/etc/
            fi

            #BACKUP /ETC
            for diretorio in $(ls -l $HOME_USUARIO/etc/ | grep '^d' | awk -F" " {'print$9'}); do cp $HOME_USUARIO/etc/$diretorio/shadow $HOME_USUARIO/etc/$diretorio/shadow.bkp; done;
            for diretorio in $(ls -l $HOME_USUARIO/etc/ | grep '^d' | awk -F" " {'print$9'}); do cp $HOME_USUARIO/etc/$diretorio/passwd $HOME_USUARIO/etc/$diretorio/passwd.bkp; done;
            tar -czf $HOME_USUARIO/etc/etc-bkp.$DATA_BACKUP.$HORA_BACKUP.tar.gz $HOME_USUARIO/etc/ -P --warning=no-timestamp 2>/dev/null
            #RESTORE
            rsync -qzarhP $BACKUP_NAME/homedir/etc/* $HOME_USUARIO/etc/
            rsync -qzarhP $BACKUP_NAME/homedir/mail/* $HOME_USUARIO/mail/
            for diretorio in $(ls -l $HOME_USUARIO/etc/ | grep '^d' | awk -F" " {'print$9'}); do cat $HOME_USUARIO/etc/$diretorio/shadow $HOME_USUARIO/etc/$diretorio/shadow.bkp | sort -u -o $HOME_USUARIO/etc/$diretorio/shadow; done 2>/dev/null
            for diretorio in $(ls -l $HOME_USUARIO/etc/ | grep '^d' | awk -F" " {'print$9'}); do cat $HOME_USUARIO/etc/$diretorio/passwd $HOME_USUARIO/etc/$diretorio/passwd.bkp | sort -u -o $HOME_USUARIO/etc/$diretorio/passwd; done 2>/dev/null

            echo -e "$GREEN_SINAL - Todos os E-mails disponíveis neste backup foram restaurados com sucesso."
            rm -rf $PWD/$BACKUP_NAME
            echo -e "$GREEN_SINAL - Executando perms para correção depermissões..."
            cd $HOME_USUARIO
            perms 1>/dev/null
            echo -e "$GREEN_SINAL - Operação concluída com sucesso"
            exit 0
        else
            echo -e "$RED_SINAL -$AMARELO Arquivo de Backup selecionado pode estar corrompido ou possui formato inválido para esta restauração.$COLOR_OFF"
            exit 1
        fi
    else
        echo -e "$GREEN_SINAL - A restauração completa não será executada"
        exit 1
    fi
fi
# ------------------------------------------------------------------------ # 

# ------------------------------- EXECUÇÃO - RESTAURAÇÃO INDIVUDUAL DE CONTA DE E-MAIL ----------------------------------------- # 

#VERIFICAR SE O DOMÍNIO ESCOLHIDO PARA O ARGUMENTO $2 EXISTE NO ARQUIVO DE BACKUP:
tar -xf $1 $BACKUP_NAME/cp/$USUARIO --warning=no-timestamp --ignore-command-error;
if [ $? -ne 0 ]
then
    echo -e "$RED_SINAL -$AMARELO Arquivo de Backup selecionado pode estar corrompido ou possui formato inválido para esta restauração.$COLOR_OFF"
    exit 1
else
    if [ -d $BACKUP_NAME/cp/ ];
    then
        DOMINIOS=$(cat $BACKUP_NAME/cp/$USUARIO | grep "DNS" | sed 's/backup.*=//' | grep -v "backup" | sed 's/DNS.*=//');
        rm -rf $PWD/$BACKUP_NAME;
    fi
fi
for DOMINIO in $DOMINIOS
do
    if [ "$2" = "$DOMINIO" ]
        then
            DOMINIO_CHAVE=1 
    fi
done

if [ $DOMINIO_CHAVE -ne 1 ]
then
    echo -e "$RED_SINAL -$AMARELO O domínio $VERMELHO$2$AMARELO não existe neste backup ou não é um formato de domínio válido!$COLOR_OFF"
    exit 1
fi

#VERIFICA SE O ARQUIVO É INTEGRO E ESTÁ NO FORMATO DE BACKUP DE CPANEL:
EMAIL_USERS=$(echo "$(tar --ignore-command-error -tvf $1 $BACKUP_NAME/homedir/mail/$2)" | awk -F" " {'print $6'} | awk -F"/" {'print $5'} | uniq)
if [ $? -ne 0 ]
then 
    echo -e "$RED_SINAL -$VERMELHO O Backup está corrompido. $COLOR_OFF 
    A pasta $AMARELO $BACKUP_NAME/homedir/mail $COLOR_OFF não foi localizada neste backup";
    exit 1
fi
    
#CRIA FUNÇÃO PARA LISTAR OS EMAILS DO DOMÍNIO ESCOLHIDO E SOLICITA QUE UM DELES SEJA SELECIONADO PARA RESTAURAÇÃO:
restore(){
echo -e "$GREEN_SINAL - Os seguintes E-mails foram localizados e estão disponíveis para restauração:"    
for LINE in $EMAIL_USERS;
    do echo -e $AMARELO"E-mail localizado: $VERDE $LINE@$DOMINIO_INPUT $COLOR_OFF";
done;

echo -e "$GREEN_SINAL - Selecione um dos E-mails listados para prosseguir com a restauração da conta."
read -p "Insira o E-mail que deseja restaurar: " EMAIL_INPUT

#VERIFICA SE O INPUT É UM DOS EMAILS LISTADOS E ATIVE UM SWITCH PARA PERMITIR O PROSSEGUIMENTO:
for LINE in $EMAIL_USERS
do
    if [ "$EMAIL_INPUT" = "$LINE@$DOMINIO_INPUT" ]
    then
        EMAIL_CHAVE=1 
    fi
done

#INICIA O PROCESSO DE RESTAURAÇÃO DO EMAIL
if [ $EMAIL_CHAVE -eq 1 ]
then
    echo -e "$GREEN_SINAL - O backup de $VERDE$EMAIL_INPUT$COLOR_OFF será restaurado!"
    EMAIL_DIR=$(echo $EMAIL_INPUT | awk -F"@" {'print$1'})
    echo -e "$GREEN_SINAL - Extraindo conteúdo do e-mail $EMAIL_INPUT..."
    tar -xf $ARQUIVO_INPUT $BACKUP_NAME/homedir/mail/$DOMINIO_INPUT/$EMAIL_DIR --warning=no-timestamp
    tar -xf $ARQUIVO_INPUT $BACKUP_NAME/homedir/etc/$DOMINIO_INPUT --warning=no-timestamp
    echo -e "$GREEN_SINAL - Restaurando e-mails com Rsync..."
    if [ ! -d $HOME_USUARIO/mail/$DOMINIO_INPUT/$EMAIL_DIR ]
    then
        mkdir -p $HOME_USUARIO/mail/$DOMINIO_INPUT/$EMAIL_DIR/
    fi
    if [ ! -d $HOME_USUARIO/etc/$DOMINIO_INPUT ]
    then
        mkdir -p $HOME_USUARIO/etc/$DOMINIO_INPUT/
    fi
    
    #RESTAURANDO ARQUIVO /ETC/DOMINIO/SHADOW
    if [ -f $HOME_USUARIO/etc/$DOMINIO_INPUT/shadow ]
    then
        cp $HOME_USUARIO/etc/$DOMINIO_INPUT/shadow $HOME_USUARIO/etc/$DOMINIO_INPUT/shadow.backup.$DATA_BACKUP
    else
        touch $HOME_USUARIO/etc/$DOMINIO_INPUT/shadow
        SHADOW_LINE=$(cat $BACKUP_NAME/homedir/etc/$DOMINIO_INPUT/shadow | grep -w $EMAIL_DIR)
        echo "$SHADOW_LINE" >> $HOME_USUARIO/etc/$DOMINIO_INPUT/shadow
    fi
    
    if [ -z $(grep -w "$EMAIL_DIR:" $HOME_USUARIO/etc/$DOMINIO_INPUT/shadow) ]
    then
        SHADOW_LINE=$(cat $BACKUP_NAME/homedir/etc/$DOMINIO_INPUT/shadow | grep -w $EMAIL_DIR)
        echo "$SHADOW_LINE" >> $HOME_USUARIO/etc/$DOMINIO_INPUT/shadow
    fi

    #RESTAURANDO ARQUIVO /ETC/DOMINIO/PASSWD
    if [ -f $HOME_USUARIO/etc/$DOMINIO_INPUT/passwd ]
    then
        cp $HOME_USUARIO/etc/$DOMINIO_INPUT/passwd $HOME_USUARIO/etc/$DOMINIO_INPUT/passwd-backup-$DATA_BACKUP-$HORA_BACKUP
    else
        touch $HOME_USUARIO/etc/$DOMINIO_INPUT/passwd
        SHADOW_LINE=$(cat $BACKUP_NAME/homedir/etc/$DOMINIO_INPUT/passwd | grep -w $EMAIL_DIR)
        echo "$SHADOW_LINE" >> $HOME_USUARIO/etc/$DOMINIO_INPUT/passwd
    fi
    
    if [ -z $(grep -w "$EMAIL_DIR:" $HOME_USUARIO/etc/$DOMINIO_INPUT/passwd) ]
    then
        SHADOW_LINE=$(cat $BACKUP_NAME/homedir/etc/$DOMINIO_INPUT/passwd | grep -w $EMAIL_DIR)
        echo "$SHADOW_LINE" >> $HOME_USUARIO/etc/$DOMINIO_INPUT/passwd
    fi

    #RESTAURANDO ARQUIVOS DA PASTA /MAIL
    rsync -qzarhP $BACKUP_NAME/homedir/mail/$DOMINIO_INPUT/$EMAIL_DIR/* $HOME_USUARIO/mail/$DOMINIO_INPUT/$EMAIL_DIR
    echo -e "$GREEN_SINAL -$VERDE E-mails restaurados com sucesso.$COLOR_OFF"
    rm -rf $PWD/$BACKUP_NAME
    echo -e "$GREEN_SINAL - Executando perms para correção depermissões..."
    cd $HOME_USUARIO
    perms 1>/dev/null
    echo -e "$GREEN_SINAL - Operação concluída com sucesso"
    exit 0
else
    echo -e "$RED_SINAL -$AMARELO Não é possível restaurar o e-mail solicitado $VERMELHO($EMAIL_INPUT)$AMARELO. Escolha um email listado anteriormente! $COLOR_OFF"
fi
}

#REALIZA A RESTAURAÇÃO ATRAVÉS DA FUNÇÃO
restore

#ENQUANTO O IPUNT FOR INVÁLIDO, SOLICITA QUE ENTRE COM UM VALOR VÁLIDO.
while [ $EMAIL_CHAVE -ne 1 ]
do
    clear
    echo -e "$RED_SINAL -$AMARELO Não é possível restaurar o e-mail solicitado $VERMELHO($EMAIL_INPUT)$AMARELO. Escolha um email listado anteriormente! $COLOR_OFF"
    restore
done
# ------------------------------------------------------------------------ #
