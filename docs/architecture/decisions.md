# Decisions flagged for validation

Per section 16 of the master prompt ("Marcar toda decisión que necesite
validación legal, bancaria, comercial o técnica"). Nothing here blocks the
increment it was raised in; each is either a documented assumption, a
stubbed integration point, or (once resolved) left in place as a record of
what changed and why.

## No SMS gateway selected yet

`Identity::DeliverOtpJob` (`app/domains/identity/jobs/deliver_otp_job.rb`)
has no real SMS provider wired up — it only logs that a dispatch was
requested. Needs a commercial decision (which provider covers Venezuela/
Barinas reliably) before going further than local development, where the
code is returned directly in the API response (`dev_only_code`, only outside
production) instead of being texted.

## Admin authentication reuses the customer/courier/merchant OTP flow

Section 7 calls for MFA on administration but doesn't specify the
mechanism. `Api::V1::Admin::SessionsController` currently authenticates the
same way as every other role (phone + OTP). Needs a decision on the actual
second factor (TOTP? WebAuthn? something else) before this goes to
production with real admin accounts.

## Registration flow: no separate "sign up" endpoint

The spec's endpoint list only mentions "Solicitar OTP" / "Verificar OTP",
not a distinct registration step. `Identity::VerifyOtp` creates the account
on the first successful verification for a phone number, using
`first_name`/`last_name` passed alongside the code (required only that
first time). This is an assumption about the intended UX, not something the
spec pins down explicitly — worth confirming against the actual Flutter
client flow once it exists.

## Role/branch scoping ahead of Organizations (Increment 2)

**Resolved in Increment 2** — `roles.organization_id` and
`role_assignments.organization_id`/`branch_id` now have real foreign keys
(`db/migrate/*_add_organization_foreign_keys_to_access_control.rb`). Along
the way, `Role`'s own `organization_id` was clarified to mean "which
organization defined this custom role" (nil = global template, e.g.
`merchant_owner`), independent of `scope_type` (which controls how
*assignments* of the role are scoped) — the original Increment 1 validation
conflated the two and would have made a reusable org-scoped role template
impossible to create.

## Barinas zone geometry is a placeholder

`db/seeds.rb` seeds one `Zone` for Barinas using a rough bounding box
(-70.35..-70.10, 8.55..8.75), not a real administrative boundary. Needs
real GIS data (municipality shapefile or hand-drawn coverage polygon)
before it's used for anything beyond local development/testing.

## Prescription sales gated behind a config flag, not real regulatory review

`config.x.prescription_sales_enabled` (`config/application.rb`, default
`false`) blocks activating a `prescription_required` product
(`app/models/product.rb`). This satisfies the spec's requirement not to
allow it by default, but the flag itself is a placeholder — actually
enabling pharmacy prescription sales needs legal/regulatory sign-off first,
and probably a real mechanism (uploaded prescription, pharmacist review)
that doesn't exist yet.

## Delivery fee is a made-up placeholder rate

`db/seeds.rb` seeds one fixed `DeliveryFeeRule` for Barinas (150.00 VES) so
`Pricing::GenerateQuote` can be exercised end-to-end in development without
manual setup. This is not a real commercial rate — it needs a pricing
decision (and probably distance-based tiers, not a flat fee) before this
goes anywhere near production.

## No service fee configuration exists

`Pricing::GenerateQuote` always sets `service_fee_amount` to 0 — the spec's
`quotes`/`orders` tables have the column, but no table or rule configures
what a service fee should be. Needs a decision on whether/how Baquiano
charges a platform service fee before this stays hardcoded to zero.

## Quotes don't do currency conversion yet

`quotes.exchange_rate_id`/`exchange_rate_value` stay null — carts and
quotes are priced entirely in the branch's own currency (VES for every
seeded branch). The `ExchangeRate` model exists and is validated/tested,
but `Pricing::GenerateQuote` never reaches for it. Needs a product decision
on when/whether a customer should see a USD-equivalent total before that
logic gets written.

## Organizations/merchants are hard-deletable via the admin API

`Api::V1::Admin::OrganizationsController`/`MerchantsController` expose
`destroy`, relying on `dependent: :restrict_with_error` (merchants,
branches) to block deletion while children exist. Whether a real
organization should ever be *deletable* (versus only suspendable via
`suspend!`) is a business decision this MVP hasn't made — flagging in case
`destroy` should be removed in favor of suspend-only once that's decided.

## Order state machine stops at ready_for_pickup; courier/payment states exist only as enum values

