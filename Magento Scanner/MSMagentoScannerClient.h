//
//  MSMagentoScannerClient.h
//  Magento Scanner
//
//  Created by Red Davis on 22/09/2012.
//  Copyright (c) 2012 NIfty Apps. All rights reserved.
//

#import "AFHTTPClient.h"


@class MSStockTake;


@interface MSMagentoScannerClient : AFHTTPClient

+ (MSMagentoScannerClient *)sharedClient;

- (void)createStockTake:(MSStockTake *)stockTake completionBlock:(void (^)(BOOL success, NSError *error))block;

@end
