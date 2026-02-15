import os
from PIL import Image

# 🛠️ CONFIGURATION
ASSET_DIR = r"c:\Users\shuba\Desktop\Med_buddy\mobile\assets\images"
ALPHA_THRESHOLD = 50 
RESIZE_MAX = 1000  # Updated to 1000px as per user request

def hard_alpha_clip(directory):
    print(f"🔧 Starting Resize & Hard Alpha Clip in: {directory}")
    print(f"🎯 Threshold: {ALPHA_THRESHOLD}/255")
    print(f"📏 Max Size: {RESIZE_MAX}px")
    
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            is_png = file.lower().endswith('.png')
            is_webp = file.lower().endswith('.webp')
            
            if is_png or is_webp:
                filepath = os.path.join(root, file)
                
                try:
                    with Image.open(filepath) as img:
                        # 1️⃣ RESIZE
                        w, h = img.size
                        
                        modified = False
                        
                        if w > RESIZE_MAX or h > RESIZE_MAX:
                            print(f"   📉 Resizing {file} ({w}x{h} -> {RESIZE_MAX}px)...")
                            img.thumbnail((RESIZE_MAX, RESIZE_MAX), Image.Resampling.LANCZOS)
                            # Update dimensions after resize
                            w, h = img.size
                            modified = True
                        
                        if img.mode != 'RGBA':
                            img = img.convert("RGBA")
                            
                        # 2️⃣ ALPHA CLIP & STAR REMOVAL
                        datas = img.getdata()
                        new_data = []
                        
                        clipped_pixels = 0
                        star_pixels = 0
                        
                        for y in range(h):
                            for x in range(w):
                                idx = y * w + x
                                item = datas[idx]
                                
                                # STAR REMOVAL ZONE: Bottom-Right 150x150
                                # Check if we are in the kill zone
                                if x > w - 150 and y > h - 150 and item[3] > 0:
                                    # Erase star
                                    new_data.append((0, 0, 0, 0))
                                    star_pixels += 1
                                    modified = True
                                    continue # Skip alpha check
                                    
                                # ALPHA CLIP
                                # item is (R, G, B, A)
                                if item[3] > 0 and item[3] < ALPHA_THRESHOLD:
                                    new_data.append((0, 0, 0, 0))
                                    clipped_pixels += 1
                                else:
                                    new_data.append(item)

                        if clipped_pixels > 0 or star_pixels > 0:
                            img.putdata(new_data)
                            modified = True
                            
                        # SAVE
                        if is_png:
                            new_path = os.path.splitext(filepath)[0] + ".webp"
                            img.save(new_path, "WEBP", quality=95)
                            print(f"   🔄 Converted: {file} -> {os.path.basename(new_path)} (Risize: {w>RESIZE_MAX or h>RESIZE_MAX}, Clipped: {clipped_pixels}, Star: {star_pixels})")
                            modified = True 
                            count += 1
                        elif modified:
                            img.save(filepath, "WEBP", quality=95)
                            print(f"   ✅ Processed: {file} (Resized: {w>RESIZE_MAX or h>RESIZE_MAX}, Clipped: {clipped_pixels}, Star: {star_pixels})")
                            count += 1
                        else:
                             pass
                             
                except Exception as e:
                    print(f" ❌ Error processing {file}: {e}")

                # Post-process cleanup for PNGs
                if is_png:
                    try:
                        os.remove(filepath)
                        # print(f"   🗑️ Removed source: {file}")
                    except Exception as e:
                        print(f"   ⚠️ Could not remove source {file}: {e}")
    
    print(f"\n🎉 Done! Processed {count} files.")

if __name__ == "__main__":
    hard_alpha_clip(ASSET_DIR)
