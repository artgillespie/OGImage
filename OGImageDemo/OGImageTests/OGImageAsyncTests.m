//
//  OGImageAsyncTests.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>
#import "OGImage.h"
#import "OGImageLoader.h"

static NSString * const TEST_IMAGE_URL_STRING = @"http://easyquestion.net/thinkagain/wp-content/uploads/2009/05/james-bond.jpg";
static NSString * const FAKE_IMAGE_URL_STRING = @"http://easyquestion.net/thinkagain/wp-content/uploads/2009/05/james00.jpg";
static const CGSize TEST_IMAGE_SIZE = {317.f, 400.f};

#pragma mark -

@interface OGImage404Test : GHAsyncTestCase
@end

@implementation OGImage404Test

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSAssert(YES == [NSThread isMainThread], @"Expected `observeValueForKeyPath` to only be called on main thread");
    if ([keyPath isEqualToString:@"error"]) {
        OGImage *image = (OGImage *)object;
        GHTestLog(@"Error changed: %@", image.error);
        if (OGImageLoadingError == image.error.code) {
            // we expect a loading error here
            [self notify:kGHUnitWaitStatusSuccess];
        } else {
            [self notify:kGHUnitWaitStatusFailure];
        }
        return;
    }
    GHTestLog(@"Unexpected key change...");
    [self notify:kGHUnitWaitStatusUnknown];
}

- (void)test404 {
    [self prepare];
    OGImage *image = [[OGImage alloc] initWithURL:[NSURL URLWithString:FAKE_IMAGE_URL_STRING]];
    [image addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.];
    [image removeObserver:self forKeyPath:@"error"];
}

@end

#pragma mark -

@interface OGImageTest1 : GHAsyncTestCase

@end

@implementation OGImageTest1
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSAssert(YES == [NSThread isMainThread], @"Expected `observeValueForKeyPath` to only be called on main thread");
    if ([keyPath isEqualToString:@"image"]) {
        OGImage *image = (OGImage *)object;
        GHTestLog(@"Image loaded: %@ : %@", image.image, NSStringFromCGSize(image.image.size));
        GHAssertTrue(CGSizeEqualToSize(image.image.size, TEST_IMAGE_SIZE), @"Unexpected image size");
        [self notify:kGHUnitWaitStatusSuccess];
        return;
    }
    GHTestLog(@"Unexpected key change...");
    [self notify:kGHUnitWaitStatusFailure];
}

- (void)testImageOne {
    [self prepare];
    OGImage *image = [[OGImage alloc] initWithURL:[NSURL URLWithString:TEST_IMAGE_URL_STRING]];
    [image addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.];
    [image removeObserver:self forKeyPath:@"image"];
}

@end
