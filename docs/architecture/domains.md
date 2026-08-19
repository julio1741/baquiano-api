# Domain modules

ActiveRecord models stay flat in `app/models` (plain Rails convention: `User`,
`Session`, `Role`, ...) — Increment 1 showed that domain-namespacing models
too would produce stuttering names (`Users::User`) for no benefit, since
Pundit and associations already expect the plain top-level class name.

Everything else that section 2 of the spec calls out per domain (services,
policies, queries, jobs, events, subscribers, validators, domain-specific
errors) lives under `app/domains/<domain>/`, with the role folder collapsed
into the domain's own namespace (configured in
`config/initializers/autoloading.rb`):

```
app/domains/identity/
  services/        -> Identity::RequestOtp, Identity::VerifyOtp
  jobs/            -> Identity::DeliverOtpJob

app/domains/access_control/
  queries/         -> AccessControl::HasPermission
  services/        -> AccessControl::AssignRole, AccessControl::RevokeRole
```

`app/domains/identity/services/verify_otp.rb` resolves to `Identity::VerifyOtp`
(not `Identity::Services::VerifyOtp`), matching the command names used
throughout the spec (`Orders::PlaceOrder`, `Payments::CreatePaymentIntent`,
`Deliveries::AssignCourier`, ...).

Pundit policies also stay flat in `app/policies` (`UserPolicy`, `RolePolicy`,
...) — that's Pundit's own convention (`authorize record` looks up
`"#{record.class}Policy"`), and a policy can lean on a domain query object
for the actual scope-matching logic (e.g. `ApplicationPolicy#has_permission?`
calls `AccessControl::HasPermission`).

## Gotcha: model names that collide with an API route namespace

`Api::V1::Merchant` exists as a real Ruby module (Zeitwerk creates it because
`app/controllers/api/v1/merchant/` holds `Api::V1::Merchant::OtpsController`
etc.) — the routing namespace for the merchant-role API. That collides with
the top-level `Merchant` model: a bare `Merchant` referenced from *inside*
any `Api::V1::*` controller resolves to the *namespace module*, not the
model, because Ruby's lexical constant lookup checks the enclosing
`Api::V1` scope before falling back to the top level. It fails at runtime,
not load time (`NoMethodError: undefined method 'find' for module
Api::V1::Merchant`), so it isn't caught by RuboCop/Brakeman — only by
actually exercising the code path.

Every `app/controllers/api/v1/**/*.rb` file that touches the `Merchant`
model must spell it `::Merchant`. Same trap for `Customer`, confirmed in
Increment 3 once the model existed alongside `Api::V1::Customer` — avoided
there by never referencing the bare model from inside `Api::V1::Customer::*`
controllers, only through associations (`current_user.customer`,
`current_customer.addresses`). `::Customer` would still be needed by any
code that does `Customer.find(...)` or similar from in there. `Courier`
(Increment 5) will need the same care.

Domains are added incrementally, one per implementation increment (section 14
of the master prompt) — folders are only created once they hold real code, to
avoid empty scaffolding:

| Increment | Domains |
|---|---|
| 1 | Identity, AccessControl |
| 2 | Organizations, Merchants, Catalog |
| 3 | Customers, Carts, Pricing |
| 4 | Orders |
| 5 | Couriers, Dispatch, Deliveries, Geography |
| 6 | Payments, Accounting, Reconciliation |
| 7 | Notifications, Support, Risk, Audit, Configuration |

Cross-cutting, non-domain code stays where Rails expects it:
`app/controllers/api/v1/<customer|courier|merchant|admin|webhooks>`,
`app/errors` (base error hierarchy shared by every domain),
`app/lib` (`Current`, `BlindIndex`, `Phone`).
