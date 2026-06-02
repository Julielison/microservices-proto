# microservices-proto

Repositório de definições de contratos e geração de stubs para os microsserviços do projeto de comércio eletrônico, utilizando **Protocol Buffers (protobuf)** e **gRPC**.

---

## Visão Geral

Este repositório centraliza os arquivos `.proto` que definem as mensagens e serviços trocados entre os microsserviços. A partir dessas definições, são gerados automaticamente os **client e server stubs** para Go (e potencialmente outras linguagens), eliminando a necessidade de escrever manualmente o código de serialização/desserialização das mensagens.

---

## Estrutura de Pastas

```
microservices-proto/
├── order/
│   └── order.proto          # Definição de mensagens e serviço Order em protobuf
└── golang/
    └── order/
        ├── go.mod            # Módulo Go do pacote gerado
        ├── order.pb.go       # Código Go gerado: structs das mensagens protobuf
        └── order_grpc.pb.go  # Código Go gerado: interfaces e stubs gRPC
```

### Detalhamento dos arquivos

| Arquivo | Descrição |
|---|---|
| `order/order.proto` | Contrato protobuf: define mensagens (`CreateOrderRequest`, `OrderItem`, `CreateOrderResponse`) e o serviço `Order` com o método `Create` |
| `golang/order/order.pb.go` | Gerado automaticamente: structs Go correspondentes às mensagens protobuf, com métodos de serialização/desserialização |
| `golang/order/order_grpc.pb.go` | Gerado automaticamente: interface do servidor (`OrderServer`), cliente (`OrderClient`) e o tipo `UnimplementedOrderServer` para embedding |
| `golang/order/go.mod` | Módulo Go com as dependências `google.golang.org/grpc` e `google.golang.org/protobuf` |

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

### Comando de geração

```bash
# Na raiz do microservices-proto
protoc \
  --go_out=golang/order \
  --go_opt=paths=source_relative \
  --go-grpc_out=golang/order \
  --go-grpc_opt=paths=source_relative \
  -I order \
  order/order.proto
```

Isso gera dois arquivos em `golang/order/`:
- `order.pb.go` — structs das mensagens
- `order_grpc.pb.go` — interfaces e stubs do serviço gRPC

---

## Como os microsserviços usam este repositório

O repositório `microservices` referencia este módulo via `replace` directive no `go.mod`:

```go
require github.com/ruandg/microservices-proto/golang/order v0.0.0-00010101000000-000000000000

replace github.com/ruandg/microservices-proto/golang/order => ../../microservices-proto/golang/order
```

Isso permite que o código dos adaptadores gRPC use os tipos gerados (`order.CreateOrderRequest`, `order.CreateOrderResponse`, `order.UnimplementedOrderServer`) sem precisar publicar o módulo em um registry.

---

## Tecnologias

- [Protocol Buffers v3](https://protobuf.dev/)
- [gRPC](https://grpc.io/)
- [Go](https://golang.org/) 1.22+
- `protoc` 3.21+
- `protoc-gen-go` 1.32+
- `protoc-gen-go-grpc` 1.3+
