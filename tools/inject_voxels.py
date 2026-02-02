import os

def inject():
    with open('voxels.txt', 'r') as f:
        data = f.read()
    
    dart_content = f"""
// AUTO-GENERATED VOXEL DATA
class VoxelData {{
  static const Map<String, List<List<double>>> data = {data}
}}
"""
    # Fix python print output to valid Dart map syntax?
    # Python printed: { "ac.webp": [ [..], ... ], ... }; 
    # Dart expects: { "ac.webp": [ [..], ... ], ... }; (Similar)
    # But Python Lists are `[...]`. Dart Lists are `[...]`.
    # It should match.
    
    os.makedirs('mobile/lib/widgets/cozy', exist_ok=True)
    with open('mobile/lib/widgets/cozy/voxel_data.dart', 'w') as f:
        f.write(dart_content)
    
    print("Injected voxel_data.dart")

if __name__ == "__main__":
    inject()
