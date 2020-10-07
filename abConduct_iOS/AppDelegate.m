//
//  AppDelegate.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 16.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import "AppDelegate.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "ViewController.h"
#include <AVFoundation/AVFoundation.h>

// Log levels: off, error, warn, info, verbose

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.server = [[WebServer alloc] init];
    
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:&setCategoryErr];
    [[AVAudioSession sharedInstance] setActive:YES error:&activationErr];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    [self openUrl:url];
    return YES;
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [self openUrl:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [self openUrl:url];
    return YES;
}

- (void) openUrl: (NSURL *)url {
    
    if (url != nil && [url isFileURL]) {
        
        //  xdxf file type handling
        
        if ([[url pathExtension] isEqualToString:@"abc"]) {
            
            NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSError *error;
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSString *file = [url path];
            NSString *copyFile = [docsPath stringByAppendingPathComponent:[[file lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
            if ([fileManager fileExistsAtPath:copyFile]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"File exists" message:[NSString stringWithFormat:@"a file with name %@ already exists in the documents directory. Do You want to replace it?", [copyFile lastPathComponent]]  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *replace = [UIAlertAction actionWithTitle:@"replace" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSError *thisError;
                    if (![fileManager removeItemAtPath:copyFile error:&thisError]) {
                        NSLog(@"Could`t remove existing file: %@, reason: %@", copyFile, error.localizedFailureReason);
                    }
                    else {
                        if ([fileManager copyItemAtPath:file toPath:copyFile error:&thisError])
                            [self askToLoadCopiedFile:copyFile];
                        else NSLog(@"couldn´t copy File: %@ to documentsDirectory: %@, reason: %@, %@ after deleting the old...", file, copyFile, error.localizedDescription, error.localizedFailureReason);
                    }
                }];
                [alert addAction:replace];
                UIAlertAction *keepBoth = [UIAlertAction actionWithTitle:@"keepBoth" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSError *thisError;
                    NSDate *startTime = [NSDate date];
                    NSString *timeString = [NSString stringWithFormat:@"%@", startTime];
                    timeString = [timeString substringToIndex:timeString.length-6];
                    NSString *newCopyFile = [[NSString stringWithFormat:@"%@", [[[copyFile substringToIndex:copyFile.length-4] stringByAppendingString: timeString] stringByAppendingPathExtension: @"abc"]] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
                    if ([fileManager copyItemAtPath:file toPath:newCopyFile error:&thisError])
                        [self askToLoadCopiedFile:newCopyFile];
                    else NSLog(@"couldn´t copy File: %@ to documentsDirectory: %@, reason: %@, %@", file, newCopyFile, error.localizedDescription, error.localizedFailureReason);
                }];
                [alert addAction:keepBoth];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
            else if (![fileManager copyItemAtPath:file toPath:copyFile error:&error]) {
                NSLog(@"couldn´t copy File: %@ to documentsDirectory: %@, reason: %@, %@", file, copyFile, error.localizedDescription, error.localizedFailureReason);
            }
            else {
                [self askToLoadCopiedFile:copyFile];
            }
        }
    }
}

- (void) askToLoadCopiedFile: (NSString*) file {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat: @"copied file %@ to documents folder.", [file lastPathComponent]] message:@"select open to view..." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"open" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        ViewController *controller = (ViewController*) self.window.rootViewController;
        controller.refreshButton.enabled = YES;
        controller.saveButton.enabled = YES;
        [controller loadABCfileFromPath:file];
        
    }];
    [alert addAction:action];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

@end
