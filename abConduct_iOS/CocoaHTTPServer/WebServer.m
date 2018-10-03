/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "WebServer.h"
 
#import "HTTPServer.h"
#import "DAVConnection.h"
#import "Reachability.h"

#import <CFNetwork/CFNetwork.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <UIKit/UIKit.h>

#import "Util.h"


@interface WebServer () {
	HTTPServer *server;
}
@end

@implementation WebServer

- (id)init {
	self = [super init];
	if(self) {
		server = [[HTTPServer alloc] init];
		[server setPort:[[NSUserDefaults standardUserDefaults] integerForKey:@"webServerPort"]];
	}
	return self;
}


- (BOOL)start:(NSString *)directory {

    //check Wifi connection
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    BOOL noWifi = NO;
    if(status != ReachableViaWiFi) {
        //WiFi
        if (status == ReachableViaWWAN) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"no wifi connection..."
                                                                message:[NSString stringWithFormat:@"Please make shure You have Personal Hotspot enabled in system settings.", nil]
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        else noWifi = YES;
    }
    if (noWifi) {
        NSLog(@"no wifi connection!");
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"no wifi connection"
                                                            message:[NSString stringWithFormat:@"Please connect to a local Network first", nil]
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        return NO;
    }
    
	// create DAV server
	[server setConnectionClass:[DAVConnection class]];
	
	// enable Bonjour
	[server setType:@"_http._tcp."];

	// set document root
	[server setDocumentRoot:[directory stringByExpandingTildeInPath]];
	NSLog(@"WebServer: set root to %@", directory);

	// start DAV server
    NSError* error = nil;
	if(![server start:&error]) {
		NSLog(@"WebServer: error starting: %@", error.localizedDescription);
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops"
															message:[NSString stringWithFormat:@"Couldn't start server: %@", error.localizedDescription]
														   delegate:self
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
		[alertView show];
		return NO;
	}
	return YES;
}

- (BOOL)start {
    NSError *error;
    NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:webFolder])
        [[NSFileManager defaultManager] createDirectoryAtPath:webFolder withIntermediateDirectories:NO attributes:nil error:&error];
    if (error) {
        NSLog(@"couldn't create webDAV-folder: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
        return NO;
    }
	return [self start:webFolder];
}

- (void)stop {
	if(server.isRunning) {
		[server stop];
		NSLog(@"WebServer: stopped");
	}
}

#pragma mark Setter/Getter Overrides

- (void)setPort:(int)port {
	NSLog(@"WebServer: port set to %d", port);
	[server setPort:port];
	[[NSUserDefaults standardUserDefaults] setInteger:port forKey:@"webServerPort"];
}

- (int)port {
	if([server isRunning]) {
		return [server listeningPort];
	}
	else {
		return [server port];
	}
}

- (NSString *)hostName {
	if([server isRunning]) {
		return [server publishedName];
	}
	else {
		return [server name];
	}
}

- (BOOL)isRunning {
	return [server isRunning];
}

// from http://blog.zachwaugh.com/post/309927273/programmatically-retrieving-ip-address-of-iphone
+ (NSString *)wifiInterfaceAddress {

	NSString *address = nil;
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;

	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if(success == 0) {

		// loop through interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL) {
			if(temp_addr->ifa_addr->sa_family == AF_INET) {
				NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];

				// iOS wifi interface = en0, include en1 for Mac wifi in simulator 
				if([interfaceName isEqualToString:@"en0"] || (TARGET_IPHONE_SIMULATOR && [interfaceName isEqualToString:@"en1"])) {
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			temp_addr = temp_addr->ifa_next;
		}
	}
	freeifaddrs(interfaces);

	return address;
}


@end
