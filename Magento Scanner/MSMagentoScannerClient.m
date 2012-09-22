//
//  MSMagentoScannerClient.m
//  Magento Scanner
//
//  Created by Red Davis on 22/09/2012.
//  Copyright (c) 2012 NIfty Apps. All rights reserved.
//

#import "MSMagentoScannerClient.h"
#import "MSStockTake.h"
#import "AFNetworkActivityIndicatorManager.h"


static NSString *const kMSBaseURL = @"http://192.168.147.177:8888";
static NSString *const kMSUpdateStockTakePath = @"/personal/magehack/stockupdate/api/update";


@implementation MSMagentoScannerClient

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url {
    
    self = [super initWithBaseURL:url];
    if (self) {
        
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [self setDefaultHeader:@"X-Api-Key" value:@"93u4oike04owkm30pwoeklsd"];
    }
    
    return self;
}

#pragma mark -

+ (MSMagentoScannerClient *)sharedClient {
    
    static MSMagentoScannerClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[MSMagentoScannerClient alloc] initWithBaseURL:[NSURL URLWithString:kMSBaseURL]];
    });
    
    return sharedClient;
}

#pragma mark - 

- (void)createStockTake:(MSStockTake *)stockTake completionBlock:(void (^)(BOOL, NSError *))block {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:stockTake.barCodeNumber, @"barcode", stockTake.amount, @"qty", nil];
    [self postPath:kMSUpdateStockTakePath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
        if (block) {
            block(YES, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (block) {
            block(NO, error);
        }
    }];
}

@end
