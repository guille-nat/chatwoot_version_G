# custom/ -- CoopFlow (Coop Core)

This directory is CoopFlow's extension overlay. It reuses the same injection
framework Chatwoot already ships for `enterprise/` (see
`config/initializers/01_inject_enterprise_edition_module.rb` and
`lib/chatwoot_app.rb`). CoopFlow code lives here so it never requires editing
`app/`, `lib/`, or `enterprise/`.

Full architecture is in the `f1-plataforma-base` design doc. This file is the
practical, PR-time checklist (ADR-010).

## The one permanent core diff

`config/application.rb` carries a single additive block (search for
`ChatwootApp.custom?`). If an upstream merge conflicts on that file, re-apply
the same block after the existing `enterprise` block -- do not delete it.

`config/routes.rb` has **zero** diff. All CoopFlow routes live in
`custom/config/routes.rb`, wired via `config.paths['config/routes.rb']`.

## Namespace rules (locked -- violating these silently breaks Zeitwerk)

| Path pattern | Constant |
|---|---|
| `custom/app/models/coop_core/producer.rb` | `CoopCore::Producer` |
| `custom/app/models/coop_core/producer/cuit.rb` | `CoopCore::Producer::Cuit` |
| `custom/app/models/custom/concerns/account.rb` | `Custom::Concerns::Account` |
| `custom/app/controllers/api/v1/accounts/coop/producers_controller.rb` | `Api::V1::Accounts::Coop::ProducersController` |
| `custom/app/dispatchers/custom/async_dispatcher.rb` | `Custom::AsyncDispatcher` |
| `custom/lib/coop_core.rb` | `CoopCore` (explicit namespace) |

- Domain namespace is `CoopCore::`. Injection namespace (matches
  `include_mod_with`/`prepend_mod_with` calls in core) is `Custom::`. HTTP
  namespace is `Api::V1::Accounts::Coop::` -- deliberately `coop`, not
  `coop_core`, so a Ruby constant-resolution bug can't accidentally resolve
  `CoopCore::X` through a controller's lexical scope.
- **Forbidden:** a `concerns/` directory directly under `custom/app/models` or
  `custom/app/controllers` -- it produces a bare `Concerns::` prefix instead of
  a namespaced one. Model concerns for Chatwoot injection go under
  `custom/app/models/custom/concerns/`; CoopCore's own controller concerns go
  under `custom/app/controllers/coop_core/`.
- **Forbidden:** nested `module Api; module V1; ...` definition style in
  `custom/app/controllers`. Use the compact form
  `class Api::V1::Accounts::Coop::ProducersController < ...` (matches the rest
  of the codebase and keeps `Module.nesting` minimal).
- `custom/app/**` must contain only directories -- each direct child of
  `custom/app` is its own Zeitwerk autoload root.

## Every CoopFlow table is prefixed `coop_core_`

Via `CoopCore.table_name_prefix` (`custom/lib/coop_core.rb`). This guarantees
zero collision risk with any future upstream Chatwoot table.

## Migrations

`accounts`, `contacts`, and `users` primary keys are `serial` (int4), not
bigint (`db/schema.rb`). Any FK column pointing at them
(`account_id`, `contact_id`, `user_id`, `updated_by_id`) **must** use
`t.integer`, never `t.references` (which emits bigint). CoopFlow's own primary
keys and internal FKs stay bigint (Rails default).

## `db/schema.rb` conflicts on upstream merges

This is expected and safe. Recipe: accept upstream's `db/schema.rb`, run
`bin/rails db:migrate` (the live DB already has the CoopFlow tables, so the
regenerated file is correct), commit.

## `DISABLE_ENTERPRISE` and FOSS CI (ADR-009)

`ChatwootApp.extensions` checks `custom?` **before** `enterprise?`. The moment
`custom/` exists, `ChatwootApp.extensions` returns `%w[enterprise custom]`
**even when `DISABLE_ENTERPRISE` is set** -- creating this directory silently
re-enables Enterprise module injection for FOSS-mode boots. This is
intentional and documented, not a bug: CoopFlow is a commercial SaaS that
always ships the full fork.

Do not patch `lib/chatwoot_app.rb` to "fix" this -- it would be a second
permanent core diff for zero CoopFlow benefit. Instead:

- `spec/custom/coop_core_wiring_spec.rb` asserts this behavior explicitly, so
  an upstream change to `chatwoot_app.rb` fails CI loudly instead of silently
  changing FOSS-mode behavior.
- The FOSS-only CI workflows (`.github/workflows/run_foss_spec.yml`,
  `publish_foss_docker.yml`, `size-limit.yml`) strip `custom/` alongside the
  existing `enterprise/` strip, so FOSS builds/specs never see CoopFlow code.

## Initializers load before Rails initializers

Files under `custom/config/initializers/*.rb` are `require`d from
`config/application.rb`'s class body -- i.e. **before** Rails' own
initializers run (same constraint `enterprise/config/initializers` already
lives with). Do not reference autoloaded constants at the top level of an
initializer file.

## Never touch

- `config/features.yml` -- CoopFlow flags live in CoopFlow's own multi-scope
  system (`CoopCore::Feature`), never in Chatwoot's account-scoped bitmask.
- `CustomRole::PERMISSIONS` -- CoopFlow staff roles are a separate,
  non-overlapping authorization layer (`CoopCore::Permission`).
- `enterprise/` -- CoopCore never depends on or edits Enterprise Edition code.

## Proof it works

`spec/custom/coop_core_wiring_spec.rb` is the smoke test for everything in
this document. It must stay green.