`Orders::TransitionOrder::TRANSITIONS` (Increment 4) only wires up the
transitions that don't depend on Dispatch or Payments:
`placed → merchant_pending → merchant_accepted → preparing →
ready_for_pickup`, plus cancellation up to that point. `current_status`'s
enum already declares every later state from the spec's full lifecycle
(`courier_search` through `closed`, plus `refund_pending`/`disputed`/etc.)
so the column and validations are future-proof, but no rule in the table
can reach them yet — that's Increment 5 (Dispatch) and Increment 6
(Payments) work. An order that reaches `ready_for_pickup` today has no way
to progress further through the API.

## orders.delivery_id has no foreign key yet

`db/migrate/*_create_orders.rb` adds a bare `uuid` column for `delivery_id`
with no `references`/FK, since the `deliveries` table (Dispatch domain)
doesn't exist yet. Needs a migration adding the real foreign key once
Increment 5 creates that table.

## payment_method's upfront-confirmation split is a guess, not a confirmed business rule

`Orders::PlaceOrder::UPFRONT_CONFIRMATION_METHODS` (currently just
`mobile_payment`) decides whether a new order starts in `payment_pending`
(waiting for confirmation) versus going straight to `placed`. This mirrors
the spec's description of `pago_movil` needing manual/external
confirmation before an order is real, while `pos_on_delivery`/`cash` don't
block placement — but the exact list of "which payment methods need
upfront confirmation" hasn't been validated with product/finance and may
need to grow (e.g. a future card-on-file method) or shrink.

## "system" actor bypasses all transition authorization checks

`Orders::TransitionOrder#authorize!` (`app/domains/orders/services/
transition_order.rb`) skips every actor check when `actor_type: "system"`
is passed, regardless of which rule's declared `actor:` would otherwise
apply. This is what lets internal jobs — currently only
`Orders::AutoCancelUnacceptedOrdersJob` — force a transition (e.g.
`merchant_pending → cancelled`, a rule declared `actor: :customer`)
without a customer or staff member actually present. `actor_type` is never
taken from client input (controllers always pass a fixed string), so this
is safe *today*, but it means any future code path that manages to call
`TransitionOrder.call(actor_type: "system", ...)` gets unconditional
authority over every order transition. Worth revisiting if that ever stops
being true — e.g. by requiring an explicit allow-list of which transitions
"system" may force, rather than blanket bypass.

## No scheduler wired up for maintenance jobs yet

`Orders::AutoCancelUnacceptedOrdersJob` (like `Carts::ExpireStaleCartsJob`
and `Identity::PurgeExpiredOtpChallengesJob` before it) is a plain
`ApplicationJob` with no recurring trigger — nothing currently calls
`.perform_later` on a schedule. Needs a periodic job scheduler (e.g.
sidekiq-cron, or an external cron hitting a rake task) configured before
any of these three jobs actually run outside of manual/test invocation.

## Two bugs found by a live end-to-end walkthrough, invisible to the request spec suite

After Increment 4 shipped, a manual curl-driven walkthrough of the full
customer → merchant journey against the running dev server (not RSpec)
surfaced two real defects that every request spec had silently worked
around via factories:

1. **`Api::V1::Admin::OrganizationsController#organization_params` never
   permitted `:status`** (merchant/branch controllers already did), so a
   real admin had no way to move an organization out of `pending` — only
   `Organization.new`'s DB default, never touched by a real request. Fixed
   by adding `:status` to the permitted params, with a new request spec
   (`organizations_merchants_branches_spec.rb`) asserting it. Every
   existing organization spec used `create(:organization)` directly, which
   never exercises `update` with a `status` param, so this went uncaught.

2. **`db/seeds.rb`'s `merchant_owner` role template was never granted
   `orders:read`/`orders:update_status`** — both permission codes existed
   in the seed `PERMISSIONS` list since Increment 1, but Increment 4's
   `RolePolicy`/`OrderPolicy` staff checks were never wired into the one
   role real merchant staff actually get assigned. A merchant correctly
   onboarded and assigned `merchant_owner` could not accept, reject,
   prepare, or mark ready any of their own orders. Every merchant order
   spec built its own one-off role + permission via factories
   (`create(:role, code: "merchant_owner")` + a hand-picked
   `role_permission`), so the seed template's actual contents were never
   exercised. Fixed by adding both codes to the `merchant_owner` grant list
   in `db/seeds.rb`.

Neither bug could have been caught by the request spec suite as written,
since specs construct roles/permissions/organizations directly with
FactoryBot rather than going through the real admin bootstrap → activate →
assign-role flow a production operator would use. Worth keeping in mind
for future increments: request specs verify the *application* logic, not
that the *seeded reference data* (roles, permission grants, default
statuses) actually lets a real operator reach that logic.

## Zone/ServiceArea have no admin API — coverage areas are console/seed-only

