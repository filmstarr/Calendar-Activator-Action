export THEOS_DEVICE_IP=rosstafarian.local

include theos/makefiles/common.mk

ARCHS = armv7 arm64
TARGET = iphone:7.0

TWEAK_NAME = StravaActivator
StravaActivator_FILES = Tweak.xm
StravaActivator_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
	
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"