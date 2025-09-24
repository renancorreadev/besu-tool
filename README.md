# Besu Debug Tool

Script shell inteligente para monitoramento e debugging da rede Besu Bradesco. Desenvolvido especificamente para ambientes corporativos RHEL sem acesso à internet.

## Características

- ✅ **Sem dependências externas** - funciona apenas com bash e curl
- ✅ **Compatível com RHEL** - testado para sistemas corporativos  
- ✅ **Output colorido e claro** - interface amigável
- ✅ **Validação de entrada** - verifica hashes de transação automaticamente
- ✅ **Diagnóstico inteligente** - sugere possíveis causas de problemas
- ✅ **Monitoramento em tempo real** - acompanha blocos e transações
- ✅ **Comandos específicos** - pré-configurado para a rede Bradesco

## Instalação

1. **Salve o script:**
   ```bash
   vi besu.sh
   # Cole o conteúdo do script
   # Salve e saia (:wq)
   ```

2. **Torne executável:**
   ```bash
   chmod +x besu.sh
   ```

3. **Crie um alias (opcional):**
   ```bash
   echo "alias besu='$(pwd)/besu.sh'" >> ~/.bashrc
   source ~/.bashrc
   ```

## Configuração

O script vem pré-configurado com:

- **Nó padrão:** `localhost:8545`
- **Nós conhecidos da rede Bradesco:**
  - 172.23.105.97:8545 (principal)
  - 172.23.105.99:8545 (bootnode)
  - 172.23.105.82:8545 (bootnode)
  - 172.23.105.101:8545
  - 172.23.105.105:8545 (bootnode)
  - 172.23.105.107:8545
  - 172.23.105.108:8545

## Comandos Disponíveis

### Comandos de Transação

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `tx-receipt <hash>` | Obter recibo de transação | `./besu.sh tx-receipt 0x33d88f...` |
| `tx-details <hash>` | Detalhes completos da transação | `./besu.sh tx-details 0x33d88f...` |
| `tx-status <hash>` | Status resumido (mais usado) | `./besu.sh tx-status 0x33d88f...` |
| `tx-pending` | Listar transações pendentes | `./besu.sh tx-pending` |
| `tx-count-pending` | Contar transações pendentes | `./besu.sh tx-count-pending` |

### Comandos de Rede

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `network-status` | Status geral da rede | `./besu.sh network-status` |
| `block-number` | Último bloco minerado | `./besu.sh block-number` |
| `peer-count` | Número de peers conectados | `./besu.sh peer-count` |
| `node-info` | Informações do cliente | `./besu.sh node-info` |
| `chain-id` | ID da blockchain | `./besu.sh chain-id` |

### Comandos de Monitoramento

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `health-check` | Verificação completa de saúde | `./besu.sh health-check` |
| `monitor-blocks [intervalo]` | Monitorar novos blocos | `./besu.sh monitor-blocks 3` |
| `node-status <ip:porta>` | Status de nó específico | `./besu.sh node-status 172.23.105.99:8545` |
| `network-scan` | Escanear todos os nós | `./besu.sh network-scan` |

### Comandos de Sistema

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `service-status` | Status do serviço local | `./besu.sh service-status` |
| `service-logs [linhas]` | Logs do serviço | `./besu.sh service-logs 100` |
| `service-restart` | Reiniciar serviço (sudo) | `sudo ./besu.sh service-restart` |
| `metrics` | Verificar métricas | `./besu.sh metrics` |

### Opções Globais

| Opção | Descrição | Exemplo |
|-------|-----------|---------|
| `--node <ip:porta>` | Usar nó específico | `./besu.sh tx-status 0x123... --node 172.23.105.97:8545` |
| `--json` | Output em JSON | `./besu.sh network-status --json` |
| `--help, -h` | Mostrar ajuda | `./besu.sh --help` |

## Exemplos Práticos

### Verificar Transação Específica
```bash
# Verificar status de uma transação
./besu.sh tx-status 0x33d88fcccfe727a1d4e36225500d2b32e9104a4d9f6f91e9d464cc1f88b2884a

# Obter recibo completo em JSON
./besu.sh tx-receipt 0x33d88fcccfe727a1d4e36225500d2b32e9104a4d9f6f91e9d464cc1f88b2884a --json
```

