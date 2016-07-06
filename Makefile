ARCHS = armv7 arm64
THEOS_PACKAGE_DIR_NAME = debs
SKDVERVSION=9.2

export THEOS_DEVICE_IP=rosstafarian.local

include theos/makefiles/common.mk

SOURCE_FILES=$(wildcard tweak/*.m tweak/*.mm tweak/*.x tweak/*.xm)

TWEAK_NAME = StravaActivator
StravaActivator_FILES = $(SOURCE_FILES)
StravaActivator_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk	
SUBPROJECTS += stravaActivatorPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"