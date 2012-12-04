//
//  OGScaledImage.m
//  OGImageDemo
//
//  Created by Art Gillespie on 12/4/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGScaledImage.h"
#import "OGImageCache.h"
#import "OGImageProcessing.h"
#import "DDLog.h"

static int ddLogLevel = LOG_LEVEL_INFO;

NSString *OGKeyWithSize(NSString *origKey, CGSize size) {
    return [NSString stringWithFormat:@"%@-%f-%f", origKey, size.width, size.height];
}

@implementation OGScaledImage {
    CGSize _scaledSize;
    NSString *_scaledKey;
}

- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key {
    self = [super init];
    if (nil != self) {
        self.key = key;
        self.url = url;
        _scaledSize = size;
        _scaledKey = OGKeyWithSize(self.key, _scaledSize);
        [self loadImageFromURL];
    }
    return self;

}

- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key placeholderImage:(UIImage *)placeholderImage {
    self = [super init];
    if (nil != self) {
        self.key = key;
        self.url = url;
        self.scaledImage = placeholderImage;
        _scaledSize = size;
        _scaledKey = OGKeyWithSize(self.key, _scaledSize);
        [self loadImageFromURL];
    }
    return self;
}

- (void)loadImageFromURL {
    [[OGImageCache shared] imageForKey:_scaledKey block:^(UIImage *image) {
        if (nil == image) {
            DDLogInfo(@"cache miss for scaled key: %@", _scaledKey);
            [super loadImageFromURL];
        } else {
            DDLogInfo(@"cache hit for scaled key: %@", _scaledKey);
            self.scaledImage = image;
        }
    }];
}

- (void)setImage:(UIImage *)image {
    [super setImage:image];
    [[OGImageProcessing shared] scaleImage:image toSize:_scaledSize completionBlock:^(UIImage *image) {
        DDLogInfo(@"scaling image: %@", _scaledKey);
        self.scaledImage = image;
    }];
}

@end
