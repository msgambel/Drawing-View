//  AppDelegate.h

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
  UIWindow * _window;
}

@property (strong, nonatomic) UIWindow * window;

+ (AppDelegate *)appDelegate;

@end