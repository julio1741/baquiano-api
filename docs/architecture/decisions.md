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

## Organizations/merchants are hard-deletable via the admin API

`Api::V1::Admin::OrganizationsController`/`MerchantsController` expose
`destroy`, relying on `dependent: :restrict_with_error` (merchants,
branches) to block deletion while children exist. Whether a real
organization should ever be *deletable* (versus only suspendable via
`suspend!`) is a business decision this MVP hasn't made — flagging in case
`destroy` should be removed in favor of suspend-only once that's decided.
