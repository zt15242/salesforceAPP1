//
//  QRScannerViewController.h
//  OCMQRScanner
//
//  Created by 王 文丰 on 2014/07/03.
//  Copyright (c) 2014年 sohobb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QRScannerViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, UITextFieldDelegate>
{
    IBOutlet UIView *viewPreview;
    id target;
    SEL action;
    SEL upaction;
    IBOutlet UITextField *qrCodeField;
}

@property (nonatomic, strong) NSString* qrContent;

- (IBAction)stopScaner:(id)sender;
- (void) setDoneAction:(id)aTarget
                action:(SEL)aSelector;
- (void) setUploadAction:(SEL)aSelector;
- (void)fetchRemarkLabel;

@end
