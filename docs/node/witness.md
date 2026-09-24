---
description: mega_getBlockWitness — fetch the SALT + MPT witness needed to stateless-verify a MegaETH block.
---

# Get block witness

MegaETH defines a `mega_getBlockWitness` RPC method to return the cryptographic witness for a single MegaETH block.
The witness contains the subset of state the block reads or writes, packaged with proofs against the previous block's state root, so that a stateless verifier can re-execute the block without holding any chain state locally.

The RPC method is served at the public MegaETH RPC endpoint:

```text
https://mainnet.megaeth.com/rpc
```

The witness JSON-RPC method is the same logical service that powers the [stateless validator](stateless-validation.md)'s `--witness-endpoint`.
Any client — an operator running [`stateless-validator`](https://github.com/megaeth-labs/stateless-validator) or a custom verifier — can call it directly.

## Request

|        | Value                             |
| ------ | --------------------------------- |
| Method | `mega_getBlockWitness`            |
| Params | `[<keys>]` — single-element array |

`<keys>` is a JSON object that identifies the block.
`blockNumber` is always required; pair it with `blockHash` to pin the witness to a specific block.

| Field         | Type              | Required | Description                                                                                                        |
| ------------- | ----------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `blockNumber` | `Quantity` (hex)  | Yes      | Block number, 0x-prefixed lowercase hex (e.g. `"0x7fd"`).                                                          |
| `blockHash`   | `Data` (32 bytes) | No       | 0x-prefixed lowercase hash of the block to fetch the witness for. Pins the requested block identity across reorgs. |

### Lookup modes

As of mega-reth v2.2.1, a number-only lookup resolves the node's local canonical hash before selecting a witness.
**Pass `blockHash` when you need a specific block.**

| Mode                        | Selection                                                                | When to use                                                |
| --------------------------- | ------------------------------------------------------------------------ | ---------------------------------------------------------- |
| `blockNumber` + `blockHash` | Matches the supplied block hash                                          | The caller already knows the block it wants to verify      |
| `blockNumber`               | Resolves the local canonical hash at that height, then matches that hash | The caller wants the node's canonical block at lookup time |

If the canonical hash is unknown, the number-only lookup returns `result: null`, even if stored witnesses exist at that height.
This can happen during resynchronization after an unwind or when the requested height is beyond the local head.
Retry after the node catches up.
When the canonical hash is known, the handler returns its matching witness, or `null` if that witness is unavailable; it does not fall back to the first stored row or an orphaned witness.

{% hint style="info" %}
A number-only lookup follows the node's canonical view, which can change across a reorg.
Supplying `blockHash` pins the requested block identity; it does not guarantee that the block remains canonical.
Hash-keyed and payload-keyed lookups are unchanged by v2.2.1.
For all supported selectors, see the [RPC reference](../dev/rpc/reference/mega_getBlockWitness.md).
{% endhint %}

### Examples

{% tabs %}
{% tab title="Preferred — by block number and hash" %}

```json
[
  {
    "blockNumber": "0x7fd",
    "blockHash": "0x262206173864c1e597ab9fcf2f718f95f942907207f4fed97dda66d272c5d4a6"
  }
]
```

{% endtab %}

{% tab title="By block number (local canonical)" %}

```json
[{ "blockNumber": "0x7fd" }]
```

{% endtab %}
{% endtabs %}

## Response

When a witness is available, `result` is a string of the form `<version>:<base64-payload>`.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "v0:<base64 payload>"
}
```

| Field     | Description                                                                                                                                                                                     |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `version` | Encoding version. Currently `v0`. Bumped if the witness payload format ever changes — clients must check the prefix.                                                                            |
| `payload` | Base64-encoded, Zstd-compressed [bincode](https://docs.rs/bincode/2.0.1/bincode) tuple ([`SaltWitness`](#saltwitness--main-state-trie), [`MptWitness`](#mptwitness--withdrawals-storage-trie)). |

When no matching witness is available, the node returns a successful JSON-RPC response with `result: null`:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": null
}
```

