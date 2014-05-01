#import <libactivator/libactivator.h>
#import <notify.h>
#import <substrate.h>
#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIKit.h>
#import "StravaHeaders.h"

#define RecordingRequestedNotification "com.filmstarr.stravaactivator.recordingRequestedNotification"
#define RecordingSucceededNotification "com.filmstarr.stravaactivator.recordingSucceededNotification"
#define RecordingFailedNotification "com.filmstarr.stravaactivator.recordingFailedNotification"
#define RecordingProcessedNotification "com.filmstarr.stravaactivator.recordingProcessedNotification"
#define ToggleRecordingNotification "com.filmstarr.stravaractivator.toggleNotification"
#define StartRecordingNotification "com.filmstarr.stravaractivator.startNotification"
#define StopRecordingNotification "com.filmstarr.stravaractivator.stopNotification"

static StravaAppDelegate *strava = nil;
static BOOL wasLaunchedWithActivator = NO;
static BOOL recordingRequestHandled = YES;
static BOOL isToggling = NO;
static BOOL isStarting = NO;
static BOOL isStopping = NO;


%group springBoardHooks

%hook SBLockScreenManager
-(void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
	%orig;
	if (wasLaunchedWithActivator) {
		SBApplication *stravaSBApplication = [(SBApplicationController *) [objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.strava.stravaride"];
		if (stravaSBApplication) {
			SBApplication *frontApp = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
			if ([[frontApp displayIdentifier] isEqualToString: @"com.strava.stravaride"]) {
				notify_post(RecordingRequestedNotification);
			}
			else {
				[(SBUIController *) [objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:stravaSBApplication];
			}
		}
	}
}
-(void)_lockScreenDimmed:(id)dimmed {
	wasLaunchedWithActivator = NO;
	%orig;
}
%end

%hook SBLockScreenViewController
-(void)passcodeLockViewEmergencyCallButtonPressed:(id)pressed {
	wasLaunchedWithActivator = NO;
	%orig;
}
-(void)passcodeLockViewCancelButtonPressed:(id)pressed {
	wasLaunchedWithActivator = NO;
	%orig;
}
%end

%end


%group stravaHooks

%hook StravaAppDelegate
- (void)applicationDidBecomeActive:(id)fp8 {
	%orig;
	strava = self;
	notify_post(RecordingRequestedNotification);
}
- (void)setAppInitialized:(BOOL)fp8 {
	%orig;
	if (fp8) {
		notify_post(RecordingRequestedNotification);
	}
}
%end

%end


static void recordingRequest (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (wasLaunchedWithActivator && !recordingRequestHandled) {
		recordingRequestHandled = YES;
		if (isToggling) {
			notify_post(ToggleRecordingNotification);
		}
		else if (isStarting) {
			notify_post(StartRecordingNotification);
		}
		else if (isStopping) {
			notify_post(StopRecordingNotification);
		}
	}
}

static void processRecordingRequest (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if ([strava isAppInitialized])
	{
		//Open recording tab
		[strava selectTab:0];

		//Perform activator action
		NewActivityViewController *activityRecordingPageViewController = [[strava recordPageViewController] activityRecordingPageViewController];
		if (name == CFSTR(ToggleRecordingNotification)) {
			[activityRecordingPageViewController toggleRecording:nil];
		}
		else if (name == CFSTR(StartRecordingNotification)) {
			if (![[activityRecordingPageViewController recordButton] isRecording]) {
				[activityRecordingPageViewController toggleRecording:nil];
			}
		}
		else if (name == CFSTR(StopRecordingNotification)) {
			if ([[activityRecordingPageViewController recordButton] isRecording]) {
				[activityRecordingPageViewController toggleRecording:nil];
			}	
		}
		notify_post(RecordingSucceededNotification);
	}
	else {
		notify_post(RecordingFailedNotification);
	}
}

static void recordingProcessed (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (name == CFSTR(RecordingSucceededNotification)) {
		recordingRequestHandled = YES;
		wasLaunchedWithActivator = NO;
		isToggling = NO;
		isStarting = NO;
		isStopping = NO;
	}
	else if (name == CFSTR(RecordingFailedNotification)) {
		recordingRequestHandled = NO;
		wasLaunchedWithActivator = YES;
	}
}

%ctor {
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, recordingRequest, CFSTR(RecordingRequestedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, recordingProcessed, CFSTR(RecordingSucceededNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, recordingProcessed, CFSTR(RecordingFailedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		%init(springBoardHooks);
	}
	else if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.strava.stravaride"]) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, processRecordingRequest, CFSTR(ToggleRecordingNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, processRecordingRequest, CFSTR(StartRecordingNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, processRecordingRequest, CFSTR(StopRecordingNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		%init(stravaHooks);
	}
}


@interface LAStravaToggleActivator : NSObject<LAListener> {}
@end

@implementation LAStravaToggleActivator

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	SBApplication *stravaSBApplication = [(SBApplicationController *) [objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.strava.stravaride"];

	if(stravaSBApplication) {
		wasLaunchedWithActivator = YES;
		recordingRequestHandled = NO;
		isToggling = YES;
			
        SBLockScreenManager *sbLockScreenManager = (SBLockScreenManager*) [%c(SBLockScreenManager) sharedInstance];
        if ([sbLockScreenManager isUILocked]){
            [sbLockScreenManager unlockUIFromSource:0 withOptions:nil];
        }
		else
		{
			SBApplication *frontApp = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
			if ([[frontApp displayIdentifier] isEqualToString: @"com.strava.stravaride"]) {
				notify_post(RecordingRequestedNotification);
			}
			else {
				[(SBUIController *) [objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:stravaSBApplication];
			}
		}
	}
	else {
	    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Strava Activator" message:@"Strava must be installed to use Strava Activator." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"App Store", nil];
	    [error show];
	    [error release];
	}
		
	[event setHandled:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 1) {
	   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/strava-running-cycling-gps/id426826309"]];
	}
}

+ (void)load {
	if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
	{
	  [[%c(LAActivator) sharedInstance] registerListener:[self new] forName:@"com.filmstarr.stravaactivator.toggle"];
	}
}

@end

@interface LAStravaStartActivator : NSObject<LAListener> {}
@end

@implementation LAStravaStartActivator

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	SBApplication *stravaSBApplication = [(SBApplicationController *) [objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.strava.stravaride"];

	if(stravaSBApplication) {
		wasLaunchedWithActivator = YES;
		recordingRequestHandled = NO;
		isStarting = YES;

        SBLockScreenManager *sbLockScreenManager = (SBLockScreenManager*) [%c(SBLockScreenManager) sharedInstance];
        if ([sbLockScreenManager isUILocked]){
            [sbLockScreenManager unlockUIFromSource:0 withOptions:nil];
        }
		else
		{
			SBApplication *frontApp = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
			if ([[frontApp displayIdentifier] isEqualToString: @"com.strava.stravaride"]) {
				notify_post(RecordingRequestedNotification);
			}
			else {
				[(SBUIController *) [objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:stravaSBApplication];
			}
		}
	}
	else {
	    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Strava Activator" message:@"Strava must be installed to use Strava Activator." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"App Store", nil];
	    [error show];
	    [error release];
	}
		
	[event setHandled:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 1) {
	   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/strava-running-cycling-gps/id426826309"]];
	}
}

+ (void)load {
	if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
	{
	  [[%c(LAActivator) sharedInstance] registerListener:[self new] forName:@"com.filmstarr.stravaactivator.start"];
	}
}

@end

@interface LAStravaStopActivator : NSObject<LAListener> {}
@end

@implementation LAStravaStopActivator

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	SBApplication *stravaSBApplication = [(SBApplicationController *) [objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.strava.stravaride"];

	if(stravaSBApplication) {
		wasLaunchedWithActivator = YES;
		recordingRequestHandled = NO;
		isStopping = YES;
	
        SBLockScreenManager *sbLockScreenManager = (SBLockScreenManager*) [%c(SBLockScreenManager) sharedInstance];
        if ([sbLockScreenManager isUILocked]){
            [sbLockScreenManager unlockUIFromSource:0 withOptions:nil];
        }
		else
		{
			SBApplication *frontApp = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
			if ([[frontApp displayIdentifier] isEqualToString: @"com.strava.stravaride"]) {
				notify_post(RecordingRequestedNotification);
			}
			else {
				[(SBUIController *) [objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:stravaSBApplication];
			}
		}
	}
	else {
	    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Strava Activator" message:@"Strava must be installed to use Strava Activator." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"App Store", nil];
	    [error show];
	    [error release];
	}
		
	[event setHandled:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 1) {
	   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/strava-running-cycling-gps/id426826309"]];
	}
}

+ (void)load {
	if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
	{
	  [[%c(LAActivator) sharedInstance] registerListener:[self new] forName:@"com.filmstarr.stravaactivator.stop"];
	}
}

@end