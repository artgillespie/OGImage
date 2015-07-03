//
//  OGViewController.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGViewController.h"
#import "OGImageTableViewCell.h"

@interface OGViewController ()

@end

@implementation OGViewController {
    NSArray *_urls;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"OGImageDemo", @"");
    [self loadJSON];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadJSON {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *jsonURL = [[NSBundle mainBundle] URLForResource:@"james_bond" withExtension:@"json"];
        NSAssert(nil != jsonURL, @"Couldn't get json resource URL");
        NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
        NSAssert(nil != jsonData, @"Couldn't load json resource data");
        NSError *error;
        NSArray *tmpArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (nil == tmpArray) {
            NSAssert(NO, @"Couldn't parse json resource: %@", error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _urls = tmpArray;
            [self.tableView reloadData];
        });
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_urls count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const OGImageCellIdentifier = @"OGImageCellIdentifier";
    OGImageTableViewCell *cell = (OGImageTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:OGImageCellIdentifier];
    if (nil == cell) {
        cell = [[OGImageTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:OGImageCellIdentifier];
        cell.ogImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    NSURL *imageURL = [NSURL URLWithString:_urls[indexPath.row]];
    [cell.ogImageView setImageURL:imageURL placeholder:[UIImage imageNamed:@"placeholder"]];
    cell.textLabel.text = [imageURL lastPathComponent];
    return cell;
}

@end
