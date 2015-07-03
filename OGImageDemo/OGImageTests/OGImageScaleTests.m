//
//  OGImageScaleTests.m
//  OGImageDemo
//
//  Created by Sixten Otto on 11/4/14.
//  Copyright (c) 2014 Origami Labs. All rights reserved.
//

#import <GHUnit/GHUnit.h>
#import "__OGImage.h"
//#import "OGImageCache.h"

@interface OGImageScaleTests : GHAsyncTestCase

@property (strong, nonatomic) NSURL *destinationDirectoryURL;

@end

@implementation OGImageScaleTests

- (void)setUp {
  NSURL *tempDir = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:@"OGImageScaleTests" isDirectory:YES];
  if( ![[NSFileManager defaultManager] fileExistsAtPath:[tempDir path]] ) {
    [[NSFileManager defaultManager] createDirectoryAtURL:tempDir withIntermediateDirectories:NO attributes:nil error:NULL];
  }
  self.destinationDirectoryURL = tempDir;
  
  //[[OGImageCache shared] purgeCache:YES];
}

- (void)tearDown {
  [[NSFileManager defaultManager] removeItemAtURL:self.destinationDirectoryURL error:NULL];
  //[[OGImageCache shared] purgeCache:YES];
}

- (UIImage *)newTestImageAtScale:(float)scale
{
  CGSize size = CGSizeMake(80, 17);
  CGRect bounds = (CGRect){.origin=CGPointZero, .size=size};
  UIGraphicsBeginImageContextWithOptions(size, YES, scale);
  
  [[UIColor whiteColor] setFill];
  UIRectFill(bounds);
  
  CGFloat r = (arc4random_uniform(101) / 100.f),
          g = (arc4random_uniform(101) / 100.f),
          b = (arc4random_uniform(101) / 100.f);
  [[UIColor colorWithRed:r green:g blue:b alpha:0.5f] setFill];
  UIRectFill(bounds);
  
  [@"Lorem ipsum dolor sit amet" drawInRect:bounds withFont:[UIFont systemFontOfSize:15]];
  
  UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return result;
}

- (void)test1xImagesHaveNoExtension {
  UIImage *testImg = [self newTestImageAtScale:1.0f];
  __OGImage *img = [[__OGImage alloc] initWithCGImage:testImg.CGImage scale:testImg.scale orientation:UIImageOrientationUp];
  NSURL *fileURL = [self.destinationDirectoryURL URLByAppendingPathComponent:@"one_echs_image.png"];
  
  BOOL success = [img writeToURL:fileURL error:NULL];
  GHAssertTrue(success, @"Should successfully write to file.");
  GHAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]], @"File should exist with unmodified name");
}

- (void)testRetinaImagesHaveResolutionExtensions {
  for( CGFloat s = 2.0f; s < 6.0f; ++s ) {
    UIImage *testImg = [self newTestImageAtScale:s];
    __OGImage *img = [[__OGImage alloc] initWithCGImage:testImg.CGImage scale:s orientation:UIImageOrientationUp];
    NSURL *fileURL = [self.destinationDirectoryURL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    NSURL *expectedFileURL = [fileURL URLByAppendingPathExtension:[NSString stringWithFormat:@"@%lix", (long)s]];
    
    BOOL success = [img writeToURL:fileURL error:NULL];
    GHAssertTrue(success, @"Should successfully write to file.");
    GHAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]], @"File should not exist with unmodified name at scale %.0f", s);
    GHAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[expectedFileURL path]], @"File should exist with modified name at scale %.0f", s);
  }
}

- (void)testImagesWithNoExtensionLoadedAs1x {
  UIImage *testImg = [self newTestImageAtScale:1.0f];
  NSURL *fileURL = [self.destinationDirectoryURL URLByAppendingPathComponent:@"one_echs_image.png"];
  [UIImagePNGRepresentation(testImg) writeToURL:fileURL atomically:YES];
  
  __OGImage *img = [[__OGImage alloc] initWithDataAtURL:fileURL];
  GHAssertNotNil(img, @"Should load the image.");
  GHAssertEquals((CGFloat)1.0f, img.scale, @"Loaded image should be 1x");
}

- (void)testImagesWithResolutionExtensionsLoadedWithScale {
  for( CGFloat s = 2.0f; s < 6.0f; ++s ) {
    UIImage *testImg = [self newTestImageAtScale:s];
    NSURL *fileURL = [self.destinationDirectoryURL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [UIImagePNGRepresentation(testImg) writeToURL:[fileURL URLByAppendingPathExtension:[NSString stringWithFormat:@"@%lix", (long)s]] atomically:YES];
    
    __OGImage *img = [[__OGImage alloc] initWithDataAtURL:fileURL];
    GHAssertNotNil(img, @"Should load the image at scale %.0f", s);
    GHAssertEquals(s, img.scale, @"Loaded image should match scale %.0f", s);
  }
}

@end
