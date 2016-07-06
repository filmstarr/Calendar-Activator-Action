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
#define ToggleRecordingNotification "com.filmstarr.stravaactivator.toggleNotification"
#define StartRecordingNotification "com.filmstarr.stravaactivator.startNotification"
#define StopRecordingNotification "com.filmstarr.stravaactivator.stopNotification"

#define StravaDisplayIdentifier @"com.strava.stravaride"

enum {
	STRAVA_ACTIVATOR_NONE = 0x0,
	STRAVA_ACTIVATOR_TOGGLE = 0x1,
	STRAVA_ACTIVATOR_START = 0x2,
	STRAVA_ACTIVATOR_STOP = 0x3,
};

static BOOL isAppInitialized = NO;
static StravaAppDelegate *strava = nil;
static STRVRecordControlsViewController *stravaRecordControlsViewController = nil;
static BOOL recordingRequestHandled = YES;
static int stravaAction = STRAVA_ACTIVATOR_NONE;


%group springBoardHooks

	%hook SBLockScreenManager
		-(void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
			%orig;
			if (stravaAction != STRAVA_ACTIVATOR_NONE) {
				SBApplication *stravaSBApplication = [(SBApplicationController *) [objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:StravaDisplayIdentifier];
				if (stravaSBApplication) {
					SBApplication *frontApp = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
					if ([[frontApp displayIdentifier] isEqualToString: StravaDisplayIdentifier]) {
						notify_post(RecordingRequestedNotification);
					}
					else {
						[(SBUIController *) [objc_getClass("SBUIController") sharedInstance] activateApplication:stravaSBApplication];
					}
				}
			}
		}
		-(void)_lockScreenDimmed:(id)dimmed {
			stravaAction = STRAVA_ACTIVATOR_NONE;
			%orig;
		}
	%end

	%hook SBLockScreenViewController
		-(void)passcodeLockViewEmergencyCallButtonPressed:(id)pressed {
			stravaAction = STRAVA_ACTIVATOR_NONE;
			%orig;
		}
		-(void)passcodeLockViewCancelButtonPressed:(id)pressed {
			stravaAction = STRAVA_ACTIVATOR_NONE;
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
		- (void)showInitialInterfaceAnimated:(BOOL)fp8 {
			%orig;
			if (fp8) {
				isAppInitialized = YES;
				notify_post(RecordingRequestedNotification);
			}
		}
	%end

	%hook STRVRecordControlsViewController
		- (void)viewDidLoad {
			%orig;
			stravaRecordControlsViewController = self;
		}
	%end

%end


static void recordingRequest (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (!recordingRequestHandled) {
		recordingRequestHandled = YES;		
		switch (stravaAction) {
			case STRAVA_ACTIVATOR_TOGGLE:
				notify_post(ToggleRecordingNotification);
				break;
			case STRAVA_ACTIVATOR_START:
				notify_post(StartRecordingNotification);
				break;
			case STRAVA_ACTIVATOR_STOP:
				notify_post(StopRecordingNotification);
				break;
			default:
				break;
		}
	}
}

static void processRecordingRequest (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (isAppInitialized)
	{
		//Open recording tab
		[strava selectTab:2];

		//Perform activator action
		if (name == CFSTR(ToggleRecordingNotification)) {
			[stravaRecordControlsViewController toggleRecordState:nil];
		}
		else if (name == CFSTR(StartRecordingNotification)) {
			if ([stravaRecordControlsViewController recordButtonState] == 0) {
				[stravaRecordControlsViewController toggleRecordState:nil];
			}
		}
		else if (name == CFSTR(StopRecordingNotification)) {
			if ([stravaRecordControlsViewController recordButtonState] == 1) {
				[stravaRecordControlsViewController toggleRecordState:nil];
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
		stravaAction = STRAVA_ACTIVATOR_NONE;
	}
	else if (name == CFSTR(RecordingFailedNotification)) {
		recordingRequestHandled = NO;
	}
}


@interface LAStravaActivator : NSObject<LAListener>
{
	int action;
}
@end

@implementation LAStravaActivator

- (id)initWithAction:(int) inputAction
{
	if ((self = [super init])) {
		self->action = inputAction;
	}
	return self;
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	SBApplication *stravaSBApplication = [(SBApplicationController *) [objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:StravaDisplayIdentifier];

	if(stravaSBApplication) {
		[self setStateFlags];

    SBLockScreenManager *sbLockScreenManager = (SBLockScreenManager*) [%c(SBLockScreenManager) sharedInstance];
    if ([sbLockScreenManager isUILocked]){
        [sbLockScreenManager unlockUIFromSource:0 withOptions:nil];
    }
		else
		{
			SBApplication *frontApp = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
			if ([[frontApp displayIdentifier] isEqualToString: StravaDisplayIdentifier]) {
				notify_post(RecordingRequestedNotification);
			}
			else {
				[(SBUIController *) [objc_getClass("SBUIController") sharedInstance] activateApplication:stravaSBApplication];
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

-(void)setStateFlags {
	recordingRequestHandled = NO;
	stravaAction = action;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 1) {
	   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/strava-running-cycling-gps/id426826309"]];
	}
}

@end


%ctor {
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, recordingRequest, CFSTR(RecordingRequestedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, recordingProcessed, CFSTR(RecordingSucceededNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, recordingProcessed, CFSTR(RecordingFailedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		%init(springBoardHooks);
		
		[[%c(LAActivator) sharedInstance] registerListener:[[LAStravaActivator alloc] initWithAction: STRAVA_ACTIVATOR_TOGGLE] forName:@"com.filmstarr.stravaactivator.toggle"];
		[[%c(LAActivator) sharedInstance] registerListener:[[LAStravaActivator alloc] initWithAction: STRAVA_ACTIVATOR_START] forName:@"com.filmstarr.stravaactivator.start"];
		[[%c(LAActivator) sharedInstance] registerListener:[[LAStravaActivator alloc] initWithAction: STRAVA_ACTIVATOR_STOP] forName:@"com.filmstarr.stravaactivator.stop"];
	}
	else if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:StravaDisplayIdentifier]) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, processRecordingRequest, CFSTR(ToggleRecordingNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, processRecordingRequest, CFSTR(StartRecordingNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, processRecordingRequest, CFSTR(StopRecordingNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		%init(stravaHooks);
	}
}