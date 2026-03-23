# Database Choices for Hello World Sinatra App

## Current State

The app uses **in-memory Ruby arrays** (`$todos`, `$next_id`) for storage. Data is lost on every server restart. The data model is simple: todo items with `id`, `text`, `done`, and `created_at` fields.

---

## Option 1: SQLite (Recommended for this project)

**What**: File-based relational database, no separate server process needed.

**Ruby gems**: `sqlite3` + `sequel` (or `activerecord`)

**Pros**:
- Zero configuration — just a file on disk
- No separate database server to install or manage
- Perfect for small apps and prototypes
- ACID-compliant with full SQL support
- Extremely fast for read-heavy workloads
- Easy to back up (copy a single file)

**Cons**:
- Single-writer concurrency (one write at a time)
- Not suitable for high write-throughput or multi-server deployments
- No built-in user/role access control

**Best for**: Small-to-medium apps, prototypes, single-server deployments, dev/test environments.

**Example integration**:
```ruby
# Gemfile
gem 'sqlite3'
gem 'sequel'

# app.rb
require 'sequel'
DB = Sequel.connect('sqlite://todos.db')

DB.create_table? :todos do
  primary_key :id
  String :text, null: false
  TrueClass :done, default: false
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
end
```

---

## Option 2: PostgreSQL

**What**: Full-featured, open-source relational database server.

**Ruby gems**: `pg` + `sequel` (or `activerecord`)

**Pros**:
- Robust concurrency handling (MVCC)
- Advanced features: JSONB columns, full-text search, arrays, CTEs
- Excellent data integrity and reliability
- Scales well for production workloads
- Strong ecosystem and community support
- Great extension system (PostGIS, pg_trgm, etc.)

**Cons**:
- Requires a separate server process
- More complex setup and administration
- Heavier resource usage than SQLite
- Overkill for a simple todo app

**Best for**: Production web applications, complex queries, multi-server deployments, apps that need strong data integrity.

---

## Option 3: MySQL / MariaDB

**What**: Popular open-source relational database server.

**Ruby gems**: `mysql2` + `sequel` (or `activerecord`)

**Pros**:
- Widely deployed and well-understood
- Good read performance, especially with InnoDB
- Large hosting/tooling ecosystem
- MariaDB is a fully compatible drop-in replacement

**Cons**:
- Requires a separate server process
- Fewer advanced features than PostgreSQL
- Historically weaker data integrity defaults (though improved in recent versions)
- Less capable JSON support than PostgreSQL

**Best for**: Teams already familiar with MySQL, WordPress-adjacent stacks, legacy integrations.

---

## Option 4: Redis

**What**: In-memory key-value store with optional persistence.

**Ruby gems**: `redis`

**Pros**:
- Extremely fast (in-memory)
- Simple key-value and data structure operations
- Built-in pub/sub, expiration, and atomic operations
- Optional disk persistence (RDB snapshots, AOF)

**Cons**:
- Not a traditional relational database — no SQL, no joins
- Data size limited by available RAM
- Persistence is secondary; primarily an in-memory store
- Poor fit for complex querying

**Best for**: Caching, session storage, real-time leaderboards, queues. Not ideal as a primary database for structured data.

---

## Option 5: MongoDB

**What**: Document-oriented NoSQL database.

**Ruby gems**: `mongoid` or `mongo`

**Pros**:
- Flexible schema — store JSON-like documents directly
- Easy to get started with simple CRUD
- Horizontal scaling via sharding
- Good for rapidly evolving schemas

**Cons**:
- No joins (must denormalize or use `$lookup`)
- Weaker ACID guarantees (improved in v4+, but still different from RDBMS)
- Higher memory usage
- Schema flexibility can lead to inconsistent data over time

**Best for**: Apps with highly variable document structures, content management, event logging.

---

## Recommendation

**For this project: SQLite with Sequel ORM.**

Rationale:
1. The app is a simple single-server todo list — SQLite handles this perfectly
2. Zero infrastructure overhead (no database server to manage)
3. Sequel ORM keeps the code clean and makes it easy to migrate to PostgreSQL later if needed
4. Adds data persistence with minimal changes to the existing codebase
5. The todo data model is simple and relational

If the app later grows to need multi-server deployment or heavier concurrency, migrating from SQLite to PostgreSQL via Sequel is straightforward — just change the connection string.

---

## ORM Comparison (for Ruby/Sinatra)

| ORM | Complexity | Best With | Notes |
|-----|-----------|-----------|-------|
| **Sequel** | Low | Sinatra | Lightweight, flexible, great docs. Recommended for Sinatra apps. |
| **ActiveRecord** | Medium | Rails (works with Sinatra) | Full-featured, heavier. Brings Rails conventions. |
| **ROM (Ruby Object Mapper)** | High | Complex domains | Very flexible but steeper learning curve. |
| **Raw SQL** | Lowest | Simple apps | No abstraction overhead, but manual query building. |
