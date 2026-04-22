# SimpleX Chat - Agent Development Guide

## Project Overview

SimpleX Chat is a **privacy-first messaging platform written in Haskell** using Cabal. The codebase implements a decentralized chat protocol with **no user identifiers**, supporting mobile apps, desktop clients, and bot APIs. Core architecture uses client-server messaging queues (SMP protocol) with double-ratchet encryption.

**Key Components:**
- **Core Library** (`src/Simplex/Chat/`) - Protocol, message handling, database abstractions
- **Executables** - CLI (`simplex-chat`), bots (`simplex-bot`, `simplex-bot-advanced`, `simplex-broadcast-bot`), directory service
- **Apps** - iOS, Android, multiplatform desktop clients
- **Tests** - Comprehensive test suite with database-specific variants

## Build System & Tooling

### Quick Build Commands

```bash
# Full build with all executables and tests
cabal build all

# Build just the library
cabal build simplex-chat:lib

# Run CLI with WebSocket server on port 5225
cabal run simplex-chat -- -p 5225

# Run tests (database-dependent - see below)
cabal test simplex-chat-test

# Format code with fourmolu
fourmolu --mode inplace $(find src apps -name '*.hs')
```

### Build Flavors & Database Options

The project supports **conditional compilation** via Cabal flags (`simplex-chat.cabal` lines 22-35):

```bash
# SQLite build (default)
cabal build

# PostgreSQL build - for server deployments
cabal build -f+client_postgres

# Client library only (no CLI/bot code)
cabal build -f+client_library

# Swift JSON format (iOS apps)
cabal build -f+swift
```

**Critical:** Test suite behavior differs by backend:
- **SQLite:** Includes `MobileTests`, `WebRTCTests`, `SchemaDump` (lines 550-552)
- **PostgreSQL:** Includes `PostgresSchemaDump` (lines 545-546), skips mobile-specific tests

### Key Dependencies & Custom Forks

Project uses **multiple custom Git repository packages** (cabal.project lines 12-65):
- `simplexmq` (tag 9346b85c3f34f8b12fefef4631ba21087cf5f0e3) - Core messaging queue protocol
- `direct-sqlcipher`, `sqlcipher-simple` - SQLite encryption bindings
- Custom forks include `aeson`, `haskell-terminal`, `hs-socks`, `android-support`, `zip`, and `wai` (`warp` and `warp-tls`) with project-specific patches

**GHC Constraints:** Conditional code for GHC 9.6.2+ vs earlier (bytestring 0.11 vs 0.10, text version, template-haskell).

## Code Architecture & Patterns

### Module Organization

```
src/Simplex/Chat/
├── Controller.hs             # Main state machine & command routing
├── Types.hs                  # Core type definitions
├── Types/                    # Type submodules (preferences, UI theme, shared helpers)
├── Store.hs                  # Database abstraction facade
│   ├── Store/Messages.hs     # Message storage operations
│   ├── Store/Groups.hs       # Group chat operations
│   ├── Store/Profiles.hs     # User/contact profiles
│   ├── Store/Connections.hs  # Connection management
│   ├── Store/NoteFolders.hs  # Private notes / folders storage
│   ├── SQLite/Migrations/    # 80+ numbered schema migrations
│   └── Postgres/Migrations/  # Parallel Postgres migrations
├── Messages.hs               # Protocol & encryption encoding
├── Protocol.hs               # SimpleX protocol types
├── Terminal/                 # CLI interface
│   ├── Terminal.hs           # Main terminal loop
│   ├── Main.hs               # CLI bootstrap / runtime wiring
│   ├── Input.hs              # Command parsing
│   ├── Notification.hs       # Local notifications and alert logic
│   └── Output.hs             # Response formatting
├── Bot.hs                    # Bot framework
├── Bot/                      # Bot helpers (e.g., known contacts)
├── Remote/                   # Remote control & app updates
├── Library/                  # Public command/subscriber API used by app bindings
├── Operators/                # Operator presets and conditions used in policy checks
└── Mobile/                   # Mobile-specific features
```

### Critical Design Patterns

**1. Double Dispatch via IsContact Typeclass (Types.hs:74-98)**

```haskell
class IsContact a where
  contactId' :: a -> ContactId
  profile' :: a -> LocalProfile
  localDisplayName' :: a -> ContactName
  preferences' :: a -> Maybe Preferences
```

Enables generic code for `User` and `Contact` without duplication. Always prefer typeclass-based operations over type-specific code.

**2. Store Abstraction with Dual Backend Support**

- Database operations are abstraction-first with dual SQLite/PostgreSQL implementations
- All migrations are timestamped modules: `M20220101_initial`, `M20250802_chat_peer_type`
- Each migration file is standalone and importable for schema versioning
- Conditional compilation `#if defined(dbPostgres)` manages backend differences everywhere

