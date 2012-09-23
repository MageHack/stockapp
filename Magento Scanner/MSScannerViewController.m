//
//  MSScannerViewController.m
//  Magento Scanner
//
//  Created by Red Davis on 22/09/2012.
//  Copyright (c) 2012 NIfty Apps. All rights reserved.
//

#import "MSScannerViewController.h"
#import "ZBarSDK.h"
#import "MSStockTake.h"
#import "MSUploadedStockTakesViewController.h"
#import "MSMagentoScannerClient.h"

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>


@interface MSScannerViewController () <ZBarReaderDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) AVCaptureSession *cameraSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) NSTimer *captureImageTimer;
@property (strong, nonatomic) MSStockTake *capturedStockTake;
@property (strong, nonatomic) NSMutableArray *stockTakes;

- (AVCaptureSession *)buildCaptureSession;
- (void)showEnterAmountAlert;
- (void)processCameraImage:(id)sender;
- (void)userTappedScreen:(UIGestureRecognizer *)gesture;
- (void)userSwippedScreen:(UIGestureRecognizer *)gesture;

@end


NSString *const kMSScannerViewControllerXibName = @"MSScannerViewController";
static NSInteger const kMSAmountAlertViewTag = 1111;


@implementation MSScannerViewController

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Magento Scanner";
    
    self.stockTakes = [NSMutableArray array];
    
    UITapGestureRecognizer *tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedScreen:)];
    [self.cameraPreviewView addGestureRecognizer:tapGestureRecogniser];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(userSwippedScreen:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    self.cameraSession = [self buildCaptureSession];
    [self.cameraSession startRunning];
    
    self.captureImageTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(processCameraImage:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.captureImageTimer invalidate];
    [self.cameraSession stopRunning];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (void)userSwippedScreen:(UIGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        MSUploadedStockTakesViewController *uploadedStockTakesViewController = [[MSUploadedStockTakesViewController alloc] initWithNibName:kMSUploadedStockTakesViewControllerXibName bundle:nil];
        uploadedStockTakesViewController.stockTakes = self.stockTakes;
        [self.navigationController pushViewController:uploadedStockTakesViewController animated:YES];
    }
}

- (void)userTappedScreen:(UIGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        // Not working right now :(
//        CGPoint location = [gesture locationInView:self.cameraPreviewView];
//        
//        AVCaptureDeviceInput *captureInput = [self.cameraSession.inputs objectAtIndex:0];
//        AVCaptureDevice *device = captureInput.device;
//
//        [device lockForConfiguration:nil];
//        
//        [device setFocusPointOfInterest:location];
//        [device setFocusMode:AVCaptureFocusModeAutoFocus];
//        
//        [device unlockForConfiguration];
    }
}

- (void)showEnterAmountAlert {
    
    UIAlertView *amountAlert = [[UIAlertView alloc] initWithTitle:@"Enter Amount" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    amountAlert.tag = kMSAmountAlertViewTag;
    amountAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [amountAlert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
    
    [amountAlert show];
}

- (void)processCameraImage:(id)sender {
        
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) break;
    }
    
    if (![self.cameraSession isRunning]) {
        
        [self.cameraSession startRunning];
        return [self processCameraImage:nil];
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
                
        ZBarImage *zBarImage = [[ZBarImage alloc] initWithCGImage:image.CGImage];
        ZBarImageScanner *imageScanner = [[ZBarImageScanner alloc] init];
        [imageScanner scanImage:zBarImage];
        
        if (self.capturedStockTake) {
            return;
        }
        
        if (zBarImage.symbols.count > 0) {
            
            self.capturedStockTake = [[MSStockTake alloc] init];
            self.capturedStockTake.image = image;
            
            for (ZBarSymbol *symbol in zBarImage.symbols) {
                
                if (self.capturedStockTake.barCodeNumber) {
                    return;
                }
                
                self.capturedStockTake.barCodeNumber = symbol.data;
            }
                        
            [self showEnterAmountAlert];
        }
    }];
}

#pragma mark - Helpers

- (AVCaptureSession *)buildCaptureSession {
    
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureInput *captureInput = nil;
    
    for (AVCaptureDevice *device in cameras) {
        
        if (device.position == AVCaptureDevicePositionBack) {
            
            [device lockForConfiguration:nil];
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
            
            NSError *error = nil;
            captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            
            if (error) {
                NSLog(@"Error settings up capture input %@", error);
            }
        }
    }
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    [captureSession addInput:captureInput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    self.stillImageOutput.outputSettings = outputSettings;
    
    [captureSession addOutput:self.stillImageOutput];
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    previewLayer.frame = self.cameraPreviewView.bounds;
    self.cameraPreviewView.layer.sublayers = nil;
    [self.cameraPreviewView.layer addSublayer:previewLayer];
    
    return captureSession;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == kMSAmountAlertViewTag) {
        
        if (buttonIndex == 1) {
            
            UITextField *amountTextField = [alertView textFieldAtIndex:0];
            self.capturedStockTake.amount = [NSNumber numberWithInteger:amountTextField.text.integerValue];
            
            [self.stockTakes addObject:self.capturedStockTake];
            
            [[MSMagentoScannerClient sharedClient] createStockTake:self.capturedStockTake completionBlock:^(BOOL success, NSError *error) {
               
                if (success) {
                    
                    NSLog(@"Success");
                }
                else {
                    
                    NSError *JSONReadingError = nil;
                    id JSON = [NSJSONSerialization JSONObjectWithData:[error.localizedRecoverySuggestion dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&JSONReadingError];
                    
                    if (!JSONReadingError) { // If Nick's fucked up
                        NSString *errorMessage = [JSON objectForKey:@"message"];
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    }
                    else {
                        NSLog(@"%@", JSONReadingError);
                    }
                }
            }];
            
            self.capturedStockTake = nil;
        }
        else {
            self.capturedStockTake = nil;
        }
    }
}

@end
