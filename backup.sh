#!/bin/bash
#2022-09-09
#2023-03-28
#2023-04-04
#2023-04-12

##################################################################
#                           REFERÊNCIAS                          #
##################################################################

#Slackjeff - https://www.youtube.com/watch?v=NjVtMaZR47Q
#Edmarcos Antonio de Souza - EDGE - http://www.edmarcos.com.br/
#OpenIA - ChatGPT - https://chat.openai.com/chat
#Adaptado por Diézare Conde - https://diezare.wordpress.com/

##################################################################
#                     DEFINIÇÃO DAS VARIÁVEIS                    #
##################################################################

#Diretorio que ira fazer backup
backup_path="/home/aes"

#Diretorio onde o backup sera salvo
external_storage="/mnt/backup"

#Diretorio onde o log sera salvo
external_log="/var/backup"

#Formato de data - Y ano completo - m mes - d  | H hora - M minutos - S segundos
date_format=$(date "+%Y-%m-%d--%H-%M-%S")

#Formato do arquivo compactado - tgz
final_archive="$date_format-backup.tgz"

#Local onde sera salvo o log do backup
log_file="/var/backup/$date_format-backup.log"

#Dias de arquivos de backup para ser removido
time=3

#E-mail de destino para envio do log do backup
email_destination="informatica@materdeiapucarana.com.br"

#Assunto do e-mail
email_subject="Backup realizado em $date_format"

#Nome do servidor
hostname=$(hostname)

#IP do servidor
ip_server="192.168.0.245"

#Credenciais de login para o servidor de backup
username="srvaes"
password="Mater@2021."

##################################################################
# TESTANDO A MONTAGEM DA UNIDADE QUE FICARA ARMAZENADO O BACKUP  #
#      CASO A UNIDADE NAO SEJA MONTADA, VOCE SERA NOTIFICADO     #
#        COM O ENVIO DE UM E-MAIL ALERTANDO SOBRE O ERRO         #
##################################################################

if ! mountpoint -q -- $external_storage; then
    printf "[$date_format] - Unidade de rede não montada em: $external_storage. Tentando montar automaticamente...\n" >> $log_file

    if ping -c 1 $ip_server; then
        sudo mount -t cifs -o username="$username",password="$password" //"$ip_server"/aes $external_storage

        if mountpoint -q -- $external_storage; then
            printf "[$date_format] - Unidade de rede $external_storage montada com sucesso.\n" >> $log_file
        else
            printf "[$date_format] - Não foi possível montar a unidade de rede $external_storage.\n" >> $log_file
			mail -s "Erro na montagem da unidade de rede em $date_format" -a "$log_file" "$email_destination" < "$log_file"
            exit 1
        fi
    else
        printf "[$date_format] - Não foi possível acessar o servidor $ip_server para montar a unidade de rede $external_storage. Tentando novamente...\n" >> $log_file
        if ping -c 1 $ip_server; then
            sudo mount -t cifs -o username="$username",password="$password" //"$ip_server"/aes $external_storage

            if mountpoint -q -- $external_storage; then
                printf "[$date_format] - Unidade de rede $external_storage montada com sucesso.\n" >> $log_file
            else
                printf "[$date_format] - Não foi possível montar a unidade de rede $external_storage.\n" >> $log_file
                mail -s "Erro na montagem da unidade de rede em $date_format" -a "$log_file" "$email_destination" < "$log_file"
                exit 1
            fi
        else
            printf "[$date_format] - Não foi possível acessar o servidor $ip_server para montar a unidade de rede $external_storage.\n" >> $log_file
            mail -s "Erro na montagem da unidade de rede. Abortando BACKUP em $date_format" -a "$log_file" "$email_destination" < "$log_file"
            exit 1
        fi
    fi
fi

##################################################################
#                       INICIANDO O BACKUP                       #
##################################################################

cd "$backup_path"

if tar -czvf "$external_storage/$final_archive" "$backup_path"; then
        printf "[$date_format] BACKUP CONCLUIDO COM SUCESSO!\n" >> "$log_file"
else
        printf "[$date_format] NÃO FOI POSSÍVEL REALIZAR O BACKUP. POR FAVOR, VERIFICAR MANUALMENTE!\n" >> "$log_file"
fi

##################################################################
#                   ENVIANDO E-MAIL APÓS O BACKUP                #
##################################################################

#if [ $? -ne 0 ]
#then
#  mail -s "Erro no backup em $date_format" -a "$log_file" "$email_destination" < "$log_file"
#else
#  uuencode "$log_file" "$log_file" | mail -s "$email_subject" "$email_destination"
#fi


if [ $? -ne 0 ]; then
  printf "[$date_format] ERRO NO BACKUP\n" >> "$log_file"
  printf "[$date_format] Tamanho do backup: $(du -sh "$external_storage/$final_archive" | cut -f1)\n" >> "$log_file"
  printf "[$date_format] Pastas backupadas:\n" >> "$log_file"
  ls -l "$backup_path" | awk '{if(NR>1) print $9}' >> "$log_file"
  mail -s "Erro no backup em $date_format" -a "$log_file" "$email_destination" < "$log_file"
else
  printf "[$date_format] BACKUP CONCLUÍDO COM SUCESSO!\n" >> "$log_file"
  printf "[$date_format] Tamanho do backup: $(du -sh "$external_storage/$final_archive" | cut -f1)\n" >> "$log_file"
  printf "[$date_format] Pastas backupadas:\n" >> "$log_file"
  ls -l "$backup_path" | awk '{if(NR>1) print $9}' >> "$log_file"
  uuencode "$log_file" "$log_file" | mail -s "$email_subject" "$email_destination"
fi


##################################################################
#   EXCLUINDO OS ARQUIVOS DE BACKUP E LOGS MAIORES QUE X DIAS    #
##################################################################

find "$external_storage"/*.tgz -mtime +$time -exec rm -f {} \;
find "$external_log"/*.log -mtime +$time -exec rm -f {} \;