# microservices-proto

Repositório de definições de contratos e geração de stubs para os microsserviços do projeto de comércio eletrônico, utilizando **Protocol Buffers (protobuf)** e **gRPC**.

> **Parte 2:** adicionado o contrato `payment.proto`, utilizado pelo microsserviço **Order** para solicitar a cobrança de um pedido ao microsserviço **Payment**.

---

## Visão Geral

Este repositório centraliza os arquivos `.proto` que definem as mensagens e serviços trocados entre os microsserviços. A partir dessas definições, são gerados automaticamente os **client e server stubs** para Go (e potencialmente outras linguagens), eliminando a necessidade de escrever manualmente o código de serialização/desserialização das mensagens.

---

## Estrutura de Pastas

```
microservices-proto/
├── order/
│   └── order.proto             # Definição de mensagens e serviço Order em protobuf
├── payment/
│   └── payment.proto           # Definição de mensagens e serviço Payment em protobuf
├── golang/
│   ├── order/
│   │   ├── go.mod              # Módulo Go do pacote gerado para Order
│   │   ├── go.sum
│   │   ├── order.pb.go         # Código Go gerado: structs das mensagens protobuf
│   │   └── order_grpc.pb.go    # Código Go gerado: interfaces e stubs gRPC
│   └── payment/
│       ├── go.mod              # Módulo Go do pacote gerado para Payment
│       ├── go.sum
│       ├── payment.pb.go       # Código Go gerado: structs das mensagens protobuf
│       └── payment_grpc.pb.go  # Código Go gerado: interfaces e stubs gRPC
└── run.sh                      # Script para (re)gerar os stubs de todos os serviços
```

### Detalhamento dos arquivos

| Arquivo | Descrição |
|---|---|
| `order/order.proto` | Contrato protobuf: define mensagens (`CreateOrderRequest`, `OrderItem`, `CreateOrderResponse`) e o serviço `Order` com o método `Create` |
| `payment/payment.proto` | **(Parte 2)** Contrato protobuf: define mensagens (`CreatePaymentRequest`, `CreatePaymentResponse`) e o serviço `Payment` com o método `Create` |
| `golang/order/order.pb.go` | Gerado automaticamente: structs Go correspondentes às mensagens protobuf de Order, com métodos de serialização/desserialização |
| `golang/order/order_grpc.pb.go` | Gerado automaticamente: interface do servidor (`OrderServer`), cliente (`OrderClient`) e o tipo `UnimplementedOrderServer` para embedding |
| `golang/payment/payment.pb.go` | **(Parte 2)** Gerado automaticamente: structs Go correspondentes às mensagens protobuf de Payment |
| `golang/payment/payment_grpc.pb.go` | **(Parte 2)** Gerado automaticamente: interface do servidor (`PaymentServer`), cliente (`PaymentClient`) e o tipo `UnimplementedPaymentServer` para embedding |
| `golang/order/go.mod`, `golang/payment/go.mod` | Módulos Go com as dependências `google.golang.org/grpc` e `google.golang.org/protobuf` |
| `run.sh` | Script que invoca o `protoc` (com os plugins `protoc-gen-go` e `protoc-gen-go-grpc`) para gerar os stubs de Order e de Payment |

---

## Como funciona o protobuf

O **Protocol Buffer** (protobuf) é um mecanismo de serialização binária desenvolvido pelo Google. No contexto do gRPC:

1. **Você escreve** um arquivo `.proto` declarando mensagens e serviços
2. **O compilador `protoc`** gera código na linguagem alvo (Go, Python, Java etc.)
3. **O código gerado** implementa automaticamente a codificação/decodificação das mensagens para transmissão em rede
4. **Os desenvolvedores** precisam apenas implementar a lógica de negócio, sem se preocupar com serialização

### Exemplo: order.proto

