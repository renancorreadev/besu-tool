#!/bin/bash


# Configurações padrão
BESU_NODE="localhost:8545"
SCRIPT_NAME="besu.sh"


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "\n${CYAN}=== $1 ===${NC}"
}

# Função para fazer chamadas RPC
rpc_call() {
    local method="$1"
    local params="$2"
    local node="${3:-$BESU_NODE}"

    if [ -z "$params" ]; then
        params="[]"
    fi

    curl -s -X POST -H "Content-Type: application/json" "http://$node" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params,\"id\":1}" 2>/dev/null
}

# Função para extrair resultado do JSON (sem jq)
extract_result() {
    local json="$1"
    echo "$json" | sed -n 's/.*"result":"\?\([^",}]*\)"\?.*/\1/p'
}

extract_full_result() {
    local json="$1"
    echo "$json" | sed -n 's/.*"result":\([^}]*}\).*/\1/p'
}

# Função para conversão hexadecimal para decimal
hex_to_dec() {
    local hex="$1"
    echo $((${hex}))
}

# Função para validar hash de transação
validate_tx_hash() {
    local hash="$1"

    # Debug: mostrar o que foi recebido
    if [ -z "$hash" ]; then
        log_error "Hash de transação não fornecido"
        log_info "Uso: $SCRIPT_NAME tx-status <hash>"
        log_info "Exemplo: $SCRIPT_NAME tx-status 0x33d88fcccfe727a1d4e36225500d2b32e9104a4d9f6f91e9d464cc1f88b2884a"
        return 1
    fi

    # Verificar se começa com 0x
    if [[ ! "$hash" =~ ^0x ]]; then
        log_error "Hash deve começar com '0x'"
        log_info "Hash recebido: '$hash'"
        return 1
    fi

    # Verificar comprimento (0x + 64 caracteres = 66 total)
    if [ ${#hash} -ne 66 ]; then
        log_error "Hash deve ter 66 caracteres (0x + 64 hex)"
        log_info "Hash recebido tem ${#hash} caracteres: '$hash'"
        return 1
    fi

    # Verificar se são caracteres hexadecimais válidos
    if [[ ! "$hash" =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        log_error "Hash contém caracteres inválidos (apenas 0-9, a-f, A-F permitidos após 0x)"
        log_info "Hash recebido: '$hash'"
        return 1
    fi

    return 0
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
${CYAN}=== BESU DEBUG TOOL - Rede Bradesco ===${NC}

${YELLOW}COMANDOS DE TRANSAÇÃO:${NC}
  $SCRIPT_NAME tx-receipt <hash>              - Obter recibo de transação
  $SCRIPT_NAME tx-details <hash>              - Obter detalhes completos da transação
  $SCRIPT_NAME tx-status <hash>               - Status resumido da transação
  $SCRIPT_NAME tx-pending                     - Listar transações pendentes
  $SCRIPT_NAME tx-count-pending               - Contar transações pendentes

${YELLOW}COMANDOS DE REDE:${NC}
  $SCRIPT_NAME network-status                 - Status geral da rede
  $SCRIPT_NAME block-number                   - Último bloco minerado
  $SCRIPT_NAME peer-count                     - Número de peers conectados
  $SCRIPT_NAME node-info                      - Informações do nó
  $SCRIPT_NAME chain-id                       - ID da blockchain

${YELLOW}COMANDOS DE MONITORAMENTO:${NC}
  $SCRIPT_NAME health-check                   - Verificação completa de saúde
  $SCRIPT_NAME monitor-blocks [intervalo]     - Monitorar novos blocos (padrão: 5s)
  $SCRIPT_NAME node-status <ip:porta>         - Status de um nó específico
  $SCRIPT_NAME network-scan                   - Escanear todos os nós conhecidos

${YELLOW}COMANDOS DE SISTEMA:${NC}
  $SCRIPT_NAME service-status                 - Status do serviço Besu local
  $SCRIPT_NAME service-logs [linhas]          - Logs do serviço (padrão: 50 linhas)
  $SCRIPT_NAME service-restart               - Reiniciar serviço Besu
  $SCRIPT_NAME metrics                        - Verificar métricas (se disponível)

${YELLOW}OPÇÕES GERAIS:${NC}
  --node <ip:porta>                          - Especificar nó diferente
  --json                                     - Output em formato JSON
  --help, -h                                 - Mostrar esta ajuda

${YELLOW}EXEMPLOS:${NC}
  $SCRIPT_NAME tx-status 0x7b29286158256ab6c4ea7eb69e797e1934b97844a36601ac017130fd9e988bfe
  $SCRIPT_NAME health-check
  $SCRIPT_NAME monitor-blocks 3
  $SCRIPT_NAME node-status 172.23.105.99:8545
  $SCRIPT_NAME tx-receipt 0xabc123... --node 172.23.105.101:8545

${YELLOW}NODOS CONHECIDOS (Configuração Bradesco):${NC}
  172.23.105.97:8545  (padrão)
  172.23.105.99:8545  (bootnode)
  172.23.105.82:8545  (bootnode)
  172.23.105.101:8545
  172.23.105.105:8545 (bootnode)
  172.23.105.107:8545
  172.23.105.108:8545

EOF
}

# Função para obter recibo de transação
get_tx_receipt() {
    local hash="$1"
    local json_output="$2"

    if ! validate_tx_hash "$hash"; then
        return 1
    fi

    log_header "RECIBO DA TRANSAÇÃO"
    log_info "Hash: $hash"
    log_info "Consultando nó: $BESU_NODE"

    local result=$(rpc_call "eth_getTransactionReceipt" "[\"$hash\"]")

    if [ "$json_output" = "true" ]; then
        echo "$result"
        return
    fi

    if echo "$result" | grep -q '"result":null'; then
        log_warning "Transação não encontrada ou ainda não foi minerada"
        log_info "Verificando se está pendente..."
        check_pending_tx "$hash"
    elif echo "$result" | grep -q '"status":"0x1"'; then
        log_success "Transação CONFIRMADA com sucesso!"
        extract_receipt_info "$result"
    elif echo "$result" | grep -q '"status":"0x0"'; then
        log_error "Transação FALHOU na execução!"
        extract_receipt_info "$result"
    else
        log_error "Resposta inesperada do nó"
        echo "$result"
    fi
}

# Função para extrair informações do recibo
extract_receipt_info() {
    local json="$1"

    local block_number=$(echo "$json" | sed -n 's/.*"blockNumber":"\([^"]*\)".*/\1/p')
    local gas_used=$(echo "$json" | sed -n 's/.*"gasUsed":"\([^"]*\)".*/\1/p')
    local tx_index=$(echo "$json" | sed -n 's/.*"transactionIndex":"\([^"]*\)".*/\1/p')

    if [ -n "$block_number" ]; then
        local block_dec=$(hex_to_dec "$block_number")
        echo "  • Bloco: $block_dec ($block_number)"
    fi

    if [ -n "$gas_used" ]; then
        local gas_dec=$(hex_to_dec "$gas_used")
        echo "  • Gas usado: $gas_dec ($gas_used)"
    fi

    if [ -n "$tx_index" ]; then
        local index_dec=$(hex_to_dec "$tx_index")
        echo "  • Índice na transação: $index_dec"
    fi
}

# Função para verificar se transação está pendente
check_pending_tx() {
    local target_hash="$1"

    log_info "Buscando nas transações pendentes..."
    local pending=$(rpc_call "eth_pendingTransactions")

    if echo "$pending" | grep -q "$target_hash"; then
        log_warning "Transação encontrada na pool de transações PENDENTES"
    else
        log_error "Transação não encontrada nem como pendente"
        log_info "Possíveis causas:"
        echo "  • Hash incorreto"
        echo "  • Transação já foi removida da mempool"
        echo "  • Nó não sincronizado"
    fi
}

# Função para obter detalhes da transação
get_tx_details() {
    local hash="$1"
    local json_output="$2"

    if ! validate_tx_hash "$hash"; then
        return 1
    fi

    log_header "DETALHES DA TRANSAÇÃO"

    local result=$(rpc_call "eth_getTransactionByHash" "[\"$hash\"]")

    if [ "$json_output" = "true" ]; then
        echo "$result"
        return
    fi

    if echo "$result" | grep -q '"result":null'; then
        log_error "Transação não encontrada"
    else
        log_success "Transação encontrada"
        extract_tx_details "$result"
    fi
}

# Função para extrair detalhes da transação
extract_tx_details() {
    local json="$1"

    local from=$(echo "$json" | sed -n 's/.*"from":"\([^"]*\)".*/\1/p')
    local to=$(echo "$json" | sed -n 's/.*"to":"\([^"]*\)".*/\1/p')
    local value=$(echo "$json" | sed -n 's/.*"value":"\([^"]*\)".*/\1/p')
    local gas=$(echo "$json" | sed -n 's/.*"gas":"\([^"]*\)".*/\1/p')
    local gas_price=$(echo "$json" | sed -n 's/.*"gasPrice":"\([^"]*\)".*/\1/p')
    local nonce=$(echo "$json" | sed -n 's/.*"nonce":"\([^"]*\)".*/\1/p')

    echo "  • De: $from"
    echo "  • Para: $to"
    echo "  • Valor: $value"
    echo "  • Gas: $(hex_to_dec $gas) ($gas)"
    [ -n "$gas_price" ] && echo "  • Preço do Gas: $(hex_to_dec $gas_price) ($gas_price)"
    echo "  • Nonce: $(hex_to_dec $nonce) ($nonce)"
}

# Função para status resumido da transação
get_tx_status() {
    local hash="$1"

    if ! validate_tx_hash "$hash"; then
        return 1
    fi

    log_header "STATUS DA TRANSAÇÃO"

    # Primeiro verifica se existe
    local tx_result=$(rpc_call "eth_getTransactionByHash" "[\"$hash\"]")

    if echo "$tx_result" | grep -q '"result":null'; then
        log_error "❌ TRANSAÇÃO NÃO ENCONTRADA"
        return 1
    fi

    # Depois verifica o recibo
    local receipt_result=$(rpc_call "eth_getTransactionReceipt" "[\"$hash\"]")

    if echo "$receipt_result" | grep -q '"result":null'; then
        log_warning "⏳ TRANSAÇÃO PENDENTE (não minerada)"
        echo "  • Transação foi enviada mas ainda não foi incluída em bloco"
        check_network_health
    elif echo "$receipt_result" | grep -q '"status":"0x1"'; then
        log_success "✅ TRANSAÇÃO CONFIRMADA"
        extract_receipt_info "$receipt_result"
    elif echo "$receipt_result" | grep -q '"status":"0x0"'; then
        log_error "❌ TRANSAÇÃO FALHOU"
        extract_receipt_info "$receipt_result"
    fi
}

# Função para listar transações pendentes
list_pending_txs() {
    log_header "TRANSAÇÕES PENDENTES"

    local result=$(rpc_call "eth_pendingTransactions")

    if echo "$result" | grep -q '"result":\[\]'; then
        log_success "Nenhuma transação pendente"
        return
    fi

    # Contar transações pendentes (método simples sem jq)
    local count=$(echo "$result" | grep -o '"hash":"0x[^"]*"' | wc -l)

    if [ "$count" -gt 0 ]; then
        log_warning "Encontradas $count transações pendentes"
        echo "$result" | grep -o '"hash":"0x[^"]*"' | sed 's/"hash":"\([^"]*\)"/  • \1/' | head -20

        if [ "$count" -gt 20 ]; then
            log_info "Mostrando apenas as primeiras 20. Total: $count"
        fi
    else
        log_info "Nenhuma transação pendente encontrada"
    fi
}

# Função para contagem de transações pendentes
count_pending_txs() {
    local result=$(rpc_call "eth_pendingTransactions")
    local count=$(echo "$result" | grep -o '"hash":"0x[^"]*"' | wc -l)

    log_header "CONTAGEM DE TRANSAÇÕES PENDENTES"

    if [ "$count" -eq 0 ]; then
        log_success "✅ 0 transações pendentes"
    elif [ "$count" -le 5 ]; then
        log_info "⚠️  $count transações pendentes (normal)"
    else
        log_warning "⚠️  $count transações pendentes (alta)"
        log_info "Considere investigar possíveis problemas na rede"
    fi
}

# Função para verificar saúde da rede
check_network_health() {
    log_header "VERIFICAÇÃO DE SAÚDE DA REDE"

    # Verificar conectividade básica
    log_info "Testando conectividade com nó principal..."
    local block_result=$(rpc_call "eth_blockNumber")

    if echo "$block_result" | grep -q '"result"'; then
        log_success "✅ Nó respondendo"

        local block_hex=$(extract_result "$block_result")
        local block_number=$(hex_to_dec "$block_hex")
        echo "  • Último bloco: $block_number"

        # Verificar peers
        local peers_result=$(rpc_call "net_peerCount")
        local peers_hex=$(extract_result "$peers_result")
        local peer_count=$(hex_to_dec "$peers_hex")

        if [ "$peer_count" -gt 0 ]; then
            log_success "✅ $peer_count peers conectados"
        else
            log_error "❌ Nenhum peer conectado"
        fi

        # Verificar se está minerando
        log_info "Verificando atividade de mineração..."
        sleep 2
        local new_block_result=$(rpc_call "eth_blockNumber")
        local new_block_hex=$(extract_result "$new_block_result")
        local new_block_number=$(hex_to_dec "$new_block_hex")

        if [ "$new_block_number" -gt "$block_number" ]; then
            log_success "✅ Rede está ativa (novos blocos sendo criados)"
        else
            log_warning "⚠️  Rede pode estar parada (sem novos blocos em 2s)"
        fi

    else
        log_error "❌ Nó não está respondendo"
        return 1
    fi
}

# Função para status da rede
network_status() {
    log_header "STATUS GERAL DA REDE"

    # Bloco atual
    local block_result=$(rpc_call "eth_blockNumber")
    local block_hex=$(extract_result "$block_result")
    local block_number=$(hex_to_dec "$block_hex")
    echo "📦 Último bloco: $block_number ($block_hex)"

    # Peers
    local peers_result=$(rpc_call "net_peerCount")
    local peers_hex=$(extract_result "$peers_result")
    local peer_count=$(hex_to_dec "$peers_hex")
    echo "🌐 Peers conectados: $peer_count"

    # Chain ID
    local chain_result=$(rpc_call "eth_chainId")
    local chain_hex=$(extract_result "$chain_result")
    local chain_id=$(hex_to_dec "$chain_hex")
    echo "⛓️  Chain ID: $chain_id"

    # Transações pendentes
    local pending_result=$(rpc_call "eth_pendingTransactions")
    local pending_count=$(echo "$pending_result" | grep -o '"hash":"0x[^"]*"' | wc -l)
    echo "⏳ Transações pendentes: $pending_count"

    # Status geral
    echo ""
    if [ "$peer_count" -gt 0 ] && [ "$pending_count" -lt 100 ]; then
        log_success "✅ Rede aparenta estar saudável"
    else
        log_warning "⚠️  Rede pode ter problemas"
    fi
}

# Função para monitorar blocos
monitor_blocks() {
    local interval="${1:-5}"

    log_header "MONITOR DE BLOCOS (intervalo: ${interval}s)"
    log_info "Pressione Ctrl+C para parar"

    local last_block=0

    while true; do
        local block_result=$(rpc_call "eth_blockNumber")
        local block_hex=$(extract_result "$block_result")
        local block_number=$(hex_to_dec "$block_hex")
        local timestamp=$(date '+%H:%M:%S')

        if [ "$block_number" -gt "$last_block" ]; then
            if [ "$last_block" -ne 0 ]; then
                log_success "[$timestamp] 🆕 Novo bloco: $block_number (aumento: $((block_number - last_block)))"
            else
                log_info "[$timestamp] 📦 Bloco atual: $block_number"
            fi
            last_block=$block_number
        else
            log_warning "[$timestamp] ⏸️  Sem novos blocos (ainda em: $block_number)"
        fi

        sleep "$interval"
    done
}

# Função para status de nó específico
node_status() {
    local node="$1"

    if [ -z "$node" ]; then
        log_error "Especifique o nó (formato: ip:porta)"
        return 1
    fi

    log_header "STATUS DO NÓ: $node"

    # Testar conectividade
    local block_result=$(rpc_call "eth_blockNumber" "[]" "$node")

    if echo "$block_result" | grep -q '"result"'; then
        log_success "✅ Nó online e respondendo"

        local block_hex=$(extract_result "$block_result")
        local block_number=$(hex_to_dec "$block_hex")
        echo "  • Último bloco: $block_number"

        # Peers deste nó
        local peers_result=$(rpc_call "net_peerCount" "[]" "$node")
        local peers_hex=$(extract_result "$peers_result")
        local peer_count=$(hex_to_dec "$peers_hex")
        echo "  • Peers conectados: $peer_count"

    else
        log_error "❌ Nó offline ou não respondendo"
        log_info "Verifique se o serviço está rodando e a porta está aberta"
    fi
}

# Função para escanear todos os nós conhecidos
network_scan() {
    local nodes=(
        "172.23.105.97:8545"
        "172.23.105.99:8545"
        "172.23.105.82:8545"
        "172.23.105.101:8545"
        "172.23.105.105:8545"
        "172.23.105.107:8545"
        "172.23.105.108:8545"
    )

    log_header "ESCANEANDO TODOS OS NÓS CONHECIDOS"

    local online_count=0
    local total_count=${#nodes[@]}

    for node in "${nodes[@]}"; do
        echo ""
        log_info "Testando $node..."

        local block_result=$(rpc_call "eth_blockNumber" "[]" "$node")

        if echo "$block_result" | grep -q '"result"'; then
            log_success "✅ $node ONLINE"
            local block_hex=$(extract_result "$block_result")
            local block_number=$(hex_to_dec "$block_hex")
            echo "    Bloco: $block_number"
            ((online_count++))
        else
            log_error "❌ $node OFFLINE"
        fi
    done

    echo ""
    log_header "RESUMO DO SCAN"
    echo "📊 Nós online: $online_count/$total_count"

    if [ "$online_count" -eq "$total_count" ]; then
        log_success "✅ Todos os nós estão online"
    elif [ "$online_count" -gt $((total_count / 2)) ]; then
        log_warning "⚠️  Maioria dos nós online ($online_count/$total_count)"
    else
        log_error "❌ Maioria dos nós offline - rede pode estar comprometida"
    fi
}

# Função para status do serviço local
service_status() {
    log_header "STATUS DO SERVIÇO BESU LOCAL"

    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet besu-node; then
            log_success "✅ Serviço besu-node está ATIVO"
        else
            log_error "❌ Serviço besu-node está INATIVO"
        fi

        echo ""
        systemctl status besu-node --no-pager -l
    else
        log_warning "systemctl não disponível"
    fi
}

# Função para logs do serviço
service_logs() {
    local lines="${1:-50}"

    log_header "LOGS DO SERVIÇO BESU (últimas $lines linhas)"

    if command -v journalctl >/dev/null 2>&1; then
        journalctl -u besu-node -n "$lines" --no-pager
    else
        log_error "journalctl não disponível"
    fi
}

# Função para reiniciar serviço
service_restart() {
    log_header "REINICIANDO SERVIÇO BESU"

    if [ "$EUID" -ne 0 ]; then
        log_error "Este comando requer privilégios de root"
        log_info "Execute: sudo $0 service-restart"
        return 1
    fi

    log_info "Parando serviço besu-node..."
    systemctl stop besu-node

    log_info "Aguardando 3 segundos..."
    sleep 3

    log_info "Iniciando serviço besu-node..."
    systemctl start besu-node

    sleep 2

    if systemctl is-active --quiet besu-node; then
        log_success "✅ Serviço reiniciado com sucesso"
    else
        log_error "❌ Falha ao reiniciar o serviço"
    fi
}

# Função para verificar métricas
check_metrics() {
    log_header "VERIFICANDO MÉTRICAS"

    if curl -s --connect-timeout 5 http://localhost:9545/metrics >/dev/null; then
        log_success "✅ Métricas disponíveis em http://localhost:9545/metrics"

        # Algumas métricas básicas
        local metrics_data=$(curl -s http://localhost:9545/metrics 2>/dev/null)

        if [ -n "$metrics_data" ]; then
            echo ""
            echo "Algumas métricas importantes:"
            echo "$metrics_data" | grep -E "(besu_blockchain_height|besu_peers_connected_total|besu_transaction_pool_transactions)" | head -5
        fi
    else
        log_error "❌ Métricas não disponíveis"
        log_info "Verifique se as métricas estão habilitadas na configuração do Besu"
    fi
}

# Função principal
main() {
    local command=""
    local tx_hash=""
    local param2=""
    local json_output="false"

    # Capturar argumentos de forma mais robusta
    local original_args=("$@")

    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --node)
                BESU_NODE="$2"
                shift 2
                ;;
            --json)
                json_output="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            tx-receipt|tx-details|tx-status)
                command="$1"
                tx_hash="$2"
                shift 2
                ;;
            monitor-blocks|service-logs|node-status)
                command="$1"
                param2="$2"
                shift 2
                ;;
            *)
                if [ -z "$command" ]; then
                    command="$1"
                    shift
                else
                    if [ -z "$tx_hash" ] && [ -z "$param2" ]; then
                        tx_hash="$1"
                        param2="$1"
                    fi
                    shift
                fi
                ;;
        esac
    done

    # Debug: mostrar argumentos capturados
    if [ "$command" = "tx-status" ] || [ "$command" = "tx-receipt" ] || [ "$command" = "tx-details" ]; then
        if [ -z "$tx_hash" ]; then
            log_error "Hash da transação não fornecido"
            log_info "Argumentos recebidos: ${original_args[*]}"
            log_info "Uso: $SCRIPT_NAME $command <hash_da_transacao>"
            exit 1
        fi
    fi

    # Verificar se comando foi especificado
    if [ -z "$command" ]; then
        log_error "Comando não especificado"
        echo ""
        show_help
        exit 1
    fi

    # Executar comando
    case "$command" in
        tx-receipt)
            get_tx_receipt "$tx_hash" "$json_output"
            ;;
        tx-details)
            get_tx_details "$tx_hash" "$json_output"
            ;;
        tx-status)
            get_tx_status "$tx_hash"
            ;;
        tx-pending)
            list_pending_txs
            ;;
        tx-count-pending)
            count_pending_txs
            ;;
        network-status)
            network_status
            ;;
        block-number)
            local result=$(rpc_call "eth_blockNumber")
            local block_hex=$(extract_result "$result")
            local block_number=$(hex_to_dec "$block_hex")
            echo "Último bloco: $block_number ($block_hex)"
            ;;
        peer-count)
            local result=$(rpc_call "net_peerCount")
            local peers_hex=$(extract_result "$result")
            local peer_count=$(hex_to_dec "$peers_hex")
            echo "Peers conectados: $peer_count"
            ;;
        node-info)
            local result=$(rpc_call "web3_clientVersion")
            echo "$result"
            ;;
        chain-id)
            local result=$(rpc_call "eth_chainId")
            local chain_hex=$(extract_result "$result")
            local chain_id=$(hex_to_dec "$chain_hex")
            echo "Chain ID: $chain_id"
            ;;
        health-check)
            check_network_health
            ;;
        monitor-blocks)
            monitor_blocks "$param2"
            ;;
        node-status)
            node_status "$param2"
            ;;
        network-scan)
            network_scan
            ;;
        service-status)
            service_status
            ;;
        service-logs)
            service_logs "$param2"
            ;;
        service-restart)
            service_restart
            ;;
        metrics)
            check_metrics
            ;;
        *)
            log_error "Comando desconhecido: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal com todos os argumentos
main "$@"
