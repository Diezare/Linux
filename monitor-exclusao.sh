#!/bin/bash

##################################################################
#                     DEFINIÇÃO DAS VARIÁVEIS                    #
##################################################################

# Endereço de e-mail para envio de notificações
email="info@seu-email.com"

# Formato de data
date_format=$(date "+%Y-%m-%d--%H-%M-%S")

# Nome do servidor
hostname=$(hostname)

# Assunto do e-mail
email_subject="Arquivo ou diretório excluído em $date_format"

# Diretório onde o log será salvo
external_log="/var/excluidos"

# Local onde será salvo o log dos arquivos excluídos
log_file="/var/excluidos/$date_format-monitor-exclusao-arquivos.log"

# Diretório raiz a ser monitorado
root_directory="/"

# Dias de arquivos de logs para serem removidos
dias_exclusao=15

##################################################################
#           VERIFICA SE O INOTIFY-TOOLS ESTÁ INSTALADO           #
##################################################################

if ! command -v inotifywait &> /dev/null; then
    printf "[$date_format] O pacote inotify-tools não está instalado. Instale-o com o comando 'sudo apt-get install inotify-tools' (Ubuntu/Debian)." >> "$log_file"
    exit 1
fi

##################################################################
#           AUMENTA O LIMITE DE OBSERVADORES DO INOTIFY           #
##################################################################

if [[ $(cat /proc/sys/fs/inotify/max_user_watches) -lt 524288 ]]; then
    printf "[$date_format] Aumentando o limite de observadores do inotify...\n" >> "$log_file"
    sudo sysctl -w fs.inotify.max_user_watches=524288 >> "$log_file"
fi

##################################################################
#           MONITORA A EXCLUSÃO DE ARQUIVOS E DIRETÓRIOS          #
##################################################################

inotifywait -mrq --format '%w%f' -e delete,delete_self,move_self "$root_directory" | while read -r deleted_file
do
    # Verifica se o caminho é um arquivo ou diretório válido
    if [ -f "$deleted_file" ] || [ -d "$deleted_file" ]; then
        # Notificação de exclusão do arquivo/diretório
        echo "Arquivo ou diretório excluído: $deleted_file em $(date)" >> "$log_file"
        mail -s "$email_subject" -a "$log_file" "$email" <<< "Arquivo ou diretório $deleted_file foi excluído. Verifique o arquivo de log anexado."
    fi
done

##################################################################
#        EXCLUINDO OS ARQUIVOS DE LOGS MAIORES QUE X DIAS         #
##################################################################

if [ ! -d "$external_log" ]; then
  exit 1
fi

find "$external_log"/*.log -mtime +$dias_exclusao -exec rm -r {} \;