Handle `null` before decoding the payload.
It means the witness is unavailable, not a `-32000` or `-32603` error.
Retry after catch-up for a temporarily unknown canonical hash; missing historical coverage may remain unavailable.

### Errors

| Code     | Cause                                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------------------------ |
| `-32602` | Invalid params — malformed parameters, missing `blockNumber`, unparseable hex, or an invalid parameter combination |
| `-32603` | Internal failure while resolving the canonical hash, reading, or encoding a witness                                |

Do not match a `Witness not found` error message to detect unavailability; check for `result: null`.
The RPC layer in front of the witness service may also return standard JSON-RPC transport codes: `-32700` (parse error), `-32600` (invalid request).

### Historical coverage

Witness availability on the public RPC depends on the network:

| Network | Coverage                                                                                                                                                 |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mainnet | All blocks.                                                                                                                                              |
| Testnet | As of 2026-07-24: block `1000` (a permanent test fixture) and blocks `>= 10325789`. Older testnet witnesses are not guaranteed and cannot be backfilled. |

A request with no available witness returns `result: null`.

### Decoding pipeline

After checking for an RPC error or `result: null`, decode an available response string in this order:

1. Verify the string starts with the literal prefix `v0:` and strip it.
2. Base64-decode the payload (standard alphabet, padded).
3. Zstd-decompress the result.
4. Bincode-deserialize using the **legacy** config (fixed-int encoding, little-endian) into `(SaltWitness, MptWitness)`.

