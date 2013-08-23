//
//  OGImageTableViewCell.h
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OGImageView.h"

@interface OGImageTableViewCell : UITableViewCell

@property (nonatomic, readonly, strong) OGImageView *ogImageView;

@end
