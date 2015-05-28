import os
import sys
import shutil
from PIL import Image

ICONS_SET_SRC_PATH = "resources/AppIcon.appiconset"
ICONS_SET_DEST_PATH = "output/AppIcon.appiconset"
#SRC_ICON_IMAGE = "resources/monkey_app_icon.jpg"
#SRC_ICON_IMAGE = "resources/homage_app_icon.png"
#SRC_ICON_IMAGE = "resources/emo app icon 1024.png"
#SRC_ICON_IMAGE = "resources/emuAppIcon.png"
#SRC_ICON_IMAGE = "resources/emuAppIconMsgr.png"
#SRC_ICON_IMAGE = "resources/EmuIcon.png"
SRC_ICON_IMAGE = "resources/BlueEmuIcon.png"

IGNORE_PATTERNS = shutil.ignore_patterns(('*.DS_*'))

def make_icons_folder(src, dest):
    # Remove output folder if already exists
    try:
        shutil.rmtree(ICONS_SET_DEST_PATH)
    except:
        pass

    # Create the destination output folder and copy all files
    shutil.copytree(ICONS_SET_SRC_PATH, ICONS_SET_DEST_PATH, ignore=IGNORE_PATTERNS)

    # Read the source big image
    src_image = Image.open(SRC_ICON_IMAGE)
    print "Original image size:",
    print src_image.size

    # iterate all images in the output folder.
    # Create re sized images from the source image, to match the size of
    # images in the destination folder.
    icons = os.listdir(ICONS_SET_DEST_PATH)
    for icon in icons:
        if not icon.endswith('png'):
            continue

        # read the destination icon
        dest_icon = Image.open(os.path.join(ICONS_SET_DEST_PATH, icon))

        # get the size of the dest icon
        w, h = dest_icon.size
        print "%s,%s --> %s" % (w, h, icon)
        img = src_image.resize((w, h), Image.ANTIALIAS)
        img.save(os.path.join(ICONS_SET_DEST_PATH, icon))

# The script
if __name__ == '__main__':
    make_icons_folder(src=ICONS_SET_SRC_PATH, dest=ICONS_SET_DEST_PATH)
