#import <Preferences/Preferences.h>

@interface preferencesListController: PSListController {
}
@end

@implementation preferencesListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"preferences" target:self] retain];
	}
	return _specifiers;
}

- (void)openTwitterProfile {
	if ([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"tweetbot:///user_profile/deviationalist"]];
	} else if ([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=deviationalist"]];
	} else if ([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"twitter://user?screen_name=deviationalist"]];
	} else {
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"http://twitter.com/intent/follow?screen_name=deviationalist"]];
	}
}

- (void)openGitHubProfile {
	[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"http://github.com/filmstarr"]];
}

@end

// vim:ft=objc
