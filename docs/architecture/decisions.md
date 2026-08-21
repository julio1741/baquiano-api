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

## No real payment gateway — Payments is a manual-review record-keeper

Per section 16's explicit rules ("no inventar integraciones bancarias",
"no asumir acceso automático a Pago Móvil", "no confirmar pagos mediante
una imagen"), `Payments::SubmitMobilePayment`/`ReviewMobilePayment` and
`Payments::RecordPosPayment` never talk to a real bank/processor —
`provider` is always `"manual"`, and every confirmation is a human
decision (a staff member reviewing a claimed Pago Móvil reference, or a
courier/staff member physically present at a POS swipe). This is
deliberate scope, not a placeholder to fill in later within this MVP.

## Two real bugs found by a live end-to-end walkthrough (Increment 6)

Same practice as Increments 4 and 5 — a full manual walkthrough (real OTP
logins, mobile-payment order → submission → admin review → delivery →
refund → settlement, plus a cash order hitting its courier's exposure
limit) surfaced defects the automated suite's factories had papered over:

1. **`Merchant.commission_rate_basis_points` had no admin API path to set
   it at all** — the column existed and `Ledger::RecordOrderSettlementEntries`/
   `Settlements::Create` both read it, but every merchant's effective rate
   was silently `nil` → 0% forever, with no error raised anywhere (a
   wrong-answer bug, not a crash — the same "silently wrong" shape flagged
   below for the `case/when` collision risk). Fixed by adding it to
   `Api::V1::Admin::MerchantsController`'s permitted params.
2. **A courier could mark a cash/pos_on_delivery order "delivered" without
   ever successfully collecting payment** — e.g. after their own cash
   exposure limit blocked the collection — since `Deliveries::TransitionDelivery`'s
   `at_customer → delivered` rule only ever checked the PIN, never payment
   state. Fixed by adding a `requires_captured_payment` rule flag that
   checks `order.payment_intent.status_captured?` before allowing
   delivery completion; mobile_payment orders are unaffected since their
   payment is already captured long before delivery starts.

## `Api::V1::<role>` namespace collision bit an Admin controller, not just same-named ones

`docs/architecture/domains.md`'s "gotcha" entry already documented this
correctly (it says the trap applies from *any* `Api::V1::*` controller,
not just a role's own namespace) — the lapse here was in applying that
rule while writing new code, not a gap in the documentation. Worth a
reminder anyway: since `Merchant`/`Customer`/`Courier`'s colliding
routing-namespace modules are direct children of `Api::V1`, a bare
reference from `Api::V1::Admin::SettlementsController` — nowhere near
`Api::V1::Merchant` or `Api::V1::Courier` lexically — still resolves to
the wrong sibling module, because Ruby's constant lookup walks every
enclosing lexical scope, not just the innermost one. Caught when
`{ "merchant" => Merchant, "courier" => Courier }` in the new admin
settlements controller raised `NoMethodError: undefined method 'find' for
module Api::V1::Merchant`. Fixed there (`::Merchant`/`::Courier`) and
audited every other `app/controllers/api/v1/**/*.rb` file — no other bare
references existed. Also defensively `::`-prefixed three files outside
`api/v1` that reference `Merchant`/`Courier`/`Customer` in a `case/when`
(`Settlements::Create`, `Settlements::MarkPaid`, `SettlementPolicy`,
`Customers::EnsureProfile`) — safe today since no colliding module exists
in *their* lexical chain, but a `case/when` misresolution fails silently
(the branch just never matches) rather than raising, which is harder to
notice than a crash.

## Settlement gross/commission is computed independently of the ledger and of later refunds

`Settlements::Create` computes `gross_amount`/`commission_amount` by
summing `Order` fields directly (subtotal/tax/discount, or delivery_fee
for couriers) over the period — not from `LedgerAccount` running balances.
This keeps a settlement easy to audit ("exactly these N orders"), but it
means a refund issued *after* an order's settlement period closes isn't
netted out of that merchant's next settlement automatically — refund
accounting only ever touches the ledger's `merchant:*:payable` balance
(itself a simplification, see below), never a `Settlement` record. A
merchant could be paid out gross for an order that's later fully refunded.
Needs a real reconciliation step between refunds and settlements before
this is production-safe.

## Refund ledger entries are simplified, and the delivery-fee pool has no per-courier ledger trail

Two related simplifications from Increment 6 worth keeping together:
`Ledger::RecordRefundEntries` reverses a refund's full amount against the
merchant's own payable rather than proportionally unwinding it across the
original subtotal/tax/delivery_fee/commission split (see the class comment
for the reasoning). Separately, `platform:delivery_fee_payable` is one
shared liability account for *every* courier's pooled delivery-fee
earnings — `Settlements::Create`/`MarkPaid` compute and pay out a specific
courier's share correctly from `Order`/`Delivery` data, but the ledger
account itself has no per-courier subdivision, so nothing there would
catch the pool ever going net-negative from over-paying couriers relative
to what was actually collected. Both are acceptable for an MVP's
audit-lite bookkeeping but not for real accounting close.

## Payment intent expiry window and cash exposure blocking are unvalidated constants

`Payments::CreatePaymentIntent::MOBILE_PAYMENT_WINDOW` (30 minutes) and
the whole `cash_balances.blocked_for_cash_orders` flag (settable by an
admin via `Api::V1::Admin::CashBalancesController`, but nothing ever sets
it automatically) are placeholders — no product/risk decision has picked
a real submission window, and there's no automated trigger (repeated cash
shortfalls, fraud signals) that would ever flip `blocked_for_cash_orders`
on its own. That's Risk domain territory (Increment 7).

