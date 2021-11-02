import os
import json

from .storage import IStorage

class FileStorage(IStorage):
    def __init__(self) -> None:
        self.path = 'temp/'
        try:
            os.mkdir(self.path)
        except:
            pass

    def store_json(self, path, data):
        print("storing JSON")
        with open(self.path + path + ".json", "w+") as f:
            json.dump(data, f)
        return True

    def load_json(self, path):
        print("loading JSON")
        with open(self.path + path + ".json", "r") as f:
            return json.load(f)

    def list_json(self):
        return [x for x in os.listdir(self.path) if x.endswith(".json")]