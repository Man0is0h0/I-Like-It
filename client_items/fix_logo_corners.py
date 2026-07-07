"""
Aggressively fix white corners on the iLikeIt logo.
Scans every corner region pixel-by-pixel and makes any pixel transparent
if it's white/near-white, going inward until it hits the actual logo content.
"""

from PIL import Image
import math

def is_near_white(r, g, b, threshold=230):
    return r >= threshold and g >= threshold and b >= threshold

def fix_corners_aggressive(image_path, output_path):
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    pixels = img.load()
    
    print(f"Image size: {width}x{height}")
    
    # For each corner, flood-fill from the corner pixel inward,
    # making any white/near-white pixel transparent.
    # We'll process each quadrant separately.
    
    changed = 0
    # We'll scan from each corner and make white pixels transparent
    # until we hit non-white content. Use a simple approach:
    # for each row/column in the corner area, scan inward until non-white.
    
    corner_size = 30  # Max area to scan from each corner
    
    # TOP-LEFT corner
    for y in range(min(corner_size, height)):
        for x in range(min(corner_size, width)):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            else:
                break  # Stop scanning this row once we hit non-white
    
    # TOP-RIGHT corner
    for y in range(min(corner_size, height)):
        for x in range(width - 1, max(width - corner_size - 1, -1), -1):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            else:
                break
    
    # BOTTOM-LEFT corner
    for y in range(height - 1, max(height - corner_size - 1, -1), -1):
        for x in range(min(corner_size, width)):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            else:
                break
    
    # BOTTOM-RIGHT corner
    for y in range(height - 1, max(height - corner_size - 1, -1), -1):
        for x in range(width - 1, max(width - corner_size - 1, -1), -1):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            else:
                break
    
    print(f"Made {changed} white corner pixels transparent")
    
    # Also scan columns (top-down and bottom-up) to catch any remaining
    # TOP-LEFT corner (column scan)
    for x in range(min(corner_size, width)):
        for y in range(min(corner_size, height)):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            elif a == 0:
                continue  # Skip already-transparent pixels
            else:
                break
    
    # TOP-RIGHT corner (column scan)
    for x in range(width - 1, max(width - corner_size - 1, -1), -1):
        for y in range(min(corner_size, height)):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            elif a == 0:
                continue
            else:
                break
    
    # BOTTOM-LEFT corner (column scan)
    for x in range(min(corner_size, width)):
        for y in range(height - 1, max(height - corner_size - 1, -1), -1):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            elif a == 0:
                continue
            else:
                break
    
    # BOTTOM-RIGHT corner (column scan)
    for x in range(width - 1, max(width - corner_size - 1, -1), -1):
        for y in range(height - 1, max(height - corner_size - 1, -1), -1):
            r, g, b, a = pixels[x, y]
            if a > 0 and is_near_white(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
            elif a == 0:
                continue
            else:
                break
    
    print(f"Total transparent pixels after all passes: {changed}")
    
    img.save(output_path, "PNG")
    print(f"Saved to {output_path}")
    
    # Print some diagnostic info
    pixels = img.load()
    print("\nCorner area diagnostics:")
    print("Top-left 5x5:")
    for y in range(5):
        row = []
        for x in range(5):
            r, g, b, a = pixels[x, y]
            row.append(f"{'T' if a == 0 else 'W' if is_near_white(r,g,b) else 'C'}")
        print(f"  {''.join(row)}")

if __name__ == "__main__":
    fix_corners_aggressive("App iconn.png", "App_icon_final.png")
