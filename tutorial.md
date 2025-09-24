
🔍 COMANDOS DE TRANSAÇÃO
# Verificar recibo de uma transação específica
./besu.sh tx-receipt 0x33d88fcccfe727a1d4e36225500d2b32e9104a4d9f6f91e9d464cc1f88b2884a

# Ver detalhes completos da transação
./besu.sh tx-details 0x33d88fcccfe727a1d4e36225500d2b32e9104a4d9f6f91e9d464cc1f88b2884a

# Status resumido da transação (mais usado)
./besu.sh tx-status 0x33d88fcccfe727a1d4e36225500d2b32e9104a4d9f6f91e9d464cc1f88b2884a

# Listar todas as transações pendentes
./besu.sh tx-pending

# Contar quantas transações estão pendentes
./besu.sh tx-count-pending

# Ver dados brutos em JSON
./besu.sh tx-receipt 0x33d88fcccfe727a1d4e36225500d2b32e9104a4d9f6f91e9d464cc1f88b2884a --json

🌐 COMANDOS DE REDE
bash# Status geral da rede (resumo completo)
./besu.sh network-status

# Último bloco minerado
./besu.sh block-number

# Quantos peers estão conectados
./besu.sh peer-count

# Informações do cliente Besu
./besu.sh node-info

# ID da blockchain
./besu.sh chain-id

COMANDOS DE MONITORAMENTO
bash# Verificação completa de saúde da rede
./besu.sh health-check

# Monitorar novos blocos a cada 5 segundos (padrão)
./besu.sh monitor-blocks

# Monitorar novos blocos a cada 3 segundos
./besu.sh monitor-blocks 3

# Status de um nó específico
./besu.sh node-status 172.23.105.99:8545

# Escanear todos os nós conhecidos da rede
./besu.sh network-scan
⚙️ COMANDOS DE SISTEMA LOCAL
bash# Status do serviço Besu local
./besu.sh service-status

# Ver logs do serviço (50 linhas padrão)
./besu.sh service-logs

# Ver últimas 100 linhas de logs
./besu.sh service-logs 100

# Reiniciar serviço Besu (requer sudo)
sudo ./besu.sh service-restart

# Verificar métricas do Besu
./besu.sh metrics
🔧 OPÇÕES GLOBAIS
bash# Usar nó específico em vez do padrão
./besu.sh tx-status 0x123... --node 172.23.105.101:8545

# Output em formato JSON
./besu.sh network-status --json

# Mostrar ajuda
./besu.sh --help
./besu.sh -h
