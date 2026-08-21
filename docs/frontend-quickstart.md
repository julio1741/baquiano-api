# Guía rápida para quien integre el frontend

Este documento es el punto de entrada para cualquiera que vaya a consumir la
API de Baquiano desde una app cliente, una app de repartidor, un portal de
comercio o la consola administrativa. No repite el catálogo completo de
endpoints — para eso está el OpenAPI (ver "Referencia completa" al final) —
sino que explica lo que **no** está en el OpenAPI: cómo autenticarse, qué
pedir en qué orden, y las particularidades de cada rol.

## 1. Levantar el backend

```bash
docker compose up
```

La API queda en `http://localhost:3001`. `docker compose up` ya deja la base
de datos migrada y las 4 piezas (`web`, `sidekiq`, `db`, `redis`) corriendo —
no hace falta ningún paso manual antes.

Chequeo rápido de que está vivo:

```bash
curl http://localhost:3001/up
```

## 2. Cómo está organizada la API

Todo vive bajo `/api/v1/<rol>/...`, con cuatro roles y un namespace especial
para webhooks entrantes:

| Namespace | Para quién | Ejemplos |
|---|---|---|
| `/api/v1/customer` | App de clientes | catálogo, carrito, pedidos, tracking |
| `/api/v1/courier` | App de repartidores | ofertas de entrega, entregas, efectivo |
| `/api/v1/merchant` | Portal de comercio | catálogo propio, pedidos entrantes |
| `/api/v1/admin` | Consola administrativa | todo lo anterior + aprobar, revisar, configurar |
| `/api/v1/webhooks` | Proveedores externos | no lo consume un frontend |

Cada uno de los primeros cuatro tiene su **propio login** (mismo mecanismo,
cuentas separadas) — ver sección 3.

## 3. Autenticación (igual en los 4 roles)

No hay registro por separado: la primera vez que alguien verifica su OTP,
la cuenta se crea sola. El flujo es siempre el mismo 4 pasos, cambiando solo
el prefijo `/api/v1/<rol>`:

### Paso 1 — Pedir el código OTP

```bash
curl -X POST http://localhost:3001/api/v1/customer/otp \
  -H "Content-Type: application/json" \
  -d '{"phone_country_code": "58", "phone_number": "4141234567"}'
```

Respuesta:

```json
{
  "otp_challenge_id": "…",
  "expires_at": "2026-08-21T03:10:00Z",
  "dev_only_code": "123456"
}
```

**`dev_only_code` solo aparece en desarrollo/test** (no hay proveedor de SMS
real todavía — ver `docs/architecture/decisions.md`). En producción esa
clave no viene en la respuesta; el código llega por SMS. En local, usalo tal
cual para el paso 2.

### Paso 2 — Verificar el código y obtener tokens

```bash
curl -X POST http://localhost:3001/api/v1/customer/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "phone_country_code": "58",
    "phone_number": "4141234567",
    "code": "123456",
    "first_name": "Julio",
    "last_name": "Baptista",
    "device": {
      "installation_id": "algo-unico-por-instalacion",
      "platform": "ios",
      "app_version": "1.0.0"
    }
  }'
```

Respuesta:

```json
{
  "user": { "id": "…", "status": "active" },
  "access_token": "eyJf…",
  "access_token_expires_at": "2026-08-21T03:25:00Z",
  "refresh_token": "…"
}
```

`first_name`/`last_name` solo hacen falta la primera vez (cuando se crea la
cuenta); en logins siguientes se ignoran. `device.installation_id` tiene que
ser estable por instalación de la app — identifica el dispositivo para
sesiones/push, no hace falta reinventarlo en cada request.

### Paso 3 — Usar el `access_token`

Todos los demás endpoints van con:

```
Authorization: Bearer <access_token>
```

El access token es de corta duración (ver `access_token_expires_at`). Cuando
expira, no se vuelve a pedir OTP — se refresca:

```bash
curl -X POST http://localhost:3001/api/v1/customer/session/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "…"}'
```

Devuelve un `access_token`/`refresh_token` nuevos (el refresh token es
rotativo: el viejo deja de servir). Guardá siempre el más reciente.

### Paso 4 — Cerrar sesión

```bash
curl -X DELETE http://localhost:3001/api/v1/customer/session \
  -H "Authorization: Bearer <access_token>"
```

