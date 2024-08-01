#!/bin/bash
#2022-09-09
#2023-03-28
#2023-04-04
#2023-04-12
#2023-06-19
#2024-05-15

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

# Diretório que irá fazer backup
backup_path="/home"

# Diretório onde o backup será salvo
external_storage="/backup"

# Diretório onde o log será salvo
external_log="/backup"

# Formato de data - Y ano completo - m mes - d dia | H hora - M minutos - S segundos
date_format=$(date "+%Y-%m-%d_%H:%M:%S")

# Formato do arquivo compactado - tgz
final_archive="$date_format-backup.tgz"

# Local onde será salvo o log do backup
log_file="/backup/$date_format-backup.log"

# Dias de arquivos de backup para serem mantidos
dias_manter_backup=7

# Dias de arquivos de log para serem mantidos
dias_manter_log=7

# Número máximo de backups a serem mantidos
num_max_backups=7

# E-mail de destino para envio do log do backup
email_destination="seu@email.com"

# Assunto do e-mail
email_subject="Backup realizado em $date_format"

##################################################################
#   EXCLUINDO O BACKUP MAIS ANTIGO SE EXISTIREM MUITOS BACKUPS   #
##################################################################

# Verifica se existem mais backups do que o número máximo permitido
num_backups=$(ls -1 "$external_storage"/*.tgz 2>/dev/null | wc -l)
if [ "$num_backups" -gt "$num_max_backups" ]; then
    echo "Excluindo o backup mais antigo..."
    ls -1tr "$external_storage"/*.tgz | head -n 1 | xargs rm -f
fi

##################################################################
#                       INICIANDO O BACKUP                       #
##################################################################

cd "$backup_path"

if tar -czvf "$external_storage/$final_archive" "$backup_path"; then
        printf "[$date_format] BACKUP CONCLUIDO COM SUCESSO!\n" >> "$log_file"
else
        printf "[$date_format] NÃO FOI POSSÍVEL REALIZAR O BACKUP. POR FAVOR, VERIFICAR MANUALMENTE!\n" >> "$log_file"
        printf "[$date_format] - Erro ocorreu no arquivo: $(basename "$0"), linha: $LINENO\n" >> "$log_file"
fi

##################################################################
#                   ENVIANDO E-MAIL APÓS O BACKUP                #
##################################################################

if [ $? -ne 0 ]; then
  printf "[$date_format] ERRO NO BACKUP\n" >> "$log_file"
  printf "[$date_format] Tamanho do backup: $(du -sh "$external_storage/$final_archive" | cut -f1)\n" >> "$log_file"
  printf "[$date_format] Pastas backupadas:\n" >> "$log_file"
  ls -l "$backup_path" | awk '{if(NR>1) print $9}' >> "$log_file"
  printf "[$date_format] - Erro ocorreu em: $BASH_SOURCE, linha: $LINENO\n" >> "$log_file"
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

if [ -d "$external_log" ]; then
    find "$external_storage" -name "*.tgz" -mtime +$dias_manter_backup -exec rm -f {} +
    find "$external_log" -name "*.log" -mtime +$dias_manter_log -exec rm -f {} +
fi

##################################################################
#              FIM DE ROTINA DE BACKUP AUTOMATIZADA              #
##################################################################
