//
//  QRViewController.h
//  OCMQRScanner
//
//  Created by 王 文丰 on 2014/07/03.
//  Copyright (c) 2014年 sohobb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRViewController : UIViewController<UIWebViewDelegate>
{
    IBOutlet UISegmentedControl *qrTypeSeg;
    IBOutlet UIWebView *mainWebView;
    IBOutlet UILabel *titleLabel;
}

- (void)checkLogin;
- (void)loadUserName;
- (void)loadUrl;
- (IBAction)qrReadAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (void)loadJS:(NSDictionary*)param;

@end
