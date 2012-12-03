//
//  OGImage.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGImage.h"
#import "OGImageLoader.h"

@interface OGImage()
// make these read/write within the class
@property (nonatomic, strong) NSError *error;
@end

@implementation OGImage

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (nil != self) {
        self.url = url;
        [self loadImageFromURL];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage {
    self = [super init];
    if (nil != self) {
        self.image = placeholderImage;
        self.url = url;
        [self loadImageFromURL];
    }
    return self;
}

- (void)imageDidLoadFromURL:(UIImage *)image {
    self.image = image;
}

#pragma mark - Protected

- (void)loadImageFromURL {
    [[OGImageLoader shared] enqueueImageRequest:_url completionBlock:^(UIImage *image, NSError *error) {
        if (nil != image) {
            [self imageDidLoadFromURL:image];
        } else if (nil != error) {
            [self _setError:error];
        }
    }];
}

- (void)_setError:(NSError *)error {
    [self setValue:error forKey:@"error"];
}

@end
