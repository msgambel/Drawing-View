//  AppDelegate.m

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

#pragma mark - Application LifeCycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions; {
  // Return that the application did finish launching.
  return YES;
}

#pragma mark - Class Methods

+ (AppDelegate *)appDelegate; {
  // Return a reference to the AppDelegate.
  return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Methods

@end