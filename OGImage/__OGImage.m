//
//  __OGImage.m
//  OGImageDemo
//
//  Created by Art Gillespie on 2/8/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import "__OGImage.h"
#import <ImageIO/ImageIO.h>

NSString * const OGImageInfoKey = @"OGImageInfoKey";
NSString * const OGImageInfoScaleKey = @"OGImageInfoScaleKey";

UIImageOrientation OGEXIFOrientationToUIImageOrientation(NSInteger exif) {
    switch (exif) {
        case 1: // landscape left
            return UIImageOrientationUp;
        case 3: // landscape right
            return UIImageOrientationDown;
        case 8: // portrait down
            return UIImageOrientationLeft;
        case 6: // portrait up
            return UIImageOrientationRight;
        case 2: //
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

NSString *OGResolutionSuffixForScale(CGFloat scale) {
  return [NSString stringWithFormat:@"@%.0fx", scale];
}

@implementation __OGImage

- (id)initWithDataAtURL:(NSURL *)url {
    CGFloat scale = 1.f;
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        // handling of scaled images is still limited, but at a practical level, the odds of seeing scale factors > 10 seem pretty long
        // try to optimize by starting with screen rez of device
        // possible that directory enumeration might be faster? but generally, hard to prove the negative proposition that there's no file
        scale = [[UIScreen mainScreen] scale];
        NSURL *scaledURL = [url URLByAppendingPathExtension:OGResolutionSuffixForScale(scale)];
        if (YES == [[NSFileManager defaultManager] fileExistsAtPath:[scaledURL path]]) {
            url = scaledURL;
        }
        else {
            // no file at the device resolution; try others
            // ??? or should we refuse to load images at mis-matched rez?
            for (scale = 2.f; scale < 11.f; ++scale) {
                if( scale != [[UIScreen mainScreen] scale] ) {
                    scaledURL = [url URLByAppendingPathExtension:OGResolutionSuffixForScale(scale)];
                    if (YES == [[NSFileManager defaultManager] fileExistsAtPath:[scaledURL path]]) {
                        url = scaledURL;
                        break;
                    }
                }
            }
        }
        if( url != scaledURL ) {
            return nil;
        }
    }
    NSData *data = [NSData dataWithContentsOfURL:url];
    return [self initWithData:data scale:scale];
}

- (id)initWithCGImage:(CGImageRef)image type:(NSString *)type info:(NSDictionary *)info alphaInfo:(CGImageAlphaInfo)alphaInfo scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    self = [super initWithCGImage:image scale:scale orientation:orientation];
    if (nil != self) {
        _originalFileType = type;
        _originalFileProperties = info;
        _originalFileAlphaInfo = alphaInfo;
    }
    return self;
}

- (id)initWithCGImage:(CGImageRef)image type:(NSString *)type info:(NSDictionary *)info alphaInfo:(CGImageAlphaInfo)alphaInfo {
    self = [super initWithCGImage:image];
    if (nil != self) {
        _originalFileType = type;
        _originalFileProperties = info;
        _originalFileAlphaInfo = alphaInfo;
    }
    return self;
}

- (id)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (nil == data)
        return nil;

    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (NULL == imageSource) {
        // data isn't nil, but we couldn't create an image out of it...
        return nil;
    } else {
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        if (NULL == cgImage) {
            CFRelease(imageSource);
            return nil;
        } else {
            _originalFileProperties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil));
            // do we have an OGImageDictionary?
            _originalFileType = (__bridge NSString *)CGImageSourceGetType(imageSource);
            _originalFileAlphaInfo = CGImageGetAlphaInfo(cgImage);
            _originalFileOrientation = [_originalFileProperties[(__bridge NSString *)kCGImagePropertyOrientation] integerValue];
            self = [super initWithCGImage:cgImage scale:scale orientation:OGEXIFOrientationToUIImageOrientation(_originalFileOrientation)];
            CGImageRelease(cgImage);
        }
        CFRelease(imageSource);
    }
    return self;
}

- (CGImageAlphaInfo)alphaInfo {
    return CGImageGetAlphaInfo(self.CGImage);
}

- (BOOL)writeToURL:(NSURL *)fileURL error:(NSError **)error {
    NSString *imgType = _originalFileType;
    if (nil == imgType) {
        if (kCGImageAlphaFirst == self.alphaInfo ||
            kCGImageAlphaLast == self.alphaInfo ||
            kCGImageAlphaPremultipliedFirst == self.alphaInfo ||
            kCGImageAlphaPremultipliedLast == self.alphaInfo) {
            imgType = @"public.png";
        } else {
            imgType = @"public.jpeg";
        }
    }
    if (1.f < self.scale) {
        fileURL = [fileURL URLByAppendingPathExtension:OGResolutionSuffixForScale(self.scale)];
    }
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, (__bridge CFStringRef)imgType, 1, NULL);
    if (NULL == imageDestination) {
        if (nil != error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-255 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"[OGImageCache ERROR] failed to created image destination %s %d", __FILE__, __LINE__]}];
        }
        return NO;
    }
    CGImageDestinationAddImage(imageDestination, self.CGImage, (__bridge CFDictionaryRef)_originalFileProperties);
    CGImageDestinationFinalize(imageDestination);
    CFRelease(imageDestination);
    return YES;
}

@end
