import mania2json

print("Package contents:")
print(dir(mania2json))

print("\nTrying to find the right function...")
for item in dir(mania2json):
    if not item.startswith('_'):
        print(f"  - {item}")