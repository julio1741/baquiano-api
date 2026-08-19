# Decisions flagged for validation

Per section 16 of the master prompt ("Marcar toda decisión que necesite
validación legal, bancaria, comercial o técnica"). Nothing here blocks
Increment 1; each is either a documented assumption or a stubbed
integration point.

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

`roles.organization_id` and `role_assignments.organization_id` /
`branch_id` are plain UUID columns with no foreign key yet, because
`organizations` and `branches` don't exist until Increment 2. Increment 2
must add the real foreign keys (a migration, not a schema change) once
those tables exist. Until then, admin role management in this API only
really exercises platform-scoped roles.
