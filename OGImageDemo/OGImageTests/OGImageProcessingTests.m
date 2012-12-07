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

extern CGSize OGAspectFit(CGSize from, CGSize to);
extern CGSize OGAspectFill(CGSize from, CGSize to, CGPoint *offset);

static NSString * const TEST_IMAGE_URL_STRING = @"http://easyquestion.net/thinkagain/wp-content/uploads/2009/05/james-bond.jpg";
static const CGSize TEST_IMAGE_SIZE = {317.f, 400.f};
static const CGSize TEST_SCALE_SIZE = {128.f, 128.f};

@interface OGImageProcessingTests : GHTestCase
@end

@implementation OGImageProcessingTests

- (void)testAspectFit_1 {
    CGSize newSize = OGAspectFit(CGSizeMake(600.f, 1024.f), CGSizeMake(64.f, 64.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(38.f, 64.f)), @"Invalid dimensions...");
}

- (void)testAspectFit_2 {
    CGSize newSize = OGAspectFit(CGSizeMake(1024.f, 1024.f), CGSizeMake(64.f, 64.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(64.f, 64.f)), @"Invalid dimensions...");
}

- (void)testAspectFit_3 {
    CGSize newSize = OGAspectFit(CGSizeMake(64.f, 100.f), CGSizeMake(128.f, 128.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(82.f, 128.f)), @"Invalid dimensions...");
}

- (void)testAspectFit_4 {
    CGSize newSize = OGAspectFit(CGSizeMake(64.f, 100.f), CGSizeMake(64.f, 100.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(64.f, 100.f)), @"Invalid dimensions...");
}

- (void)testAspectFit_5 {
    GHAssertThrows(OGAspectFit(CGSizeMake(0.f, 0.f), CGSizeMake(0.f, 0.f)), @"Expect OGAspectFit to throw when any dimension is zero.");
}

- (void)testAspectFill_1 {
    CGPoint pt = CGPointZero;
    GHAssertThrows(OGAspectFill(CGSizeMake(0.f, 0.f), CGSizeMake(0.f, 0.f), &pt), @"Expect OGAspectFill to throw when any dimension is zero.");
}

- (void)testAspectFill_2 {
    GHAssertThrows(OGAspectFill(CGSizeMake(128.f, 128.f), CGSizeMake(1024.f, 1024.f), NULL), @"Expect OGAspectFill to throw when `offset` parameter is NULL.");
}

- (void)testAspectFill_3 {
    CGPoint pt = CGPointZero;
    CGSize newSize = OGAspectFill(CGSizeMake(1920.f, 1024.f), CGSizeMake(256.f, 256.f), &pt);
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(480.f, 256.f)), @"Expected 480, 256");
    GHAssertTrue(pt.x == 112.f && pt.y == 0.f, @"Expected offset point at 112, 0");
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
        CGSize retinaSize = TEST_SCALE_SIZE;
        retinaSize.width *= [UIScreen mainScreen].scale;
        retinaSize.height *= [UIScreen mainScreen].scale;
        CGSize expectedSize = OGAspectFit(TEST_IMAGE_SIZE, TEST_SCALE_SIZE);
        if (NO == CGSizeEqualToSize(image.scaledImage.size, expectedSize)) {
            [self notify:kGHUnitWaitStatusFailure];
        } else {
            [self notify:kGHUnitWaitStatusSuccess];
        }
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
