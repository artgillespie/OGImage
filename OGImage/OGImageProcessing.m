//
//  OGImageProcessing.m
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGImageProcessing.h"
#import <Accelerate/Accelerate.h>

NSString * const OGImageProcessingErrorDomain = @"OGImageProcessingErrorDomain";

/*
 * Return the size that aspect fits `from` into `to`
 */
CGSize OGAspectFit(CGSize from, CGSize to) {
    NSCParameterAssert(0.f != from.width);
    NSCParameterAssert(0.f != from.height);
    NSCParameterAssert(0.f != to.width);
    NSCParameterAssert(0.f != to.height);

    if (CGSizeEqualToSize(from, to)) {
        return to;
    }
    CGFloat r1 = from.width / from.height;
    CGFloat r2 = to.width / to.height;
    if (r2 > r1) {
        return CGSizeMake(ceilf(from.width * to.height/from.height), ceilf(to.height));
    } else {
        return CGSizeMake(ceilf(to.width), ceilf(from.height * (to.width / from.width)));
    }
    return CGSizeZero;
}

CGSize OGAspectFill(CGSize from, CGSize to, CGPoint *offset) {
    NSCParameterAssert(0.f != from.width);
    NSCParameterAssert(0.f != from.height);
    NSCParameterAssert(0.f != to.width);
    NSCParameterAssert(0.f != to.height);
    NSCParameterAssert(nil != offset);
    CGFloat sRatio = from.width / from.height;
    CGFloat dRatio = to.width / to.height;
    CGFloat ratio = (dRatio <= sRatio) ? to.height / from.height : to.width / from.width;
    CGSize ret = CGSizeMake(ceilf(from.width * ratio), ceilf(from.height * ratio));
    if (ret.width > to.width) {
        offset->x = ceilf(ret.width / 2.f - to.width / 2.f);
    }
    if (ret.height > to.height) {
        offset->y = ceilf(ret.height / 2.f - to.height / 2.f);
    }
    return ret;
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
                                             buffer->height, 8,
                                             buffer->rowBytes, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(ctx, CGRectMake(0.f, 0.f, width, height), cgImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    return err;
}

UIImage *VImageBufferToUIImage(vImage_Buffer *buffer, CGFloat scale) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreateWithData(buffer->data,
                                                     buffer->width,
                                                     buffer->height,
                                                     8, buffer->rowBytes, colorSpace, kCGImageAlphaPremultipliedFirst, NULL, NULL);
    CGImageRef theImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    UIImage *ret = [UIImage imageWithCGImage:theImage scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(theImage);
    return ret;
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
        _imageProcessingQueue = dispatch_queue_create("com.origamilabs.imageProcessing", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size completionBlock:(OGImageProcessingBlock)block {
    [self scaleImage:image toSize:size method:OGImageProcessingScale_AspectFit completionBlock:block];
}

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size method:(OGImageProcessingScaleMethod)method completionBlock:(OGImageProcessingBlock)block {
    dispatch_async(_imageProcessingQueue, ^{
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize newSize = CGSizeZero;
        CGPoint offset = CGPointZero;
        CGSize fromSize = image.size;
        fromSize.width *= scale;
        fromSize.height *= scale;
        CGSize toSize = size;
        toSize.width *= scale;
        toSize.height *= scale;

        if (OGImageProcessingScale_AspectFit == method) {
            newSize = OGAspectFit(fromSize, toSize);
        } else {
            newSize = OGAspectFill(fromSize, toSize, &offset);
        }

        vImage_Buffer vBuffer;
        OSStatus err = UIImageToVImageBuffer(image, &vBuffer);
        if (noErr != err) {
            NSError *error = [NSError errorWithDomain:OGImageProcessingErrorDomain
                                                 code:err userInfo:@{NSLocalizedDescriptionKey : @"Error converting UIImage to vImage"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil, error);
            });
            return;
        }
        vImage_Buffer dBuffer;
        dBuffer.width = newSize.width;
        dBuffer.height = newSize.height;
        dBuffer.rowBytes = newSize.width * 4;
        dBuffer.data = malloc(newSize.width * newSize.height * 4);

        vImage_Error vErr = vImageScale_ARGB8888(&vBuffer, &dBuffer, NULL, kvImageNoFlags);
        if (kvImageNoError != vErr) {
            NSError *error = [NSError errorWithDomain:OGImageProcessingErrorDomain
                                                 code:err userInfo:@{NSLocalizedDescriptionKey : @"Error scaling image"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil, error);
            });
            return;
        }

        void *origDataPtr = dBuffer.data;

        if (OGImageProcessingScale_AspectFill == method) {
            if (0.f < offset.x) {
                dBuffer.data = dBuffer.data + ((int)offset.x * 4);
                dBuffer.width = toSize.width;
            } else if (0.f < offset.y) {
                int row_offset = (int)offset.y;
                row_offset *= dBuffer.rowBytes;
                dBuffer.data = dBuffer.data + row_offset;
                dBuffer.height = toSize.height;
            }
        }

        UIImage *scaledImage = VImageBufferToUIImage(&dBuffer, [UIScreen mainScreen].scale);
        free(vBuffer.data);
        free(origDataPtr);
        dispatch_async(dispatch_get_main_queue(), ^{
            block(scaledImage, nil);
        });
    });
}

@end
