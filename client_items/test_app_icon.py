from PIL import Image

img = Image.open("c:\\Users\\misal\\OneDrive\\Documents\\I like it\\I-Like-It\\i_like_it\\assets\\app_icon.png").convert("RGBA")
width, height = img.size
print(f"app_icon.png Size: {width}x{height}")

for y in range(0, height, height // 30):
    row = []
    for x in range(0, width, width // 30):
        r, g, b, a = img.getpixel((x, y))
        if a == 0:
            row.append(".") # Transparent
        elif r < 40 and g < 40 and b < 40:
            row.append("#") # Black/dark
        elif r > 200 and g > 200 and b > 200:
            row.append("W") # White
        else:
            row.append("G") # Green/other
    print("".join(row))
