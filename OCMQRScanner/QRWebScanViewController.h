//
//  QRWebScanViewController.h
//  OCMQRScanner
//
//  Created by Aismov on 2018/09/03.
//  Copyright © 2018年 sohobb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QRWebScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>
{
    IBOutlet UIView *viewPreview;
    id target;
    SEL action;
    SEL action_close;
    SEL action_changeType;
    IBOutlet UITextView *qrHistory;
}

- (void) setScanType:(int)type;

- (void) setDoneAction:(id)aTarget
                action:(SEL)aSelector;

- (void) setCloseAction:(id)aTarget
                action:(SEL)aSelector;

- (void) setTypeAction:(id)aTarget
                 action:(SEL)aSelector;
@end
