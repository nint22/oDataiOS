//
//  AppDelegate.h
//  oData
//
//  Created by Jeremy Bridon on 11/18/12.
//  Copyright (c) 2012 Jeremy Bridon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConsoleViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, readwrite) ConsoleViewController* ConsoleView;

@end
