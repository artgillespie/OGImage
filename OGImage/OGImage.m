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
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSURL *url;
@end

@implementation OGImage

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (nil != self) {
        _url = url;
        [self loadImage];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage {
    self = [super init];
    if (nil != self) {
        _image = placeholderImage;
        _url = url;
        [self loadImage];
    }
    return self;
}

#pragma mark - Properties

#pragma mark - Private

- (void)loadImage {
    [[OGImageLoader shared] enqueueImageRequest:_url completionBlock:^(UIImage *image, NSError *error) {
        if (nil != image) {
            [self _setImage:image];
        } else if (nil != error) {
            [self _setError:error];
        }
    }];
}

- (void)_setError:(NSError *)error {
    [self setValue:error forKey:@"error"];
}

- (void)_setImage:(UIImage *)image {
    [self setValue:image forKey:@"image"];
}

@end
