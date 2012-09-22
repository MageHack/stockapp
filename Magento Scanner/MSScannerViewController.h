//
//  MSScannerViewController.h
//  Magento Scanner
//
//  Created by Red Davis on 22/09/2012.
//  Copyright (c) 2012 NIfty Apps. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *const kMSScannerViewControllerXibName;


@interface MSScannerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *cameraPreviewView;

@end
