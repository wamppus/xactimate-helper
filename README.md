# Xactimate Photo Description Copier

Automates the tedious task of copying Image Name → Description for each photo.

## Setup (Windows)

```bash
pip install pyautogui keyboard
```

## Usage

1. Open Xactimate to the photo panel
2. Select the **first photo** you want to process
3. Click in the **Image Name** field
4. Run: `python photo_description_copier.py`
5. Press **F9** to start
6. Press **F10** to stop
7. Press **Esc** to exit completely

## Safety

- Move mouse to **top-left corner** to emergency abort
- Script pauses between actions so you can see what's happening

## Tuning

If things don't line up right, adjust these in the script:

```python
# How many tabs from Image Name to Description
for _ in range(6):  # Change this number!
    pyautogui.press('tab')

# Timing between actions
CLICK_DELAY = 0.15      # Increase if Xactimate is slow
BETWEEN_PHOTOS = 0.3    # Increase if photos need time to load
```

## Alternative: Click-Based Version

If tab navigation doesn't work, we can use click positions instead. 
Run `python get_positions.py` to record the exact click coordinates for:
- Image Name field
- Description field
- Next photo button/area
