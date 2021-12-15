import os
import json

from .storage import IStorage
# Imports the Google Cloud client library
from google.cloud import storage

BUCKET = os.environ.get('CLOUD_STORAGE_BUCKET') or 'test-bucket'

class CloudStorage(IStorage):
    def __init__(self) -> None:
        self.storage_client = storage.Client()
        self.bucket = self.storage_client.bucket(BUCKET)
        self.path = "sets/"
    
    def store_json(self, path, data):
        print("storing JSON")
        print(str(self.bucket.blob(self.path + path + ".json").upload_from_string(json.dumps(data), content_type='application/json', timeout=10)))
        return True

    def load_json(self, path):
        print("loading JSON")
        return json.loads(self.bucket.blob(self.path + path + ".json").download_as_text())

    def has_json(self, path):
        return self.bucket.blob(self.path + path + ".json").exists()

    def list_json(self):
        return [x.name.replace(self.path, "") for x in self.storage_client.list_blobs(self.bucket, prefix=self.path, timeout=5) if ".json" in x.name]
