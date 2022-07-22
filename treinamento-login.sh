#!/bin/bash
#VARIAVEIS
VERMELHO="\033[31;1m"
VERDE="\033[32;1m"
COLOR_OFF="\033[0m"
login=dudu
senha=pecefaster123
limite=3
tentativas=0
sucesso=0

#FUNÇÃO
login(){
    read -p "LOGIN: " login_input
    read -p "SENHA: " senha_input
    if [ "$login" = "$login_input" -a "$senha" = "$senha_input"  ]
    then
        sucesso=1
    fi
}

login

    while [ "$login" != "$login_input" -o "$senha" != "$senha_input" ]
    do
        if [ $tentativas -eq $limite ]
        then
            echo -e "$VERMELHO Você atingiu o limite de tentativas! Comunique o administrador para recuperar sua senha.$COLOR_OFF"
            exit 1
        fi
        echo -e "$VERMELHO Login ou Senha inválidos$COLOR_OFF"
        tentativas=$(($tentativas+1))
        echo -e "Você tem somente mais $VERMELHO$(($limite-$tentativas))$COLOR_OFF tentativas"
        login
    done

if [ $sucesso -eq 1 ]
then
    echo -e "$VERDE Login realizado com sucesso. Bem vindo! $COLOR_OFF"
else
    echo -e "$VERMELHO Você atingiu o limite de tentativas! Comunique o administrador para recuperar sua senha.$COLOR_OFF"
fi
