#!/usr/bin/env python3
"""
Position Finder for Xactimate Automation

Hover over each UI element and press the indicated key to record its position.
"""

import pyautogui
import keyboard
import time

positions = {}

def record_position(name, key):
    """Wait for keypress then record mouse position."""
    print(f"\n👆 Hover over {name}, then press '{key}'...")
    keyboard.wait(key)
    pos = pyautogui.position()
    positions[name] = pos
    print(f"   ✓ {name}: {pos}")
    time.sleep(0.3)


def main():
    print("=" * 50)
    print("Xactimate Position Finder")
    print("=" * 50)
    print("\nHover over each element and press the indicated key.\n")
    
    record_position("Image Name field", '1')
    record_position("Description field", '2')
    record_position("Next photo (or right edge of current)", '3')
    
    print("\n" + "=" * 50)
    print("RECORDED POSITIONS:")
    print("=" * 50)
    for name, pos in positions.items():
        print(f"{name}: x={pos.x}, y={pos.y}")
    
    print("\n📋 Copy these into photo_description_copier.py:")
    print(f"""
# Click positions (from get_positions.py)
IMAGE_NAME_POS = ({positions.get('Image Name field', (0,0)).x}, {positions.get('Image Name field', (0,0)).y})
DESCRIPTION_POS = ({positions.get('Description field', (0,0)).x}, {positions.get('Description field', (0,0)).y})
NEXT_PHOTO_POS = ({positions.get('Next photo (or right edge of current)', (0,0)).x}, {positions.get('Next photo (or right edge of current)', (0,0)).y})
""")


if __name__ == "__main__":
    main()
