//
//  QRUploadViewController.h
//  OCMQRScanner
//
//  Created by 王 文丰 on 2015/01/06.
//  Copyright (c) 2015年 sohobb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRUploadViewController : UIViewController

@property (nonatomic, strong) NSDictionary* info;

-(void)clearImageCache;
-(void)requestForRepair;

@end
