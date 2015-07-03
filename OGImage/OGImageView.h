//
//  OGImageView.h
//  OGImageDemo
//
//  Created by Art Gillespie on 8/23/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OGImageView : UIImageView

/**
 * Set image view's image with the image at `url`. `OGImageView` supports the following
 * protocols:
 *
 * * `http` 
 * * `file`
 * * `assets-library`
 *
 * The image will be scaled and fit according to the view's `bounds` and `contentMode`,
 * respectively.
 */
- (void)setImageURL:(NSURL *)url placeholder:(UIImage *)image;

/**
 * If there's a problem loading the image, this property will be set. KVO-observable.
 * @see `OGImage.error`
 */
@property (nonatomic, strong, readonly) NSError *imageError;

@end
