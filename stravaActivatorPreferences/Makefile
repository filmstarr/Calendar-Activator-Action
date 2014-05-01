include theos/makefiles/common.mk

BUNDLE_NAME = stravaActivatorPreferences
stravaActivatorPreferences_FILES = stravaActivatorPreferences.mm
stravaActivatorPreferences_INSTALL_PATH = /Library/PreferenceBundles
stravaActivatorPreferences_FRAMEWORKS = UIKit
stravaActivatorPreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/stravaActivatorPreferences.plist$(ECHO_END)
