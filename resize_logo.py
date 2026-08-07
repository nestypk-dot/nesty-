from PIL import Image
import os

def add_padding(image_path, output_path, padding_percent=0.2):
    img = Image.open(image_path)
    img = img.convert("RGBA")
    
    width, height = img.size
    new_width = int(width * (1 + 2 * padding_percent))
    new_height = int(height * (1 + 2 * padding_percent))
    
    # Create a new transparent background
    new_img = Image.new("RGBA", (new_width, new_height), (255, 255, 255, 0))
    
    # Calculate position to center the original image
    offset_x = (new_width - width) // 2
    offset_y = (new_height - height) // 2
    
    new_img.paste(img, (offset_x, offset_y), img)
    new_img.save(output_path)
    print(f"Padded image saved to {output_path}")

if __name__ == "__main__":
    src = r"h:\nesty\assets\images\logo.png"
    dst = r"h:\nesty\assets\images\launcher_logo.png"
    if os.path.exists(src):
        add_padding(src, dst, padding_percent=0.3)
    else:
        print(f"Source file not found: {src}")
