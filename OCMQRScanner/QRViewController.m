//
//  QRViewController.m
//  OCMQRScanner
//
//  Created by 王 文丰 on 2014/07/03.
//  Copyright (c) 2014年 sohobb. All rights reserved.
//

#import "QRViewController.h"
#import "QRScannerViewController.h"
#import "QRUploadViewController.h"
#import "QRWebScanViewController.h"
#import "QRAppDelegate.h"
#import "QRAssetTableViewController.h"
#import <SalesforceSDKCore/SFUserAccountManager.h>
#import <SalesforceSDKCore/SFUserAccount.h>
#import <SalesforceNativeSDK/SFRestAPI+Blocks.h>
#import <SalesforceSDKCore/SFAuthenticationManager+Internal.h>

@interface QRViewController ()
@property (strong, nonatomic) IBOutlet UIButton *BackBtn;
@property (nonatomic, strong) UIPopoverController* popOver;
@property (nonatomic, strong) UIPopoverController* webPopOver;
@property (weak, nonatomic) IBOutlet UIWebView *loginWebView;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (nonatomic, strong) UIActivityIndicatorView* indicator;
@property (strong, nonatomic) QRUploadViewController* qrUpVC;
@property (strong, nonatomic) NSString *codeAid;
@end

@implementation QRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [qrTypeSeg addTarget:self action:@selector(segment_ValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    mainWebView.scalesPageToFit = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        QRScannerViewController* popOverVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QRScanner"];
        popOverVC.modalInPopover = YES;
        popOverVC.modalPresentationStyle = UIModalPresentationCurrentContext;
        [popOverVC fetchRemarkLabel];
        [popOverVC setDoneAction:self action:@selector(doneQRScan:cfg:)];
        [popOverVC setUploadAction:@selector(toUploadView:)];
        
        if (self.popOver == nil)
        {
            self.popOver = [[UIPopoverController alloc] initWithContentViewController:popOverVC];
        }
        
        QRWebScanViewController* webPopOverVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QRWebScan"];
        webPopOverVC.modalInPopover = YES;
        webPopOverVC.modalPresentationStyle = UIModalPresentationCurrentContext;
        [webPopOverVC setCloseAction:self action:@selector(dismissPop)];
        [webPopOverVC setDoneAction:self action:@selector(injectWebJsWith:)];
        [webPopOverVC setTypeAction:self action:@selector(injectTypeChange)];
        if (self.webPopOver == nil)
        {
            self.webPopOver = [[UIPopoverController alloc] initWithContentViewController:webPopOverVC];
        }
        //        [_BackBtn setHidden:YES];
    } else {
        [(UIScrollView *)[mainWebView.subviews objectAtIndex:0] setScrollsToTop:YES];
    }
}

- (void)dismissPop
{
    // popOver非表示
    if (self.webPopOver.popoverVisible == YES) {
        [self.webPopOver dismissPopoverAnimated:YES];
    }
}

