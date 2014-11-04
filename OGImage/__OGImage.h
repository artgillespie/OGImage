//
//  __OGImage.h
//  OGImageDemo
//
//  Created by Art Gillespie on 2/8/13.
//  art@origami.com
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Note the underscores in the name of this class: It's intended for internal use only.
 *
 * This is a simple subclass of `UIImage` that lets us pass around some additional
 * information (original file type, metadata, alpha info) and provides some
 * convenience methods for saving/loading.
 *
 * When you create an __OGImage with a fileURL or NSData instance, it uses the
 * Image I/O framework under the hood to find out about the file's format, metadata
 * and alpha. Additionally, if the file ends with an extension like `.@2x`,
 * __OGImage will set UIImage's `scale` property correctly.
 *
 * When you save an __OGImage using `writeToURL`, it will automatically choose
 * the best format based on the current alpha properties and original file format.
 * Additionally, if the superclass' property `scale` is > 1, `writeToURL` will
 * automatically append a resolution suffix like `.@2x`.
 * 
 * (Ultimately, this `.@2x` stuff is an implementation detail: If you're not
 * worried about cache internals, you don't need to worry about this. Just use
 * keys normally and `__OGImage` and friends will figure everything out for you.
 */

@interface __OGImage : UIImage

/**
 * Given a file URL, this will use Image I/O to load the file and populate the
 * `originalFileType`, `originalFileProperties` and `originalFileAlphaInfo` properties.
 * Additionally, if there's scale info in the file, this will set `scale` correctly.
 */
- (id)initWithDataAtURL:(NSURL *)url;

/**
 * Given an `NSData` instance, this will use Image I/O to load the data and populate the `originalFile**`
 * properties.
 */
- (id)initWithData:(NSData *)data scale:(CGFloat)scale;

- (id)initWithCGImage:(CGImageRef)image type:(NSString *)type info:(NSDictionary *)info alphaInfo:(CGImageAlphaInfo)alphaInfo;

- (id)initWithCGImage:(CGImageRef)image type:(NSString *)type info:(NSDictionary *)info alphaInfo:(CGImageAlphaInfo)alphaInfo scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;

@property (nonatomic, readonly) NSString *originalFileType;

@property (nonatomic, readonly) NSDictionary *originalFileProperties;

@property (nonatomic, readonly) CGImageAlphaInfo originalFileAlphaInfo;

@property (nonatomic, readonly) CGImageAlphaInfo alphaInfo;

// note this is the TIFF/EXIF orientation number, not UIImageOrientation constant
@property (nonatomic, readonly) NSInteger originalFileOrientation;

@end
