//  ViewController.h

#import <UIKit/UIKit.h>

@class DrawView;

@interface ViewController : UIViewController {
  IBOutlet UISwitch * _debugModeSwitch;
  IBOutlet DrawView * _drawView;
}

- (IBAction)debugModeSwitchPressed:(UISwitch *)aSwitch;

@end