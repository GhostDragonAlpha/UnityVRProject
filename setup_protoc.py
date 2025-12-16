import os
import requests
import zipfile
import io

# Protoc 25.1 Win64
PROTOC_URL = "https://github.com/protocolbuffers/protobuf/releases/download/v25.1/protoc-25.1-win64.zip"
TARGET_DIR = "Tools/protoc"

def install_protoc():
    if not os.path.exists(TARGET_DIR):
        os.makedirs(TARGET_DIR)
    
    print(f"Downloading Protoc from {PROTOC_URL}...")
    try:
        r = requests.get(PROTOC_URL)
        r.raise_for_status()
        z = zipfile.ZipFile(io.BytesIO(r.content))
        z.extractall(TARGET_DIR)
        print("Protoc extracted.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    install_protoc()
