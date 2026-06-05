# Security Advisory — RPC Method Availability Discrepancies

**Date:** 2026-06-05
**Severity:** Medium
**Affected Page:** `docs/dev/read/overview.md` — Available Methods table

## Summary

The RPC method availability table in the developer documentation incorrectly marks five debug/trace methods as "Managed only" (i.e., only available through managed RPC providers like Alchemy). Source code inspection of `mega-rpc` confirms these methods are registered in the public RPC gateway's `RPC_METHODS` array and are routed to the appropriate upstream pools. The documentation understates their availability.

## Affected Methods

| Method | Docs Say | Source Says | Source Location |
|--------|----------|-------------|-----------------|
| `debug_getRawHeader` | Managed only | In `RPC_METHODS`, routed via `COMPUTE_DEBUG_METHODS` | `workers/src/spec/methods.ts:34`, `workers/src/services/upstream/routing.ts:13` |
| `debug_traceCall` | Managed only | In `RPC_METHODS`, routed via `DEBUG_TRACE_METHODS` | `workers/src/spec/methods.ts:38`, `workers/src/services/upstream/routing.ts:20` |
| `trace_call` | Managed only | In `RPC_METHODS`, routed via `DEBUG_TRACE_METHODS` | `workers/src/spec/methods.ts:40`, `workers/src/services/upstream/routing.ts:21` |
| `trace_block` | Managed only | In `RPC_METHODS`, routed via `COMPUTE_DEBUG_METHODS` | `workers/src/spec/methods.ts:41`, `workers/src/services/upstream/routing.ts:14` |
| `trace_transaction` | Managed only | In `RPC_METHODS`, routed via `COMPUTE_DEBUG_METHODS` | `workers/src/spec/methods.ts:42`, `workers/src/services/upstream/routing.ts:15` |

## Impact

Developers relying on the documentation may incorrectly assume these methods require a managed RPC provider, leading to unnecessary dependency on third-party services for functionality that is available on the public endpoint.

## Root Cause

The `RPC_METHODS` array in `mega-rpc/workers/src/spec/methods.ts` defines the complete set of methods accepted by the public RPC gateway. The documentation table was not updated when these methods were added to the gateway.

## Resolution

The availability column for all five methods has been corrected from "Managed only" to "Available" in `docs/dev/read/overview.md`.

## Verification

Source references (mega-rpc repo, commit `c148f59d`):

- `workers/src/spec/methods.ts` lines 34–42 — `debug_getRawHeader`, `debug_traceCall`, `trace_call`, `trace_block`, `trace_transaction` are all in the `RPC_METHODS` const array
- `workers/src/services/upstream/routing.ts` lines 9–22 — routing configuration for `COMPUTE_DEBUG_METHODS` and `DEBUG_TRACE_METHODS`

## Discovery

Found by the automated documentation audit pipeline (`megaeth-labs/auto-audits`), issues #30 and #2.
