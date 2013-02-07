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
    offset->x = 0.f;
    offset->y = 0.f;
    CGFloat sRatio = from.width / from.height;
    CGFloat dRatio = to.width / to.height;
    CGFloat ratio = (dRatio <= sRatio) ? to.height / from.height : to.width / from.width;
    CGSize ret = CGSizeMake(roundf(from.width * ratio), roundf(from.height * ratio));
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

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius completionBlock:(OGImageProcessingBlock)block {
    [self scaleImage:image toSize:size cornerRadius:cornerRadius method:OGImageProcessingScale_AspectFit completionBlock:block];
}

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius method:(OGImageProcessingScaleMethod)method completionBlock:(OGImageProcessingBlock)block {
    dispatch_async(_imageProcessingQueue, ^{
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize newSize = CGSizeZero;
        CGPoint offset = CGPointZero;
        CGSize fromSize = image.size;
        fromSize.width *= image.scale;
        fromSize.height *= image.scale;
        CGSize toSize = size;
        toSize.width *= scale;
        toSize.height *= scale;

        // if the two sizes are the same, I mean, come on
        if (CGSizeEqualToSize(fromSize, toSize)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(image, nil);
            });
            return;
        }

        NSParameterAssert(toSize.width < fromSize.width && toSize.height < fromSize.height);
        if (OGImageProcessingScale_AspectFit == method) {
            newSize = OGAspectFit(image.size, size);
        } else {
            newSize = OGAspectFill(image.size, size, &offset);
        }
        newSize.width *= scale;
        newSize.height *= scale;
        offset.x *= scale;
        offset.y *= scale;
        NSParameterAssert(newSize.width < fromSize.width && newSize.height < fromSize.height);

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
                // TODO: [alg] Well, commenting this out kills the crash (see https://github.com/origamilabs/OGImage/issues/7),
                //  but kinda breaks aspect fill.
                //  With this commented out, aspect fills that need to crop horizontally won't center:
                //  they'll just crop the rightmost pixels.
                //
                // Notes:
                // When we set this offset, it occasionally causes a memcpy crash deep in
                // CGBitmapContextCreateImage (in the call to VImageBufferToUIImage below)
                // Not sure what's going on here.

                // dBuffer.data = dBuffer.data + ((int)offset.x * 4);
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
        if (0.f < cornerRadius) {
            scaledImage = [self applyCornerRadius:cornerRadius toImage:scaledImage];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            block(scaledImage, nil);
        });
    });
}

- (UIImage *)applyCornerRadius:(CGFloat)cornerRadius toImage:(UIImage *)origImage {
    CGSize _size = origImage.size;
    float _cornerRadius = cornerRadius;
    // If we're on a retina display, make sure everything is @2x
    if ([[UIScreen mainScreen] scale] > 1.f) {
        _size.width *= origImage.scale;
        _size.height *= origImage.scale;
        _cornerRadius *= origImage.scale;
    }

    // Lots of weird math
    uint32_t bitsPerComponent = 8;
    uint32_t numberOfComponents = 4;
    uint32_t dataSize = _size.height * _size.width * (numberOfComponents * bitsPerComponent) / 8;
    uint8_t *data = (uint8_t *)malloc(dataSize);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    bzero(data, dataSize);

    // REFACTOR: [alg] Is this okay? Before we determined whether we'd save as JPEG or PNG
    // and set the alpha info appropriately, but this processing code shouldn't
    // know how we're saving it.
    CGImageAlphaInfo alphaInfo = kCGImageAlphaPremultipliedLast;
    CGContextRef context = CGBitmapContextCreate(data, _size.width, _size.height, bitsPerComponent,
                                                 _size.width * (bitsPerComponent * numberOfComponents) / 8, colorSpace,
                                                 alphaInfo);

    // Let's round the corners, if desired
    if (_cornerRadius != 0.0) {
        CGContextSaveGState(context);
        CGContextMoveToPoint(context, 0.f, _cornerRadius);
        CGContextAddArc(context, _cornerRadius, _cornerRadius, _cornerRadius, M_PI, 1.5 * M_PI, 0);
        CGContextAddLineToPoint(context, _size.width - _cornerRadius, 0.f);
        CGContextAddArc(context, _size.width - _cornerRadius, _cornerRadius, _cornerRadius, 1.5 * M_PI, 0.f, 0);
        CGContextAddLineToPoint(context, _size.width, _size.height - _cornerRadius);
        CGContextAddArc(context, _size.width - _cornerRadius, _size.height - _cornerRadius, _cornerRadius, 0.f, 0.5 * M_PI, 0);
        CGContextAddLineToPoint(context, _cornerRadius, _size.height);
        CGContextAddArc(context, _cornerRadius, _size.height - _cornerRadius, _cornerRadius, 0.5 * M_PI, M_PI, 0);
        CGContextAddLineToPoint(context, 0.f, _cornerRadius);
        CGContextSaveGState(context);
        CGContextClip(context);
    }

    // Create a fresh image from the context
    CGContextDrawImage(context, CGRectMake(0.f, 0.f, _size.width, _size.height), [origImage CGImage]);
    if (_cornerRadius != 0.0)
        CGContextRestoreGState(context);
    CGImageRef image = CGBitmapContextCreateImage(context);
    UIImage *ret = [UIImage imageWithCGImage:image scale:origImage.scale orientation:UIImageOrientationUp];
    if (image)
        CFRelease(image);

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(data);
    context = NULL;
    return ret;
}

@end
