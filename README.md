OGImage
=======

## Installation

To use OGImage in your projects, simply add the files in the `OGImage`
subdirectory to your target.

## Usage

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
    }
}
```

## Demo and Tests

To run the demo and tests in the `OGImageDemo project`, you'll need
[CocoaPods](http://cocoapods.org/) If you already have cocoapods on your
system, just run `pod install` from the terminal in the `OGImageDemo`
directory.

Note that you *do not* need cocoapods to use `OGImage` in your projects--there
are no external dependencies for the library itself, only for the tests
(GHUnit) and demo (CocoaLumberjack)

## TODO:

* Add hooks and/or subclasses for caching and processing the images.
