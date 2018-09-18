//
//  AppDelegate.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebServer.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) WebServer *server;

@end