A reference Rust implementation lives in the upstream stateless validator at [`fetch_witness_raw`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-common/src/rpc_client.rs#L978):

```rust
use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use bincode::{config, serde::decode_from_slice};
use salt::SaltWitness;
use stateless_core::withdrawals::MptWitness;
use zstd;

let b64 = encoded.strip_prefix("v0:").ok_or("missing v0 prefix")?;
let compressed = BASE64.decode(b64)?;
let decompressed = zstd::decode_all(compressed.as_slice())?;
let (salt_witness, mpt_witness): (SaltWitness, MptWitness) =
    decode_from_slice(&decompressed, config::legacy())?.0;
```

{% hint style="info" %}
`SaltWitness` is defined in the [`salt`](https://github.com/megaeth-labs/salt) crate; `MptWitness` is defined in the `stateless-core` crate of the [`stateless-validator`](https://github.com/megaeth-labs/stateless-validator) repository.
Add both as Cargo dependencies (via a git or path source) before compiling this snippet.
{% endhint %}

## Witness data structure

The decoded payload is a 2-tuple — one component per state surface the validator must check.
Every type below is given as the upstream Rust definition with its source location, so a third-party decoder in another language can reproduce the byte layout exactly.

### `SaltWitness` — main state trie

Carries the subset of [SALT](https://github.com/megaeth-labs/salt) key-value pairs the block touches, plus a single multi-point IPA proof binding them to the previous block's state root.

Defined at [`salt/src/proof/salt_witness.rs:46`](https://github.com/megaeth-labs/salt/blob/main/salt/src/proof/salt_witness.rs#L46):

```rust
pub struct SaltWitness {
    pub kvs:   BTreeMap<SaltKey, Option<SaltValue>>,
    pub proof: SaltProof,
}
```

| Field   | Description                                                                                                                                                      |
| ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `kvs`   | Witnessed slots. `Some(v)` means the slot is occupied with value `v`; `None` means the slot is proven empty; an absent key is **unknown** (verifier must error). |
| `proof` | IPA multi-point proof + the path commitments needed to authenticate every entry in `kvs` against the state root.                                                 |

A verifier uses the witness as a `StateReader` / `TrieReader`: every state read during block re-execution falls through to `kvs` (existence-proven) or errors (unknown).
The three-state distinction (existing / proven-empty / unknown) is what blocks a malicious witness server from hiding state by omission — see the security model in the upstream `SaltWitness` doc-comment.
For the trie design this witness proves against, see the [SALT README](https://github.com/megaeth-labs/salt#design).

#### `SaltKey`

Defined at [`salt/src/types.rs:198`](https://github.com/megaeth-labs/salt/blob/main/salt/src/types.rs#L198):

```rust
pub struct SaltKey(pub u64);
```

The `u64` packs the SALT trie address into two fields:

| Bits      | Field       | Range          | Meaning                                                                                       |
| --------- | ----------- | -------------- | --------------------------------------------------------------------------------------------- |
| `63..=40` | `bucket_id` | 24 bits (~16M) | Index into the static main trie. The first `NUM_META_BUCKETS = 65_536` buckets hold metadata. |
| `39..=0`  | `slot_id`   | 40 bits (~1T)  | Slot offset inside the bucket's SHI hash table.                                               |

Use `bucket_id = key >> 40` and `slot_id = key & ((1<<40) - 1)` to unpack.
Bincode-legacy serializes `SaltKey` as a fixed 8-byte little-endian `u64`.

#### `SaltValue`

Defined at [`salt/src/types.rs:274`](https://github.com/megaeth-labs/salt/blob/main/salt/src/types.rs#L274):

```rust
pub const MAX_SALT_VALUE_BYTES: usize = 94;

pub struct SaltValue {
    pub data: [u8; MAX_SALT_VALUE_BYTES],  // serialized as a fixed 94-byte array
}
```

`data` holds a length-prefixed key-value blob:

| Offset                           | Size        | Field       |
| -------------------------------- | ----------- | ----------- |
| `0`                              | 1 byte      | `key_len`   |
| `1`                              | 1 byte      | `value_len` |
| `2..2+key_len`                   | `key_len`   | `key`       |
| `2+key_len..2+key_len+value_len` | `value_len` | `value`     |
| `2+key_len+value_len..94`        | remainder   | zero-padded |

Three `SaltValue` flavors share this encoding:

| Kind         | `key_len` | `value_len`              | Used bytes | Notes                                                                                                   |
| ------------ | --------- | ------------------------ | ---------- | ------------------------------------------------------------------------------------------------------- |
| `Account`    | 20        | 40 (EOA) / 72 (contract) | 62 / 94    | Key is the 20-byte address; value is the encoded account body.                                          |
| `Storage`    | 52        | 32                       | 86         | Key is `address(20) ++ storage_slot(32)`; value is the 32-byte slot value.                              |
| `BucketMeta` | 12        | 0                        | 14         | Reserved for the metadata buckets — `BucketMeta` is fully encoded into the 12-byte key, value is empty. |

#### `SaltProof`

Defined at [`salt/src/proof/prover.rs:103`](https://github.com/megaeth-labs/salt/blob/main/salt/src/proof/prover.rs#L103):

```rust
pub struct SaltProof {
    pub parents_commitments: BTreeMap<NodeId, SerdeCommitment>,
    pub proof:               SerdeMultiPointProof,
    pub levels:              FxHashMap<BucketId, u8>,
}
```

| Field                 | Type                                | Description                                                                                                                                                                                                                                                                     |
| --------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `parents_commitments` | `BTreeMap<NodeId, SerdeCommitment>` | Commitment for every trie node on the path from a witnessed bucket up to the root. Lookups by `NodeId = u64` (a flat trie-node index) — the verifier walks these to the root.                                                                                                   |
| `proof`               | `SerdeMultiPointProof`              | The IPA multi-point opening proof over the Banderwagon scalar field. Serialized via `MultiPointProof::to_bytes`; deserialize with `MultiPointProof::from_bytes(&buf, DOMAIN_SIZE)` where `DOMAIN_SIZE = 256` (the IPA polynomial degree, matching SALT's 256-ary trie fan-out). |
| `levels`              | `FxHashMap<BucketId, u8>`           | Number of subtree levels for each bucket present in the proof. Required because the verifier doesn't always know a bucket's capacity from the witness alone.                                                                                                                    |

`SerdeCommitment` wraps a Banderwagon group `Element`; `SerdeMultiPointProof` wraps an `ipa_multipoint::MultiPointProof`.
Both serialize to opaque byte vectors via the IPA crate's encoding.

{% hint style="info" %}
**Map encoding order.** `kvs` and `parents_commitments` are `BTreeMap`, so bincode emits their entries in canonical (sorted) key order — wire output is byte-stable for re-implementors that want to round-trip-compare.
`levels` is an `FxHashMap`, whose iteration order depends on the hasher; do not assume a fixed order when re-encoding.
{% endhint %}

### `MptWitness` — withdrawals storage trie

A small Merkle Patricia Trie witness covering the storage trie of the L2-to-L1 message-passer contract (`0x4200000000000000000000000000000000000016`), so the validator can recompute `withdrawals_root` after applying the block's withdrawal-message writes.

Defined at [`stateless-core/src/withdrawals.rs:49`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/withdrawals.rs#L49):

```rust
pub struct MptWitness {
    pub storage_root: B256,         // 32-byte fixed array
    pub state:        Vec<Bytes>,   // length-prefixed list of RLP-encoded trie nodes
}
```

| Field          | Type         | Description                                                                                                                                             |
| -------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `storage_root` | `B256`       | Pre-state storage root of the L2ToL1MessagePasser contract. Serialized as 32 raw bytes.                                                                 |
| `state`        | `Vec<Bytes>` | RLP-encoded MPT trie nodes that authenticate the storage slots the block's withdrawal writes will touch. Each `Bytes` is a length-prefixed byte string. |

This is intentionally an MPT (not SALT) witness: withdrawals are committed to the standard Ethereum withdrawals MPT root for L1 compatibility, so the slice of state needed to maintain it is proved separately from the SALT-backed account/storage state.

## Example

Fetch the witness for a known block and pipe it through the decode pipeline.
Replace `<BLOCK_NUMBER>` (0x-prefixed lowercase hex) and `<BLOCK_HASH>` with values from `eth_getBlockByNumber`.
The pipeline below assumes `jq` and `zstd` are on `PATH` — install them via `brew install jq zstd` on macOS or `apt install jq zstd` on Debian/Ubuntu.

```bash
set -euo pipefail

response=$(curl -fsS https://mainnet.megaeth.com/rpc \
  -X POST -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "mega_getBlockWitness",
    "params": [{
      "blockNumber": "<BLOCK_NUMBER>",
      "blockHash": "<BLOCK_HASH>"
    }]
  }')

encoded=$(printf '%s' "$response" | jq -er '
  if .error then error(.error.message)
  elif .result == null then error("Witness unavailable; check sync and coverage before retrying")
  else .result end
')

printf '%s' "$encoded" \
  | sed 's/^v0://' \
  | base64 --decode \
  | zstd -d \
  > witness.bincode
```

`witness.bincode` is a Zstd-decompressed bincode tuple — feed it into a Rust deserializer (using the snippet under [Decoding pipeline](#decoding-pipeline)) to obtain `(SaltWitness, MptWitness)`.

## Related pages

- [mega-reth v2.2.1 witness handler](https://github.com/megaeth-labs/mega-reth/blob/v2.2.1/crates/megaeth/rpc/src/witness.rs) — canonical lookup and nullable response behavior.
- [Stateless Validation](stateless-validation.md) — the operator guide for the reference client that consumes this RPC.
- [stateless-validator source](https://github.com/megaeth-labs/stateless-validator) — Rust implementation of the witness fetcher and verifier.
- [SALT](https://github.com/megaeth-labs/salt) — the authenticated key-value store that produces `SaltWitness`.
