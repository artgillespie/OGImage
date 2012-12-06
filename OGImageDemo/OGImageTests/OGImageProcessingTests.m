//
//  OGImageProcessingTests.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>
#import "OGImageProcessing.h"
#import "OGScaledImage.h"
#import "OGImageCache.h"

static NSString * const TEST_IMAGE_URL_STRING = @"http://easyquestion.net/thinkagain/wp-content/uploads/2009/05/james-bond.jpg";
static const CGSize TEST_IMAGE_SIZE = {317.f, 400.f};
static const CGSize TEST_SCALE_SIZE = {128.f, 128.f};

@interface OGImageProcessingTests : GHTestCase
@end

@implementation OGImageProcessingTests

- (void)testAspectFill_1 {
    CGSize newSize = OGAspectFit(CGSizeMake(600.f, 1024.f), CGSizeMake(64.f, 64.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(38.f, 64.f)), @"Invalid dimensions...");
}

- (void)testAspectFill_2 {
    CGSize newSize = OGAspectFit(CGSizeMake(1024.f, 1024.f), CGSizeMake(64.f, 64.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(64.f, 64.f)), @"Invalid dimensions...");
}

- (void)testAspectFill_3 {
    CGSize newSize = OGAspectFit(CGSizeMake(64.f, 100.f), CGSizeMake(128.f, 128.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(82.f, 128.f)), @"Invalid dimensions...");
}

- (void)testAspectFill_4 {
    CGSize newSize = OGAspectFit(CGSizeMake(64.f, 100.f), CGSizeMake(64.f, 100.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(64.f, 100.f)), @"Invalid dimensions...");
}

@end

@interface OGScaledImageTest : GHAsyncTestCase
@end

@implementation OGScaledImageTest

- (void)setUp {
    // make sure we get the image from the network
    [[OGImageCache shared] purgeCache:YES];
}

- (void)tearDown {
    // clean up the in-memory and disk cache when we're done
    [[OGImageCache shared] purgeCache:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSAssert(YES == [NSThread isMainThread], @"Expected `observeValueForKeyPath` to only be called on main thread");
    if ([keyPath isEqualToString:@"scaledImage"]) {
        OGScaledImage *image = (OGScaledImage *)object;
        GHTestLog(@"Image loaded: %@ : %@", image.image, NSStringFromCGSize(image.image.size));
        CGSize expectedSize = OGAspectFit(TEST_IMAGE_SIZE, TEST_SCALE_SIZE);
        GHAssertTrue(CGSizeEqualToSize(image.scaledImage.size, expectedSize), @"Unexpected image size");
        [self notify:kGHUnitWaitStatusSuccess];
        return;
    }
    GHTestLog(@"Unexpected key change...");
    [self notify:kGHUnitWaitStatusFailure];
}

- (void)testScaledImage1 {
    [self prepare];
    OGScaledImage *image = [[OGScaledImage alloc] initWithURL:[NSURL URLWithString:TEST_IMAGE_URL_STRING] size:TEST_SCALE_SIZE key:nil];
    [image addObserver:self forKeyPath:@"scaledImage" options:NSKeyValueObservingOptionNew context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.];
    [image removeObserver:self forKeyPath:@"scaledImage"];
}

@end
