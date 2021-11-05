postgresql:
  enabled: false
data:
  metadataConnection:
    user: postgres
    pass: ${postgres_pass}
    protocol: postgresql
    host: ${postgres_name}-postgresql
    port: 5432
    db: ${postgres_database}