-(void)prompt:(NSString*)type code1:(NSString*)code1 code2:(NSString*)code2
          num:(NSString*)num cotype:(NSString*)cotype
{
    //   __weak typeof(self) weakSelf = self;
    if([cotype isEqualToString:@"1"]){
        @autoreleasepool {
            UIAlertController * alertController =
            [UIAlertController alertControllerWithTitle:@"备品数量"
                                                message:@"数量管理备品请输入数量"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            void (^configurationHandler)(UITextField *) = ^(UITextField * textField) {
                textField.text = @"1";
                textField.keyboardType = UIKeyboardTypeDecimalPad;
            };
            [alertController addTextFieldWithConfigurationHandler:configurationHandler];
            
            void (^cancelHandler)(UIAlertAction *) = ^(UIAlertAction * action) {
            };
            UIAlertAction * cancelAction =
            [UIAlertAction actionWithTitle:@"取消"
                                     style:UIAlertActionStyleCancel
                                   handler:cancelHandler];
            [alertController addAction:cancelAction];
            
            void (^createHandler)(UIAlertAction *) = ^(UIAlertAction * action) {
                UITextField * textField = alertController.textFields[0];
                if (textField.text.length > 0) {
                    dispatch_block_t mainBlock = ^{
                        // ここに UI の更新やデータベースへの追記などを実施するコードを記述する
                        [self injectPromptDone:type code1:code1 code2:code2 amount:textField.text];
                    };
                    dispatch_async(dispatch_get_main_queue(), mainBlock);
                }
            };
            UIAlertAction * createAction =
            [UIAlertAction actionWithTitle:@"OK"
                                     style:UIAlertActionStyleDefault
                                   handler:createHandler];
            [alertController addAction:createAction];
            
            [self.webPopOver.contentViewController presentViewController:alertController animated:YES completion:nil];
            
        }} else{
            [self injectPromptDone:type code1:code1 code2:code2 amount:num];
            
        }
}

- (void)injectPromptDone:(NSString*)type code1:(NSString*)code1 code2:(NSString*)code2 amount:(NSString*)amount
{
    [mainWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"promptDone('%@','%@','%@','%@')", type, code1, code2, amount]];
}

