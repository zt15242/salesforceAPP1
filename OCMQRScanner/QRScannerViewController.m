//
//  QRScannerViewController.m
//  OCMQRScanner
//
//  Created by 王 文丰 on 2014/07/03.
//  Copyright (c) 2014年 sohobb. All rights reserved.
//

#import "QRScannerViewController.h"
#import "QRAssetTableViewController.h"
#import "SFRestAPI+Blocks.h"
#import "QRAppDelegate.h"

@interface QRScannerViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) CAShapeLayer *fillLayer;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegCtl;
@property (weak, nonatomic) IBOutlet UIButton *photoUpBtn;
@property (nonatomic) BOOL isReading;
@property (nonatomic) BOOL isBack;
@property (nonatomic) BOOL hasPop;
@end

@implementation QRScannerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _isBack = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _qrContent = nil;
    _hasPop = NO;
    [qrCodeField setKeyboardType:UIKeyboardTypeDefault];
    [self.view endEditing:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_videoPreviewLayer removeFromSuperlayer];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [_fillLayer removeFromSuperlayer];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [self startReading];
}

- (void) setDoneAction:(id)aTarget
                action:(SEL)aSelector
{
    target = aTarget;
    action = aSelector;
}

- (void) setUploadAction:(SEL)aSelector;
{
    upaction = aSelector;
}

- (BOOL)startReading {
    NSError *error;
    
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
    // as the media type parameter.
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Get an instance of the AVCaptureDeviceInput class using the previous device object.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];

    if (!input) {
        // If any error occurs, simply log the description of it and don't continue any more.
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    // Initialize the captureSession object.
    _captureSession = [[AVCaptureSession alloc] init];
    // Set the input device on the capture session.
    [_captureSession addInput:input];
    
    if ([[input device] respondsToSelector:@selector(setVideoZoomFactor:)]) {
        if ([ [input device] lockForConfiguration:nil]) {
            float zoomFactor = [input device].activeFormat.videoZoomFactorUpscaleThreshold;
            [[input device] setVideoZoomFactor:zoomFactor];
            [[input device] unlockForConfiguration];
        }
    }

    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    // Create a new serial dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:viewPreview.layer.bounds];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIInterfaceOrientation orientationNew = [UIApplication sharedApplication].statusBarOrientation;
        if (UIDeviceOrientationLandscapeLeft == orientationNew) {
            [[_videoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        } else if (UIDeviceOrientationLandscapeRight == orientationNew) {
            [[_videoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        }
    }
    
    [viewPreview.layer addSublayer:_videoPreviewLayer];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, viewPreview.frame.size.width, viewPreview.frame.size.height) cornerRadius:0];
        UIBezierPath *subPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(50, 80, 220, 220) cornerRadius:0];
        [path appendPath:subPath];
        [path setUsesEvenOddFillRule:YES];
        
        _fillLayer = [CAShapeLayer layer];
        _fillLayer.path = path.CGPath;
        _fillLayer.fillRule = kCAFillRuleEvenOdd;
        _fillLayer.fillColor = [UIColor blackColor].CGColor;
        _fillLayer.opacity = 0.5;
        [viewPreview.layer addSublayer:_fillLayer];
    }
    
    // Start video capture.
    [_captureSession startRunning];
    
    return YES;
}


-(void)stopReading{
    // Stop video capture and make the capture session object nil.
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_videoPreviewLayer removeFromSuperlayer];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [_fillLayer removeFromSuperlayer];
        _hasPop = YES;
        if (_photoUpBtn.isEnabled) {
            [self uploadPhoto:nil];
        } else {
            [target performSelector:action withObject:[qrCodeField text] withObject:@{@"scanType": @(_typeSegCtl.selectedSegmentIndex), @"backFlg": @(_isBack)}];
        }
    } else {
        if (_photoUpBtn.isEnabled) {
            [self uploadPhoto:nil];
        } else {
            [target performSelector:action withObject:_qrContent withObject:@{@"scanType": @(_typeSegCtl.selectedSegmentIndex)}];
        }
    }
    
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
//        [self.navigationController popToRootViewControllerAnimated:YES];
//    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.
            _qrContent = [metadataObj stringValue];