**3. Three-Layer Message Encryption**

- **Queue-level**: NaCl cryptobox per message queue (prevent ciphertext correlation attacks)
- **Conversation-level**: Double-ratchet (Signal-compatible) with post-quantum key exchange
- **File encryption**: XFTP protocol for large files with separate encryption
- Key code in `Messages.hs`, `Messages/CIContent.hs`, and SimplexMQ integration

**4. Terminal CLI as Extensible WebSocket Server**

- `-p <port>` flag (apps/simplex-chat/Main.hs) runs local WebSocket server
- Bot API documented in `bots/README.md` - commands/events exchanged as JSON
- API docs and TypeScript unions are generated/validated from Haskell types via `tests/APIDocs.hs` (`bots/api/COMMANDS.md`, `bots/api/EVENTS.md`, `bots/api/TYPES.md`, `packages/simplex-chat-client/types/typescript/src/*.ts`)

### Testing Patterns

- **Modular test suites**: `tests/Test.hs` imports domain-specific test modules (ChatTests, ProtocolTests, etc.)
- **Isolated temporary databases**: Test bracket (Test.hs:77) creates per-test SQLite instances
- **Fixture management**: `tests/fixtures/` directory + `JSONFixtures.hs` for reproducible test data
- **Built-in query statistics**: TMap-based query tracking for performance analysis (Test.hs:43-44)
- **Schema validation**: Backend-specific schema dump tests (`SchemaDump` for SQLite, `PostgresSchemaDump` for Postgres)
- **Bot API docs + TS types validation**: SQLite test runs include `describe "Bot API docs" apiDocsTest`, which rewrites and verifies `bots/api/*.md` and `packages/simplex-chat-client/types/typescript/src/*.ts`

## Project-Specific Conventions

### Naming & Type-Level Discipline

- **DuplicateRecordFields pragma** (pragmas in almost all modules) - field names can repeat safely across types
  - Example: `Contact` and `User` both have `profile` field without collision
- **Phantom newtypes for safety**: `UserId`, `ContactId`, `ConnId`, `MsgId` prevent accidental ID mix-ups
  - Compiler enforces proper usage; convert with helper functions only
- **Aeson-TH derivation pattern**: Most types use `J.deriveJSON defaultJSON` with `dropPrefix` for field naming
  - Haskell `myFieldName` becomes JSON `myFieldName` automatically

### Error Handling & Exceptions

- Explicit error types: `Either ChatError a` or `ExceptT ChatError m a`
- Database errors handled per-backend: `#if defined(dbPostgres)` catches `PostgreSQL.ResultError` vs `SQLite.SQLError`
- Logging via `Control.Logger.Simple` - set via `setLogLevel LogError` in test main
- Use `liftIOEither` utility (Util.hs) to convert IO exceptions to Either

### Code Smells to Avoid

- **Don't access Store directly from Controller**: Use transaction wrappers (`withTransaction`, `withTransactionPriority`)
- **Don't hardcode server defaults**: Use `AppSettings` module (AppSettings.hs)
- **Don't mix encryption layers**: Queue encryption is cryptographically orthogonal to message-level encryption
- **Don't add new message types without migrations**: Every `ChatItem` variant requires corresponding DB schema updates
- **Don't use `undefined` or `error` in production code**: Use `Maybe` or `Either` for failure cases

## Integration Points & Data Flow

### Complete Message Send Flow

1. **User sends message** → `Controller.hs` `cmdSendMessage` routes command
2. **Message validation** → Check group permissions, contact status, quotas
3. **Message encoding** → `Messages.hs` encodes to `CIContent` with markdown parsing
4. **Ratchet encryption** → Double-ratchet key advancement per message
5. **Queue-level encryption** → NaCl cryptobox wrapping per queue
6. **Agent delivery** → SimplexMQ client sends via SMP protocol
7. **Status tracking** → `Store/Messages.hs` inserts with `msgId`, `status=New`, server timestamp
8. **Event emission** → `Controller` emits `MsgSent` event to subscribers
9. **Recipient flow** → Agent notifies, `Controller` decrypts (reverse ratchet), stores, updates chat list

### Group Membership & Permissions

- Groups are special `Group` connection type with `host` (creator) and `members`
- `member_role` column tracks permissions: `admin`, `member`, `observer`
- Group features (threads, reactions, etc.) stored in `group_features` table
- See `ChatTests/Groups.hs` for comprehensive member management patterns

### Bot Integration Flow

1. CLI starts with `simplex-chat -p 5225` (WebSocket server on localhost:5225)
2. External bot connects via WebSocket
3. Bot sends command JSON: `{"corrId":"42","cmd":"<command string>"}`
4. CLI parses via command parser, executes side effects
5. CLI returns `{"corrId":"42","resp":{...}}` for responses and `{"resp":{...}}` for events
6. Security: bot runs in same process namespace (no network exposure needed)

