import os
from PIL import Image

ASSET_DIR = r"c:\Users\shuba\Desktop\Med_buddy\mobile\assets\images\furniture"
GRID_SIZE = 25 # Tighter 25px blocks

def generate_voxels(directory, output_file):
    print(f"Generating Voxels from {directory} -> {output_file}")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("// AUTO-GENERATED VOXEL DATA\n")
        f.write("class VoxelData {\n")
        f.write("  static const Map<String, List<List<double>>> data = {\n")
    
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.lower().endswith('.webp'):
                    filepath = os.path.join(root, file)
                    try:
                        with Image.open(filepath) as img:
                            if img.mode != 'RGBA':
                                img = img.convert('RGBA')
                            
                            width, height = img.size
                            rects = []
                            pixels = img.load() # Access pixel data directly
                            
                            # Scan Grid
                            for y in range(0, height, GRID_SIZE):
                                for x in range(0, width, GRID_SIZE):
                                    # Check this block for density
                                    # Only add if we have enough "solid" pixels
                                    box_w = min(x + GRID_SIZE, width) - x
                                    box_h = min(y + GRID_SIZE, height) - y
                                    
                                    visible_count = 0
                                    total_pixels = box_w * box_h
                                    
                                    # Optimization: Don't scan every pixel if not needed? 
                                    # Actually 25x25 is small (625 pixels). Fast enough to scan.
                                    has_content = False
                                    for by in range(y, y + box_h, 2): # Step 2 for speed
                                        for bx in range(x, x + box_w, 2):
                                            if pixels[bx, by][3] > 20: # Alpha Threshold
                                                visible_count += 1
                                    
                                    # Threshold: If > 5% of scanned pixels are visible
                                    # (Scanning 1/4th of pixels, so visible_count is roughly 1/4th of actual)
                                    # Let's say we need ~2% coverage of the 'region' to prevent empty-ish blocks
                                    if visible_count > 2: 
                                        rects.append(f"[{x}.0, {y}.0, {box_w}.0, {box_h}.0]")
                            
                            if rects:
                                f.write(f'    "{file}": [\n')
                                # Write in chunks to avoid massive lines? No, Dart can handle it if no null bytes.
                                # Let's format nicely.
                                f.write(f'      {", ".join(rects)},\n')
                                f.write("    ],\n")
                                
                    except Exception as e:
                        print(f"Error {file}: {e}")
                        
        f.write("  };\n")
        f.write("}\n")
    print("✅ Done!")

if __name__ == "__main__":
    OUT_PATH = r"c:\Users\shuba\Desktop\Med_buddy\mobile\lib\widgets\cozy\voxel_data.dart"
    generate_voxels(ASSET_DIR, OUT_PATH)
