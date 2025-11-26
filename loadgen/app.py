# ./loadgen/app.py
import os
import time
import random
import string
import psycopg2
from psycopg2.extras import execute_values

DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Configurações de carga
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "50"))
SLEEP_MIN_SEC = float(os.getenv("SLEEP_MIN_SEC", "0.2"))
SLEEP_MAX_SEC = float(os.getenv("SLEEP_MAX_SEC", "1.5"))
READ_RATIO = float(os.getenv("READ_RATIO", "0.4"))      # 40% reads
WRITE_RATIO = float(os.getenv("WRITE_RATIO", "0.3"))     # 30% inserts
UPDATE_RATIO = float(os.getenv("UPDATE_RATIO", "0.2"))   # 20% updates
DELETE_RATIO = float(os.getenv("DELETE_RATIO", "0.1"))   # 10% deletes

TABLE_NAME = os.getenv("TABLE_NAME", "loadgen_events")

def rand_text(n=32):
    return "".join(random.choices(string.ascii_letters + string.digits, k=n))

def ensure_schema(conn):
    with conn.cursor() as cur:
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
                id BIGSERIAL PRIMARY KEY,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                category TEXT NOT NULL,
                payload TEXT NOT NULL,
                counter INT NOT NULL DEFAULT 0
            );
        """)
        # índice para acelerar reads/updates por categoria
        cur.execute(f"CREATE INDEX IF NOT EXISTS idx_{TABLE_NAME}_category ON {TABLE_NAME}(category);")
        conn.commit()

def insert_batch(conn, batch_size):
    rows = [(random.choice(["alpha","beta","gamma","delta"]),
             rand_text(64),
             0) for _ in range(batch_size)]
    with conn.cursor() as cur:
        execute_values(cur,
            f"INSERT INTO {TABLE_NAME} (category, payload, counter) VALUES %s",
            rows)
        conn.commit()
    return batch_size

def read_random(conn, limit=100):
    cat = random.choice(["alpha","beta","gamma","delta"])
    with conn.cursor() as cur:
        cur.execute(f"""
            SELECT id, category, payload, counter
            FROM {TABLE_NAME}
            WHERE category = %s
            ORDER BY created_at DESC
            LIMIT %s;
        """, (cat, limit))
        rows = cur.fetchall()
    return len(rows)

def update_random(conn, limit=50):
    with conn.cursor() as cur:
        cur.execute(f"""
            UPDATE {TABLE_NAME}
            SET counter = counter + 1,
                payload = SUBSTRING(payload FOR 48) || %s
            WHERE id IN (
                SELECT id FROM {TABLE_NAME}
                ORDER BY random()
                LIMIT %s
            );
        """, (rand_text(16), limit))
        updated = cur.rowcount
        conn.commit()
    return updated

def delete_random(conn, limit=20):
    with conn.cursor() as cur:
        cur.execute(f"""
            DELETE FROM {TABLE_NAME}
            WHERE id IN (
                SELECT id FROM {TABLE_NAME}
                ORDER BY random()
                LIMIT %s
            );
        """, (limit,))
        deleted = cur.rowcount
        conn.commit()
    return deleted

def main():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST, port=DB_PORT,
                dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
                connect_timeout=5,
            )
            conn.autocommit = False
            ensure_schema(conn)
            print("Loadgen connected and schema ensured.")
            break
        except Exception as e:
            print(f"Waiting for database... {e}")
            time.sleep(2)

    ops = [
        ("READ", READ_RATIO, lambda: read_random(conn, limit=random.randint(50, 200))),
        ("WRITE", WRITE_RATIO, lambda: insert_batch(conn, batch_size=random.randint(max(1, BATCH_SIZE//2), BATCH_SIZE))),
        ("UPDATE", UPDATE_RATIO, lambda: update_random(conn, limit=random.randint(10, 100))),
        ("DELETE", DELETE_RATIO, lambda: delete_random(conn, limit=random.randint(5, 50))),
    ]

    # Normalize ratios to sum to 1
    total_ratio = sum(r for _, r, _ in ops)
    ops = [(name, r/total_ratio, fn) for name, r, fn in ops]

    tick = 0
    while True:
        tick += 1
        # Escolhe operação pela distribuição de probabilidade
        p = random.random()
        acc = 0.0
        chosen = None
        for name, ratio, fn in ops:
            acc += ratio
            if p <= acc:
                chosen = (name, fn)
                break

        name, fn = chosen
        try:
            affected = fn()
            print(f"[{tick}] {name}: {affected} rows | sleep ...")
        except Exception as e:
            print(f"[{tick}] {name} failed: {e}")
            # Conexões podem cair: tenta reabrir
            try:
                conn.close()
            except Exception:
                pass
            time.sleep(1)
            try:
                conn = psycopg2.connect(
                    host=DB_HOST, port=DB_PORT,
                    dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
                    connect_timeout=5,
                )
                conn.autocommit = False
                print("Reconnected to database.")
            except Exception as e2:
                print(f"Reconnect failed: {e2}")

        # Intervalo aleatório
        time.sleep(random.uniform(SLEEP_MIN_SEC, SLEEP_MAX_SEC))

if __name__ == "__main__":
    main()# ./loadgen/app.py
import os
import time
import random
import string
import psycopg2
from psycopg2.extras import execute_values

DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Configurações de carga
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "50"))
SLEEP_MIN_SEC = float(os.getenv("SLEEP_MIN_SEC", "0.2"))
SLEEP_MAX_SEC = float(os.getenv("SLEEP_MAX_SEC", "1.5"))
READ_RATIO = float(os.getenv("READ_RATIO", "0.4"))      # 40% reads
WRITE_RATIO = float(os.getenv("WRITE_RATIO", "0.3"))     # 30% inserts
UPDATE_RATIO = float(os.getenv("UPDATE_RATIO", "0.2"))   # 20% updates
DELETE_RATIO = float(os.getenv("DELETE_RATIO", "0.1"))   # 10% deletes

TABLE_NAME = os.getenv("TABLE_NAME", "loadgen_events")

def rand_text(n=32):
    return "".join(random.choices(string.ascii_letters + string.digits, k=n))

def ensure_schema(conn):
    with conn.cursor() as cur:
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
                id BIGSERIAL PRIMARY KEY,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                category TEXT NOT NULL,
                payload TEXT NOT NULL,
                counter INT NOT NULL DEFAULT 0
            );
        """)
        # índice para acelerar reads/updates por categoria
        cur.execute(f"CREATE INDEX IF NOT EXISTS idx_{TABLE_NAME}_category ON {TABLE_NAME}(category);")
        conn.commit()

