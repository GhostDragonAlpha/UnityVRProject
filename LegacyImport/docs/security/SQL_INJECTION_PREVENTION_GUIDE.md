# SQL Injection Prevention Guide

**For Developers Working with SpaceTime VR Database Layer**

---

## Quick Reference

### ✅ SAFE Practices

```python
# CORRECT: Use parameterized queries
cursor.execute("SELECT * FROM users WHERE username = %s", (username,))

# CORRECT: Use validated column names
validated_columns = state_manager._validate_columns('regions', columns)

# CORRECT: Use table whitelist
table = state_manager._validate_table_name(table_name)
```

### ❌ UNSAFE Practices

```python
# WRONG: String concatenation
query = "SELECT * FROM " + table_name  # SQL INJECTION RISK!

# WRONG: String formatting with values
query = f"SELECT * FROM users WHERE id = {user_id}"  # VULNERABLE!

# WRONG: Dynamic column names without validation
query = f"UPDATE table SET {column} = %s"  # INJECTION RISK!
```

---

## Understanding SQL Injection

### What is SQL Injection?

SQL injection is a code injection technique that exploits security vulnerabilities in an application's database layer. Attackers insert malicious SQL code into queries to:

- Access unauthorized data
- Modify or delete data
- Execute administrative operations
- Bypass authentication

### Example Attack

**Vulnerable Code:**
```python
# DANGEROUS: String concatenation
username = request.get('username')
query = f"SELECT * FROM users WHERE username = '{username}'"
cursor.execute(query)
```

**Attack Input:**
```
Username: admin'; DROP TABLE users; --
```

**Resulting SQL:**
```sql
SELECT * FROM users WHERE username = 'admin'; DROP TABLE users; --'
```

**Result:** The `users` table is deleted!

---

## Defense Mechanisms in SpaceTime VR

### 1. Table Name Whitelist

**Implementation:**
```python
ALLOWED_TABLES = {
    'regions', 'entities', 'players', 'structures',
    'terrain_modifications', 'operation_log',
    'conflict_resolution_log', 'server_heartbeats'
}

def _validate_table_name(self, table: str) -> str:
    if table not in self.ALLOWED_TABLES:
        raise ValueError(f"Invalid table name: {table}")
    return table
```

**Usage:**
```python
# Always validate table names
table = state_manager._validate_table_name(user_input_table)
query = f"SELECT * FROM {table} WHERE id = %s"
```

### 2. Column Name Whitelist

**Implementation:**
```python
ALLOWED_COLUMNS = {
    'regions': {
        'region_id', 'region_x', 'region_y', 'region_z',
        'owner_server_id', 'is_active', 'player_count',
        'entity_count'
    },
    # ... other tables
}

def _validate_columns(self, table: str, columns: List[str]) -> List[str]:
    allowed = self.ALLOWED_COLUMNS.get(table, set())
    invalid = set(columns) - allowed
    if invalid:
        raise ValueError(f"Invalid columns: {invalid}")
    return columns
```

**Usage:**
```python
# Always validate column names
columns = state_manager._validate_columns('regions', user_columns)
set_clause = ", ".join([f"{col} = %s" for col in columns])
```

### 3. Parameterized Queries

**Implementation:**
```python
# CORRECT: Values are parameterized
query = "INSERT INTO regions (region_id, region_x) VALUES (%s, %s)"
cursor.execute(query, (region_id, region_x))

# WRONG: Values in query string
query = f"INSERT INTO regions (region_id, region_x) VALUES ('{region_id}', {region_x})"
cursor.execute(query)  # VULNERABLE!
```

### 4. Identifier Sanitization

**Implementation:**
```python
def _sanitize_identifier(self, identifier: str) -> str:
    # Only allow alphanumeric and underscore
    if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', identifier):
        raise ValueError(f"Invalid identifier: {identifier}")

    # Prevent SQL keywords
    if identifier.upper() in self.SQL_KEYWORDS:
        raise ValueError(f"SQL keyword not allowed: {identifier}")

    return identifier
```

---

## How to Write Secure Database Code

### Step-by-Step Guide

#### 1. Define Your Schema First

Before writing any code, define:
- What tables you need
- What columns each table has
- What the primary keys are

**Example:**
```python
# Add to ALLOWED_TABLES
ALLOWED_TABLES.add('my_new_table')

# Add to ALLOWED_COLUMNS
ALLOWED_COLUMNS['my_new_table'] = {
    'id', 'name', 'created_at', 'data'
}

# Add to TABLE_PRIMARY_KEYS
TABLE_PRIMARY_KEYS['my_new_table'] = 'id'
```

#### 2. Use Prepared Statements

**Pattern:**
```python
def get_item(self, item_id: str) -> Optional[Dict]:
    with self.get_connection() as conn:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            # Define query template
            query = """
                SELECT id, name, data
                FROM my_new_table
                WHERE id = %s
            """
            # Execute with parameters
            cur.execute(query, (item_id,))
            return cur.fetchone()
```

#### 3. Validate Dynamic Identifiers

**Pattern:**
```python
def update_item(self, item_id: str, updates: Dict[str, Any]) -> bool:
    # Validate columns
    columns = list(updates.keys())
    validated_columns = self._validate_columns('my_new_table', columns)

    # Build query with validated identifiers
    set_clause = ", ".join([f"{col} = %s" for col in validated_columns])
    values = list(updates.values()) + [item_id]

    with self.get_connection() as conn:
        with conn.cursor() as cur:
            query = f"UPDATE my_new_table SET {set_clause} WHERE id = %s"
            cur.execute(query, values)
            return cur.rowcount > 0
```

