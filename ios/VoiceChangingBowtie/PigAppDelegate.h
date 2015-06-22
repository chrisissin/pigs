//
//  PigAppDelegate.h
//  Pig
//
//  Created by Chris (hsin-yuan) Ho on 5/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PigViewController;

@interface PigAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet PigViewController *viewController;

@end
