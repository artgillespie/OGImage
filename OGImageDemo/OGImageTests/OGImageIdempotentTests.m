//
//  OGImageIdempotentTests.m
//  OGImageDemo
//
//  Created by Art Gillespie on 2/7/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import "GHAsyncTestCase.h"
#import "OGImage.h"

static NSString *KVOContext = @"OGImageIdempotentTests observation";

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
    if ((void *)&KVOContext == context) {
        if (_image1 == object) {
            _image1Loaded = YES;
        } else if (_image2 == object) {
            _image2Loaded = YES;
        }
        if (_image1Loaded && _image2Loaded) {
            [self notify:kGHUnitWaitStatusSuccess];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)testIdempotent {
    // we want to make sure that multiple requests for the same URL result in
    // a single network request with notifications
    [self prepare];
    _image1 = [[OGImage alloc] initWithURL:[NSURL URLWithString:TEST_IMAGE_URL_STRING]];
    [_image1 addObserver:self context:&KVOContext];
    _image2 = [[OGImage alloc] initWithURL:[NSURL URLWithString:TEST_IMAGE_URL_STRING]];
    [_image2 addObserver:self context:&KVOContext];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:15.f];
    [_image1 removeObserver:self context:&KVOContext];
    [_image2 removeObserver:self context:&KVOContext];
}
@end
