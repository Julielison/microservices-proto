# microservices-proto

Repositório de definições de contratos e geração de stubs para os microsserviços do projeto de comércio eletrônico, utilizando **Protocol Buffers (protobuf)** e **gRPC**.

> **Parte Final:** adicionado o contrato `shipping.proto`, utilizado pelo microsserviço **Order** para solicitar o agendamento de envio de um pedido ao microsserviço **Shipping**.

---

## Visão Geral

Este repositório centraliza os arquivos `.proto` que definem as mensagens e serviços trocados entre os microsserviços. A partir dessas definições, são gerados automaticamente os **client e server stubs** para Go, eliminando a necessidade de escrever manualmente o código de serialização/desserialização das mensagens.

---

## Estrutura de Pastas

```
microservices-proto/
├── order/
│   └── order.proto              # Mensagens e serviço Order
├── payment/
│   └── payment.proto            # Mensagens e serviço Payment
├── shipping/
│   └── shipping.proto           # (Parte Final) Mensagens e serviço Shipping
├── golang/
│   ├── order/
│   │   ├── go.mod
│   │   ├── go.sum
│   │   ├── order.pb.go
│   │   └── order_grpc.pb.go
│   ├── payment/
│   │   ├── go.mod
│   │   ├── go.sum
│   │   ├── payment.pb.go
│   │   └── payment_grpc.pb.go
│   └── shipping/                # (Parte Final)
│       ├── go.mod
│       ├── shipping.pb.go
│       └── shipping_grpc.pb.go
└── run.sh                       # Script para (re)gerar os stubs de todos os serviços
```

---

## Contratos protobuf

### order.proto

```protobuf
syntax = "proto3";
message CreateOrderRequest {
  int32 costumer_id = 1;
  repeated OrderItem order_items = 2;
  float total_price = 3;
}
message OrderItem {
  string product_code = 1;
  float unit_price = 2;
  int32 quantity = 3;
}
message CreateOrderResponse { int32 order_id = 1; }
service Order {
  rpc Create(CreateOrderRequest) returns (CreateOrderResponse) {}
}
```

### payment.proto

```protobuf
syntax = "proto3";
message CreatePaymentRequest {
  int64 user_id = 1;
  int64 order_id = 2;
  float total_price = 3;
}
message CreatePaymentResponse {
  int64 payment_id = 1;
  int64 bill_id = 2;
}
service Payment {
  rpc Create(CreatePaymentRequest) returns (CreatePaymentResponse) {}
}
```

### shipping.proto (Parte Final)

```protobuf
syntax = "proto3";
message ShippingItem {
  string product_code = 1;
  int32  quantity     = 2;
}
message CreateShippingRequest {
  int64                order_id       = 1;
  repeated ShippingItem shipping_items = 2;
}
message CreateShippingResponse {
  int64 shipping_id        = 1;
  int32 delivery_deadline  = 2;   // prazo em dias
}
service Shipping {
  rpc Create(CreateShippingRequest) returns (CreateShippingResponse) {}
}
```

O microsserviço **Order** usa este contrato como **cliente**: após confirmar o pagamento, invoca `Shipping.Create` para agendar o envio e receber o prazo de entrega.

---

## Como gerar os stubs

### Pré-requisitos

```bash
apt-get install -y protobuf-compiler
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

### Gerando todos os stubs

```bash
chmod +x run.sh
./run.sh
```

O script gera, para cada serviço, dois arquivos em `golang/<serviço>/`:
- `<serviço>.pb.go` — structs das mensagens
- `<serviço>_grpc.pb.go` — interfaces e stubs do serviço gRPC

---

## Como os microsserviços usam este repositório

Os microsserviços utilizam este repositório baixando os pacotes gerados remotamente do GitHub através do comando `go get`.

Por exemplo, no microsserviço **Order**, você adiciona as dependências executando:

```bash
go get github.com/Julielison/microservices-proto/golang/order@latest
go get github.com/Julielison/microservices-proto/golang/payment@latest
go get github.com/Julielison/microservices-proto/golang/shipping@latest
```

Isso garantirá que o `go.mod` contenha as versões remotas mais atualizadas (sem necessidade da diretiva `replace` local).

```go
// go.mod do microsserviço Order (Exemplo de como ficará)
require (
    github.com/Julielison/microservices-proto/golang/order v1.x.x
    github.com/Julielison/microservices-proto/golang/payment v1.x.x
    github.com/Julielison/microservices-proto/golang/shipping v1.x.x
)
```
---

## Tecnologias

- [Protocol Buffers v3](https://protobuf.dev/)
- [gRPC](https://grpc.io/)
- [Go](https://golang.org/) 1.22+
- `protoc` 3.21+
- `protoc-gen-go` 1.32+
- `protoc-gen-go-grpc` 1.3+