//            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [qrCodeField performSelectorOnMainThread:@selector(setText:) withObject:_qrContent waitUntilDone:NO];
//            }
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            
            _isReading = NO;
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)changeScanType:(UISegmentedControl*)sender {
    BOOL btnEnable = sender.selectedSegmentIndex == 1;
    [_photoUpBtn setEnabled:btnEnable];
    if (btnEnable) {
        [qrCodeField setKeyboardType:UIKeyboardTypeNumberPad];
        [self.view endEditing:YES];
//        [qrCodeField becomeFirstResponder];
    } else {
        [qrCodeField setKeyboardType:UIKeyboardTypeDefault];
        [self.view endEditing:YES];
    }
}
- (IBAction)uploadPhoto:(id)sender {
    if ([[qrCodeField text] length] == 0) return;
    [self.view setUserInteractionEnabled:NO];
    SFRestRequest* infoRequest = [[SFRestAPI sharedInstance] requestForQuery:[NSString stringWithFormat:@"Select Id, Product_Serial_No__c, Name, Remark__c, SerialNumber, ImageAsset__c, ImageSerial__c, Product2.Asset_Model_No__c, Internal_asset_location__c, ImageAssetUploadedTime__c, ImageSerialUploadedTime__c From Asset Where (SerialNumber = '%@' or Internal_Asset_number__c = '%@' or Internal_Asset_number_key__c = '%@') and Product2Id <> null", [qrCodeField text], [qrCodeField text], [qrCodeField text]]];
    infoRequest.networkOperation.operationTimeout = 20;
    
    UIActivityIndicatorView* indicator= [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
    indicator.layer.cornerRadius = 10;
    indicator.opaque = NO;
    indicator.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    indicator.center = self.view.center;
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [indicator setColor:[UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0]];
    [self.view addSubview: indicator];
    [indicator startAnimating];
    
    [[SFRestAPI sharedInstance] sendRESTRequest:infoRequest failBlock:^(NSError *e) {
        NSLog(@"error:%@", e);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
            [indicator stopAnimating];
            [indicator removeFromSuperview];
            
            UIAlertView* alertView=[[UIAlertView alloc]
                                    initWithTitle:@"错误" message:[NSString stringWithFormat:@"%@", e] delegate:self
                                    cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        });
    } completeBlock:^(NSDictionary *dict) {
        NSLog(@"dict:%@", dict);
        NSArray* records = [dict objectForKey:@"records"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
            [indicator stopAnimating];
            [indicator removeFromSuperview];
            if ([records count] > 0) {
                QRAssetTableViewController* assetVC = [self.storyboard instantiateViewControllerWithIdentifier:@"assetTable"];
                assetVC.infoList = records;
//                [self.navigationController pushViewController:assetVC animated:YES];
                [target performSelector:upaction withObject:assetVC];
            } else {
                UIAlertView* alertView=[[UIAlertView alloc]
                                        initWithTitle:@"错误" message:@"保有设备不存在" delegate:self
                                        cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
        });
    }];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (_captureSession == nil) {
        [self startReading];
    }
}

- (void)fetchRemarkLabel {
    SFRestRequest* descRequest = [[SFRestAPI sharedInstance] requestForDescribeWithObjectType:@"Asset"];
    descRequest.networkOperation.operationTimeout = 20;
    
    [[SFRestAPI sharedInstance] sendRESTRequest:descRequest failBlock:^(NSError *e) {
        UIAlertView* alertView=[[UIAlertView alloc]
                                initWithTitle:@"错误" message:[NSString stringWithFormat:@"%@", e] delegate:nil
                                cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } completeBlock:^(NSDictionary *dict) {
        NSArray* fields = [dict objectForKey:@"fields"];
        NSPredicate* p = [NSPredicate predicateWithFormat:@"name = %@", @"Remark__c"];
        NSDictionary* field = [[fields filteredArrayUsingPredicate:p] lastObject];
        NSString* labelStr = [field objectForKey:@"label"];
        
        QRAppDelegate* app = [[UIApplication sharedApplication] delegate];
        app.remarkLabel = labelStr;
    }];
}

- (IBAction)stopScaner:(id)sender {
    [self stopReading];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [textField resignFirstResponder];
    [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
    return NO;
}

- (void)willMoveToParentViewController:(UIViewController *)parent{
    if (parent == nil && !_hasPop){
        _isBack = YES;
        [self stopReading];
    }
}

@end
