//
//  OGImageTestsAppDelegate.m
//  OGImageDemo
//
//  Created by Art Gillespie on 1/2/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import "OGImageTestsAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

@implementation OGImageTestsAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [self setupLogging];
    [super applicationDidFinishLaunching:application];
}

- (void)setupLogging {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

@end
