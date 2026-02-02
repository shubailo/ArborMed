import os
from PIL import Image

ASSET_DIR = r"c:\Users\shuba\Desktop\Med_buddy\mobile\assets\images\furniture"

def analyze_hitboxes(directory):
    print(f"Analyzing Hitboxes in: {directory}")
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.webp'):
                filepath = os.path.join(root, file)
                try:
                    with Image.open(filepath) as img:
                        if img.mode != 'RGBA':
                            img = img.convert('RGBA')
                        
                        bbox = img.getbbox() # Returns (left, upper, right, lower)
                        
                        if bbox:
                            left, upper, right, lower = bbox
                            width = right - left
                            height = lower - upper
                            print(f"{file}: Size={img.size}, VolatileBox=[L:{left}, T:{upper}, W:{width}, H:{height}]")
                        else:
                            print(f"WARN {file}: Is completely transparent!")
                except Exception as e:
                    print(f"ERROR: {file} - {e}")

if __name__ == "__main__":
    analyze_hitboxes(ASSET_DIR)
