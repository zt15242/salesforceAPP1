//
//  QRAppDelegate.h
//  OCMQRScanner
//
//  Created by 王 文丰 on 2014/07/03.
//  Copyright (c) 2014年 sohobb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) BOOL autoLogin;
@property (strong, nonatomic) NSString* remarkLabel;

@end
