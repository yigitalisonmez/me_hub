from PIL import Image, ImageDraw, ImageFont
import os

def create_slogan(text, text_color, filename):
    # Image size
    width = 400
    height = 100
    
    # Create transparent image
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Load font
    try:
        # Try to use a nice font if available, otherwise default
        font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if not os.path.exists(font_path):
             font_path = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
        
        font = ImageFont.truetype(font_path, 40)
    except:
        font = ImageFont.load_default()

    # Calculate text position to center it
    # getbbox returns (left, top, right, bottom)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (width - text_width) / 2
    y = (height - text_height) / 2
    
    # Draw text
    draw.text((x, y), text, font=font, fill=text_color)
    
    # Save
    img.save(filename)
    print(f"Created {filename}")

# Light mode slogan (Dark text for #F0EBE5 background)
# Text color: #4A3F35 (Dark Brown)
create_slogan("For you.", "#4A3F35", "assets/images/slogan.png")

# Dark mode slogan (Light text for #2C2C2C background)
# Text color: #E0E0E0 (Light Grey)
create_slogan("For you.", "#E0E0E0", "assets/images/slogan_dark.png")
