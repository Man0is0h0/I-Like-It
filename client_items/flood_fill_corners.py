from PIL import Image
import collections

def flood_fill_logo(image_path, output_path):
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    pixels = img.load()
    
    # We want to perform a flood fill (BFS) starting from all boundary pixels
    # of the image. Any pixel that is "background" will be made transparent.
    # What is "background"?
    # Typically, background is white/near-white or light grey, or anything that is
    # not the green/dark-green logo.
    # Let's define a function to check if a pixel is logo or background.
    def is_logo_pixel(r, g, b, a):
        if a == 0:
            return False
        # The logo is green or dark green.
        # Let's check if the pixel matches the green/dark-green profile:
        # Green has high G compared to R and B.
        # Dark green has G > R and G > B, e.g. (2, 116, 82)
        # Let's check if it's green-ish:
        is_greenish = (g > r + 10) and (g > b + 10)
        # Or maybe it is a dark outline/shadow pixel:
        # We want to keep anything that is not white/light-grey.
        # White/light-grey has r, g, b all relatively high and close to each other.
        is_white_or_grey = (r > 180 and g > 180 and b > 180)
        
        return is_greenish or (not is_white_or_grey and a > 0)

    # Queue for BFS
    queue = collections.deque()
    visited = set()
    
    # Add all boundary pixels to the queue
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
        visited.add((x, 0))
        visited.add((x, height - 1))
    for y in range(1, height - 1):
        queue.append((0, y))
        queue.append((width - 1, y))
        visited.add((0, y))
        visited.add((width - 1, y))
        
    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        
        # If it's not a logo pixel, make it transparent and propagate
        if not is_logo_pixel(r, g, b, a):
            pixels[x, y] = (0, 0, 0, 0)
            
            # Check 4-neighbors
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    if (nx, ny) not in visited:
                        visited.add((nx, ny))
                        queue.append((nx, ny))
                        
    img.save(output_path, "PNG")
    print(f"Flood fill completed. Saved to {output_path}")

if __name__ == "__main__":
    flood_fill_logo("c:\\Users\\misal\\OneDrive\\Documents\\I like it\\I-Like-It\\client_items\\App iconn.png", "c:\\Users\\misal\\OneDrive\\Documents\\I like it\\I-Like-It\\client_items\\App_icon_final.png")
