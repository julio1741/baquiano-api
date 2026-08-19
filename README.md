# Baquiano API

Backend del MVP de Baquiano: plataforma de pedidos y entregas para Barinas,
Venezuela (restaurantes, bodegas, farmacias). Monolito modular en Ruby on
Rails, API-only. Este repo es solo el backend — las apps Flutter de
clientes/repartidores, el portal de comercios y la consola administrativa
consumen esta API.

## Stack y versiones fijadas

| Componente | Versión | Por qué |
|---|---|---|
| Ruby | 3.3.12 | Última patch estable de la serie 3.3, soportada por Rails 8.1 |
| Rails | 8.1.3 (API mode) | Última versión estable mayor |
| PostgreSQL | 17 | Estable, requerida por `activerecord-postgis-adapter` junto con... |
| PostGIS | 3.5 | ...consultas geográficas (cobertura, zonas, tracking) |
| Redis | 7.4 | Caché, rate limiting (Rack::Attack) y backend de Sidekiq |
| Sidekiq | 8.1 | Jobs asíncronos (7.x tiene un bug de compatibilidad con `connection_pool` 3.x) |
| Puma | 8.0 | 6.6.1 tenía CVEs de alta criticidad (CVE-2026-47736/47737) en el parser PROXY |

Otras decisiones relevantes:

- **Cifrado de campos**: Active Record Encryption (nativo de Rails) para las
  columnas `*_encrypted`. Búsqueda por campo cifrado vía columnas `*_digest`
  (HMAC), no vía encriptación determinística, para no acoplar la forma de
  búsqueda a la de cifrado.
- **PK**: UUID en todas las tablas (`config.generators.orm` ya lo deja como
  default para nuevas migraciones/modelos), usando `pgcrypto`.
- **Schema tracking**: `db/structure.sql` (no `schema.rb`) porque las columnas
  `geography` de PostGIS y las extensiones no sobreviven al dumper de Ruby.
- **Autorización**: Pundit (una policy por dominio, deny-by-default).
- **Serializers**: Blueprinter.
- **Paginación**: Pagy.
- **Documentación de API**: rswag (genera `docs/openapi/v1/openapi.yaml` a
  partir de request specs; Swagger UI solo en desarrollo).

## Requisitos

Solo Docker y Docker Compose. No hace falta Ruby instalado localmente.

## Arrancar el entorno de desarrollo

```bash
cp .env.example .env   # opcional, los defaults ya funcionan
docker compose up
```

Esto levanta:

- `web` — Rails en http://localhost:3001 (3000 interno; el 3001 evita chocar
  con otros proyectos que ya usan el 3000 en esta máquina)
- `db` — PostgreSQL 17 + PostGIS 3.5 en `localhost:5432`
- `redis` — en `localhost:6379`
- `sidekiq` — worker de jobs asíncronos

La primera vez que arranca `web`, el entrypoint corre `bin/rails db:prepare`
automáticamente (crea la base y aplica migraciones/`structure.sql`).

Probar que todo está sano:

```bash
curl http://localhost:3001/up            # liveness (proceso vivo)
curl http://localhost:3001/health/live   # idem, vía la API propia
curl http://localhost:3001/health/ready  # 200 solo si Postgres y Redis responden
```

Documentación de la API (solo en desarrollo): http://localhost:3001/api-docs

## Comandos comunes

```bash
docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
docker compose exec web bundle exec brakeman -q
docker compose exec web bundle exec bundler-audit check --update
docker compose exec web bundle exec rake rswag:specs:swaggerize   # regenera docs/openapi
```

## Credenciales (`config/master.key`)

Se generó localmente al crear el proyecto y **no está en el repo**
(`config/*.key` está en `.gitignore`, como corresponde). Para que el resto del
equipo pueda correr la app o descifrar `config/credentials.yml.enc`, hay que
compartirles ese archivo fuera de git (gestor de contraseñas, 1Password,
etc.) — nunca por Slack/email en texto plano.

## Estructura del proyecto

Ver [`docs/architecture/domains.md`](docs/architecture/domains.md) para cómo
se organiza `app/domains/<dominio>` y por qué. El resto sigue convención Rails:
`app/controllers/api/v1/<customer|courier|merchant|admin|webhooks>`,
`app/errors` (jerarquía de errores de dominio compartida), `app/lib`
(`Current`, utilidades transversales).

## Estado actual

**Incremento 0** (base técnica): proyecto Rails, Docker, Postgres/PostGIS,
Redis, Sidekiq, CI, manejo de errores, logs estructurados, request/
correlation id, health checks, OpenAPI.

**Incremento 1** (Identidad): usuarios (teléfono cifrado + digest para
búsqueda), login por OTP (sin registro separado — la primera verificación
crea la cuenta), dispositivos, sesiones con access token de corta duración
(`Rails.application.message_verifier`, sin dependencia JWT) y refresh token
rotativo con detección de reuso, roles/permisos/asignaciones con scope
platform/organization/branch, Pundit deny-by-default. Ver
[`docs/architecture/decisions.md`](docs/architecture/decisions.md) para las
decisiones marcadas como pendientes de validación (proveedor de SMS, MFA de
administración).

**Incremento 2** (Organizaciones, comercios, sucursales, catálogo):
`organizations`/`merchants`/`branches` con horarios y cobertura geográfica
(PostGIS `ST_Covers`, sin cómputo en Ruby); catálogo completo (categorías,
productos, variantes, grupos de modificadores, modificadores) con bloqueo
real de productos `prescription_required` hasta habilitar
`config.x.prescription_sales_enabled`; disponibilidad simple por
producto/variante. Barinas + una zona de referencia sembradas de forma
idempotente. CRUD admin de organizaciones/comercios/sucursales, autoservicio
de comercio (pausar sucursal, gestionar catálogo, disponibilidad) y
endpoints públicos de cliente (cobertura, catálogo publicado) sin
autenticación. 79 tests en total.

Los dominios de negocio restantes (Customers, Carts, Orders, Payments,
Dispatch, ...) se agregan en los incrementos siguientes.
