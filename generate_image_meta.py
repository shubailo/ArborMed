import os
from PIL import Image

ASSET_DIR = r"c:\Users\shuba\Desktop\Med_buddy\mobile\assets\images\furniture"

def generate_meta(directory, output_file):
    print(f"Generating Meta {directory} -> {output_file}")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("// AUTO-GENERATED IMAGE SIZE DATA\n")
        f.write("import 'dart:ui';\n\n")
        f.write("class ImageMeta {\n")
        f.write("  static const Map<String, Size> sizes = {\n")
    
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.lower().endswith('.webp'):
                    filepath = os.path.join(root, file)
                    try:
                        with Image.open(filepath) as img:
                            w, h = img.size
                            f.write(f'    "{file}": Size({w}.0, {h}.0),\n')
                    except:
                        pass
                        
        f.write("  };\n")
        f.write("}\n")

if __name__ == "__main__":
    OUT_PATH = r"c:\Users\shuba\Desktop\Med_buddy\mobile\lib\widgets\cozy\image_meta.dart"
    generate_meta(ASSET_DIR, OUT_PATH)
