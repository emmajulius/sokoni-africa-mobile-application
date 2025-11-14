#!/usr/bin/env python3
"""
Script to resize and reshape images for app icon and splash screen.
"""

from PIL import Image
import os

def process_app_icon(input_path, output_path, size=1024):
    """Process app icon: make it square, resize to 1024x1024, convert to PNG."""
    print(f"Processing app icon: {input_path}")
    
    # Open image
    img = Image.open(input_path)
    print(f"  Original size: {img.size}")
    
    # Convert to RGB if necessary (for JPEG compatibility)
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Get dimensions
    width, height = img.size
    
    # Make it square by cropping from center
    if width != height:
        # Calculate crop box (center crop)
        size_min = min(width, height)
        left = (width - size_min) // 2
        top = (height - size_min) // 2
        right = left + size_min
        bottom = top + size_min
        img = img.crop((left, top, right, bottom))
        print(f"  Cropped to square: {img.size}")
    
    # Resize to target size
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    print(f"  Resized to: {img.size}")
    
    # Save as PNG
    img.save(output_path, 'PNG', optimize=True)
    print(f"  Saved to: {output_path}")
    print(f"  ✅ App icon processed successfully!\n")

def process_splash_screen(input_path, output_path, width=1080, height=1920):
    """Process splash screen: resize to 1080x1920 (portrait), convert to PNG."""
    print(f"Processing splash screen: {input_path}")
    
    # Open image
    img = Image.open(input_path)
    print(f"  Original size: {img.size}")
    
    # Convert to RGB if necessary
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Get dimensions
    orig_width, orig_height = img.size
    orig_ratio = orig_width / orig_height
    target_ratio = width / height
    
    # Resize maintaining aspect ratio, then crop if needed
    if orig_ratio > target_ratio:
        # Image is wider than target - fit to height, crop width
        new_height = height
        new_width = int(height * orig_ratio)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        # Crop from center
        left = (new_width - width) // 2
        img = img.crop((left, 0, left + width, height))
    else:
        # Image is taller than target - fit to width, crop height
        new_width = width
        new_height = int(width / orig_ratio)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        # Crop from center
        top = (new_height - height) // 2
        img = img.crop((0, top, width, top + height))
    
    print(f"  Resized and cropped to: {img.size}")
    
    # Save as PNG
    img.save(output_path, 'PNG', optimize=True)
    print(f"  Saved to: {output_path}")
    print(f"  ✅ Splash screen processed successfully!\n")

def main():
    # Paths
    assets_dir = "assets/images"
    icon_input = os.path.join(assets_dir, "icon.jpeg")
    splash_input = os.path.join(assets_dir, "splash.jpeg")
    icon_output = os.path.join(assets_dir, "app_icon.png")
    splash_output = os.path.join(assets_dir, "splash.png")
    
    # Check if input files exist
    if not os.path.exists(icon_input):
        print(f"❌ Error: {icon_input} not found!")
        return
    
    if not os.path.exists(splash_input):
        print(f"❌ Error: {splash_input} not found!")
        return
    
    # Process images
    try:
        process_app_icon(icon_input, icon_output)
        process_splash_screen(splash_input, splash_output)
        print("✅ All images processed successfully!")
        print(f"\nGenerated files:")
        print(f"  - {icon_output} (1024x1024)")
        print(f"  - {splash_output} (1080x1920)")
    except Exception as e:
        print(f"❌ Error processing images: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

