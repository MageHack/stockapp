//
//  MSUploadStockTakesViewController.h
//  Magento Scanner
//
//  Created by Red Davis on 22/09/2012.
//  Copyright (c) 2012 NIfty Apps. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *const kMSUploadedStockTakesViewControllerXibName;


@interface MSUploadedStockTakesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *stocksTableView;
@property (strong,  nonatomic) NSArray *stockTakes;

@end
