//
//  BouncingBallAppDelegate.h
//  BouncingBall
//
//  Created by Taylor Triggs on 5/17/12.
//  Copyright (c) 2012 Cal State Channel Islands. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BouncingBallViewController;

@interface BouncingBallAppDelegate : NSObject <UIApplicationDelegate> {
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet BouncingBallViewController *viewController;

@end

