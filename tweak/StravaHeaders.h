@interface STRVRecordControlsViewController
- (void)viewDidLoad;
- (void)toggleRecordState:(id)fp8;
- (int)recordButtonState;
@end

@interface StravaAppDelegate
- (BOOL)showInitialInterfaceAnimated:(BOOL)fp8;
- (void)applicationDidBecomeActive:(id)fp8;
- (void)selectTab:(int)fp8;
@end