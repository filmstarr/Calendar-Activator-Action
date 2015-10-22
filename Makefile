THEOS_PACKAGE_DIR_NAME = debs

export THEOS_DEVICE_IP=rosstafarian.local

include theos/makefiles/common.mk

ARCHS = armv7 armv7s arm64
TARGET = iphone:9.0

TWEAK_NAME = StravaActivator
StravaActivator_FILES = Tweak.xm
StravaActivator_FRAMEWORKS = UIKit
StravaActivator_LDFLAGS += -Wl,-segalign,4000
StravaActivator_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/tweak.mk
	
SUBPROJECTS += stravaActivatorPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"