//
//  OGImageTableViewCell.h
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OGScaledImage;

@interface OGImageTableViewCell : UITableViewCell

@property (nonatomic, strong) OGScaledImage *image;

@end
