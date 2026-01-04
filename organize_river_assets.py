import os
import shutil
import json
import subprocess

SOURCE_DIR = "New Assets"
TARGET_BASE = "monch/Assets.xcassets/River"

MAPPING = {
    "Icons": [
        "meal_kawaii.png", "coffee_kawaii.png", "tea_kawaii.png", 
        "workout_kawaii.png", "sleep_kawaii.png", 
        "insight_spike_kawaii.png", "insight_recovery_kawaii.png", 
        "supplement_kawaii.png"
    ],
    "Textures": [
        "river_texture.png", "sand_texture.png"
    ],
    "Ambient": [
        "lily_pad.png", "lily_flower.png", "splash_particle.png", 
        "fish_blip.png", "dragonfly.png"
    ],
    "Decorations": [
        "decoration_sun.png", "decoration_flower.png", 
        "decoration_moon.png", "decoration_pebbles.png"
    ]
}

# Target sizes in pts (will be multiplied by 1, 2, 3 for px)
TARGET_SIZES = {
    "meal_kawaii.png": 48,
    "coffee_kawaii.png": 48,
    "tea_kawaii.png": 48,
    "workout_kawaii.png": 48,
    "sleep_kawaii.png": 48,
    "insight_spike_kawaii.png": 48,
    "insight_recovery_kawaii.png": 48,
    "supplement_kawaii.png": 48,
    "river_texture.png": 512,
    "sand_texture.png": 256,
    "lily_pad.png": 48,
    "lily_flower.png": 32,
    "splash_particle.png": 12,
    "fish_blip.png": 24,
    "dragonfly.png": 24,
    "decoration_sun.png": 24,
    "decoration_flower.png": 20,
    "decoration_moon.png": 24,
    "decoration_pebbles.png": 32
}

def create_contents_json(filename_base):
    contents = {
        "images": [
            {
                "idiom": "universal",
                "scale": "1x",
                "filename": f"{filename_base}.png"
            },
            {
                "idiom": "universal",
                "scale": "2x",
                "filename": f"{filename_base}@2x.png"
            },
            {
                "idiom": "universal",
                "scale": "3x",
                "filename": f"{filename_base}@3x.png"
            }
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }
    return contents

def process_image(src_path, imageset_dir, filename_base, target_pt):
    # Base filename in imageset
    target_3x = os.path.join(imageset_dir, f"{filename_base}@3x.png")
    target_2x = os.path.join(imageset_dir, f"{filename_base}@2x.png")
    target_1x = os.path.join(imageset_dir, f"{filename_base}.png")
    
    # Resize using sips
    # 3x
    size_3x = target_pt * 3
    subprocess.run(["sips", "-Z", str(size_3x), src_path, "--out", target_3x])
    # 2x
    size_2x = target_pt * 2
    subprocess.run(["sips", "-Z", str(size_2x), src_path, "--out", target_2x])
    # 1x
    size_1x = target_pt
    subprocess.run(["sips", "-Z", str(size_1x), src_path, "--out", target_1x])

def main():
    if not os.path.exists(TARGET_BASE):
        os.makedirs(TARGET_BASE)
        
    for category, files in MAPPING.items():
        cat_dir = os.path.join(TARGET_BASE, category)
        if not os.path.exists(cat_dir):
            os.makedirs(cat_dir)
            
        for filename in files:
            src_path = os.path.join(SOURCE_DIR, filename)
            if not os.path.exists(src_path):
                print(f"Skipping {filename}, not found in {SOURCE_DIR}")
                continue
                
            name_base = filename.replace(".png", "")
            imageset_dir = os.path.join(cat_dir, f"{name_base}.imageset")
            if not os.path.exists(imageset_dir):
                os.makedirs(imageset_dir)
                
            # Create Contents.json
            with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
                json.dump(create_contents_json(name_base), f, indent=2)
                
            # Process and Resize
            target_pt = TARGET_SIZES.get(filename, 48)
            process_image(src_path, imageset_dir, name_base, target_pt)
            print(f"Processed {filename} -> {imageset_dir}")

if __name__ == "__main__":
    main()
