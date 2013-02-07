//
//  OGImageIdempotentTests.m
//  OGImageDemo
//
//  Created by Art Gillespie on 2/7/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import "GHAsyncTestCase.h"
#import "OGImage.h"

static NSString * const TEST_IMAGE_URL_STRING = @"http://easyquestion.net/thinkagain/wp-content/uploads/2009/05/james-bond.jpg";

@interface OGImageIdempotentTests : GHAsyncTestCase {
    OGImage *_image1;
    OGImage *_image2;
    BOOL _image1Loaded;
    BOOL _image2Loaded;
}

@end

@implementation OGImageIdempotentTests

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (_image1 == object) {
        _image1Loaded = YES;
    } else if (_image2 == object) {
        _image2Loaded = YES;
    }
    [self notify:kGHUnitWaitStatusSuccess];
}

- (void)testIdempotent {
    // we want to make sure that multiple requests for the same URL result in
    // a single network request with notifications
    [self prepare];
    _image1 = [[OGImage alloc] initWithURL:[NSURL URLWithString:TEST_IMAGE_URL_STRING]];
    [_image1 addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    _image2 = [[OGImage alloc] initWithURL:[NSURL URLWithString:TEST_IMAGE_URL_STRING]];
    [_image2 addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:15.f];
}
@end
