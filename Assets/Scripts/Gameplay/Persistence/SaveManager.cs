using UnityEngine;
using Mono.Data.Sqlite;
using System.Data;
using System.IO;
using Core.Network; // Protobuf
using Google.Protobuf;

namespace Gameplay.Persistence
{
    public class SaveManager : MonoBehaviour
    {
        private string dbPath;

        private void Awake()
        {
            string dir = Path.Combine(Application.dataPath, "StreamingAssets");
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            
            dbPath = "Data Source=" + Path.Combine(dir, "game.db");
            InitializeDB();
        }

        private void InitializeDB()
        {
            // Ensure StreamingAssets exists
            string dir = Path.Combine(Application.dataPath, "StreamingAssets");
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            using (var conn = new SqliteConnection(dbPath))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    // Simple Key-Value Store for Protobuf Blobs
                    // We can expand this to columns (x, y, z) later if SQL queries are needed.
                    cmd.CommandText = "CREATE TABLE IF NOT EXISTS GameState (Key TEXT PRIMARY KEY, Data BLOB, Timestamp REAL)";
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private void EnsureInitialized()
        {
            if (string.IsNullOrEmpty(dbPath))
            {
                string dir = Path.Combine(Application.dataPath, "StreamingAssets");
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                dbPath = "Data Source=" + Path.Combine(dir, "game.db");
                
                using (var conn = new SqliteConnection(dbPath))
                {
                    conn.Open();
                    using (var cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = "CREATE TABLE IF NOT EXISTS GameState (Key TEXT PRIMARY KEY, Data BLOB, Timestamp REAL)";
                        cmd.ExecuteNonQuery();
                    }
                }
            }
        }

        public void SaveGameState(GameStateMsg state)
        {
            EnsureInitialized();
            using (var conn = new SqliteConnection(dbPath))
            {
                conn.Open();
                using (var transaction = conn.BeginTransaction())
                {
                    foreach (var entity in state.Entities)
                    {
                        using (var cmd = conn.CreateCommand())
                        {
                            cmd.CommandText = "INSERT OR REPLACE INTO GameState (Key, Data, Timestamp) VALUES (@key, @data, @time)";
                            cmd.Parameters.Add(new SqliteParameter("@key", entity.Name));
                            cmd.Parameters.Add(new SqliteParameter("@data", entity.ToByteArray()));
                            cmd.Parameters.Add(new SqliteParameter("@time", state.Timestamp));
                            cmd.ExecuteNonQuery();
                        }
                    }
                    transaction.Commit();
                }
            }
            Debug.Log($"[SaveManager] Saved {state.Entities.Count} entities to DB.");
        }

        public GameStateMsg LoadGameState()
        {
            var state = new GameStateMsg();
            state.Status = "loaded";
            state.Timestamp = Time.time;

            using (var conn = new SqliteConnection(dbPath))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT Data FROM GameState";
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            byte[] blob = (byte[])reader["Data"];
                            var entity = TransformMsg.Parser.ParseFrom(blob);
                            state.Entities.Add(entity);
                        }
                    }
                }
            }
            Debug.Log($"[SaveManager] Loaded {state.Entities.Count} entities from DB.");
            return state;
        }
    }
}
