//  ViewController.m

#import "ViewController.h"

@implementation ViewController

#pragma mark - View LifeStyle

- (void)viewDidLoad; {
  [super viewDidLoad];
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

@end