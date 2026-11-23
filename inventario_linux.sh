cat << 'EOF' > /tmp/info_relatorio.sh
#!/bin/bash
# Inventário Técnico V1.4 - Consultoria FK+

# Variáveis de Destino e Identidade
ARQUIVO="/tmp/relatorio_$(hostname)_$(date +%Y%m%d_%H%M).txt"
DATA_HORA=$(date "+%d/%m/%Y %H:%M:%S")

# Coleta de Identidade e SO (Ajustado para Proxmox)
HOSTNAME_STATIC=$(hostnamectl hostname --static)
if command -v pveversion >/dev/null 2>&1; then
    SO_PRETTY=$(pveversion)
else
    SO_PRETTY=$(hostnamectl | grep "Operating System" | cut -d: -f2 | xargs)
fi

KERNEL_VER=$(hostnamectl | grep "Kernel" | cut -d: -f2 | xargs)
ARCH=$(hostnamectl | grep "Architecture" | cut -d: -f2 | xargs)
HW_VENDOR=$(hostnamectl | grep "Hardware Vendor" | cut -d: -f2 | xargs)
HW_MODEL=$(hostnamectl | grep "Hardware Model" | cut -d: -f2 | xargs)

# Coleta de Rede (IP, Máscara, MAC e Gateway)
INTERFACE_PRINCIPAL=$(ip route show default | awk '/default/ {print $5}')
IP_ADDR=$(ip -o -4 addr show $INTERFACE_PRINCIPAL | awk '{print $4}')
MAC_ADDR=$(cat /sys/class/net/$INTERFACE_PRINCIPAL/address | tr '[:lower:]' '[:upper:]')
GATEWAY_DEFAULT=$(ip route | grep default | awk '{print $3}')

# Hardware Metrics
CPU_CORES=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
RAM_TOTAL=$(free -h | grep "Mem:" | awk '{print $2}')
SWAP_TOTAL=$(free -h | grep "Swap:" | awk '{print $2}')

{
    echo "====================================================="
    echo "      INFORMACOES DO SISTEMA OPERACIONAL"
    echo "====================================================="
    echo "Data/Hora: $DATA_HORA"
    echo "-----------------------------------------------------"
    echo "IDENTIDADE E SISTEMA"
    echo "Static Hostname: $HOSTNAME_STATIC"
    echo "Operating System: $SO_PRETTY"
    echo "Kernel: $KERNEL_VER ($ARCH)"
    echo "-----------------------------------------------------"
    echo "REDE"
    echo "Endereço IP/CIDR: $IP_ADDR"
    echo "Gateway Padrão: $GATEWAY_DEFAULT"
    echo "MAC Address: $MAC_ADDR"
    echo "-----------------------------------------------------"
    echo "CPU / MEMORIA"
    echo "Vendor/Model: $HW_VENDOR / $HW_MODEL"
    echo "Recursos: $CPU_CORES vCPUs | RAM: $RAM_TOTAL | Swap: $SWAP_TOTAL"
    echo "-----------------------------------------------------"
    echo "PARTICIONAMENTOS"
    # Nós priorizamos o isolamento de volumes críticos para resiliência
    df -hT | grep -vE '^(tmpfs|devtmpfs|overlay|squashfs|ramfs|/dev/loop|run|none)'
    echo "====================================================="
} > "$ARQUIVO"

echo "Procedimento concluído. Relatório gerado em: $ARQUIVO"
cat "$ARQUIVO"
EOF

# Atribuição de permissão e execução automática
chmod +x /tmp/info_relatorio.sh
/tmp/info_relatorio.sh