def insert_batch(conn, batch_size):
    rows = [(random.choice(["alpha","beta","gamma","delta"]),
             rand_text(64),
             0) for _ in range(batch_size)]
    with conn.cursor() as cur:
        execute_values(cur,
            f"INSERT INTO {TABLE_NAME} (category, payload, counter) VALUES %s",
            rows)
        conn.commit()
    return batch_size

def read_random(conn, limit=100):
    cat = random.choice(["alpha","beta","gamma","delta"])
    with conn.cursor() as cur:
        cur.execute(f"""
            SELECT id, category, payload, counter
            FROM {TABLE_NAME}
            WHERE category = %s
            ORDER BY created_at DESC
            LIMIT %s;
        """, (cat, limit))
        rows = cur.fetchall()
    return len(rows)

def update_random(conn, limit=50):
    with conn.cursor() as cur:
        cur.execute(f"""
            UPDATE {TABLE_NAME}
            SET counter = counter + 1,
                payload = SUBSTRING(payload FOR 48) || %s
            WHERE id IN (
                SELECT id FROM {TABLE_NAME}
                ORDER BY random()
                LIMIT %s
            );
        """, (rand_text(16), limit))
        updated = cur.rowcount
        conn.commit()
    return updated

def delete_random(conn, limit=20):
    with conn.cursor() as cur:
        cur.execute(f"""
            DELETE FROM {TABLE_NAME}
            WHERE id IN (
                SELECT id FROM {TABLE_NAME}
                ORDER BY random()
                LIMIT %s
            );
        """, (limit,))
        deleted = cur.rowcount
        conn.commit()
    return deleted

def main():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST, port=DB_PORT,
                dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
                connect_timeout=5,
            )
            conn.autocommit = False
            ensure_schema(conn)
            print("Loadgen connected and schema ensured.")
            break
        except Exception as e:
            print(f"Waiting for database... {e}")
            time.sleep(2)

    ops = [
        ("READ", READ_RATIO, lambda: read_random(conn, limit=random.randint(50, 200))),
        ("WRITE", WRITE_RATIO, lambda: insert_batch(conn, batch_size=random.randint(max(1, BATCH_SIZE//2), BATCH_SIZE))),
        ("UPDATE", UPDATE_RATIO, lambda: update_random(conn, limit=random.randint(10, 100))),
        ("DELETE", DELETE_RATIO, lambda: delete_random(conn, limit=random.randint(5, 50))),
    ]

    # Normalize ratios to sum to 1
    total_ratio = sum(r for _, r, _ in ops)
    ops = [(name, r/total_ratio, fn) for name, r, fn in ops]

    tick = 0
    while True:
        tick += 1
        # Escolhe operação pela distribuição de probabilidade
        p = random.random()
        acc = 0.0
        chosen = None
        for name, ratio, fn in ops:
            acc += ratio
            if p <= acc:
                chosen = (name, fn)
                break

        name, fn = chosen
        try:
            affected = fn()
            print(f"[{tick}] {name}: {affected} rows | sleep ...")
        except Exception as e:
            print(f"[{tick}] {name} failed: {e}")
            # Conexões podem cair: tenta reabrir
            try:
                conn.close()
            except Exception:
                pass
            time.sleep(1)
            try:
                conn = psycopg2.connect(
                    host=DB_HOST, port=DB_PORT,
                    dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
                    connect_timeout=5,
                )
                conn.autocommit = False
                print("Reconnected to database.")
            except Exception as e2:
                print(f"Reconnect failed: {e2}")

        # Intervalo aleatório
        time.sleep(random.uniform(SLEEP_MIN_SEC, SLEEP_MAX_SEC))

if __name__ == "__main__":
    main()