```protobuf
syntax = "proto3";

// Mensagem de entrada: dados do pedido
message CreateOrderRequest {
  int32 costumer_id = 1;          // ID do cliente
  repeated OrderItem order_items = 2; // Lista de itens (repeated = array)
  float total_price = 3;          // Preço total
}

// Item individual do pedido
message OrderItem {
  string product_code = 1;
  float unit_price = 2;
  int32 quantity = 3;
}

// Mensagem de retorno: ID do pedido criado
message CreateOrderResponse {
  int32 order_id = 1;
}

// Serviço com um método RPC
service Order {
  rpc Create(CreateOrderRequest) returns (CreateOrderResponse) {}
}
```

### Exemplo: payment.proto (Parte 2)

```protobuf
syntax = "proto3";
option go_package="github/ruandg/microservices-proto/golang/payment";

// Mensagem de entrada: dados da cobrança
message CreatePaymentRequest {
  int64 user_id = 1;      // ID do cliente a ser cobrado
  int64 order_id = 2;     // ID do pedido associado à cobrança
  float total_price = 3;  // Valor total a ser cobrado
}

// Mensagem de retorno: identificadores gerados pelo Payment
message CreatePaymentResponse {
  int64 payment_id = 1;
  int64 bill_id = 2;
}

// Serviço com um método RPC
service Payment {
  rpc Create(CreatePaymentRequest) returns (CreatePaymentResponse) {}
}
```

O microsserviço **Order** usa este contrato como **cliente**: ao registrar um pedido, ele invoca `Payment.Create` para solicitar a cobrança correspondente.

Os números após cada campo (`= 1`, `= 2`, `= 3`) são **identificadores de campo** na mensagem binária serializada — não são valores padrão.

---

## Como gerar os stubs

### Pré-requisitos

```bash
# Instalar o compilador protobuf
apt-get install -y protobuf-compiler

# Instalar os plugins Go
apt-get install -y protoc-gen-go protoc-gen-go-grpc
# ou via go install (requer acesso a proxy.golang.org):
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

### Gerando com o script `run.sh`

A forma mais simples de (re)gerar os stubs de **todos** os serviços é executar o script disponibilizado na raiz do repositório:

```bash
./run.sh
```

Ele executa, para cada serviço, o comando `protoc` equivalente ao mostrado abaixo.

### Comando de geração manual

```bash
# Order — na raiz do microservices-proto
protoc \
  --go_out=golang/order \
  --go_opt=paths=source_relative \
  --go-grpc_out=golang/order \
  --go-grpc_opt=paths=source_relative \
  -I order \
  order/order.proto

# Payment — na raiz do microservices-proto (Parte 2)
protoc \
  --go_out=golang/payment \
  --go_opt=paths=source_relative \
  --go-grpc_out=golang/payment \
  --go-grpc_opt=paths=source_relative \
  -I payment \
  payment/payment.proto
```

Isso gera, para cada serviço, dois arquivos em `golang/<serviço>/`:
- `<serviço>.pb.go` — structs das mensagens
- `<serviço>_grpc.pb.go` — interfaces e stubs do serviço gRPC

---

## Como os microsserviços usam este repositório

O repositório `microservices` referencia os módulos gerados aqui via `replace` directive no `go.mod` de cada serviço. No `go.mod` do microsserviço **Order**, por exemplo:

```go
require (
	github.com/ruandg/microservices-proto/golang/order   v0.0.0-00010101000000-000000000000
	github.com/ruandg/microservices-proto/golang/payment v0.0.0-00010101000000-000000000000
)

replace github.com/ruandg/microservices-proto/golang/order => ../../microservices-proto/golang/order
replace github.com/ruandg/microservices-proto/golang/payment => ../../microservices-proto/golang/payment
```

Isso permite que o código dos adapters gRPC use os tipos gerados (`order.CreateOrderRequest`, `payment.CreatePaymentRequest`, `payment.PaymentClient` etc.) sem precisar publicar os módulos em um registry.

---

## Tecnologias

- [Protocol Buffers v3](https://protobuf.dev/)
- [gRPC](https://grpc.io/)
- [Go](https://golang.org/) 1.22+
- `protoc` 3.21+
- `protoc-gen-go` 1.32+
- `protoc-gen-go-grpc` 1.3+
