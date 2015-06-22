#import <UIKit/UIKit.h>
@class PigViewController;

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> 
{	UIWindow			*window;
	PigViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;

@property (nonatomic, retain) IBOutlet PigViewController *viewController;

@end