- (void)injectWebJsWith:(NSString*)qrcode
{
    [mainWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setTimeout(function(){filljsQR('%@');},0)", qrcode]];
}

- (void) injectTypeChange
{
    [mainWebView stringByEvaluatingJavaScriptFromString:@"scanType = 1;"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)qrReadAction:(id)sender {
    SFUserAccount *user = [SFUserAccountManager sharedInstance].currentUser;
    if (user.credentials.accessToken == nil && user.credentials.refreshToken == nil) {
        UIAlertView* alertView=[[UIAlertView alloc]
                                initWithTitle:@"错误" message:@"未登录，请重新登录后再次尝试" delegate:nil
                                cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        QRScannerViewController* qrVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QRScanner"];
        [qrVC setDoneAction:self action:@selector(doneQRScan:cfg:)];
        [self.navigationController pushViewController:qrVC animated:YES];
        [qrVC fetchRemarkLabel];
    } else {
        [_BackBtn setHidden:true];
        [mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        self.title = @"QR码扫描";
        // ポップオーバーが現在表示されていなければ表示する
        if (!self.popOver.popoverVisible)
        {
            self.popOver.accessibilityViewIsModal = YES;
            CGRect rect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
            [self.popOver presentPopoverFromRect:rect
                                          inView:self.view
                        permittedArrowDirections:0   // 矢印の向きを指定する
                                        animated:YES];
        }
    }
}

- (IBAction)saveAction:(id)sender {
    [mainWebView stringByEvaluatingJavaScriptFromString:@"savejs();"];
}
- (void) toUploadView:(QRAssetTableViewController*)assetVC
{
    if (self.popOver.popoverVisible == YES) {
        [self.popOver dismissPopoverAnimated:YES];
    }
    [self.navigationController pushViewController:assetVC animated:YES];
}
- (IBAction)ScanBack:(id)sender {
    SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
    NSString* sfUrlF = @"apex/InventoryResultRecord";
    NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)sfUrlF, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
    NSString* sessionId = [NSString stringWithFormat:@"https://%@/secur/frontdoor.jsp?sid=%@&retURL=%@", Api_Server_URL, user.credentials.accessToken, escapedUrlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:sessionId]];
    
    [mainWebView loadRequest:request];
}
- (void) doneQRScan:(NSString*)qrContent cfg:(NSDictionary*)cfg
{
    NSLog(@"ViewController#doneQRScan start");
    
    if ([qrContent length] > 0) {
        //get scan type
        /*
         int scanType = [[cfg objectForKey:@"scanType"] intValue];
         if (scanType == 1 && ![[cfg objectForKey:@"backFlg"] boolValue]) {
         SFRestRequest* infoRequest = [[SFRestAPI sharedInstance] requestForQuery:[NSString stringWithFormat:@"Select Id, Product_Serial_No__c, Name, Remark__c, SerialNumber, ImageAsset__c, ImageSerial__c, Product2.Asset_Model_No__c, Internal_asset_location__c From Asset Where SerialNumber = '%@' or Asset.Internal_Asset_number__c = '%@'", qrContent, qrContent]];
         infoRequest.networkOperation.operationTimeout = 20;
         [[SFRestAPI sharedInstance] sendRESTRequest:infoRequest failBlock:^(NSError *e) {
         NSLog(@"error:%@", e);
         dispatch_async(dispatch_get_main_queue(), ^{
         [self.navigationController popToRootViewControllerAnimated:YES];
         });
         } completeBlock:^(NSDictionary *dict) {
         NSLog(@"dict:%@", dict);
         NSArray* records = [dict objectForKey:@"records"];
         if ([records count] > 0) {
         dispatch_async(dispatch_get_main_queue(), ^{
         QRAssetTableViewController* assetVC = [self.storyboard instantiateViewControllerWithIdentifier:@"assetTable"];
         assetVC.infoList = records;
         [self.navigationController pushViewController:assetVC animated:YES];
         });
         } else {
         dispatch_async(dispatch_get_main_queue(), ^{
         [self.navigationController popToRootViewControllerAnimated:YES];
         });
         }
         }];
         
         return;
         }
         */
        
        titleLabel.text = [NSString stringWithFormat:@"QR码：%@", qrContent];
        self.title = [NSString stringWithFormat:@"QR码：%@", qrContent];
        NSString* type = qrTypeSeg.selectedSegmentIndex == 0 ? @"Shippment" : @"Received";
        NSString* sfUrlF;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            sfUrlF = @"apex/EquipmentSetSRList2?id=%@&type=%@";
        } else {
            sfUrlF = @"apex/EquipmentSetShippmentReceived2?id=%@&type=%@";
        }
        /*
         SFRestRequest* infoRequest = [[SFRestAPI sharedInstance] requestForQuery:[NSString stringWithFormat:@"select Id, Name, SerialNumber__c from Equipment_Set__c where Name ='%@'", qrContent]];
         infoRequest.networkOperation.operationTimeout = 20;
         
         [[SFRestAPI sharedInstance] sendRESTRequest:infoRequest failBlock:^(NSError *e) {
         NSLog(@"error:%@", e);
         } completeBlock:^(NSDictionary *dict) {
         NSLog(@"dict:%@", dict);
         NSArray* records = [dict objectForKey:@"records"];
         if ([records count] > 0) {
         NSString* finalUrl = [NSString stringWithFormat:sfUrlF, [qrContent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], type];
         
         NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)finalUrl, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
         SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
         NSString* sessionId = [NSString stringWithFormat:@"https://%@/secur/frontdoor.jsp?sid=%@&retURL=%@", Api_Server_URL, user.credentials.accessToken, escapedUrlString];
         NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:sessionId]];
         
         [mainWebView loadRequest:request];
         } else {
         SFRestRequest* infoRequest = [[SFRestAPI sharedInstance] requestForQuery:[NSString stringWithFormat:@"select Id, Name, SerialNumber__c from Equipment_Set__c where SerialNumber__c ='%@'", qrContent]];
         [[SFRestAPI sharedInstance] sendRESTRequest:infoRequest failBlock:^(NSError *e) {
         NSLog(@"error:%@", e);
         } completeBlock:^(NSDictionary *dict) {
         NSArray* records = [dict objectForKey:@"records"];
         NSString* finalUrl;
         if ([records count] > 1) {
         finalUrl = [NSString stringWithFormat:@"apex/EquipmentSetSRList?id=%@&type=%@", [qrContent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], type];
         } else if ([records count] == 1) {
         finalUrl = [NSString stringWithFormat:sfUrlF, [[records[0] objectForKey:@"Name"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], type];
         } else {
         finalUrl = [NSString stringWithFormat:sfUrlF, [qrContent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], type];
         }
         
         NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)finalUrl, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
         SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
         NSString* sessionId = [NSString stringWithFormat:@"https://%@/secur/frontdoor.jsp?sid=%@&retURL=%@", Api_Server_URL, user.credentials.accessToken, escapedUrlString];
         NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:sessionId]];
         
         [mainWebView loadRequest:request];
         }];
         }
         }];*/
        
        
        NSString* finalUrl = [NSString stringWithFormat:sfUrlF, [qrContent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], type];
        //        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:finalUrl]];
        
        NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)finalUrl, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
        SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
        NSString* sessionId = [NSString stringWithFormat:@"https://%@/secur/frontdoor.jsp?sid=%@&retURL=%@", Api_Server_URL, user.credentials.accessToken, escapedUrlString];
        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:sessionId]];
        
        [mainWebView loadRequest:request];
        [_BackBtn setHidden:false];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // popOver非表示
        if (self.popOver.popoverVisible == YES) {
            [self.popOver dismissPopoverAnimated:YES];
        }
    } else if (![[cfg objectForKey:@"backFlg"] boolValue]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)checkLogin
{
    NSLog(@"checkLogin start");
    [[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
        NSLog(@"checkLogin end");
        [self loadUserName];
    } failure:^(SFOAuthInfo *info, NSError *e) {
        NSLog(@"checkLogin error");
        NSLog(@"error:%@", e);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:NO];
            [mainWebView stopLoading];
            [mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
            _userNameLabel.text = nil;
            [_loginBtn setTitle:@"登陆" forState:UIControlStateNormal];
            UIAlertView* alertView=[[UIAlertView alloc]
                                    initWithTitle:@"错误" message:[NSString stringWithFormat:@"%@", e] delegate:nil
                                    cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            QRAppDelegate* app = [[UIApplication sharedApplication] delegate];
            app.autoLogin = NO;
            [[SFAuthenticationManager sharedManager] logout];
        });
    }];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.absoluteString rangeOfString:@"login-messages"].location != NSNotFound) {
        //        [[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
        //            dispatch_async(dispatch_get_main_queue(), ^{
        //                [mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        //                [self loadUserName];
        //            });
        //        } failure:^(SFOAuthInfo *info, NSError *e) {
        //            NSLog(@"error:%@", e);
        //        }];
        [mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        UIAlertView* alertView=[[UIAlertView alloc]
                                initWithTitle:@"错误" message:@"未登录，请重新登录后再次尝试" delegate:nil
                                cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return NO;
    }
    if ([request.URL.absoluteString rangeOfString:@"addPhoto"].location != NSNotFound) {
        if (_qrUpVC == nil) {
            _qrUpVC = [self.storyboard instantiateViewControllerWithIdentifier:@"uploadVC"];
        }
        _qrUpVC.info = [self getUrlParam:request];
        [_qrUpVC clearImageCache];
        [_qrUpVC requestForRepair];
        [self.navigationController pushViewController:_qrUpVC animated:YES];
        return NO;
    }
    if ([request.URL.absoluteString rangeOfString:@"sfqr://scan"].location != NSNotFound) {
        if (!self.webPopOver.popoverVisible)
        {
            CGRect rect = CGRectMake(self.view.bounds.size.width, self.view.bounds.size.height/2-100, 1, 1);
            self.webPopOver.accessibilityViewIsModal = YES;
            self.webPopOver.popoverContentSize = CGSizeMake(330, 540);
            [self.webPopOver presentPopoverFromRect:rect
                                             inView:self.view
                           permittedArrowDirections:0   // 矢印の向きを指定する
                                           animated:YES];
        }
        return NO;
    }
    if ([request.URL.absoluteString rangeOfString:@"sfqr://accsessaryScan"].location != NSNotFound) {
        //        NSString *ul = [mainWebView stringByEvaluatingJavaScriptFromString:@"j$('.modal-content2').find('ul').prop('outerHTML');"];
        QRWebScanViewController *webqr = (QRWebScanViewController *) self.webPopOver.contentViewController;
        [webqr setScanType:2];
        return NO;
    }
    if ([request.URL.absoluteString rangeOfString:@"sfqr://prompt"].location != NSNotFound) {
        NSDictionary* prompt_param = [self getUrlParam:request];
        if ([[prompt_param objectForKey:@"type"] isEqualToString: @"1"]) {
            [self prompt:[prompt_param objectForKey:@"type"] code1:[prompt_param objectForKey:@"qrId"] code2:nil num:[prompt_param objectForKey: @"num"] cotype:[prompt_param objectForKey:@"cotype"]];
        } else {
            [self prompt:[prompt_param objectForKey:@"type"] code1:[prompt_param objectForKey:@"mid"] code2:[prompt_param objectForKey:@"aid"] num:[prompt_param objectForKey: @"num"] cotype:[prompt_param objectForKey:@"cotype"]];
        }
        
        return NO;
    }
    if ([request.URL.absoluteString rangeOfString:@"sfqr://selectDept"].location != NSNotFound) {
        NSDictionary* dept_param = [self getUrlParam:request];
        [self selectDept:[[dept_param objectForKey:@"dept"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                     aid:[[dept_param objectForKey:@"aid"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                showflag:[[dept_param objectForKey:@"showflag"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                    code:[[dept_param objectForKey:@"code"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
        ];
        
        return NO;
    }
    if (_indicator == nil) {
        _indicator= [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
        _indicator.layer.cornerRadius = 10;
        _indicator.opaque = NO;
        _indicator.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
        _indicator.center = webView.center;
        _indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [_indicator setColor:[UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0]];
        [webView addSubview: _indicator];
    }
    [_indicator stopAnimating];
    [_indicator startAnimating];
    return YES;
}
- (void)selectDept:(NSString*)dept aid:(NSString*)aid showflag:(NSString*)showflag code:(NSString*)code{
    NSArray* depts = [dept componentsSeparatedByString:@";"];
    NSArray* aids = [aid componentsSeparatedByString:@";"];
    @autoreleasepool {
     if([showflag isEqualToString: @"1"]){
        UIAlertController * alertController =
        [UIAlertController alertControllerWithTitle:@"耗材存在复数件"
                                            message:@"请选择所在营业本部"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        void (^cancelHandler)(UIAlertAction *) = ^(UIAlertAction * action) {
        };
        UIAlertAction * cancelAction =
        [UIAlertAction actionWithTitle:@"取消"
                                 style:UIAlertActionStyleCancel
                               handler:cancelHandler];
        [alertController addAction:cancelAction];
        
        int i = 0;
        for (NSString* dp in depts) {
            UIAlertAction * createAction =
            [UIAlertAction actionWithTitle:dp
                                     style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * _Nonnull action) {
                dispatch_block_t mainBlock = ^{
                    _codeAid = aids[i];
                    [self injectDeptDone:aids[i] code:code];
                };
                dispatch_async(dispatch_get_main_queue(), mainBlock);
            }];
            [alertController addAction:createAction];
            i++;
        }

         [self presentViewController:alertController animated:YES completion:nil];
        [self.webPopOver.contentViewController presentViewController:alertController animated:YES completion:nil];
     }
            else{
                [self injectDeptDone:_codeAid code:code];
                }
        }
}
- (void)injectDeptDone:(NSString*)aid code:(NSString*)code
{
    [mainWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"deptDone('%@','%@')", aid,code]];
}

- (IBAction)toSafari:(id)sender {
    SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
    NSString* sfUrlF = @"apex/CheckAllOlympusAsset";
    NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)sfUrlF, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
    NSString* sessionId = [NSString stringWithFormat:@"https://%@/secur/frontdoor.jsp?sid=%@&retURL=%@", Api_Server_URL, user.credentials.accessToken, escapedUrlString];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:sessionId]];
}

- (NSMutableDictionary*)getUrlParam:(NSURLRequest*)req
{
    return [self getUrlParamByStr:req.URL.absoluteString];
}

- (NSMutableDictionary*)getUrlParamByStr:(NSString*)url
{
    NSString* query = [[url componentsSeparatedByString:@"?"] lastObject];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [query componentsSeparatedByString:@"&"]) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if([parts count] < 2) continue;
        [params setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    return params;
}

- (IBAction)loginAction:(id)sender {
    if ([[_loginBtn titleForState:UIControlStateNormal] isEqualToString:@"注销"]) {
        QRAppDelegate* app = [[UIApplication sharedApplication] delegate];
        app.autoLogin = NO;
        [[SFAuthenticationManager sharedManager] logout];
        _userNameLabel.text = @" ";
        [_loginBtn setTitle:@"登陆" forState:UIControlStateNormal];
    } else {
        [[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
            [_loginBtn setTitle:@"注销" forState:UIControlStateNormal];
            [self loadUserName];
            [self loadUrl];
        } failure:^(SFOAuthInfo *info, NSError *e) {
            [[SFAuthenticationManager sharedManager] logout];
        }];
    }
    
}

- (void)loadUrl
{
    SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
    NSString* sfUrlF = @"apex/InventoryResultRecord";
    NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)sfUrlF, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
    NSString* sessionId = [NSString stringWithFormat:@"https://%@/secur/frontdoor.jsp?sid=%@&retURL=%@", Api_Server_URL, user.credentials.accessToken, escapedUrlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:sessionId]];
    
    [mainWebView loadRequest:request];
}

- (void)loadUserName
{
    SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
    _userNameLabel.text = [NSString stringWithFormat:@" %@", user.fullName];
    [_loginBtn setTitle:@"注销" forState:UIControlStateNormal];
}

- (NSString*)buildUrlByParam:(NSDictionary*)param
{
    NSMutableString* url = [NSMutableString stringWithFormat:@"https://%@/apex/addPhoto?", Api_Server_URL];
    
    [param enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [url appendFormat:@"%@=%@&", key, obj];
    }];
    
    [url deleteCharactersInRange:NSMakeRange([url length]-1, 1)];
    
    return url;
}

- (void)loadJS:(NSDictionary*)param
{
    [mainWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('%@').getElementsByTagName('a')[0].innerHTML = '修改照片'", [param objectForKey:@"psNo"]]];
    NSString* href = [mainWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('%@').getElementsByTagName('a')[0].href", [param objectForKey:@"psNo"]]];
    NSMutableDictionary* paramF = [self getUrlParamByStr:href];
    
    NSDictionary* message = [param objectForKey:@"message"];
    if (![[message objectForKey:@"imgaId"] isEqualToString:@"null"]) {
        NSString* imga = [NSString stringWithFormat:@"<img style=\"width:320px\" src=\"/servlet/servlet.FileDownload?file=%@&t=%f\"/>", [message objectForKey:@"imgaId"], [[NSDate date] timeIntervalSince1970]];
        NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)imga, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
        [paramF setObject:escapedUrlString forKey:@"imga"];
    }
    if (![[message objectForKey:@"imgsId"] isEqualToString:@"null"]) {
        NSString* imgs = [NSString stringWithFormat:@"<img style=\"width:320px\" src=\"/servlet/servlet.FileDownload?file=%@@&t=%f\"/>", [message objectForKey:@"imgsId"], [[NSDate date] timeIntervalSince1970]];
        NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)imgs, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
        [paramF setObject:escapedUrlString forKey:@"imgs"];
    }
    
    [mainWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('%@').getElementsByTagName('a')[0].href = '%@'", [param objectForKey:@"psNo"], [self buildUrlByParam:paramF]]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (_indicator != nil) [_indicator stopAnimating];
}

- (void)segment_ValueChanged:(id)sender
{
    [mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    titleLabel.text = @"QR码扫描";
}

- (void)viewWillAppear:(BOOL)animated {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    [super viewWillDisappear:animated];
}

@end
