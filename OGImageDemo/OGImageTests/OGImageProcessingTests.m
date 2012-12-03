//
//  OGImageProcessingTests.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>
#import "OGImageProcessing.h"

@interface OGImageProcessingTests : GHTestCase
@end

@implementation OGImageProcessingTests

- (void)testAspectFill_1 {
    CGSize newSize = OGAspectFit(CGSizeMake(600.f, 1024.f), CGSizeMake(64.f, 64.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(37.5, 64.f)), @"Invalid dimensions...");
}

- (void)testAspectFill_2 {
    CGSize newSize = OGAspectFit(CGSizeMake(1024.f, 1024.f), CGSizeMake(64.f, 64.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(64.f, 64.f)), @"Invalid dimensions...");
}

- (void)testAspectFill_3 {
    CGSize newSize = OGAspectFit(CGSizeMake(64.f, 100.f), CGSizeMake(128.f, 128.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(81.92f, 128.f)), @"Invalid dimensions...");
}

- (void)testAspectFill_4 {
    CGSize newSize = OGAspectFit(CGSizeMake(64.f, 100.f), CGSizeMake(64.f, 100.f));
    GHAssertTrue(CGSizeEqualToSize(newSize, CGSizeMake(64.f, 100.f)), @"Invalid dimensions...");
}

@end