## Two real bugs found by a live end-to-end walkthrough (Increment 7)

Same practice as Increments 4, 5, and 6 — a real HTTP walkthrough (bootstrap
admin/customer/courier via `bin/rails runner`, build an order chain, then
exercise every Increment 7 endpoint over `curl` against a running
`docker compose` stack) found two defects invisible to the RSpec suite:

1. **`config/sidekiq.yml` didn't exist, so the real Sidekiq process only
   ever listened to the `default` queue.** Every `queue_as` in the app uses
   `:maintenance`, `:notifications`, or `:webhooks` — none use `:default` —
   so **no background job of any kind had ever actually run** in any
   environment using this compose file, since the first custom queue was
   introduced back in Increment 4. Completely invisible to specs, since
   they call jobs synchronously (`perform_now`/`perform_enqueued_jobs`) and
   never touch a real Sidekiq worker process. Caught only because the live
   webhook-replay test kept showing `status: "received"` instead of
   `"processed"` after `Webhooks::ProcessJob.perform_later` had clearly
   enqueued something. Fixed by adding `config/sidekiq.yml` listing all
   four queues (`default`, `webhooks`, `notifications`, `maintenance`);
   Sidekiq loads that file automatically with no command-line changes
   needed. Worth auditing again if a queue is ever renamed or added.
