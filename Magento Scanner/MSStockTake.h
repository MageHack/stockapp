//
//  MSStockTake.h
//  Magento Scanner
//
//  Created by Red Davis on 22/09/2012.
//  Copyright (c) 2012 NIfty Apps. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ZBarImage;


@interface MSStockTake : NSObject

@property (copy, nonatomic) NSString *barCodeNumber;
@property (strong, nonatomic) NSNumber *amount;
@property (strong, nonatomic) UIImage *image;

@end
