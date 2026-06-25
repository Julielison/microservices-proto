#!/bin/sh
# Gera os stubs Go a partir dos arquivos .proto do repositório.
# Pré-requisitos: protoc, protoc-gen-go e protoc-gen-go-grpc disponíveis no PATH.
#
# Uso:
#   ./run.sh           # gera os stubs de todos os microsserviços (order e payment)

set -e

echo "Gerando stubs para order..."
protoc \
  --go_out=golang/order \
  --go_opt=paths=source_relative \
  --go-grpc_out=golang/order \
  --go-grpc_opt=paths=source_relative \
  -I order \
  order/order.proto

echo "Gerando stubs para payment..."
protoc \
  --go_out=golang/payment \
  --go_opt=paths=source_relative \
  --go-grpc_out=golang/payment \
  --go-grpc_opt=paths=source_relative \
  -I payment \
  payment/payment.proto

echo "Stubs gerados com sucesso."
