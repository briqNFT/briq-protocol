class IStorage:
    def __init__(self) -> None:
        pass
    
    def store_json(self, path, data):
        pass

    def load_json(self, path):
        pass

    def has_json(self, path):
        pass

    def list_files(self, path):
        pass

def get_storage():
    try:
        from .cloud_storage import CloudStorage
        return CloudStorage()
    except:
        from .file_storage import FileStorage
        print("Falling back to local storage")
        return FileStorage()