**Estos mismos 4 pasos aplican a `courier`, `merchant` y `admin`** —
cambiando solo `/customer/` por `/courier/`, `/merchant/` o `/admin/` en las
4 URLs. El resto (formato de request/response, rotación de refresh token)
es idéntico.

## 4. Particularidades por rol (esto sí cambia)

- **Customer**: al verificar el OTP por primera vez, el perfil de cliente se
  crea automáticamente. No hay un paso extra de "crear cliente."
- **Courier**: después de loguearse por primera vez, hay que crear el
  perfil explícitamente con `POST /api/v1/courier/profile` (no se crea
  solo). Un repartidor recién creado no puede operar hasta que un admin lo
  apruebe (`approval_status`) — antes de la aprobación, la mayoría de sus
  endpoints van a devolver 403.
- **Merchant**: el login funciona igual, pero para que el usuario vea algo
  (sus sucursales, catálogo, pedidos) un administrador tiene que haberle
  asignado antes un rol sobre esa organización/sucursal
  (`POST /api/v1/admin/role_assignments`). No hay autoservicio de alta de
  comercio todavía.
- **Admin**: mismo login OTP que los demás — no hay un flujo separado de
  "admin login." Pero **no existe alta de admin por autoservicio**: el
  primer usuario admin de un ambiente nuevo se crea a mano por consola
  (`bin/rails runner`, asignándole el rol `Platform Admin`). Si estás
  armando la consola administrativa y necesitás un usuario admin en tu
  ambiente de desarrollo, pedile a alguien del equipo backend que te
  bootstree uno, o hacelo vos mismo con:
  ```bash
  docker compose exec web bin/rails runner '
    user = User.create!(phone_country_code: "58", phone_number: "41########",
                         first_name: "Admin", last_name: "Local",
                         status: "active", phone_verified_at: Time.current)
    RoleAssignment.create!(user: user, role: Role.find_by!(name: "Platform Admin"),
                            assigned_by_user: user, starts_at: Time.current)
    puts user.id
  '
  ```
  Después logueate normalmente con OTP usando ese número de teléfono.

## 5. Formato de errores (igual en toda la API)

Cualquier error viene siempre con esta forma, sin importar el código HTTP:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed",
    "details": { "subject": ["can't be blank"] },
    "request_id": "…",
    "correlation_id": "…"
  }
}
```

Códigos más comunes: `validation_failed` (422, `details` trae los campos),
`not_found` (404), `forbidden` (403, incluye `account_disabled`/
`account_locked`/`session_invalid` como variantes), `bad_request` (400,
falta un parámetro requerido), `invalid_reference` (422, un id que no
existe), `internal_error` (500). Guardate `request_id` si necesitás reportar
un bug — es el mismo id que loguea el backend.

## 6. Convenciones a tener en cuenta

- **Dinero siempre en unidades mínimas de la moneda, como entero** (nunca
  con decimales/float) — ej. `total_amount: 150000` en VES son 1.500,00 Bs,
  no 150.000. Cada monto va acompañado de su `currency`.
- **Fechas siempre en UTC, formato ISO 8601** (`2026-08-21T03:10:00Z`).
- **Idempotencia**: los endpoints que crean algo "de una sola vez" (pedidos,
  reembolsos, envíos de Pago Móvil, etc.) piden un `idempotency_key` en el
  body. Mandá el mismo valor si reintentás la misma acción (ej. por un
  timeout de red) — el backend te va a devolver el mismo recurso ya creado
  en vez de duplicarlo. Generá un UUID nuevo por cada acción real del
  usuario, no uno fijo.
- **IDs son UUID**, no enteros autoincrementales.

## 7. Referencia completa de endpoints

Este documento cubre el "cómo empezar," no cada endpoint uno por uno. Para
eso:

- **Swagger UI interactivo** (podés probar requests desde el navegador):
  `http://localhost:3001/api-docs` con el backend corriendo.
- **El archivo OpenAPI en crudo**: [`docs/openapi/v1/openapi.yaml`](openapi/v1/openapi.yaml).

Ahí está el detalle de cada path, cada schema de request/response, y qué
permiso/rol necesita cada uno.

## 8. Qué falta o es un placeholder todavía

Antes de asumir que algo "no funciona," revisá
[`docs/architecture/decisions.md`](architecture/decisions.md) — ahí está
documentado explícitamente lo que es un placeholder a propósito (ej. sin
proveedor de SMS real, sin pasarela de pago real, algoritmo de despacho
simple, sin scheduler para jobs de mantenimiento) versus lo que sería un bug
real.
