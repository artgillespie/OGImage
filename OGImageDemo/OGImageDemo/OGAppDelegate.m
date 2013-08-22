//
//  OGAppDelegate.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGAppDelegate.h"
#import "OGViewController.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "OGImageCache.h"

@implementation OGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[OGViewController alloc] initWithNibName:@"OGViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    [self setupLogging];
    return YES;
}

- (void)setupLogging {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // purge the disk cache of any image that hasn't been
    // accessed more recently than 2 minutes ago. This is obviously pretty contrived;
    NSDate *before = [NSDate dateWithTimeIntervalSinceNow:-120.];
    [[OGImageCache shared] purgeDiskCacheOfImagesLastAccessedBefore:before];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
