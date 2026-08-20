---
name: postgres-indexing-best-practices
description: Postgres indexing best practices for optimised querying and writing efficiency
---

# PostgreSQL Indexes: Comprehensive Reference

> Source: Aaron Francis — Mastering Postgres (Database School)
>
> This document is a reference for developers and AI coding agents working with PostgreSQL schemas. It covers index theory, practical usage, composite strategies, query plan analysis, and common pitfalls. All concepts are PostgreSQL-specific unless noted otherwise.

---

## Table of Contents

1. [Introduction to Indexes](#introduction-to-indexes)
2. [Heaps and CTIDs](#heaps-and-ctids)
3. [B-Tree Overview](#b-tree-overview)
4. [Primary Keys vs. Secondary Indexes](#primary-keys-vs-secondary-indexes)
5. [Primary Key Types](#primary-key-types)
6. [Where to Add Indexes](#where-to-add-indexes)
7. [Index Selectivity](#index-selectivity)
8. [Composite Indexes](#composite-indexes)
9. [Composite Range](#composite-range)
10. [Combining Multiple Indexes](#combining-multiple-indexes)
11. [Covering Indexes](#covering-indexes)
12. [Partial Indexes](#partial-indexes)
13. [Index Ordering](#index-ordering)
14. [Ordering Nulls in Indexes](#ordering-nulls-in-indexes)
15. [Functional Indexes](#functional-indexes)
16. [Duplicate Indexes](#duplicate-indexes)
17. [Hash Indexes](#hash-indexes)
18. [Naming Indexes](#naming-indexes)

---

## Introduction to Indexes

### Core Concept

An index is a **fundamentally separate, discrete data structure** from the table it is associated with. While you define an index on a table, it creates a second data structure optimized for specific operations (lookups, range scans, ordering, etc.).

### Three Things to Know About Every Index

1. **Indexes are separate data structures.** The most common structure is a **B-tree**. Others include GiST, GIN, SP-GiST, and Hash — each optimized for different use cases.

2. **Indexes maintain a copy of part of your data.** If you index `last_name`, all last name values are copied into the index in a traversable order. This is why excessive indexes slow writes — every `INSERT`, `UPDATE`, or `DELETE` must update every relevant index.

3. **Every index contains a pointer back to the table.** After traversing the index to find matching entries, PostgreSQL follows the pointer to fetch the full row from the table (the heap).

### PostgreSQL-Specific Behavior

In most databases, index entries point to the **primary key**, which is then used to locate the row. In PostgreSQL, index entries point directly to the **physical location** of the row on disk (the CTID). This is because PostgreSQL has no clustered index — all data lives in a heap.

### Key Takeaway

> Indexes trade write performance for read performance. Every index you add makes writes slower (more structures to maintain) but can make specific reads dramatically faster. Have as many indexes as you need, but as few as you can get away with.

---

## Heaps and CTIDs

### How PostgreSQL Stores Data

Under the hood, PostgreSQL stores table data in **pages** — equal-sized blocks of data. Within each page, rows occupy numbered positions. A row's location is identified by its **CTID** (Current Tuple ID), which is a `(page, position)` pair.

```sql
-- You can see CTIDs (they are hidden system columns)
SELECT ctid, * FROM users LIMIT 5;
-- Returns: (0,1), (0,2), (0,3), etc.
```

### The Heap

The underlying storage structure is a **heap** — an unordered pile. Rows are written wherever there is free space. This makes inserts fast (just find blank space and write) but means the data has no inherent order.

### CTIDs Are Volatile — Never Rely on Them

```sql
-- You CAN look up by CTID, but you should NEVER do this
SELECT * FROM users WHERE ctid = '(0,2)';
```

CTIDs **change** when:

- A row is updated and moved to a different page (e.g., variable-length data grows too large for the current page)
- The database is vacuumed (`VACUUM` rearranges rows and reclaims space)

They are not primary keys, not stable, and not deterministic.

### Connection to Indexes

Every index stores the **CTID** of each indexed row. This is the actual pointer that gets you from the index back to the heap to retrieve the full row data.

> When we say "every index contains a pointer back to the table," that pointer is the CTID.

---

## B-Tree Overview

### Structure

A B-tree is a balanced tree data structure. It has:

- **Root node**: The top of the tree, containing boundary values
- **Interior nodes**: Intermediate levels that guide traversal
- **Leaf nodes**: The bottom level, containing the actual indexed values and CTIDs (pointers back to the table)

The leaf nodes contain all indexed values **in sorted order** from left to right.

### How a B-Tree Lookup Works

Given a query `SELECT * FROM users WHERE name = 'Jennifer'`:

1. Start at the **root node** (e.g., contains `Isaac` and `Steve`)
2. Compare: `Jennifer` falls between `Isaac` and `Steve` — follow the middle path
3. Reach an **interior node** (e.g., contains `Simon`)
4. Compare: `Jennifer` < `Simon` — follow the left path
5. Arrive at a **leaf node** — scan for `Jennifer`, find it, grab the CTID
6. Use the CTID to fetch the full row from the heap

### Why Indexes Matter

- **With an index**: Traverse a few tree nodes, then fetch the exact row. O(log n) complexity.
- **Without an index**: Full **sequential table scan** — brute-force through every row. O(n) complexity.

For 10 rows, a table scan might actually be faster (no overhead of index traversal + heap lookup). For 10 billion rows, you absolutely want index traversal.

### Supported Operations

B-tree indexes support:

- Strict equality (`=`)
- Range queries (`<`, `>`, `<=`, `>=`, `BETWEEN`)
- Ordering (`ORDER BY`)
- Grouping (`GROUP BY`)
- Sorting (reading the index front-to-back or back-to-front)

---

## Primary Keys vs. Secondary Indexes

### PostgreSQL: Every Index Is a Secondary Index

In MySQL, the primary key defines a **clustered index** — the table data itself is stored as a B-tree ordered by the primary key. Every other index is a "secondary index" that points to the primary key.

In PostgreSQL, table data is stored in a **heap** (unordered). There is no clustered index. Therefore, **every index — including the primary key index — is a secondary index**. Every index lookup requires traversing the index and then hopping to the heap.

### What a Primary Key Gives You

A primary key is a secondary index with extras:

- Enforces **uniqueness**
- Enforces **NOT NULL**
- Automatically **creates the underlying B-tree index**
- Only **one** primary key per table

You can have as many additional secondary indexes as you want. Those can also be unique and/or not null — the distinction is that the primary key is the canonical row identifier.

### Exception: Covering Indexes

The one caveat to "every lookup requires a heap visit" is **covering indexes** (discussed later), where all data needed by the query exists in the index itself.

---

## Primary Key Types

### Recommendation: Use `bigint` (98% of Cases)

```sql
CREATE TABLE users (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);
```

**Why `bigint` over `integer`?**

- You do not want to run out of IDs at the peak of your success (this happened to Basecamp)
- The storage trade-off (8 bytes vs. 4 bytes) is worth the peace of mind
- Auto-incrementing values fit naturally with B-tree structure — always appended to the right, keeping the tree balanced

### When to Use UUIDs/ULIDs

UUIDs are appropriate when you need to **generate IDs without database coordination** — e.g., optimistic UI where the client needs an ID before the server round-trip.

**If using UUIDs, use a time-ordered variant:**

| Variant                  | Behavior                                 | Recommendation                                                          |
| ------------------------ | ---------------------------------------- | ----------------------------------------------------------------------- |
| `gen_random_uuid()` (v4) | Fully random                             | **Avoid as PK** — random insertion causes B-tree splits and rebalancing |
| UUID v7                  | Time-ordered prefix                      | **Preferred** — behaves like auto-increment for B-tree purposes         |
| ULID                     | Time-ordered, lexicographically sortable | **Preferred** — same benefits as v7                                     |

**Drawbacks of random UUIDs as primary keys:**

- Larger size (16 bytes vs. 8 bytes for bigint)
- Random insertion causes B-tree fragmentation and rebalancing (less severe in PostgreSQL than MySQL since PostgreSQL uses a heap, but still a penalty)

### Handling Public-Facing IDs

If you don't want to expose auto-incrementing integers (which leak information like total user count):

```sql
CREATE TABLE users (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id text NOT NULL UNIQUE DEFAULT generate_nano_id()  -- or similar
);
```

Use a **secondary key** (e.g., nano ID) for URLs and APIs while keeping the performant bigint as the actual primary key internally. This gives you the best of both worlds.

---

## Where to Add Indexes

### The Fundamental Rule

> You cannot derive good indexes from your schema alone. You must look at your **access patterns** — how you query the data.

### Common Anti-Patterns

**"Index every column"** — Bad idea:

- Duplicates your data storage
- Slows all writes (every index must be maintained)
- Read performance won't be as good as a well-designed composite index

**"Index everything in the WHERE clause"** — Closer, but incomplete. You must consider the **entire query**:

- `WHERE` — filtering conditions
- `ORDER BY` — sort requirements
- `GROUP BY` — aggregation keys
- `JOIN` — join conditions
- `SELECT` — columns retrieved (for covering index potential)

### Proving Index Usage with EXPLAIN

```sql
-- Without index: Sequential scan (bad for large tables)
EXPLAIN SELECT * FROM users WHERE birthday = '1989-02-14';
-- "Seq Scan on users" with parallel workers

-- Create the index
CREATE INDEX bday_on_users ON users USING btree (birthday);

-- With index: Index scan (good)
EXPLAIN SELECT * FROM users WHERE birthday = '1989-02-14';
-- "Bitmap Index Scan on bday"
```

### What B-Tree Indexes Help With

| Operation                       | Example                                                | Uses Index?                                |
| ------------------------------- | ------------------------------------------------------ | ------------------------------------------ |
| Strict equality                 | `WHERE birthday = '1989-02-14'`                        | Yes                                        |
| Bounded range                   | `WHERE birthday BETWEEN '1989-01-01' AND '1989-12-31'` | Yes                                        |
| Unbounded range (selective)     | `WHERE birthday < '1989-02-14'`                        | Yes (if selective enough)                  |
| Unbounded range (non-selective) | `WHERE birthday > '1989-02-14'`                        | No — too many rows, falls back to seq scan |
| ORDER BY                        | `ORDER BY birthday`                                    | Yes (values already in order in index)     |
| GROUP BY                        | `GROUP BY birthday`                                    | Yes                                        |

### Index-Assisted vs. Unassisted Sorts

- **With index**: Values are already sorted. PostgreSQL reads the index front-to-back (or back-to-front) and fetches rows in that order. Fast.
- **Without index**: PostgreSQL must read the entire heap, then sort all rows in memory. Expensive.

If you have a frequently used `ORDER BY`, try to get it index-assisted.

---

## Index Selectivity

### Cardinality vs. Selectivity

- **Cardinality**: The number of distinct values in a column
- **Selectivity**: The ratio of distinct values to total rows (closer to 1.0 = more selective = better for indexing)

```sql
-- Perfect selectivity (primary key): 1.0
SELECT COUNT(DISTINCT id)::decimal / COUNT(*) FROM users;
-- 1.000000

-- Good selectivity (birthday): ~0.011
SELECT COUNT(DISTINCT birthday)::decimal / COUNT(*) FROM users;
-- 0.0111...

-- Poor selectivity (boolean): ~0.000002
SELECT COUNT(DISTINCT is_pro)::decimal / COUNT(*) FROM users;
-- 0.0000020...
```

### The Selectivity Rule

> You want your index to help you get down to just a few rows as quickly as possible. The closer to 1.0, the better.

### Skewed Data Distribution Changes Everything

A column with poor overall selectivity can still be an excellent index candidate if the data is skewed:

```sql
-- is_pro has only 2 distinct values (terrible overall selectivity)
-- But only 44,000 out of ~1,000,000 are pro users

-- Selectivity for is_pro = TRUE queries:
SELECT 44000::decimal / 1000000;
-- 0.044 — quite selective for this specific query!
```

If your common query is `WHERE is_pro = TRUE`, an index on `is_pro` is very useful despite the column having only 2 possible values.

### When PostgreSQL Skips Your Index

PostgreSQL maintains internal **statistics** about data distribution. If the planner determines that an index would return too many rows (e.g., more than ~50% of the table), it skips the index and does a sequential scan instead.

```sql
-- Returns 417,000 rows — uses the index
EXPLAIN SELECT * FROM users WHERE birthday < '1989-02-14';

-- Returns 572,000 rows — skips the index, does seq scan
EXPLAIN SELECT * FROM users WHERE birthday > '1989-02-14';
```

### Updating Statistics

PostgreSQL doesn't run queries in real-time to decide index usage — it references cached statistics. These are updated by:

- **Autovacuum** (automatic)
- **`ANALYZE`** (manual) — run this after massive bulk operations

```sql
ANALYZE users;  -- Update statistics for the users table
```

---

## Composite Indexes

### The Power of Multi-Column Indexes

A single index over multiple columns outperforms multiple single-column indexes for most query patterns.

```sql
CREATE INDEX multi ON users USING btree (first_name, last_name, birthday);
```

### The Golden Rules

> **Left to right, no skipping, stops at the first range.**

These three rules govern how a composite B-tree index is traversed:

#### Rule 1: Left to Right

The index can only be used starting from the **leftmost column** in the index definition.

```sql
-- Index: (first_name, last_name, birthday)

-- USES the index (starts from leftmost column)
WHERE first_name = 'Aaron'

-- DOES NOT use the index (skips first_name)
WHERE last_name = 'Francis'
```

#### Rule 2: No Skipping

You should not skip columns in the middle of the index.

```sql
-- USES the index efficiently (no columns skipped)
WHERE first_name = 'Aaron' AND last_name = 'Francis'

-- PARTIALLY uses the index (skips last_name)
-- PostgreSQL optimization: traverses to 'Aaron', then SCANS for the birthday
WHERE first_name = 'Aaron' AND birthday = '1989-02-14'
```

When you skip a column, PostgreSQL can still use the index but degrades from **direct B-tree traversal** to an **index scan** through the matching prefix entries. This is still better than a table scan, but less efficient.

#### Rule 3: Stops at the First Range

Once a range condition (`<`, `>`, `BETWEEN`, etc.) is encountered, the index cannot do direct traversal on subsequent columns — it switches to scanning.

```sql
-- Index: (first_name, last_name, birthday)

-- Direct traversal for first_name and last_name, then scan for birthday range
WHERE first_name = 'Aaron' AND last_name = 'Francis' AND birthday < '1989-12-31'
-- This is optimal: equalities first, range last

-- Direct traversal only for first_name, then scan for everything after
WHERE first_name = 'Aaron' AND last_name > 'F' AND birthday = '1989-02-14'
-- Less optimal: range on last_name forces scanning for birthday too
```

### Query Condition Order Doesn't Matter

The order you write conditions in the `WHERE` clause is irrelevant — PostgreSQL's planner rearranges them. What matters is the **order of columns in the index definition**.

```sql
-- These are equivalent — PostgreSQL figures it out
WHERE first_name = 'Aaron' AND last_name = 'Francis'
WHERE last_name = 'Francis' AND first_name = 'Aaron'
```

### Efficiency Hierarchy

1. **Direct B-tree traversal** (equality on leftmost prefix) — Best
2. **Index scan** (traversal to a prefix, then scan remaining entries) — Good
3. **Sequential table scan** (no index used) — Worst

### Design Principle

> Put your most commonly queried equality conditions on the **left** side of the index. Put less common conditions and range conditions on the **right**.

---

## Composite Range

### Stops at the First Range — Demonstrated

Given two indexes:

```sql
CREATE INDEX first_last_birth ON users (first_name, last_name, birthday);
CREATE INDEX first_birth_last ON users (first_name, birthday, last_name);
```

And the query:

```sql
SELECT * FROM users
WHERE first_name = 'Aaron'
  AND last_name = 'Francis'
  AND birthday < '1989-12-31';
```

PostgreSQL chooses `first_last_birth` because:

1. Direct traversal to `Aaron` + `Francis` (both equality)
2. Then scan from the first matching entry forward until `birthday >= '1989-12-31'`

If it used `first_birth_last`, it would:

1. Direct traversal to `Aaron`
2. Hit the range on `birthday` immediately — must scan all Aarons with birthday < '1989-12-31'
3. The `last_name = 'Francis'` filter happens **during the scan**, not via traversal

### Rule of Thumb

> **Equality conditions left, range conditions right.** This maximizes the portion of the index that can be traversed directly.

In other databases, the index stops being used entirely after a range or skipped column. PostgreSQL is more forgiving — it continues scanning the index — but direct traversal is always faster than scanning.

---

## Combining Multiple Indexes

### Bitmap AND / Bitmap OR

When no single composite index satisfies a query, PostgreSQL can scan **multiple separate indexes** and combine results using bitmap operations:

```sql
-- Two separate indexes
CREATE INDEX first_on_first_name ON users (first_name);
CREATE INDEX last_on_last_name ON users (last_name);

-- AND: PostgreSQL scans both indexes, combines with Bitmap AND
EXPLAIN SELECT * FROM users
WHERE first_name = 'Aaron' AND last_name = 'Francis';
-- "BitmapAnd" → scan first index, scan second index, intersect results

-- OR: PostgreSQL scans both indexes, combines with Bitmap OR
EXPLAIN SELECT * FROM users
WHERE first_name = 'Aaron' OR last_name = 'Francis';
-- "BitmapOr" → scan first index, scan second index, union results
```

### Composite Index vs. Bitmap Combine

For **AND conditions**: A single composite index is faster than scanning two indexes and combining.

```sql
CREATE INDEX first_last ON users (first_name, last_name);

-- PostgreSQL will prefer the composite index over bitmap combining
EXPLAIN SELECT * FROM users
WHERE first_name = 'Aaron' AND last_name = 'Francis';
-- Uses first_last directly
```

For **OR conditions**: Two separate indexes with Bitmap OR can actually be **more performant** than a single composite index, because B-trees are not structured to handle OR efficiently.

### Guidance

| Condition Type          | Best Strategy                                       |
| ----------------------- | --------------------------------------------------- |
| `col1 = X AND col2 = Y` | Single composite index `(col1, col2)`               |
| `col1 = X OR col2 = Y`  | Two separate indexes, let PostgreSQL Bitmap OR them |
| Mixed patterns          | Analyze your most common access patterns and test   |

> Always test with your own data, schema, and query patterns. Use `EXPLAIN` to verify which strategy PostgreSQL chooses.

---

## Covering Indexes

### What Is a Covering Index?

A **covering index** is not a special type of index — it is a regular index in a special situation where **everything the query needs** (SELECT columns, WHERE filters, ORDER BY, GROUP BY) is satisfied from the index alone.

When this happens, PostgreSQL performs an **INDEX ONLY SCAN** — it never visits the heap table.

```sql
CREATE INDEX ON users (first_name);

-- INDEX ONLY SCAN: only needs first_name, which is in the index
EXPLAIN SELECT first_name FROM users WHERE first_name = 'Aaron';

-- Regular INDEX SCAN: needs *, must visit heap for other columns
EXPLAIN SELECT * FROM users WHERE first_name = 'Aaron';
```

### Multi-Column Covering Indexes

```sql
CREATE INDEX ON users (first_name, last_name);

-- INDEX ONLY SCAN: both columns are in the index
EXPLAIN SELECT first_name, last_name FROM users
WHERE first_name = 'Aaron'
ORDER BY last_name;
```

### The INCLUDE Clause

You can attach extra columns to the index **without including them in the B-tree structure**. They are stored in the leaf nodes as extra payload:

```sql
CREATE INDEX multi ON users (first_name, last_name) INCLUDE (id);

-- INDEX ONLY SCAN: id is available in the leaf nodes
EXPLAIN SELECT first_name, last_name, id FROM users
WHERE first_name = 'Aaron';
```

`INCLUDE` columns:

- Are NOT part of the B-tree traversal/ordering
- Are stored alongside leaf node entries
- Enable covering index scenarios without bloating the B-tree structure
- Cannot be used for filtering, ordering, or grouping — only for retrieval

### Caveats and Pitfalls

1. **Don't bloat your index.** Including large columns (text, JSON) defeats the purpose. You're essentially recreating the table inside the index.

2. **Visibility map overhead.** PostgreSQL uses MVCC for concurrency. Even with a covering index, PostgreSQL must check a **visibility map** to verify that rows are visible to the current transaction. For frequently updated tables, this check may force a heap visit anyway, negating the covering index benefit.

3. **SELECT only what you need.** `SELECT *` will almost never hit a covering index. Selecting only the columns you need opens the door to index-only scans.

### When Covering Indexes Shine

- Tables that are **read-heavy and rarely updated**
- Very hot query paths where you SELECT a small, known set of columns
- Dashboards, analytics queries, or reporting on a few specific columns

---

## Partial Indexes

### Concept

A partial index indexes only a **subset of rows** matching a predicate. This keeps the index small, fast, and cheap to maintain.

```sql
-- Only index emails of pro users
CREATE INDEX email_pro ON users (email) WHERE is_pro = TRUE;
```

### Usage Requirements

The query must include the index predicate for PostgreSQL to use it:

```sql
-- USES the partial index (predicate matches)
EXPLAIN SELECT * FROM users
WHERE email = 'aaron@example.com' AND is_pro = TRUE;

-- DOES NOT use the partial index (predicate missing)
EXPLAIN SELECT * FROM users
WHERE email = 'aaron@example.com';
```

### Benefits

- **Smaller index** — only contains matching rows (e.g., 44,000 pro users vs. 1,000,000 total)
- **Faster reads** — less data to traverse
- **Faster writes** — most inserts/updates don't touch the index (if they don't match the predicate)
- **Less storage** — dramatically smaller on disk

### Partial Unique Indexes

Incredibly powerful for business logic enforcement:

```sql
-- Unique email only among active (non-deleted) users
CREATE UNIQUE INDEX unique_active_email ON users (email)
WHERE deleted_at IS NULL;
```

This allows:

- Multiple deleted accounts with the same email
- Only one active account per email
- Re-signup after account deletion

### Use Cases

- **Soft deletes**: Unique constraints only on active records
- **Status-based constraints**: Unique order number only for confirmed orders
- **High-skew columns**: Index only the rare, interesting values (e.g., `WHERE status = 'failed'`)

### Pitfall

You must always include the predicate in your queries. If your application code doesn't include `AND is_pro = TRUE` (or whatever the predicate is), the partial index won't be used.

---

## Index Ordering

### Default Behavior

Indexes are created in **ascending** order by default. PostgreSQL can read a B-tree:

- **Forward** (ascending) — normal index scan
- **Backward** (descending) — backward index scan

```sql
CREATE INDEX created_at_idx ON users (created_at);

-- Forward scan
EXPLAIN SELECT * FROM users ORDER BY created_at ASC LIMIT 10;
-- "Index Scan using created_at_idx"

-- Backward scan (still uses the index)
EXPLAIN SELECT * FROM users ORDER BY created_at DESC LIMIT 10;
-- "Index Scan Backward using created_at_idx"
```

### The Problem with Composite Indexes and Mixed Directions

For a single-column index, direction doesn't matter — PostgreSQL reads forward or backward. But for **composite indexes with mixed sort directions**, you need to match:

```sql
-- Index created as: birthday ASC, created_at ASC
CREATE INDEX bday_created ON users (birthday, created_at);

-- Both ASC: uses index (forward scan)
ORDER BY birthday ASC, created_at ASC     -- OK

-- Both DESC: uses index (backward scan)
ORDER BY birthday DESC, created_at DESC   -- OK

-- Mixed directions: CANNOT use index efficiently
ORDER BY birthday DESC, created_at ASC    -- Incremental sort required
ORDER BY birthday ASC, created_at DESC    -- Incremental sort required
```

### Solution: Declare Index with Matching Directions

```sql
CREATE INDEX bday_created ON users (birthday ASC, created_at DESC);

-- Now these work:
ORDER BY birthday ASC, created_at DESC    -- Forward scan
ORDER BY birthday DESC, created_at ASC    -- Backward scan (both flipped)

-- These still don't work:
ORDER BY birthday ASC, created_at ASC     -- Incremental sort
ORDER BY birthday DESC, created_at DESC   -- Incremental sort
```

### Rule

> You can flip **all** directions (forward scan becomes backward scan), but you cannot flip just **one** column's direction in a composite index.

---

## Ordering Nulls in Indexes

### Default Behavior

PostgreSQL treats NULLs as **larger than any other value**:

- `ASC` order: NULLs appear **last** (default)
- `DESC` order: NULLs appear **first** (default)

### Controlling NULL Position

```sql
-- Override default: NULLs first in ascending order
SELECT * FROM users ORDER BY birthday ASC NULLS FIRST LIMIT 10;

-- Override default: NULLs last in descending order
SELECT * FROM users ORDER BY birthday DESC NULLS LAST LIMIT 10;
```

### Creating Indexes That Match

If you frequently use `NULLS FIRST` or `NULLS LAST` in queries, create an index that matches:

```sql
CREATE INDEX birthday_nulls_first ON users (birthday ASC NULLS FIRST);

-- USES the index
EXPLAIN SELECT * FROM users ORDER BY birthday ASC NULLS FIRST LIMIT 10;

-- DOES NOT use the index (wrong null ordering)
EXPLAIN SELECT * FROM users ORDER BY birthday ASC NULLS LAST LIMIT 10;
```

The same forward/backward scan rules apply: you can flip **both** the sort direction and the null ordering together, but not independently.

---

## Functional Indexes

### Concept

Instead of indexing a column's raw value, you can index the **result of a function or expression**. The function is evaluated on every insert/update, and the result is stored in the B-tree.

```sql
-- Index the domain extracted from email
CREATE INDEX domain_idx ON users ((split_part(email, '@', 2)));

-- Note: the double parentheses are required to signal an expression (not a column)
```

### Usage Requirements

The query must use the **exact same function expression** for the index to be used:

```sql
-- USES the index (expression matches)
EXPLAIN SELECT * FROM users
WHERE split_part(email, '@', 2) = 'beer.com';

-- DOES NOT use the index (different expression)
EXPLAIN SELECT * FROM users
WHERE email LIKE '%@beer.com';
```

### Case-Insensitive Indexing

```sql
CREATE INDEX email_lower ON users ((lower(email)));

-- USES the index
SELECT * FROM users WHERE lower(email) = 'aaron.francis@example.com';

-- DOES NOT use the index (bare column, not wrapped in lower())
SELECT * FROM users WHERE email = 'aaron.francis@example.com';
```

When using `lower()` for case-insensitive search, always `lower()` the user input as well, or you'll compare mixed-case input against lowercase indexed values and get no results.

### Use Cases

- **Domain extraction** from email addresses
- **Case-insensitive lookups** via `lower()` or `upper()`
- **JSON key extraction** (indexing specific keys from a JSONB column)
- **Date part extraction** (e.g., `EXTRACT(YEAR FROM created_at)`)
- **Computed values** you frequently filter on

### Advantage: No Application Code Changes

Functional indexes are entirely database-side. You can add them to speed up queries generated by ORMs, libraries, or external tools without changing application code — as long as the query already uses the matching function.

---

## Duplicate Indexes

### Obvious Duplicates

Two indexes with identical column lists and parameters. These are wasteful — drop one.

### Hidden Duplicates (Shared Left-Most Prefix)

A more subtle form of duplication:

```sql
-- Index 1: created first
CREATE INDEX email_idx ON users (email);

-- Index 2: created later for new requirements
CREATE INDEX email_ispro_idx ON users (email, is_pro);
```

These share the same **left-most prefix** (`email`). For any query that only filters on `email`, both indexes work identically. The composite index (`email, is_pro`) can satisfy all queries that the single-column index can, **plus** queries on both columns.

```sql
-- Both indexes can satisfy this, but PostgreSQL prefers the smaller one
SELECT * FROM users WHERE email = 'aaron@example.com';

-- Only the composite index can satisfy this
SELECT * FROM users WHERE email = 'aaron@example.com' AND is_pro = TRUE;
```

### Rule

> If index A's columns are a prefix of index B's columns, index A is redundant. Drop it. Index B handles everything A does, plus more.

The exception: if index A is significantly smaller and the queries it serves are extremely hot, you might keep it for marginal performance gains. But this is rare.

### How to Detect

```sql
-- List all indexes on a table
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'users';
```

Look for indexes where one's column list is a prefix of another's.

---

## Hash Indexes

### When to Use

Hash indexes are useful **only for strict equality lookups** (`=`). They cannot be used for:

- Range queries (`<`, `>`, `BETWEEN`)
- Ordering (`ORDER BY`)
- Pattern matching (`LIKE`, `ILIKE`)
- Partial matches

### Why They Exist

The value is run through a hashing function, producing a fixed-size hash. The semantic meaning of the original value is lost — only equality comparisons work.

**Benefits:**

- **Constant-size entries** — even massive text/URL values produce small, uniform hashes
- **Faster than B-tree for strict equality** — different internal structure optimized for hash lookups
- **Compact index** — especially for large values

```sql
-- Create both for comparison
CREATE INDEX email_btree ON users USING btree (email);
CREATE INDEX email_hash ON users USING hash (email);

-- Strict equality: PostgreSQL prefers the hash index
EXPLAIN SELECT * FROM users WHERE email = 'aaron@example.com';
-- Uses email_hash

-- Range: falls back to B-tree
EXPLAIN SELECT * FROM users WHERE email < 'b';
-- Uses email_btree

-- LIKE: neither hash nor B-tree helps here
EXPLAIN SELECT * FROM users WHERE email LIKE 'aaron%';
-- Seq Scan
```

### Good Candidates for Hash Indexes

- URLs (can be very long)
- Email addresses (strict equality lookups for login)
- API tokens / session keys
- Any large value where you only ever do `WHERE col = 'exact_value'`

### Historical Warning

Prior to PostgreSQL 10, hash indexes were **dangerous** — they weren't written to the WAL (write-ahead log), so they didn't replicate and could cause crashes. This has been fully resolved since PostgreSQL 10. Safe to use on PostgreSQL 10+.

---

## Naming Indexes

### The Problem

Index names are **unique within a schema** (not just within a table). Two indexes on different tables cannot share the same name in the same schema.

### Recommended Pattern

```
{table_name}_{column(s)}_{type}
```

Examples:

```sql
CREATE INDEX users_email_idx ON users (email);
CREATE INDEX users_first_last_idx ON users (first_name, last_name);
CREATE UNIQUE INDEX users_email_uniq ON users (email);
CREATE INDEX orders_status_partial_idx ON orders (status) WHERE status = 'pending';
```

### Types

| Suffix   | Meaning                              |
| -------- | ------------------------------------ |
| `_idx`   | Regular index                        |
| `_uniq`  | Unique index                         |
| `_pkey`  | Primary key (usually auto-generated) |
| `_check` | Check constraint                     |
| `_hash`  | Hash index                           |

### Notes

- Most ORMs (Drizzle, Prisma, etc.) generate their own index names automatically — these are usually fine
- Prefix with table name to avoid collisions across tables
- Be consistent within your project/team

---

## Quick Reference: Decision Guide

### Should I Add an Index?

```
1. What are my most common queries? (check access patterns)
2. Which columns appear in WHERE, ORDER BY, GROUP BY, JOIN?
3. Is the column selective enough? (check cardinality/selectivity)
4. Is the data skewed? (a low-selectivity column might still be useful for specific values)
5. Am I willing to pay the write penalty? (every index slows writes)
```

### What Type of Index?

```
Need strict equality only?           → Consider Hash index
Need equality + range + ordering?    → B-tree (default, most common)
Need full-text search?               → GIN index
Need geometric/range operations?     → GiST index
Need to index JSONB containment?     → GIN index
```

### Composite Index Column Order

```
1. Most frequently queried equality conditions → leftmost
2. Less frequently queried equality conditions → middle
3. Range conditions                            → rightmost
4. Consider ORDER BY columns as part of the index
```

### Checking If an Index Is Being Used

```sql
-- Basic: does it use my index?
EXPLAIN SELECT ...;

-- Detailed: actual execution time and row counts
EXPLAIN ANALYZE SELECT ...;

-- Look for:
--   "Index Scan"        → good, using index
--   "Index Only Scan"   → best, covering index
--   "Bitmap Index Scan" → good, using index with bitmap
--   "Seq Scan"          → no index used (may be fine for small tables)

-- Find unused indexes (via pg_stat_user_indexes)
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY relname, indexrelname;
```

### Common Pitfalls

| Pitfall                                      | Why It's Bad                                     | Fix                                            |
| -------------------------------------------- | ------------------------------------------------ | ---------------------------------------------- |
| Indexing every column                        | Doubles storage, slows all writes                | Index based on access patterns                 |
| Random UUID primary keys (v4)                | B-tree fragmentation from random inserts         | Use UUID v7, ULID, or bigint                   |
| `SELECT *` everywhere                        | Prevents covering index optimizations            | Select only needed columns                     |
| Missing predicate for partial index          | Index won't be used                              | Always include the WHERE predicate in queries  |
| Wrong function in query vs. functional index | Index won't be used                              | Use the exact same expression                  |
| Duplicate indexes (shared left-most prefix)  | Wasted storage and write overhead                | Drop the redundant shorter index               |
| Not running ANALYZE after bulk operations    | Planner uses stale statistics, makes bad choices | Run `ANALYZE tablename;`                       |
| Mixed sort directions without matching index | Falls back to incremental sort                   | Create index with matching ASC/DESC per column |
| Over-including columns in INCLUDE clause     | Bloated index, defeats purpose                   | Only include small, frequently needed columns  |
| Ignoring write performance impact            | Slow inserts/updates/deletes                     | Balance read optimization with write cost      |
