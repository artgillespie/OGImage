//
//  OGImageProcessing.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGImageProcessing.h"
#import <Accelerate/Accelerate.h>

/*
 * Return the size that aspect fits `from` into `to`
 */
CGSize OGAspectFit(CGSize from, CGSize to) {
    if (CGSizeEqualToSize(from, to)) {
        return to;
    }
    CGFloat r1 = from.width / from.height;
    CGFloat r2 = to.width / to.height;
    if (r2 > r1) {
        return CGSizeMake(from.width * to.height/from.height, to.height);
    } else {
        return CGSizeMake(to.width, from.height * (to.width / from.width));
    }
    return CGSizeZero;
}

/*
 * Don't forget to free buffer->data.
 */
OSStatus UIImageToVImageBuffer(UIImage *image, vImage_Buffer *buffer) {
    OSStatus err = noErr;
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    buffer->data = malloc(width * height * 4);
    buffer->width = width;
    buffer->height = height;
    buffer->rowBytes = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(buffer->data,
                                             buffer->width,
                                             buffer->height, 32,
                                             buffer->rowBytes, colorSpace, kCGImageAlphaLast);
    CGContextDrawImage(ctx, CGRectMake(0.f, 0.f, width, height), cgImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    return err;
}

@implementation OGImageProcessing {
    dispatch_queue_t _imageProcessingQueue;
}

+ (OGImageProcessing *)shared {
    static OGImageProcessing *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[OGImageProcessing alloc] init];
    });
    return shared;
}

- (id)init
{
    self = [super init];
    if (self) {
        _imageProcessingQueue = dispatch_queue_create("com.origami.imageProcessing", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size completionBlock:(OGImageProcessingBlock)block {
    dispatch_async(_imageProcessingQueue, ^{
        CGSize newSize = OGAspectFit(image.size, size);
    });
}

@end
