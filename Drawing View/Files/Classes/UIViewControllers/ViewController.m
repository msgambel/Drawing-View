//  ViewController.m

#import "ViewController.h"
#import "DrawView.h"

@implementation ViewController

#pragma mark - View LifeStyle

- (void)viewDidLoad; {
  [super viewDidLoad];
  
  // Set the debug mode switches state to be the saved state of the last session.
  _debugModeSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"debugModeOn"];
  
  // Set the DrawView's debug mode to be the saved state of the last session.
  _drawView.debugModeOn = _debugModeSwitch.on;
}

#pragma mark - iOS 5.1 and under Rotation Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation; {
  // Return that we only accept Potrait orientations.
  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - iOS 6.0 and up Rotation Methods

- (BOOL)shouldAutorotate; {
  // Return that the ViewController should auto-rotate.
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations; {
  // Return that we only accept Potrait orientations.
  return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation; {
  // Return that the preferred orientation is Portrait.
  return UIInterfaceOrientationPortrait;
}

#pragma mark - Methods

- (IBAction)debugModeSwitchPressed:(UISwitch *)aSwitch; {
  // Store the debug move state in the NSUserDefaults.
  [[NSUserDefaults standardUserDefaults] setBool:aSwitch.on forKey:@"debugModeOn"];
  
  // Synchronize the NSUserDefaults to ensure the state is saved correctly.
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // Set the DrawView's debug mode to be the debug mode switches state.
  _drawView.debugModeOn = aSwitch.on;
}

@end