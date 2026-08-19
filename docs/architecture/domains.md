# Domain modules

Each domain listed in the spec lives under `app/domains/<domain>/`, with role
folders inside it collapsed into the domain's own namespace (configured in
`config/initializers/autoloading.rb`):

```
app/domains/orders/
  models/          -> Orders::<Model>
  services/        -> Orders::PlaceOrder, Orders::TransitionOrder
  policies/        -> Orders::<Something>Policy
  queries/         -> Orders::<Something>Query
  serializers/     -> Orders::<Something>Serializer
  jobs/            -> Orders::<Something>Job
  events/          -> Orders::<Something>Event
  subscribers/     -> Orders::<Something>Subscriber
  validators/      -> Orders::<Something>Validator
  errors/          -> Orders::<Something>Error
```

`app/domains/orders/services/place_order.rb` resolves to `Orders::PlaceOrder`
(not `Orders::Services::PlaceOrder`), matching the command names used
throughout the spec (`Orders::PlaceOrder`, `Payments::CreatePaymentIntent`,
`Deliveries::AssignCourier`, ...).

Domains are added incrementally, one per implementation increment (section 14
of the master prompt) — folders are only created once they hold real code, to
avoid empty scaffolding:

| Increment | Domains |
|---|---|
| 1 | Identity, AccessControl, Users |
| 2 | Organizations, Merchants, Catalog |
| 3 | Customers, Addresses, Carts, Pricing |
| 4 | Orders |
| 5 | Couriers, Dispatch, Deliveries, Geography |
| 6 | Payments, Accounting, Reconciliation |
| 7 | Notifications, Support, Risk, Audit, Configuration |

Cross-cutting, non-domain code stays where Rails expects it:
`app/controllers/api/v1/<customer|courier|merchant|admin|webhooks>`,
`app/errors` (base error hierarchy shared by every domain),
`app/lib` (e.g. `Current`).
