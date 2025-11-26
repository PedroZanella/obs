Observability

Diagrama:

    - Fluxo PostgreSQL → Exporter → Prometheus → Grafana



Componentes da Stack


- PostgreSQL: banco de dados principal(Banco leve de facil utilização e é compativel com Prometheus).
- Postgres Exporter: Coleta métricas do banco e expõe em formato Prometheus
  -Node exporter: O Node Exporter coleta e expõe métricas do sistema operacional para o Prometheus, como CPU, memória, disco, rede e processos. 

  -Ping exporter: O Ping Exporter serve para monitorar a conectividade e a latência de rede entre sua máquina e destinos específicos, usando ICMP (ping).

  -Postgres exporter: O Postgres Exporter é o componente que faz a ponte entre o PostgreSQL e o Prometheus, permitindo que você monitore o banco de dados de forma detalhada.

- Prometheus: Ele é o sistema de monitoramento e armazenamento de métricas.

    - É possivel executar os seguintes comando para verificar se as tabelas estão funcionando. 

        - rate(pg_stat_database_xact_commit[1m]): Calcula a taxa de crescimento por segundo de um contador
        - sum(pg_stat_activity_count{state="active"}): Total de conexões ativas
        - avg(node_memory_MemAvailable_bytes): Média dos valores
        - histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)): Usado para calcular percentis (ex: latência p95, p99)
        - rate(pg_stat_database_xact_commit[1m]) + rate(pg_stat_database_xact_rollback[1m]): Throughput de queries/s
        - pg_stat_activity_count{state="active"}: Conexões ativas
        - rate(pg_stat_database_deadlocks[1m]): Deadlocks por minuto
        - rate(pg_stat_database_xact_commit[1m]): Mostra se os dados do banco estão sendo atualizados
        

    
- Grafana: visualiza métricas e logs
    - Uso de CPU
    - Uso de memório
    - Uso de disco
    - Processos em execução
    - Tráfego de rede
    - Latência de rede (ping)
    - Locks e Deadlocks
    - Tempo de resposta das queries
    - Banco - Conexões ativas
    - Banco - Transações por Segundo
    - Banco - Tamanho da Tabela
    - Throughput (querie/s)
    - I/O e Buffers
