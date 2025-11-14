"""
Script to resize and reshape app icon and splash screen images
"""
from PIL import Image
import os

def resize_app_icon(input_path, output_path, size=(1024, 1024)):
    """Resize app icon to square format (1024x1024)"""
    try:
        img = Image.open(input_path)
        
        # Convert to RGB if necessary (for JPEG)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Create a square image with white background
        square_img = Image.new('RGB', size, (255, 255, 255))
        
        # Calculate dimensions to fit the image in the square while maintaining aspect ratio
        img.thumbnail(size, Image.Resampling.LANCZOS)
        
        # Center the image
        x_offset = (size[0] - img.size[0]) // 2
        y_offset = (size[1] - img.size[1]) // 2
        square_img.paste(img, (x_offset, y_offset))
        
        # Save as PNG
        square_img.save(output_path, 'PNG', optimize=True)
        print(f"✅ App icon created: {output_path} ({size[0]}x{size[1]})")
        return True
    except Exception as e:
        print(f"❌ Error processing app icon: {e}")
        return False

def resize_splash_screen(input_path, output_path, size=(1080, 1920), script_dir=None):
    """Resize splash screen to fit within bounds without cropping (1080x1920)"""
    try:
        img = Image.open(input_path)
        
        # Convert to RGBA first to handle transparency and detect black backgrounds
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Calculate aspect ratio
        img_width, img_height = img.size
        target_width, target_height = size
        
        # Calculate scaling to FIT within the target size (not fill) - prevents cropping
        # Use min() to ensure image fits within bounds without cropping
        # Multiply by 2.2 to make the image larger, prioritizing width (120% increase)
        scale = min(target_width / img_width, target_height / img_height) * 2.2
        new_width = int(img_width * scale)
        new_height = int(img_height * scale)
        
        # Allow width to use full target width if needed
        if new_width > target_width:
            # Scale based on width to maximize width usage
            width_scale = target_width / img_width
            new_width = target_width
            new_height = int(img_height * width_scale)
        
        # Ensure height doesn't exceed target (prevent overflow)
        if new_height > target_height:
            # Scale based on height if width-based scaling exceeds height
            height_scale = target_height / img_height
            new_height = target_height
            new_width = int(img_width * height_scale)
        
        # Resize image to fit within bounds (maintains aspect ratio, no cropping)
        img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Convert to RGB for processing - ensure white background
        if img_resized.mode == 'RGBA':
            # If image has transparency, composite it on white background
            img_rgb = Image.new('RGB', (new_width, new_height), (255, 255, 255))
            img_rgb.paste(img_resized, (0, 0), img_resized)
        elif img_resized.mode != 'RGB':
            img_rgb = Image.new('RGB', (new_width, new_height), (255, 255, 255))
            img_rgb.paste(img_resized, (0, 0))
        else:
            img_rgb = img_resized
        
        # Create target size image with white background to match splash screen
        # RGB: 255, 255, 255 = #FFFFFF (white)
        splash_img = Image.new('RGB', size, (255, 255, 255))
        
        # Center the resized image (this ensures no cropping, image fits within bounds)
        x_offset = (target_width - new_width) // 2
        y_offset = (target_height - new_height) // 2
        
        # Paste the image - if it has any transparency or non-white areas, they'll show
        # but the background will be white
        if img_rgb.mode == 'RGBA':
            splash_img.paste(img_rgb, (x_offset, y_offset), img_rgb)
        else:
            splash_img.paste(img_rgb, (x_offset, y_offset))
        
        # Process pixels to ensure edges and any dark/black background areas become white
        # This handles cases where the source image has a dark background
        pixels = splash_img.load()
        edge_threshold = 50  # Pixels from edge to process
        for y in range(size[1]):
            for x in range(size[0]):
                # Check if we're near the edges (frame area)
                is_near_edge = (x < edge_threshold or x > size[0] - edge_threshold or 
                              y < edge_threshold or y > size[1] - edge_threshold)
                
                r, g, b = pixels[x, y]
                brightness = (r + g + b) / 3
                
                # If pixel is very dark (likely background) OR near edge, make it white
                if brightness < 50 or is_near_edge:
                    # For edge pixels, make them white if they're not already very light
                    if is_near_edge and brightness < 240:
                        pixels[x, y] = (255, 255, 255)  # White
                    elif not is_near_edge and brightness < 30:
                        pixels[x, y] = (255, 255, 255)  # White
        
        # Save as PNG (no text - text will be animated in Flutter)
        splash_img.save(output_path, 'PNG', optimize=True)
        print(f"✅ Splash screen created: {output_path} ({size[0]}x{size[1]})")
        print(f"   Source: {img_width}x{img_height}, Fitted to: {new_width}x{new_height} (no cropping)")
        print(f"   Image will be centered with white background (#FFFFFF)")
        print(f"   Text will be animated in Flutter custom splash screen")
        return True
    except Exception as e:
        print(f"❌ Error processing splash screen: {e}")
        return False

if __name__ == "__main__":
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Input files
    icon_input = os.path.join(script_dir, "icon.jpeg")
    splash_input = os.path.join(script_dir, "splash2.jpeg")
    
    # Output files
    icon_output = os.path.join(script_dir, "app_icon.png")
    splash_output = os.path.join(script_dir, "splash.png")
    
    print("🖼️  Processing images...")
    print(f"   Working directory: {script_dir}\n")
    
    # Process app icon
    if os.path.exists(icon_input):
        print(f"📱 Processing app icon: {icon_input}")
        resize_app_icon(icon_input, icon_output)
    else:
        print(f"⚠️  App icon file not found: {icon_input}")
    
    print()
    
    # Process splash screen
    if os.path.exists(splash_input):
        print(f"🎨 Processing splash screen: {splash_input}")
        resize_splash_screen(splash_input, splash_output, script_dir=script_dir)
    else:
        print(f"⚠️  Splash screen file not found: {splash_input}")
    
    print("\n✨ Image processing complete!")
