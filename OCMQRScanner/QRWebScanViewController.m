//
//  QRWebScanViewController.m
//  OCMQRScanner
//
//  Created by Aismov on 2018/09/03.
//  Copyright © 2018年 sohobb. All rights reserved.
//

#import "QRWebScanViewController.h"

@interface QRWebScanViewController ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSDate* refractoryTime;
@property (strong, nonatomic) IBOutlet UILabel *type2Label;
@property (strong, nonatomic) IBOutlet UIButton *stopBtn;
@property (nonatomic, strong) NSString* lastQRCode;
@end

@implementation QRWebScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [_type2Label setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setDoneAction:(id)aTarget
                action:(SEL)aSelector
{
    target = aTarget;
    action = aSelector;
}

- (void) setCloseAction:(id)aTarget
                action:(SEL)aSelector
{
    target = aTarget;
    action_close = aSelector;
}

- (void) setTypeAction:(id)aTarget
                 action:(SEL)aSelector
{
    target = aTarget;
    action_changeType = aSelector;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_videoPreviewLayer removeFromSuperlayer];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self startReading];
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
    dispatchQueue = dispatch_queue_create("myWebQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, nil]];
    
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
    
    [qrHistory setText:@""];
    [target performSelector:action_close];
}
- (IBAction)stopAction:(id)sender {
    if (_type2Label.hidden == NO) {
        [self setScanType:1];
        [target performSelector:action_changeType];
        return;
    }
    [self stopReading];
}

- (void) setScanType:(int)type {
    if (type == 2) {
        [_type2Label setHidden:NO];
        [_stopBtn setTitle:@"返回常规扫描状态" forState:UIControlStateNormal];
    } else {
        [_type2Label setHidden:YES];
        [_stopBtn setTitle:@"停止扫描" forState:UIControlStateNormal];
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode] || [[metadataObj type] isEqualToString:AVMetadataObjectTypeCode128Code]) {
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.
            if (_refractoryTime == nil) {
                _refractoryTime = [NSDate date];
                _lastQRCode = [metadataObj stringValue];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [UIView animateWithDuration:0.12
                                          delay:0.0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         self.view.alpha = 0.0f;
                                     }
                                     completion:^(BOOL finished){
                                         self.view.alpha = 1.0f;
                                     }];
                    
                    AudioServicesPlaySystemSound(1115);
                    NSString* text = [NSString stringWithFormat:@"%@\r\n%@", [qrHistory text], [metadataObj stringValue]];
                    [qrHistory setText:text];
                    [qrHistory scrollRangeToVisible:(NSMakeRange(qrHistory.text.length - 1, 1))];
                    NSString* code = [metadataObj stringValue];
//                    if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeCode128Code]) {
//                        NSString* last8c = [code substringFromIndex:MAX((int)[code length]-8, 0)];
//                        if ([last8c hasPrefix:@"250"]) {
//                            code = [code substringToIndex:MAX((int)[code length]-8, 0)];
//                        }
//                    }
                    code = [code stringByReplacingOccurrencesOfString:@"\x1d" withString:@""];
                    code = [code stringByReplacingOccurrencesOfString:@"\x1e" withString:@""];
                    code = [code stringByReplacingOccurrencesOfString:@"\x04" withString:@""];
                    [target performSelector:action withObject:code];
                });
            } else {
                if ([[metadataObj stringValue] isEqualToString:_lastQRCode]) {
                    if ([_refractoryTime timeIntervalSinceNow] < -5) {
                        _refractoryTime = nil;
                    } else {
                        return;
                    }
                } else {
                    _refractoryTime = nil;
                }
            }
            
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
