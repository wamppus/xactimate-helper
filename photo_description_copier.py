#!/usr/bin/env python3
"""
Xactimate Photo Description Copier

Automates copying Image Name → Description for each photo.

Usage:
1. Open Xactimate to the photo panel
2. Select the FIRST photo you want to process
3. Run this script
4. Press F9 to start, F10 to stop

Requires: pip install pyautogui keyboard
"""

import pyautogui
import keyboard
import time

# Safety settings
pyautogui.PAUSE = 0.1  # Pause between actions
pyautogui.FAILSAFE = True  # Move mouse to corner to abort

# Timing (adjust if Xactimate is slow)
CLICK_DELAY = 0.15
BETWEEN_PHOTOS = 0.3

# Track state
running = False
processed = 0


def copy_name_to_description():
    """Copy Image Name field to Description field for current photo."""
    global processed
    
    # Triple-click Image Name field to select all (assuming cursor is there)
    # Or we can use Ctrl+A
    pyautogui.hotkey('ctrl', 'a')
    time.sleep(CLICK_DELAY)
    
    # Copy
    pyautogui.hotkey('ctrl', 'c')
    time.sleep(CLICK_DELAY)
    
    # Tab to Description field (adjust tab count if needed)
    # Based on the UI: Image Name → Date Taken → Taken By → Room → Exclude → Description
    # That's about 5-6 tabs, but there might be a shortcut
    # Let's try tabbing - adjust this number!
    for _ in range(6):
        pyautogui.press('tab')
        time.sleep(0.05)
    
    # Paste
    pyautogui.hotkey('ctrl', 'v')
    time.sleep(CLICK_DELAY)
    
    processed += 1
    print(f"✓ Photo {processed} done")


def next_photo():
    """Move to next photo in the grid."""
    # Try Right arrow key first
    pyautogui.press('right')
    time.sleep(BETWEEN_PHOTOS)


def run_loop():
    """Main automation loop."""
    global running, processed
    
    print("\n🚀 Starting automation...")
    print("Press F10 to stop\n")
    
    processed = 0
    
    while running:
        copy_name_to_description()
        next_photo()
        
        # Small delay to let UI catch up
        time.sleep(BETWEEN_PHOTOS)
        
        # Check if we should stop
        if not running:
            break
    
    print(f"\n✅ Done! Processed {processed} photos")


def start_automation():
    """Start the automation."""
    global running
    if not running:
        running = True
        run_loop()


def stop_automation():
    """Stop the automation."""
    global running
    running = False
    print("\n⏹ Stopping...")


def main():
    print("=" * 50)
    print("Xactimate Photo Description Copier")
    print("=" * 50)
    print("\nInstructions:")
    print("1. Open Xactimate photo panel")
    print("2. Click on the FIRST photo to process")
    print("3. Click in the Image Name field")
    print("4. Press F9 to START")
    print("5. Press F10 to STOP")
    print("\nMove mouse to top-left corner to emergency abort")
    print("=" * 50)
    
    # Register hotkeys
    keyboard.add_hotkey('F9', start_automation)
    keyboard.add_hotkey('F10', stop_automation)
    
    print("\n⏳ Waiting... Press F9 to start")
    
    # Keep script running
    keyboard.wait('esc')  # Press Esc to fully exit


if __name__ == "__main__":
    main()
