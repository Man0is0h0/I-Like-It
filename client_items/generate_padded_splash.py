from PIL import Image

def create_padded_splash(logo_path, output_path, canvas_size=(2048, 2048), target_logo_width=1000):
    # Load the logo image
    logo = Image.open(logo_path).convert("RGBA")
    
    # Find bounding box of non-black content
    # We define non-black as R, G, or B greater than 10
    width, height = logo.size
    pixels = logo.load()
    
    left, top, right, bottom = width, height, 0, 0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if r > 10 or g > 10 or b > 10:
                if x < left: left = x
                if x > right: right = x
                if y < top: top = y
                if y > bottom: bottom = y
                
    # If no non-black pixels found, use the entire image
    if left >= right or top >= bottom:
        left, top, right, bottom = 0, 0, width, height
        
    # Crop the logo
    cropped_logo = logo.crop((left, top, right, bottom))
    cropped_w, cropped_h = cropped_logo.size
    print(f"Cropped logo size: {cropped_w}x{cropped_h}")
    
    # Calculate new height to maintain aspect ratio
    aspect_ratio = cropped_h / cropped_w
    target_logo_height = int(target_logo_width * aspect_ratio)
    
    # Resize the cropped logo
    resized_logo = cropped_logo.resize((target_logo_width, target_logo_height), Image.Resampling.LANCZOS)
    print(f"Resized logo to: {target_logo_width}x{target_logo_height}")
    
    # Create the canvas (pure black background)
    canvas = Image.new("RGB", canvas_size, (0, 0, 0))
    
    # Calculate position to center the logo
    paste_x = (canvas_size[0] - target_logo_width) // 2
    paste_y = (canvas_size[1] - target_logo_height) // 2
    
    # Paste the logo onto the canvas
    # Use alpha channel of resized_logo as mask so it blends nicely (or just paste directly if no transparency)
    canvas.paste(resized_logo, (paste_x, paste_y), resized_logo)
    
    # Save the output image
    canvas.save(output_path, "JPEG", quality=95)
    print(f"Saved padded splash to {output_path}")

if __name__ == "__main__":
    # We will generate the main native splash image (wide aspect/center padded)
    create_padded_splash(
        logo_path="client_items/app logo 2.png",
        output_path="i_like_it/assets/native_splash.jpeg",
        canvas_size=(2048, 2048),
        target_logo_width=950  # 950px out of 2048px is about 46% width, so it will look beautifully proportioned and won't get cut off
    )
    
    # We will also create a version for Android 12 (512x512 canvas, smaller logo)
    create_padded_splash(
        logo_path="client_items/app logo 2.png",
        output_path="i_like_it/assets/native_splash_android12.jpeg",
        canvas_size=(512, 512),
        target_logo_width=320  # 320px out of 512px is about 62% width
    )
    
    # Save a PNG version to replace assets/splash_logo.png as well
    # Let's save a 2048x2048 PNG version
    logo = Image.open("client_items/app logo 2.png").convert("RGBA")
    # Resize to 950px width
    cropped_logo = logo.crop(logo.getbbox())
    aspect_ratio = cropped_logo.height / cropped_logo.width
    target_logo_height = int(950 * aspect_ratio)
    resized_logo = cropped_logo.resize((950, target_logo_height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (2048, 2048), (0, 0, 0, 255))
    canvas.paste(resized_logo, ((2048-950)//2, (2048-target_logo_height)//2), resized_logo)
    canvas.save("i_like_it/assets/splash_logo.png", "PNG")
    print("Saved PNG version to assets/splash_logo.png")
