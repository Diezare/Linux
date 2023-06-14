#!/bin/bash
#2023-04-14
#2023-06-05

##################################################################
#                     DEFINIÇÃO DAS VARIÁVEIS                    #
##################################################################

# E-mail de destino para envio do log do backup
email_destination="informatica@materdeiapucarana.com.br"

# Obtém a utilização atual do disco - depois do df -h vem a unidade para verificar
#uso=$(df -h /backup | awk '{print $5}' | tail -n 1 | cut -d'%' -f1)

# Defina aqui o limite de utilização do disco
limit=85

# Formato de data
date_format=$(date "+%Y-%m-%d--%H-%M-%S")

# Diretório onde o log será salvo
external_log="/var/hd"

# Local onde será salvo o log do espaco do hd
log_file="/var/hd/$date_format-backup.log"

# Dias de arquivos de backup para serem removidos
time=15

#Assunto do e-mail
email_subject="Alerta de capacidade de HD."

# Obtém a lista de discos excluindo os sistemas de arquivos especiais e o disco de swap
discos=($(lsblk -rno NAME,MOUNTPOINT | awk '$2 != "" && $2 != "[SWAP]" {print $2}'))

# Obtém o espaço restante em todos os discos
mapfile -t discos < <(df -h | awk 'NR>1 {print $1}')

##################################################################
#VERIFICA SE A UTILIZAÇÃO DO DISCO ESTÁ ACIMA DO LIMITE DEFINIDO #
##################################################################

for disco in "${discos[@]}"; do
  # Ignorar sistemas de arquivos que não são diretórios físicos
  if [ ! -e "$disco" ]; then
    continue
  fi

  nome_disco=$(basename "$disco")
  capacidade=$(df -h "$disco" | awk 'NR>1 {print $5}')
  espaco_restante=$(df -h "$disco" | awk 'NR>1 {print $4}')
  uso=$(df -h "$disco" | awk 'NR>1 {print $5}' | cut -d'%' -f1)

  if [[ "$uso" =~ ^[0-9]+$ ]]; then
    printf -- "--------------------------------------------------\n" >> "$log_file"
    printf "[$date_format] - Limite da partição: %s%%\n" "$limit" >> "$log_file"
    printf "[$date_format] - Nome do disco: %s\n" "$nome_disco" >> "$log_file"
    printf "[$date_format] - Espaço restante em disco %s: %s\n" "$disco" "$espaco_restante" >> "$log_file"
    printf "[$date_format] - Capacidade de uso em disco %s: %s\n" "$disco" "$capacidade" >> "$log_file"
    if [ "$uso" -gt "$limit" ]; then
      printf "[$date_format] - ALERTA: A utilização do disco %s está atualmente em %s%%, o que está acima do limite de %s%%\n" "$disco" "$uso" "$limit" >> "$log_file"
    else
      printf "[$date_format] - A utilização do disco %s está atualmente em %s%%, dentro do limite de %s%%\n" "$disco" "$uso" "$limit" >> "$log_file"
    fi
    printf -- "--------------------------------------------------\n" >> "$log_file"
  fi
done

printf -- "--------------------------------------------------\n" >> "$log_file"
printf "Capacidade total\n" >> "$log_file"
printf -- "--------------------------------------------------\n" >> "$log_file"
df -h >> "$log_file"

uuencode "$log_file" "$log_file" | mail -s "$email_subject" "$email_destination"
exit 1

##################################################################
#   EXCLUINDO OS ARQUIVOS DE BACKUP E LOGS MAIORES QUE X DIAS    #
##################################################################

if [ ! -d "$external_log" ]; then
  exit 1
fi

find "$external_log"/*.log -mtime +$time -exec rm -f {} \;