### Diagnóstico de Problemas
```bash
# Verificação completa de saúde
./besu.sh health-check

# Ver transações travadas
./besu.sh tx-pending

# Monitorar se a rede está ativa
./besu.sh monitor-blocks 5
```

### Monitoramento da Rede
```bash
# Status geral
./besu.sh network-status

# Escanear todos os nós
./besu.sh network-scan

# Monitorar nó específico
./besu.sh node-status 172.23.105.97:8545
```

### Sistema Local
```bash
# Verificar serviço local
./besu.sh service-status

# Ver logs detalhados
./besu.sh service-logs 200

# Reiniciar se necessário
sudo ./besu.sh service-restart
```

## Interpretação de Resultados

### Status de Transações
- ✅ **CONFIRMADA**: Transação executada com sucesso
- ❌ **FALHOU**: Transação executada mas falhou
- ⏳ **PENDENTE**: Transação ainda não foi minerada

### Status da Rede
- **Peers > 0**: Rede conectada
- **Novos blocos**: Rede ativa e minerando
- **Pendentes < 100**: Pool de transações normal

### Códigos de Status
- `0x1`: Sucesso
- `0x0`: Falha  
- `null`: Não encontrada/pendente

## Troubleshooting

### Nó Local Não Responde
```bash
# Verificar status do serviço
sudo systemctl status besu-node

# Iniciar se parado
sudo systemctl start besu-node

# Ver logs para erros
sudo journalctl -u besu-node -f -n 100
```

### Usar Nó Remoto
```bash
# Se localhost não funcionar, use nó remoto
./besu.sh tx-status 0x123... --node 172.23.105.97:8545
```

### Transação Pendente
```bash
# Verificar saúde da rede
./besu.sh health-check

# Ver quantas transações estão pendentes
./besu.sh tx-count-pending

# Monitorar se novos blocos estão sendo criados
./besu.sh monitor-blocks 3
```

## Comandos curl Equivalentes

Para usar diretamente sem o script:

```bash
# Verificar transação
curl -X POST -H "Content-Type: application/json" http://localhost:8545 \
     --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["0x123..."],"id":1}'

# Último bloco
curl -X POST -H "Content-Type: application/json" http://localhost:8545 \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Peers conectados
curl -X POST -H "Content-Type: application/json" http://localhost:8545 \
     --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'
```

## Fluxo de Trabalho Recomendado

### Para Debugging de Transações
1. `./besu.sh tx-status <hash>` - Verificar status
2. `./besu.sh health-check` - Se pendente, verificar rede
3. `./besu.sh monitor-blocks 5` - Verificar atividade
4. `./besu.sh network-scan` - Se problema persistir

### Para Monitoramento da Rede
1. `./besu.sh network-status` - Status geral
2. `./besu.sh network-scan` - Verificar todos os nós  
3. `./besu.sh monitor-blocks 10` - Monitoramento contínuo
4. `./besu.sh tx-count-pending` - Verificar congestionamento

### Para Problemas do Sistema
1. `./besu.sh service-status` - Verificar serviço local
2. `./besu.sh service-logs 100` - Analisar logs
3. `sudo ./besu.sh service-restart` - Reiniciar se necessário
4. `./besu.sh metrics` - Verificar métricas

## Personalização

Para adaptar à sua configuração, edite estas variáveis no início do script:

```bash
# Nó padrão
BESU_NODE="localhost:8545"

# Lista de nós para network-scan
nodes=(
    "172.23.105.97:8545"
    "172.23.105.99:8545"
    # adicione outros nós aqui
)
```

## Suporte

Este script foi desenvolvido especificamente para a rede Besu do Bradesco em ambiente RHEL. Para problemas:

1. Verifique se o curl está instalado: `which curl`
2. Teste conectividade básica: `./besu.sh block-number`
3. Use `./besu.sh --help` para ver todos os comandos
4. Consulte os logs: `./besu.sh service-logs 200`

---
**Versão:** 1.0  
**Compatibilidade:** RHEL/Linux, Bash 4+, Besu Ethereum Client  
**Dependências:** bash, curl (nativo na maioria das distribuições)
