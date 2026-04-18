ARCHS = arm64 arm64e
TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = Standoff2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Standoff2Cheat
Standoff2Cheat_FILES = Tweak.xm aim.xm esp.xm   # все файлы лежат рядом
Standoff2Cheat_CFLAGS = -fobjc-arc
Standoff2Cheat_PRIVATE_FRAMEWORKS = UIKit CoreGraphics Metal

include $(THEOS_MAKE_PATH)/tweak.mk