The same live walkthrough found that a branch created entirely through the
real admin API (organization → merchant → branch → catalog, all of which
now work end-to-end) still never appears in `/api/v1/customer/coverage`
without a `ServiceArea` row linking it to a `City`/geometry — and there is
no controller or route for `service_areas` (or `zones`) at all; both are
seed/console-only today (mirroring the already-documented "Barinas zone
geometry is a placeholder" decision). Deliberately not treated as an
Increment-4-blocking bug and not patched with an ad-hoc endpoint: polygon
geometry is awkward to manage via a raw JSON API (a real admin tool would
want map-drawing, not coordinate arrays over curl), and `Zone`/`ServiceArea`
are Geography-domain concerns, which Increment 5 already has scoped in
(see `docs/architecture/domains.md`). Revisit there — likely as either a
minimal coordinate-array admin endpoint or an explicit "console-managed for
the MVP" decision, not silently left unaddressed.

**Still not resolved in Increment 5** — logistics work (couriers/dispatch/
deliveries) didn't touch coverage-area configuration; `Zone`/`ServiceArea`
remain console-only. Pushed further out again; flagging so it doesn't get
silently forgotten a third time.

## Dispatch's courier-matching algorithm is a placeholder

`Dispatch::CreateOffers` (Increment 5) ranks eligible couriers purely by
distance from their most recent `LocationPing` to the pickup point —
nearest online, approved courier wins the top offer slot, `CANDIDATE_LIMIT`
(5) and `OFFER_TTL` (30 seconds) are made-up constants. Section 4.14 never
specifies a real scoring algorithm beyond "score_snapshot: jsonb", so this
isn't a validated dispatch policy — no acceptance-rate weighting, no
courier rating, no fairness/rotation logic, no surge handling. Needs a real
product/ops decision before this is anything more than a functional
placeholder.

## delivery_pin is also stored encrypted, not just as a digest

Section 4.14's `deliveries` table only lists `delivery_pin_digest` — no
encrypted counterpart, implying the PIN would be shown to the customer
once (e.g. via a push notification at assignment time) and never
retrievable from the server again. That doesn't hold up in practice: the
customer needs to be able to re-check the PIN on their own tracking screen
whenever the courier arrives, not just at the one moment it was generated,
and there's no Notifications domain yet (Increment 7) to have delivered it
any other way. `Delivery` (`app/models/delivery.rb`) adds
`delivery_pin_encrypted` (Active Record Encryption, same as every other
`*_encrypted`/`*_digest` pair in this codebase) alongside the digest —
found and fixed via a live end-to-end walkthrough that discovered the PIN
was never even being generated, let alone retrievable, so the entire
PIN-confirmation flow was unusable as originally scoped. Revisit if a real
Notifications channel makes a true show-once flow (matching the literal
schema) preferable.

## Courier self-service vs admin field authorization split

`CourierPolicy` has two distinct authorization methods over the same
`Courier` record — `update?` (self-service, `own_courier?` only) and
`manage?` (admin-only, `organizations:manage`, no owner fallback) — instead
of one shared method. This is load-bearing: `Authenticatable`
(`app/controllers/concerns/authenticatable.rb`) authorizes purely by
permission, not by which app namespace issued the access token, so a
courier's own token can reach `/api/v1/admin/*` routes and would pass a
shared `update?` via `own_courier?`. Caught before shipping by reasoning
through the shared-policy design, not by a test failure — worth
remembering for any future policy that backs both a self-service and an
admin controller for the same model (`OrderPolicy`/`OrganizationPolicy`
don't have this shape today, but a similar model might).

## Courier earnings, cash handling, and settlements are out of scope

Section 6's courier endpoint list includes "Consultar ganancias",
"Registrar cobro", "Consultar efectivo pendiente" — none of these are
built. They depend on the Payments/Ledger domain (Increment 6:
`cash_enabled`/`maximum_cash_exposure` already exist as columns on
`Courier` but aren't used yet). `courier_branch_assignments` (a merchant's
own fleet, as opposed to Baquiano-pooled couriers) also has no endpoint
yet to actually create an assignment — `courier_type: "merchant"` couriers
have no way to become eligible for a specific branch's deliveries through
the API today.

## Location ping retention/precision-reduction policy not implemented

Section 4.14 calls for a retention policy and "reducción o eliminación de
precisión después del período operacional" for `location_pings`. Neither
exists — pings are stored indefinitely at full precision via
`Deliveries::RecordLocationPing`. Needs a real decision on retention
window and whether/how to degrade precision before this goes near
production, especially given this is exactly the kind of personal location
data that data-protection rules tend to care about.
