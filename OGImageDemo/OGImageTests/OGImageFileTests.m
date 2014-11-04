//
//  OGImageFileTests.m
//  OGImageDemo
//
//  Created by Art Gillespie on 1/8/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import <GHUnit/GHAsyncTestCase.h>
#import "OGCachedImage.h"
#import "OGImageCache.h"

static NSString *KVOContext = @"OGImageFileTests observation";

static CGSize const OGExpectedSize = {1024.f, 768.f};

@interface OGImageFileTests : GHAsyncTestCase

@end

@implementation OGImageFileTests

- (void)setUp {
    [[OGImageCache shared] purgeCache:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ((void *)&KVOContext == context) {
        if ([keyPath isEqualToString:@"image"]) {
            OGCachedImage *image = (OGCachedImage *)object;
            if (nil == image) {
                [self notify:kGHUnitWaitStatusFailure];
            } else {
                GHAssertTrue(CGSizeEqualToSize(OGExpectedSize, image.image.size), @"Expected image of size %@, got %@", NSStringFromCGSize(OGExpectedSize), NSStringFromCGSize(image.image.size));
                [self notify:kGHUnitWaitStatusSuccess];
            }
        } else if ([keyPath isEqualToString:@"error"]) {
            [self notify:kGHUnitWaitStatusFailure];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)testFileURL {
    [self prepare];
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"Origami" withExtension:@"jpg"];
    GHAssertNotNil(imageURL, @"Couldn't get URL for test image");
    OGCachedImage *image = [[OGCachedImage alloc] initWithURL:imageURL key:nil];
    [image addObserver:self context:&KVOContext];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.];
    [image removeObserver:self context:&KVOContext];
}

@end