## Compilation & Debugging Tips

### Common Build Issues & Solutions

```bash
# Cache corruption - clean all build artifacts
rm -rf dist-newstyle
cabal update

# GHC version mismatch
# Check for conditional imports in code with `impl(ghc >= 9.6.2)` predicates
cabal --version

# PostgreSQL linking errors
export PKG_CONFIG_PATH=/usr/lib/pkgconfig  # Linux
brew install postgresql  # macOS

# Missing simplexmq dependency
cabal update  # Fetch latest source-repository-package commits
```

### Warnings Are Errors

Project enforces selected warnings as errors via `-Werror=<warning>` flags in all Cabal stanzas. Common fixable warnings:

- **Incomplete record updates**: Use `record { field = value }` or `record { .. }` syntax
- **Unused imports**: Check `#if`/`#else` guards - imports may be conditional
- **Missing record fields**: Pattern matches must cover all fields or use `_`
- **Redundant constraints**: Remove unnecessary `=>` bounds from function signatures

### Profiling & Performance

```bash
# Build with profiling support
cabal build --enable-profiling simplex-chat:exe:simplex-chat

# Run with heap profiling
cabal run simplex-chat -- +RTS -h -i0.1 -RTS -p 5225

# Query statistics already in test code
# Test.hs:43-44 creates TMap for tracking database queries
```

## Common Development Tasks

### Adding a New Message Type

1. **Define type** in `Types.hs` - add constructor to `ChatItem` sum type
2. **Add JSON instances** - use `J.deriveJSON defaultJSON` with correct field ordering
3. **Implement encoding** in `Messages.hs` - handle serialization via `CIContent` pattern
4. **Create migration** - add `Store/SQLite/Migrations/M<YYYYMMDD>_<name>.hs` and Postgres equivalent
   - Migration modules must follow exact naming: `M20250101_chat_feature_name`
5. **Update Controller** - add command handler in `Controller.hs` for new message type
6. **Test encoding/decoding** - add cases to `JSONTests.hs` (automatic via fixtures)

### Adding Database Column

1. **Create matching migrations** in both backends:
   ```bash
   # Create Store/SQLite/Migrations/M<date>_<feature>.hs
   # Create Store/Postgres/Migrations/M<date>_<feature>.hs
   # Module names must match exactly
   ```
2. **Update type definitions** in `Store.hs` or `Store/Submodule.hs`
3. **Run schema dump** via `cabal test`:
   ```bash
   cabal test simplex-chat-test --test-show-details=direct
   # Tests regenerate chat_schema.sql
   ```
4. **Verify migrations** are idempotent - rerunning test shouldn't fail

### Testing Bot API Command

```bash
# Terminal 1: Start CLI WebSocket server
cabal run simplex-chat -- -p 5225

# Terminal 2: Send command via WebSocket (install wscat: npm install -g wscat)
wscat -c ws://localhost:5225
> {"corrId": "1", "cmd": "<command string>"}
# Returns event JSON response

# Or use Python
python3 -c "
import json, websocket
ws = websocket.create_connection('ws://localhost:5225')
ws.send(json.dumps({'corrId': '1', 'cmd': '<command string>'}))
print(ws.recv())
"
```

## Documentation & References

- **Chat Protocol**: `docs/protocol/simplex-chat.md` - message format specification
- **Local Protocol**: `src/Simplex/Chat/protocol.md` - internal encoding details
- **SimpleX Messaging**: External `simplex-chat/simplexmq` repo - SMP server protocol
- **Bot API**: `bots/README.md` - bot configuration and creation guide
- **API Docs**: `bots/api/README.md` with generated references in `bots/api/COMMANDS.md`, `bots/api/EVENTS.md`, `bots/api/TYPES.md`
- **CLI Help**: `src/Simplex/Chat/Help.hs` - user command documentation
- **Security Model**: `PRIVACY.md`, `docs/SIMPLEX.md` - architecture rationale
- **Version History**: `docs/version-changes` - protocol evolution

## When to Modify vs. Extend

- **Protocol changes** (message format): Coordinate via `docs/protocol/simplex-chat.md` and `Version.hs` negotiation
- **New server type** (SMP variant): Implement in `simplexmq` repo, not here
- **New client feature** (message type, profile field): Extend `Controller.hs` + `Types.hs` + migrations
- **Algorithm update** (encryption, ratchet): Coordinate with `simplexmq` and security review
- **CLI command** (user-facing): Add to `Terminal/Input.hs` parser and `Controller.hs` handler
- **Bot API command**: Same as CLI - updates generated API docs in `bots/api/COMMANDS.md`, `bots/api/EVENTS.md`, `bots/api/TYPES.md`

