//
//  OGCachedImage.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGCachedImage.h"
#import "OGImageCache.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@implementation OGCachedImage

- (id)initWithURL:(NSURL *)url key:(NSString *)key {
    self = [super init];
    if (nil != self) {
        _key = key;
        self.url = url;
        [self loadImageFromURL];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url key:(NSString *)key placeholderImage:(UIImage *)placeholderImage {
    self = [super init];
    if (nil != self) {
        _key = key;
        self.url = url;
        self.image = placeholderImage;
        [self loadImageFromURL];
    }
    return self;
}

- (void)loadImageFromURL {
    [[OGImageCache shared] imageForKey:_key block:^(UIImage *image) {
        if (nil == image) {
            DDLogInfo(@"cache miss for key: %@", _key);
            [super loadImageFromURL];
        } else {
            DDLogInfo(@"cache hit for key: %@", _key);
            self.image = image;
        }
    }];
}

- (void)imageDidLoadFromURL:(UIImage *)image {
    DDLogInfo(@"image loaded, caching for key: %@", _key);
    [[OGImageCache shared] setImage:image forKey:_key];
    [super imageDidLoadFromURL:image];
}

@end
