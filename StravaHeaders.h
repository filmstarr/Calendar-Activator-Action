@interface RecordButton
- (BOOL)isRecording;
@end

@interface NewActivityViewController
- (void)toggleRecording:(id)fp8;
- (id)recordButton;
@end

@interface RecordPageViewController
- (id)activityRecordingPageViewController;
@end

@interface StravaAppDelegate
- (BOOL)isAppInitialized;
- (void)setAppInitialized:(BOOL)fp8;
- (void)applicationDidBecomeActive:(id)fp8;
- (id)recordPageViewController;
- (void)selectTab:(int)fp8;
@end