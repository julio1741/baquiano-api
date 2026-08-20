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

**Incremento 3** (Cliente y cotización): perfil `Customer` creado
automáticamente en la primera verificación OTP por el namespace customer;
direcciones con un solo "default" garantizado (índice parcial + callback) y
chequeo de cobertura informativo; carrito con un carrito activo por
(cliente, sucursal), snapshot de precios/modificadores al agregar;
`Pricing::GenerateQuote` calcula subtotal/impuesto/tarifa de envío/total
enteramente en el backend (nunca confía en el cliente), es idempotente por
`(customer_id, idempotency_key)`, y usa distancia real vía PostGIS
`ST_Distance` (no aproximación en Ruby) para tarifas por kilómetro.
`ExchangeRate` modelado con numerador/denominador racional (nunca float),
aunque todavía sin uso real — las cotizaciones se cotizan en la moneda de
la sucursal. Ver
[`docs/architecture/decisions.md`](docs/architecture/decisions.md) para lo
pendiente (tarifa de envío inventada, sin fee de servicio, sin conversión
de moneda). 101 tests en total.

**Incremento 4** (Pedidos): `Order`/`OrderItem`/`OrderItemModifier`
inmutables (snapshot completo del carrito al momento de crear el pedido,
`readonly?` a nivel de modelo), `current_status` protegido por
`before_update` — solo `Orders::TransitionOrder` puede cambiarlo, cualquier
escritura directa aborta con `RecordNotSaved`. Máquina de estados con tabla
de transiciones explícita (sección 5 del spec, hasta `ready_for_pickup` —
courier/pago quedan para Dispatch/Payments), autorización por actor
(cliente dueño, staff de comercio con permiso `orders:update_status`,
"system" para procesos internos de confianza), idempotencia vía
`OrderTransitionRequest` con registro de fallos fuera de la transacción
principal para que sobrevivan a un rollback. `Orders::PlaceOrder` convierte
`Quote` en `Order` sin recalcular nada, es idempotente por
`(customer_id, idempotency_key)`, y arranca en `merchant_pending`.
`Orders::RequestCancellation` distingue cancelación inmediata (antes de que
el comercio acepte) de cancelación que requiere revisión (después).
Eventos de dominio + outbox transaccional (`DomainEvent` + `OutboxEvent`,
adelantado de la sección 4.18) para cada transición.
`Orders::AutoCancelUnacceptedOrdersJob` cancela automáticamente pedidos
atascados en `merchant_pending` tras 15 minutos. Endpoints cliente (crear
desde cotización, listar/ver propios, solicitar cancelación), comercio
(pedidos activos de la sucursal, aceptar/rechazar/preparar/marcar listo) y
admin de solo lectura (listar todos los pedidos con filtros, ver detalle
con historial de estados — sin acciones de reembolso/disputa, eso es
Payments). Ver [`docs/architecture/decisions.md`](docs/architecture/decisions.md)
para lo pendiente (estados de courier/pago fuera de alcance, `delivery_id`
sin FK todavía, sin scheduler configurado para los jobs de mantenimiento).
119 tests en total.

**Incremento 5** (Logística): `Courier`/`Vehicle`/`CourierDocument`/
`CourierAvailability`/`CourierBranchAssignment` (repartidores propios de
Baquiano o de un comercio, teléfono y datos de placa/documento cifrados +
digest igual que el resto de la app). `Delivery` protegido con el mismo
patrón que `Order` (`before_update` + `Deliveries::TransitionDelivery`
como único punto de cambio de estado), máquina de estados completa
(`pending_assignment` → `offered` → `assigned`/`accepted` →
`at_merchant` → `picked_up` → `en_route` → `at_customer` → `delivered` /
`failed` / `cancelled`), con `Order` sincronizado en cada paso vía la
misma tabla de transiciones extendida hasta `delivered`. `Dispatch::CreateOffers`
ofrece la entrega a los repartidores en línea más cercanos (PostGIS
`ST_Distance` sobre su último `LocationPing`, nunca aproximado en Ruby);
`Dispatch::RespondToOffer` garantiza que solo una oferta gane la asignación
mediante un índice único parcial (`status='accepted'` por `delivery_id`),
verificado con un test de concurrencia real (hilos) además del caso
secuencial. `Dispatch::ExpireOffersJob` vence ofertas sin respuesta y
reintenta el despacho si a la entrega no le queda ninguna oferta viva.
PIN de entrega: dígito verificado por digest (igual que OTP), pero también
cifrado para que el cliente pueda volver a verlo en su pantalla de
seguimiento — desviación deliberada del esquema literal de la sección 4.14,
ver decisions.md. Endpoints repartidor (perfil, documentos, disponibilidad,
ofertas, ejecución completa de la entrega, incidentes), admin (aprobación
de repartidores y sus documentos, asignación manual, visibilidad de
entregas) — con una separación explícita de autorización (`CourierPolicy#update?`
vs `#manage?`) para que el propio token de un repartidor nunca pueda tocar
campos de solo-admin vía la ruta de admin. Ver
[`docs/architecture/decisions.md`](docs/architecture/decisions.md) para lo
pendiente (algoritmo de despacho es un placeholder, ganancias/efectivo
diferido a Payments, sin política de retención de ubicaciones, zonas de
cobertura siguen sin API). 142 tests en total, incluyendo un walkthrough
manual end-to-end completo (OTP real → onboarding → catálogo → pedido →
despacho → entrega con PIN) que encontró y corrigió varios bugs invisibles
para la suite automatizada (ver decisions.md).

Los dominios de negocio restantes (Payments, Notifications, ...) se
agregan en los incrementos siguientes.