#### 4. Never Trust User Input

**Rule:** All input from external sources (HTTP requests, files, network) must be validated.

```python
# WRONG: Direct usage
table = request.get('table')
query = f"SELECT * FROM {table}"

# RIGHT: Validation
table = request.get('table')
table = self._validate_table_name(table)  # Raises if invalid
query = f"SELECT * FROM {table} WHERE id = %s"
```

---

## Common Pitfalls and Solutions

### Pitfall 1: Dynamic Table Names

**Problem:**
```python
# VULNERABLE: User-controlled table name
table = get_user_preference('favorite_table')
query = f"SELECT * FROM {table}"
```

**Solution:**
```python
# SAFE: Whitelist validation
table = get_user_preference('favorite_table')
table = self._validate_table_name(table)  # Raises ValueError if invalid
query = f"SELECT * FROM {table} WHERE id = %s"
```

### Pitfall 2: Dynamic Column Names in SET Clause

**Problem:**
```python
# VULNERABLE: User-controlled columns
columns = request.get_json()['columns']
set_clause = ", ".join([f"{k} = %s" for k in columns.keys()])
```

**Solution:**
```python
# SAFE: Column validation
columns = request.get_json()['columns']
validated = self._validate_columns(table, list(columns.keys()))
set_clause = ", ".join([f"{k} = %s" for k in validated])
```

### Pitfall 3: LIKE Clause Wildcards

**Problem:**
```python
# VULNERABLE: User can inject wildcards
search = request.get('search')
query = f"SELECT * FROM items WHERE name LIKE '%{search}%'"
```

**Solution:**
```python
# SAFE: Parameterize the value
search = request.get('search')
query = "SELECT * FROM items WHERE name LIKE %s"
cursor.execute(query, (f'%{search}%',))
```

### Pitfall 4: ORDER BY Clause

**Problem:**
```python
# VULNERABLE: ORDER BY cannot be parameterized
sort_column = request.get('sort')
query = f"SELECT * FROM items ORDER BY {sort_column}"
```

**Solution:**
```python
# SAFE: Whitelist validation
sort_column = request.get('sort')
validated = self._validate_columns('items', [sort_column])[0]
query = f"SELECT * FROM items ORDER BY {validated}"
```

---

## Testing for SQL Injection

### Unit Tests

Always include SQL injection tests when writing database code:

```python
def test_sql_injection_prevention():
    """Test that SQL injection is prevented."""
    sm = StateManager()

    # Test malicious table name
    with pytest.raises(ValueError):
        sm._validate_table_name("users; DROP TABLE users; --")

    # Test malicious column name
    with pytest.raises(ValueError):
        sm._validate_columns('regions', ["id' OR '1'='1"])
```

### Manual Testing

Try these common injection patterns:

1. **Comment Injection:** `admin' --`
2. **Boolean Injection:** `' OR '1'='1`
3. **Stacked Queries:** `'; DROP TABLE users; --`
4. **UNION Injection:** `' UNION SELECT * FROM admin_users --`

**All of these should be blocked by validation.**

---

## Code Review Checklist

When reviewing database code, check:

- [ ] Are all table names validated against whitelist?
- [ ] Are all column names validated against schema?
- [ ] Are all values passed via parameters (not string concatenation)?
- [ ] Are there any `f-strings` or `+` operators in SQL queries?
- [ ] Are dynamic identifiers sanitized?
- [ ] Are error messages logged (but not exposing SQL)?
- [ ] Are there unit tests for SQL injection?

---

## Emergency Response

### If You Suspect SQL Injection

1. **Immediately** notify the security team
2. Check audit logs for suspicious queries
3. Review recent database changes
4. Check if data was exfiltrated or modified
5. Patch the vulnerability
6. Reset credentials if compromised
7. Document the incident

### Audit Log Analysis

Look for:
```python
# Check security violation counter
stats = state_manager.get_cache_stats()
if stats['security_violations'] > 0:
    # Investigate!
    logger.error(f"Security violations detected: {stats['security_violations']}")
```

---

## Resources

### Internal Documentation
- [VULN-012 Remediation Report](../../VULN-012_SQL_INJECTION_REMEDIATION_REPORT.md)
- [state_manager_SECURE.py](../../scripts/planetary_survival/database/state_manager_SECURE.py)
- [SQL Injection Tests](../../tests/security/test_sql_injection_prevention.py)

### External Resources
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [CWE-89: SQL Injection](https://cwe.mitre.org/data/definitions/89.html)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/sql-prepare.html)
- [psycopg2 SQL Injection Prevention](https://www.psycopg.org/docs/usage.html#passing-parameters-to-sql-queries)

---

## Quick Command Reference

### Run SQL Injection Tests
```bash
# Run all security tests
cd tests/security
python -m pytest test_sql_injection_prevention.py -v

# Run specific test
python -m pytest test_sql_injection_prevention.py::TestSQLInjectionPrevention::test_table_name_injection_blocked -v

# Run with coverage
python -m pytest test_sql_injection_prevention.py --cov=scripts.planetary_survival.database --cov-report=html
```

### Check Security Statistics
```python
from scripts.planetary_survival.database.state_manager_SECURE import StateManager

sm = StateManager()
stats = sm.get_cache_stats()
print(f"Security violations: {stats['security_violations']}")
```

---

## Contact

**Security Team:** security@spacetimevr.example.com
**Security Hotline:** +1-XXX-XXX-XXXX (24/7)

---

**Last Updated:** 2025-12-03
**Version:** 1.0
**Status:** Active
