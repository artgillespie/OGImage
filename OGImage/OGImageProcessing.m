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
        CGSize toSize = size;
        toSize.width *= scale;
        toSize.height *= scale;
        CGSize oSize = image.size;
        oSize.width *= image.scale;
        oSize.height *= image.scale;
        CGFloat sRatio = image.size.width / image.size.height;
        CGFloat dRatio = toSize.width / toSize.height;
        CGFloat ratio = (dRatio <= sRatio) ? toSize.height / oSize.height : toSize.width / oSize.width;
        CGSize newSize = CGSizeMake(ceilf(oSize.width * ratio), ceilf(oSize.height * ratio));
        if (OGImageProcessingScale_AspectFit == method) {
            newSize = OGAspectFit(image.size, size);
            newSize.width *= scale;
            newSize.height *= scale;
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
            if (dBuffer.width > toSize.width) {
                // what's the x offset?
                int offset = dBuffer.width / 2 - toSize.width / 2;
                dBuffer.data = dBuffer.data + (offset * 4);
                dBuffer.width = toSize.width;
            } else if (dBuffer.height > toSize.height) {
                // what's the y offset?
                int row_offset = dBuffer.height / 2 - toSize.height / 2;
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
