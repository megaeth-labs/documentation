.env:
```env
STATELESS_VALIDATOR_DATA_DIR=/home/blockchain/stateless-validator
STATELESS_VALIDATOR_WITNESS_ENDPOINT=https://mainnet.megaeth.com/rpc
STATELESS_VALIDATOR_GENESIS_FILE=/home/blockchain/stateless-validator/genesis.json
STATELESS_VALIDATOR_LOG_FILE_DIRECTORY=/home/blockchain/stateless-validator/logs
STATELESS_VALIDATOR_LOG_FILE_FILTER=debug
STATELESS_VALIDATOR_LOG_STDOUT_FILTER=info
STATELESS_VALIDATOR_METRICS_ENABLED=true
STATELESS_VALIDATOR_METRICS_PORT=9090
STATELESS_VALIDATOR_RPC_ENDPOINT=https://mainnet.megaeth.com/rpc
```

systemctl start stateless-validator
