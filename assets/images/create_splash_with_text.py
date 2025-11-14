"""
Script to create a splash screen image with text "Connecting Africa Through Trade and Trust"
This will be used for the native splash screen
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_splash_with_text(input_path, output_path, size=(1080, 1920)):
    """Create splash screen with image and text below it"""
    try:
        # Open the original splash image
        img = Image.open(input_path)
        
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Calculate aspect ratio and resize image to fit in upper portion
        img_width, img_height = img.size
        target_width, target_height = size
        
        # Reserve space for text at the bottom (about 15% of height)
        image_area_height = int(target_height * 0.75)  # 75% for image
        text_area_height = target_height - image_area_height  # 25% for text
        
        # Calculate scaling to fit image in the image area
        scale = min(target_width / img_width, image_area_height / img_height) * 1.3
        new_width = int(img_width * scale)
        new_height = int(img_height * scale)
        
        # Ensure scaled size doesn't exceed bounds
        if new_width > target_width:
            new_width = target_width
        if new_height > image_area_height:
            new_height = image_area_height
        
        # Resize image
        img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create final image with white background
        splash_img = Image.new('RGB', size, (255, 255, 255))
        
        # Center the image in the upper portion
        x_offset = (target_width - new_width) // 2
        y_offset = (image_area_height - new_height) // 2
        splash_img.paste(img_resized, (x_offset, y_offset))
        
        # Add text below the image
        draw = ImageDraw.Draw(splash_img)
        text = "Connecting Africa Through Trade and Trust"
        
        # Try to use a nice font, fallback to default if not available
        try:
            # Try to use a system font (adjust path for your system)
            # For Windows, you might use: "C:/Windows/Fonts/arial.ttf"
            # For cross-platform, we'll use default font
            font_size = 48
            try:
                # Try to load a bold font
                font = ImageFont.truetype("arial.ttf", font_size)
            except:
                try:
                    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", font_size)
                except:
                    font = ImageFont.load_default()
        except:
            font = ImageFont.load_default()
        
        # Calculate text position (centered horizontally, in text area)
        # Get text bounding box
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        # Position text in the text area (centered)
        text_x = (target_width - text_width) // 2
        text_y = image_area_height + (text_area_height - text_height) // 2
        
        # Draw text with shadow for better visibility
        # Shadow
        shadow_offset = 2
        draw.text(
            (text_x + shadow_offset, text_y + shadow_offset),
            text,
            font=font,
            fill=(200, 200, 200)  # Light gray shadow
        )
        # Main text
        draw.text(
            (text_x, text_y),
            text,
            font=font,
            fill=(26, 26, 26)  # Dark gray/black text (#1A1A1A)
        )
        
        # Save the image
        splash_img.save(output_path, 'PNG', optimize=True)
        print(f"✅ Splash screen with text created: {output_path} ({size[0]}x{size[1]})")
        print(f"   Text: '{text}'")
        return True
    except Exception as e:
        print(f"❌ Error creating splash with text: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Input file (current splash.png)
    splash_input = os.path.join(script_dir, "splash.png")
    
    # Output file (new splash with text)
    splash_output = os.path.join(script_dir, "splash_with_text.png")
    
    print("🖼️  Creating splash screen with text...")
    print(f"   Working directory: {script_dir}\n")
    
    if os.path.exists(splash_input):
        print(f"📱 Processing splash screen: {splash_input}")
        if create_splash_with_text(splash_input, splash_output):
            print(f"\n✅ Success! New splash image created: {splash_output}")
            print("   You can now use this image for the native splash screen.")
        else:
            print("\n❌ Failed to create splash with text")
    else:
        print(f"⚠️  Splash screen file not found: {splash_input}")

