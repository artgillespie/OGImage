OGImage
=======

## Introduction

The idea behind `OGImage` is to encapsulate best practices for loading images
over HTTP in a simple, extensible interface.

### Philosophy

* The default use case should be *ridiculously* simple to execute. In OGImage,
  you can load, cache, and scale an image with the following call:

    ```objc
    OGScaledImage *ogImage = [[OGScaledImage alloc] initWithURL:imageURL size:renderSize key:nil];
    [ogImage addObserver:self forKey:@"scaledImage" options:NSKeyValueObservingOptionNew context:nil];
    // there is no step 3!
    ```

* Networking belongs in the Model. Views (and to some degree, Controllers)
  shouldn't know anything about where images come from: That's the model's job.
  OGImage is designed as a model object: Controllers and Views learn about
  changes to it (e.g., when an image has loaded) through KVO.
* Generally, more recently requested images should have higher loading
  priority. For example, if images are being loaded on demand as a user scrolls
  through a table view, the user experience is improved if they don't have to
  wait for all the images they've scrolled past to load before the images that
  are visible are loaded. At the same time, we don't believe in waiting until a
  table view has finished scrolling to start loading images.  OGImage addresses
  these competing requirements by pushing image load requests into a LIFO
  queue.
* Each subsystem should have its own GCD queue.

## Installation

To use OGImage in your projects, simply add the files in the `OGImage`
subdirectory to your target.

If you're using `OGScaledImage` and/or `OGImageProcessing`, you'll need to add
`Accelerate.framework` to your target's "Link Binary With Libraries" build
phase.

## Usage

OGImage has a simple interface; just instantiate with the image's URL and
listen for KVO notifications on the `image` property. You can also specify a
placeholder image to use until loading is complete with
`initWithURL:placeholderImage`

```objc
#import "OGImage.h"

...

OGImage *image = [[OGImage alloc] initWithURL:[NSURL URLWithString:@"http://somedomain.com/someimage.jpg"]];
[image addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];

...

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        // image was loaded!
        ...
    } else if ([keyPath isEqualToString:@"error"]) {
        // error loading image
    }
}
```

There are also caching (`OGCachedImage`) and caching+scaling (`OGScaledImage`)
subclasses that provide useful functionality and demonstrate how to go about
bending OGImage to your needs via subclassing.

```objc

#import "OGScaledImage.h"

/*
 * The image at `imageURL` will be loaded from one of in-memory cache, disk cache or
 * over the network and scaled to `scaledSize`. Note that if the image at `imageURL`
 * has already been scaled to `scaledSize` in the past, OGScaledImage will simply
 * load the scaled image from cache.
 */
OGScaledImage *image = [[OGScaledImage alloc] initWithURL:imageURL size:scaledSize key:nil];

/*
 * Note that here we're interested in the `scaledImage` property, not the full-size `image`
 * property.
 */
[image addObserver:self forKeyPath:@"scaledImage" options:NSKeyValueObservingOptionNew context:nil];

...

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"scaledImage"]) {
        // image was loaded and scaled!
        ...
    } else if ([keyPath isEqualToString:@"error"]) {
        // error loading image
    }
}
```

## Demo and Tests

This repo contains a very simple project that demonstrates the use of
`OGScaledImage` with a stock `UITableView`.

To run the demo and tests in the `OGImageDemo project`, you'll need
[CocoaPods](http://cocoapods.org/) If you already have cocoapods on your
system, just run `pod install` from the terminal in the `OGImageDemo`
directory.

Note that you *do not* need cocoapods to use `OGImage` in your projects--there
are no external dependencies for the library itself, only for the tests
(GHUnit) and demo (CocoaLumberjack)

## TODO:

* Sexier demo app, maybe something `UICollectionView`-based.
* More image processing operations, e.g., adding rounded corners, b&w, etc.
* More test coverage.

