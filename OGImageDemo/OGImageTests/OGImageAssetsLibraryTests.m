//
//  OGImageAssetsLibraryTests.m
//  OGImageDemo
//
//  Created by Art Gillespie on 1/8/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import "GHAsyncTestCase.h"
#import "OGCachedImage.h"
#import "OGImageCache.h"

#import <AssetsLibrary/AssetsLibrary.h>

static CGSize const OGExpectedSize = {1024.f, 768.f};

@interface OGImageAssetsLibraryTests : GHAsyncTestCase

@end

@implementation OGImageAssetsLibraryTests {
    NSURL *_assetURL;
}

- (void)setUp {
    [self prepare];
    [[OGImageCache shared] purgeCache:YES];
    // we have to save the test image to the asset library
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"Origami" withExtension:@"jpg"];
    GHAssertNotNil(imageURL, @"Couldn't get URL for test image");
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    UIImage *image = [UIImage imageWithContentsOfFile:[imageURL path]];
    GHAssertNotNil(image, @"Couldn't load image from URL: %@", imageURL);

    [library writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        GHAssertNil(error, @"Couldn't save test image to photos album: %@", error);
        if (nil != error) {
            [self notify:kGHUnitWaitStatusSuccess];
        }
        _assetURL = assetURL;
        [self notify:kGHUnitWaitStatusSuccess];
    }];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        OGCachedImage *image = (OGCachedImage *)object;
        if (nil != image.image) {
            GHAssertTrue(CGSizeEqualToSize(OGExpectedSize, image.image.size), @"Expected image of size %@, got %@", NSStringFromCGSize(OGExpectedSize), NSStringFromCGSize(image.image.size));
            [self notify:kGHUnitWaitStatusSuccess];
        } else {
            [self notify:kGHUnitWaitStatusFailure];
        }
    } else if ([keyPath isEqualToString:@"error"]) {
        OGCachedImage *image = (OGCachedImage *)object;
        GHFail(@"Got error loading OGCachedImage: %@", image.error);
        [self notify:kGHUnitWaitStatusFailure];
    }
}

- (void)testAssetsLibrary {
    [self prepare];
    GHAssertNotNil(_assetURL, @"Expect _assetURL to be populated by setUp");
    OGCachedImage *image = [[OGCachedImage alloc] initWithURL:_assetURL key:nil];
    [image addObserver:self];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.];
    [image removeObserver:self];
}

@end