import os
from PIL import Image

# 🛠️ CONFIGURATION
ASSET_DIR = r"c:\Users\shuba\Desktop\Med_buddy\mobile\assets\images"
ALPHA_THRESHOLD = 50 
RESIZE_MAX = 800  # Max width/height. Images larger than this will be downscaled.

def hard_alpha_clip(directory):
    print(f"🔧 Starting Resize & Hard Alpha Clip in: {directory}")
    print(f"🎯 Threshold: {ALPHA_THRESHOLD}/255")
    print(f"📏 Max Size: {RESIZE_MAX}px")
    
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.webp'):
                filepath = os.path.join(root, file)
                
                try:
                    with Image.open(filepath) as img:
                        # 1️⃣ RESIZE
                        w, h = img.size
                        original_mode = img.mode
                        
                        modified = False
                        
                        if w > RESIZE_MAX or h > RESIZE_MAX:
                            print(f"   📉 Resizing {file} ({w}x{h} -> {RESIZE_MAX}px)...")
                            img.thumbnail((RESIZE_MAX, RESIZE_MAX), Image.Resampling.LANCZOS)
                            modified = True
                        
                        if img.mode != 'RGBA':
                            img = img.convert("RGBA")
                            
                        # 2️⃣ ALPHA CLIP
                        datas = img.getdata()
                        new_data = []
                        
                        # Check if we need to scan pixels (optimization: if not resized, maybe we skip if clean? No, always clip)
                        # To be safe, we always rebuild data if we want to ensure clip.
                        
                        clipped_pixels = 0
                        for item in datas:
                            # item is (R, G, B, A)
                            if item[3] > 0 and item[3] < ALPHA_THRESHOLD:
                                new_data.append((0, 0, 0, 0))
                                clipped_pixels += 1
                            else:
                                new_data.append(item)

                        if clipped_pixels > 0:
                            modified = True
                            img.putdata(new_data)
                            
                        if modified:
                            img.save(filepath, "WEBP", quality=95)
                            print(f"   ✅ Processed: {file} (Resized: {w>RESIZE_MAX or h>RESIZE_MAX}, Clipped: {clipped_pixels} px)")
                            count += 1
                        else:
                            # print(f" ⏭️ Skipped: {file} (Clean)")
                            pass



                except Exception as e:
                    print(f" ❌ Error processing {file}: {e}")
    
    print(f"\n🎉 Done! Processed {count} files.")

if __name__ == "__main__":
    hard_alpha_clip(ASSET_DIR)
