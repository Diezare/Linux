#!/bin/bash
#2023-06-06

##################################################################
#                           REFERÊNCIAS                          #
##################################################################

#Edmarcos Antonio de Souza - EDGE - http://www.edmarcos.com.br/
#OpenIA - ChatGPT - https://chat.openai.com/chat
#Adaptado por Diézare Conde - https://diezare.wordpress.com/

##################################################################
#                     DEFINIÇÃO DAS VARIÁVEIS                    #
##################################################################

# Endereço de e-mail para envio de notificações
email="seu@email.com"

# Formato de data
date_format=$(date "+%Y-%m-%d %H:%M:%S")

# Nome do servidor
hostname=$(hostname)

# Assunto do e-mail
email_subject="Verificacao da saude dos HDs em $date_format"

# Diretório onde o log será salvo
external_log="/var/saude"

# Local onde será salvo o log da saude do hd
log_file="/var/saude/$date_format-smart-check.log"

# Lista de discos já cadastrados
DISKS=$(lsblk -lpn -o NAME)

# Arquivo de log para discos que não foram reconhecidos
FAIL_LOG="/var/saude/falha-$date_format.log"

#Dias de arquivos de logs para ser removido
time=15

##################################################################
#           VERIFICA SE O SMARTMONTOOLS ESTÁ INSTALADO           #
##################################################################

if ! command -v smartctl &> /dev/null; then
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
    printf "[$date_format] O smartmontools nao esta instalado. Instalando...\n" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
    apt-get -y install smartmontools >> "$log_file" 2>&1
    if [ $? -eq 0 ]; then
                printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        printf "[$date_format] O smartmontools foi instalado com sucesso.\n" >> "$log_file"
    else
                printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        printf "[$date_format] Falha ao instalar o smartmontools. Verifique o log para mais detalhes.\n" >> "$log_file"
                printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        mail -s "ALERTA: Falha ao instalar o smartmontools em $date_format\n" "$email" < "$log_file"
        exit 1
    fi
else
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
    printf "[$date_format] O smartmontools já está instalado.\n" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
fi

##################################################################
#             VERIFICA SE HÁ DISCOS NAO RECONHECIDOS             #
##################################################################

declare -a MISSING_DISKS

for disk in $DISKS; do
    if ! [[ -b "$disk" ]]; then
        MISSING_DISKS+=("$disk")
    fi
done

if [[ ${#MISSING_DISKS[@]} -eq 0 ]]; then
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
    printf "Todos os discos foram reconhecidos.\n" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
else
    printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        printf "Os seguintes discos nao foram encontrados:\n" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
    for disk in "${MISSING_DISKS[@]}"; do
        printf "%s\n" "$disk"
    done | tee -a "$FAIL_LOG"
    mail -s "ALERTA: Um ou mais discos não foram reconhecidos em $date_format" "$email" < "$FAIL_LOG"
fi

##################################################################
#               VERIFICA A SAÚDE DOS HDS INSTALADOS              #
##################################################################

printf -- "-------------------------------------------------------------------\n" >> "$log_file"
printf "[$date_format] - Inicio da verificacao da saude dos HDs\n" >> "$log_file"
printf -- "-------------------------------------------------------------------\n" >> "$log_file"

##################################################################
#          VERIFICA AS PARTIÇÕES DOS DISCOS E PARTICOES          #
##################################################################

for disk in /dev/sd?; do
  printf -- "---------------------------------------------------------------\n" >> "$log_file"
  printf "Disco a ser analisado: %s\n" "$disk" >> "$log_file"
  smartctl -H "$disk" > "$log_file.temp"
  cat "$log_file.temp" >> "$log_file"
  rm "$log_file.temp"
  if [ $? -eq 0 ]; then
    printf "O disco %s está saudável.\n" "$disk" >> "$log_file"
    printf -- "-------------------------------------------------------------------\n" >> "$log_file"
  else
    printf -- "-------------------------------------------------------------------\n" >> "$log_file"
    printf "O disco %s está com problemas.\n" "$disk" >> "$log_file"
    printf -- "-------------------------------------------------------------------\n" >> "$log_file"
  fi
    printf -- "---------------------------------------------------------------\n" >> "$log_file"
    printf "Partições do %s sendo analisadas\n" "$disk" >> "$log_file"
    printf -- "-------------------------------------------------------------------\n" >> "$log_file"
  for part in "$disk"*; do
    if [ "$part" != "$disk" ]; then
      printf -- "-------------------------------------------------------------------\n" >> "$log_file"
      printf "Verificando partição %s\n" "$part" >> "$log_file"
      printf -- "-------------------------------------------------------------------\n" >> "$log_file"
      smartctl -H "$part" > "$log_file.temp"
      cat "$log_file.temp" >> "$log_file"
      rm "$log_file.temp"
      if [ $? -eq 0 ]; then
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        printf "A partição %s está saudável.\n" "$part" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
      else
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        printf "A partição %s está com problemas.\n" "$part" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
      fi
    fi
  done
done

##################################################################
#           ENVIA O E-MAIL COM O ARQUIVO DE LOG ANEXADO          #
##################################################################

if [[ -f "$log_file" ]]; then
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        printf "[$date_format] - Termino da verificação da saúde dos HDs\n" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        uuencode "$log_file" "$log_file" | mail -s "$email_subject" "$email"
else
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
    printf "[$date_format] - Não foi possível encontrar o arquivo de log $log_file.\n" >> "$log_file"
        printf -- "-------------------------------------------------------------------\n" >> "$log_file"
        mail -s "ALERTA: Arquivo de log não encontrado em $date_format" "$email" < "$log_file"
fi

##################################################################
#   EXCLUINDO OS ARQUIVOS DE BACKUP E LOGS MAIORES QUE X DIAS    #
##################################################################

if [ ! -d "$external_log" ]; then
  exit 1
fi

find "$external_log"/*.log -mtime +$time -exec rm -f {} \;

##################################################################
#              FIM DE ROTINA DE BACKUP AUTOMATIZADA              #
##################################################################















