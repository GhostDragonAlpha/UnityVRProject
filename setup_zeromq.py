import os
import requests
import zipfile
import io

# URLs for NetMQ and dependencies
NETMQ_URL = "https://www.nuget.org/api/v2/package/NetMQ/4.0.1.13"
ASYNCIO_URL = "https://www.nuget.org/api/v2/package/AsyncIO/0.1.69"
NACL_URL = "https://www.nuget.org/api/v2/package/NaCl.Net/0.1.13"
PROTOBUF_URL = "https://www.nuget.org/api/v2/package/Google.Protobuf/3.25.1" 
UNSAFE_URL = "https://www.nuget.org/api/v2/package/System.Runtime.CompilerServices.Unsafe/6.0.0"
# Swapping to Mono.Data.Sqlite 
SQLITE_URL = "https://www.nuget.org/api/v2/package/Mono.Data.Sqlite/1.0.61"
SQLITE_NATIVE_URL = "https://www.nuget.org/api/v2/package/SQLitePCLRaw.lib.e_sqlite3/2.1.8"

TARGET_DIR = os.path.join("Assets", "Plugins")

def download_and_extract(url, name):
    print(f"Downloading {name}...")
    try:
        r = requests.get(url)
        r.raise_for_status()
        z = zipfile.ZipFile(io.BytesIO(r.content))
        
        # Look for .netstandard2.0 OR net46 version (Unity supports both)
        found = False
        candidates = ["netstandard2.0", "netstandard2.1", "net46", "net461", "net462", "net40"]
        
        print(f"DEBUG: Files in {name}:")
        for f in z.namelist(): print(f)

        for file in z.namelist():
            is_candidate = any(c in file for c in candidates)
            if is_candidate and file.endswith(".dll") and "resources" not in file:
                filename = os.path.basename(file)
                target_path = os.path.join(TARGET_DIR, filename)
                with open(target_path, 'wb') as f:
                    f.write(z.read(file))
                print(f"Extracted {filename} to {target_path}")
                found = True
        if not found:
            print(f"Warning: Could not find netstandard2.0 dll for {name}")
    except Exception as e:
        print(f"Error downloading {name}: {e}")

def main():
    if not os.path.exists(TARGET_DIR):
        os.makedirs(TARGET_DIR)
        print(f"Created {TARGET_DIR}")
        
    download_and_extract(NETMQ_URL, "NetMQ")
    download_and_extract(ASYNCIO_URL, "AsyncIO")
    download_and_extract(NACL_URL, "NaCl.Net")
    download_and_extract(PROTOBUF_URL, "Google.Protobuf")
    download_and_extract(UNSAFE_URL, "System.Runtime.CompilerServices.Unsafe")
    download_and_extract(SQLITE_URL, "Mono.Data.Sqlite")
    
    # Custom extraction for native sqlite3.dll
    print("Downloading Native SQLite3...")
    r = requests.get(SQLITE_NATIVE_URL)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    found = False
    for file in z.namelist():
        if "win-x64/native/e_sqlite3.dll" in file:
             target_path = os.path.join(TARGET_DIR, "sqlite3.dll")
             with open(target_path, 'wb') as f:
                 f.write(z.read(file))
             print(f"Extracted {file} to {target_path}")
             found = True
             break
    if not found: print("Warning: Could not find e_sqlite3.dll")

    print("ZeroMQ + Protobuf + SQLite Setup Complete.")

if __name__ == "__main__":
    main()