2. **`RiskDecision` had no path to ever be created.** `Risk::Decide` existed
   with no caller anywhere in the app, and the admin routes only expose
   `index`/`show`/`review` for `risk_decisions` — no `create`. A fraud
   signal could fire correctly (confirmed live: an impossible-speed pair of
   `LocationPing`s produced a `FraudSignal` with `implied_speed_kmh` over
   150,000), but `GET /api/v1/admin/risk_decisions` stayed empty forever,
   so nothing ever surfaced for `Admin::RiskDecisionsController#review` to
   act on. Fixed by having `Risk::RecordSignal` call `Risk::Decide` to open
   a `manual_review` decision automatically whenever a signal's severity is
   `high` or `critical` (`medium`/`low` signals are recorded but don't open
   a decision — kept deliberately conservative per section 16's ban on an
   automated ML risk engine; this only routes existing evidence to a human,
   it doesn't decide anything on its own).

## Nine of the section-15 domain events are still never emitted

`DomainEvent`/`OutboxEvent` (Increment 4) plus `Events::ProcessOutboxJob`
(Increment 7, which finally drains the outbox instead of leaving it
write-only) cover most of the order/delivery/payment/refund lifecycle, but
`UserRegistered`, `PhoneVerified`, `MerchantApproved`, `BranchPaused`,
`CatalogPublished`, `QuoteCreated`, `CashCollected`, `CashHandedOver`,
`SettlementCreated`, and `SettlementPaid` are named in the spec's event
catalog but never actually published anywhere in the codebase. None of
these gaps block anything internal to the MVP (nothing here subscribes to
its own domain events yet — the outbox is a boundary for future external
consumers, not something the app itself currently reacts to), so this was
deliberately left as a documented gap rather than retrofitted across five
increments' worth of services.

## No merchant-facing support case self-service, and no scheduler for maintenance jobs

`SupportCase` self-service exists for customer and courier
(`Api::V1::Customer::SupportCasesController`,
`Api::V1::Courier::SupportCasesController`) but not for merchant staff —
section 4.16 only asked for "trazabilidad mínima," not full coverage
across every actor, and a merchant-side controller would be near-identical
copy-paste of the existing two. Separately, the now-nine `queue_as
:maintenance` jobs (outbox processing, webhook retry, session cleanup,
location-ping purge, cart/quote expiry, offer expiry, OTP-challenge purge,
order auto-cancel, payment-intent expiry, duplicate-payment detection) all
still have to be triggered manually or via `bin/rails runner` — there is no
cron gem or scheduler wired into this MVP (accepted and documented as a
gap since Increment 4; the list of jobs needing a schedule has just grown).

## `Idempotency::Perform`'s block-forwarding needed an explicit method, not `...`

The usual `def self.call(...) = new(...).call` shorthand used everywhere
else in this codebase silently breaks when the underlying `#call` expects
a block: Ruby's `...` forwards positional/keyword args *and* the block to
whichever call it's attached to — here, `new(...)` — so the following
`.call` has no block to `yield` into, and raises `LocalJumpError` at the
`yield` site inside `#call`, not at the call site. Caught by a smoke test
that called `Idempotency::Perform.call(...) { create_something }` in the
ordinary block-based way every other case in the codebase does. Fixed with
an explicit `def self.call(*args, **kwargs, &block); new(*args, **kwargs).call(&block); end`.
Worth remembering for any future service that both uses the `.call(...)`
shorthand *and* wants to accept a block — the shorthand and blocks don't
mix.

## `Api::V1::Webhooks` is a fourth confirmed instance of the namespace collision

`app/controllers/api/v1/webhooks/events_controller.rb` sits in
`Api::V1::Webhooks`, colliding with the top-level `Webhooks` domain module
the same way `Merchant`/`Customer`/`Courier` collide with their own
domains (documented in `docs/architecture/domains.md`'s "gotcha" section
and the Increment 6 entry above for `Api::V1::Admin`). This instance was
caught proactively while writing the controller, before it ever shipped
broken — a bare `Webhooks::Receive.call` inside this controller would have
raised "uninitialized constant" rather than a wrong-module `NoMethodError`,
since there's no `Api::V1::Webhooks::Receive` to accidentally resolve to
instead. Written correctly from the start as `::Webhooks::Receive`/
`::Webhooks::ProcessJob`. Four confirmed instances of this trap across
Increments 5-7 is enough to call it a systemic risk of the
`Api::V1::<RoleName>` routing convention, not a one-off mistake — any new
`Api::V1::<X>` namespace should be checked against existing top-level
domain module names before writing any bare constant reference inside it.

## `audit_events.change_details` deviates from a literal `changes` column name

`AuditEvent` stores a diff of what changed under `change_details`, not
`changes` — the spec's own field list literally says "changes," but
`changes` is `ActiveRecord::Base`'s own reserved dirty-tracking method
name, and defining a column with that name raises
`ActiveRecord::DangerousAttributeError` at boot. Caught before the model
was even written, via a disposable scratch-class test. Documented directly
in the migration file's own comment as well as here.
