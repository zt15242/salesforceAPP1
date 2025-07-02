//
//  QRUploadViewController.m
//  OCMQRScanner
//
//  Created by 王 文丰 on 2015/01/06.
//  Copyright (c) 2015年 sohobb. All rights reserved.
//

#import "QRUploadViewController.h"
#import "QRViewController.h"
#import "QRAppDelegate.h"
#import "QRAssetTableViewController.h"
#import <SalesforceSDKCore/SFUserAccountManager.h>
#import <SalesforceSDKCore/SFUserAccount.h>
#import <SalesforceNativeSDK/SFRestAPI+Blocks.h>

@interface QRUploadViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *imageView1;
@property (weak, nonatomic) IBOutlet UIView *borderView1;
@property (weak, nonatomic) IBOutlet UIWebView *imageView2;
@property (weak, nonatomic) IBOutlet UIView *borderView2;
@property (weak, nonatomic) IBOutlet UIWebView *hiddenWebView;
@property (nonatomic) int selectedNo;
@property (strong, nonatomic) NSString* repairNo;
@property (strong, nonatomic) NSString* baseRepairDate;
@property (strong, nonatomic) NSString* baseRemarkText;
@property (strong, nonatomic) NSString* base64ForImg1;
@property (strong, nonatomic) NSString* base64ForImg2;
@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (weak, nonatomic) IBOutlet UIButton *uploadBtn;
@property (weak, nonatomic) IBOutlet UILabel *bihenLabel1;
@property (weak, nonatomic) IBOutlet UILabel *bihenLabel2;
@property (weak, nonatomic) IBOutlet UILabel *repairLabel;
@property (weak, nonatomic) IBOutlet UILabel *repairTitleLabel;
@property (weak, nonatomic) IBOutlet UITextField *repairDate;
@property (weak, nonatomic) IBOutlet UILabel *repairDateLabel;
@property (nonatomic, strong) UIActivityIndicatorView* indicator;
@property (weak, nonatomic) IBOutlet UILabel *iaatLabel;
@property (weak, nonatomic) IBOutlet UILabel *isatLabel;
@property (weak, nonatomic) IBOutlet UILabel *remarkLabel;
@property (weak, nonatomic) IBOutlet UITextView *remarkText;
@property (nonatomic, strong) UIDatePicker* datePicker;
@property (nonatomic) BOOL hiddenLoaded;
@end

@implementation QRUploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _selectedNo = 1;
    _base64ForImg1 = nil;
    _base64ForImg2 = nil;
    _baseRepairDate = nil;
    _repairNo = nil;
    [self selectImage];
    
    _datePicker = [[UIDatePicker alloc] init];
    [_datePicker setDatePickerMode:UIDatePickerModeDate];
    [_datePicker addTarget:self action:@selector(updateTextField:) forControlEvents:UIControlEventValueChanged];
    
    _repairDate.inputView = _datePicker;
    
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle  = UIBarStyleDefault;
    keyboardDoneButtonView.translucent = YES;
    [keyboardDoneButtonView sizeToFit];
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleBordered target:self action:@selector(pickerDoneClicked)];
    UIBarButtonItem *spacer1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:spacer, spacer1, doneButton, nil]];
    
    // Viewの配置
    _repairDate.inputAccessoryView = keyboardDoneButtonView;
    _remarkText.inputAccessoryView = keyboardDoneButtonView;
    
    //keyboard => view move up
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameDidChange:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
    
    QRAppDelegate* app = [[UIApplication sharedApplication] delegate];
    _remarkLabel.text = app.remarkLabel;
    
    _baseRemarkText = [_info objectForKey:@"remark"] != [NSNull null] ? [_info objectForKey:@"remark"] : @"";
    
    _baseRemarkText = [_baseRemarkText stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    
    _baseRemarkText = [_baseRemarkText stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    _remarkText.text = _baseRemarkText;
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
}
-(void)keyboardFrameDidChange:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    
    [UIView beginAnimations:@"MoveView" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.3f];
    CGRect kKeyBoardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self.view setFrame:CGRectMake(0, (kKeyBoardFrame.origin.y < 480 ? (self.view.frame.size.height > 480 ? 400 : 250) : kKeyBoardFrame.origin.y)-self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    [UIView commitAnimations];
}

-(void)viewWillAppear:(BOOL)animated
{
    BOOL fromLink;
    if ([_info objectForKey:@"Id"] != nil) {
        fromLink = NO;
    } else {
        fromLink = YES;
    }
    
    SFUserAccount* user = [SFUserAccountManager sharedInstance].currentUser;
    NSString* sessionId = [NSString stringWithFormat:@"https://%@/secur/frontdoor.jsp?sid=%@", Api_Server_URL, user.credentials.accessToken];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:sessionId]];
    
    if ([_info objectForKey:@"astName"] != [NSNull null]) {
        _bihenLabel1.text = [[[_info objectForKey:@"astName"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    if ([_info objectForKey:@"sNo"] != [NSNull null]) {
        _bihenLabel2.text = [[_info objectForKey:@"sNo"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSDateFormatter* sdf_sql = [[NSDateFormatter alloc] init];
    [sdf_sql setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSZ"];
    NSDateFormatter* sdf = [[NSDateFormatter alloc] init];
    [sdf setDateFormat:@"yyyy/MM/dd HH:mm"];
    if ([_info objectForKey:@"iaut"] != [NSNull null]) {
        if (fromLink) {
            _iaatLabel.text = [[_info objectForKey:@"iaut"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else {
            NSDate* iaut = [sdf_sql dateFromString:[_info objectForKey:@"iaut"]];
            _iaatLabel.text = [sdf stringFromDate:iaut];
        }
    }
    if ([_info objectForKey:@"isut"] != [NSNull null]) {
        if (fromLink) {
            _isatLabel.text = [[_info objectForKey:@"isut"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else {
            NSDate* isut = [sdf_sql dateFromString:[_info objectForKey:@"isut"]];
            _isatLabel.text = [sdf stringFromDate:isut];
        }
    }
    self.hiddenLoaded = NO;
    [_hiddenWebView loadRequest:request];
}

-(NSString*)getImageSrc:(NSString*)imageUrl
{
//    NSString* url = [[[imageUrl componentsSeparatedByString:@"src=\""] lastObject] componentsSeparatedByString:@"\""][0];
//    return [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"src=\"([^\"]*)\""
                                  options:NSRegularExpressionCaseInsensitive
                                  error:nil];
    NSTextCheckingResult *m = [regex firstMatchInString:imageUrl options:0 range:NSMakeRange(0, imageUrl.length)];
    if (!NSEqualRanges(m.range, NSMakeRange(NSNotFound, 0))) {
        return [imageUrl substringWithRange:[m rangeAtIndex:1]];
    }
    return @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)selectImage1:(id)sender {
    _selectedNo = 1;
    [self selectImage];
}
- (IBAction)selectImage2:(id)sender {
    _selectedNo = 2;
    [self selectImage];
}
- (IBAction)getImageFromCamera:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController* ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
        ipc.allowsEditing = YES;
        [self presentViewController:ipc animated:YES completion:nil];
    }
}
- (IBAction)getImageFromLib:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController* ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        ipc.allowsEditing = YES;
        [self presentViewController:ipc animated:YES completion:nil];
    }
}

-(void)selectImage
{
    if (_selectedNo == 1) {
        [_borderView1 setBackgroundColor:[UIColor blueColor]];
        [_borderView2 setBackgroundColor:[UIColor whiteColor]];
    } else {
        [_borderView2 setBackgroundColor:[UIColor blueColor]];
        [_borderView1 setBackgroundColor:[UIColor whiteColor]];
    }
}

-(void)updateTextField:(id)sender {
    UIDatePicker *picker = (UIDatePicker *)sender;
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy/MM/dd"];
    _repairDate.text = [df stringFromDate:picker.date];
}

-(void)pickerDoneClicked
{
    [self.view endEditing:YES];
}

#pragma mark - WebView
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView == _hiddenWebView && [webView.request.URL.absoluteString rangeOfString:@"home.jsp"].location != NSNotFound && !self.hiddenLoaded) {
        self.hiddenLoaded = YES;
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        if ([_base64ForImg1 length] == 0 && [_info objectForKey:@"imga"] != [NSNull null]) {
            NSString* imga = [[_info objectForKey:@"imga"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if ([imga length] > 0) {
                imga = [self getImageSrc:imga];
                NSString* htmlStr = [NSString stringWithFormat:@"<img style=\"width:100%%\" src=\"%@&rd=%@\"/>", imga, [self generateRandomString:4]];
                [_imageView1 loadHTMLString:htmlStr baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", Api_Server_URL]]];
            }
        }
        
        if ([_base64ForImg2 length] == 0 && [_info objectForKey:@"imgs"] != [NSNull null]) {
            NSString* imgs = [[_info objectForKey:@"imgs"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if ([imgs length] > 0) {
                imgs = [self getImageSrc:imgs];
                NSString* htmlStr = [NSString stringWithFormat:@"<img style=\"width:100%%\" src=\"%@&rd=%@\"/>", imgs, [self generateRandomString:4]];
                [_imageView2 loadHTMLString:htmlStr baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", Api_Server_URL]]];
            }
        }
    }
}

#pragma mark - ImagePickView
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage* scaledImg = [self imageWithImage:image scaledToWidth:320.0f];
    NSData* jpgData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(scaledImg, 0.5f)];
    NSString* jpg64Str = [jpgData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
    
    NSString* htmlStr = [NSString stringWithFormat:@"<img style=\"width:100%%\" src=\"data:image/png;base64,%@\"/>", jpg64Str];
    
    if (_selectedNo == 1) {
        _base64ForImg1 = jpg64Str;
        [_imageView1 loadHTMLString:htmlStr baseURL:nil];
    } else {
        _base64ForImg2 = jpg64Str;
        [_imageView2 loadHTMLString:htmlStr baseURL:nil];
    }
}
- (IBAction)uploadImage:(id)sender {
    
    if ([_base64ForImg1 length] == 0 && [_base64ForImg2 length] == 0 && ([_repairNo length] == 0 || [_baseRepairDate isEqualToString:_repairDate.text]) && [_baseRemarkText isEqualToString:_remarkText.text]) return;
    [self setBtnEnable:NO];
    
    NSMutableDictionary* param = [NSMutableDictionary dictionary];
    
    [param setObject:[_info objectForKey:@"psNo"] forKey:@"productSerialNo"];
    [param setObject:_base64ForImg1 != nil ? _base64ForImg1 : @"" forKey:@"imageAsset"];
    [param setObject:_base64ForImg2 != nil ? _base64ForImg2 : @"" forKey:@"imageSerial"];
    [param setObject:_repairNo != nil ? _repairNo : @"" forKey:@"repairId"];
    [param setObject:![_baseRepairDate isEqualToString:_repairDate.text] ? _repairDate.text : @"" forKey:@"repairDate"];
    [param setObject:![_baseRemarkText isEqualToString:_remarkText.text] ? _remarkText.text : @"" forKey:@"remarkText"];
        
    SFRestRequest* request = [SFRestRequest requestWithMethod:SFRestMethodPOST path:@"/services/apexrest/UpdateAssetImage" queryParams:param];
    [request setEndpoint:[NSString stringWithFormat:@"https://%@", Api_Server_URL]];
    [request setParseResponse:YES];
    request.networkOperation.operationTimeout = 20;
    
    if (_indicator == nil) {
        _indicator= [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
        _indicator.layer.cornerRadius = 10;
        _indicator.opaque = NO;
        _indicator.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
        _indicator.center = self.view.center;
        _indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [_indicator setColor:[UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0]];
        [self.view addSubview: _indicator];
    }
    [_indicator stopAnimating];
    [_indicator startAnimating];
    
    [[SFRestAPI sharedInstance] sendRESTRequest:request failBlock:^(NSError *e) {
        NSLog(@"error:%@", e);
        if (_indicator != nil) [_indicator stopAnimating];
        [self showError:e];
    } completeBlock:^(NSDictionary *dict) {
        if (![[dict objectForKey:@"status"] isEqualToString:@"Success"]) {
            [self showAlert:[NSString stringWithFormat:@"%@", [dict objectForKey:@"message"]] forTitle:@"Error"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_indicator != nil) [_indicator stopAnimating];
                [self setBtnEnable:YES];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_indicator != nil) [_indicator stopAnimating];
                UIViewController* vc = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
                if ([vc isKindOfClass:[QRViewController class]]) {
                    [self setBtnEnable:YES];
                    [self.navigationController popViewControllerAnimated:YES];
                    QRViewController* mainVC = self.navigationController.viewControllers[0];
                    NSMutableDictionary* param = [dict mutableCopy];
                    [param setObject:[_info objectForKey:@"psNo"] forKey:@"psNo"];
                    [mainVC loadJS:param];
                } else {
                    SFRestRequest* infoRequest = [[SFRestAPI sharedInstance] requestForQuery:[NSString stringWithFormat:@"Select Id, Product_Serial_No__c, Name, Remark__c, SerialNumber, ImageAsset__c, ImageSerial__c, Product2.Asset_Model_No__c, Internal_asset_location__c, ImageAssetUploadedTime__c, ImageSerialUploadedTime__c From Asset Where (SerialNumber = '%@' or Internal_Asset_number__c = '%@' or Internal_Asset_number_key__c = '%@') and Product2Id <> null", [_info objectForKey:@"sNo"], [_info objectForKey:@"sNo"], [_info objectForKey:@"sNo"]]];
                    infoRequest.networkOperation.operationTimeout = 20;
                    
                    [[SFRestAPI sharedInstance] sendRESTRequest:infoRequest failBlock:^(NSError *e) {
                        NSLog(@"error:%@", e);
                    } completeBlock:^(NSDictionary *dict) {
                        NSLog(@"dict:%@", dict);
                        NSArray* records = [dict objectForKey:@"records"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([records count] > 0) {
                                ((QRAssetTableViewController*) vc).infoList = records;
                            }
                            [self setBtnEnable:YES];
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                    }];
                }
                
            });
        }
    }];
}

- (void)showError:(NSError*)error
{
    if (_indicator != nil) [_indicator stopAnimating];
    [self setBtnEnable:YES];
    
    if ([[error domain] isEqualToString:@"NSURLErrorDomain"] && [error code] < -1000) {
        [self showAlert:@"未连接网络" forTitle:@"网络错误"];
    } else {
        [self showAlert:[NSString stringWithFormat:@"%@", error] forTitle:@"error"];
    }
}

- (void)showAlert:(NSString*)msg forTitle:(NSString*)title
{
    UIAlertView* alertView=[[UIAlertView alloc]
                            initWithTitle:title message:msg delegate:nil
                            cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
}

-(void)requestForRepair
{
    QRAppDelegate* app = [[UIApplication sharedApplication] delegate];
    _remarkLabel.text = app.remarkLabel;
    
    _baseRemarkText = [_info objectForKey:@"remark"] != [NSNull null] ? [_info objectForKey:@"remark"] : @"";
    
    _baseRemarkText = [_baseRemarkText stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    
    _baseRemarkText = [_baseRemarkText stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    _remarkText.text = _baseRemarkText;
    
    NSString* assetId;
    if ([_info objectForKey:@"Id"] != nil) {
        assetId = [_info objectForKey:@"Id"];
    } else {
        assetId = [_info objectForKey:@"ast"];
    }
    
    SFRestRequest* infoRequest = [[SFRestAPI sharedInstance] requestForQuery:[NSString stringWithFormat:@"Select Id, Repair_Returned_To_HP_Date__c, Name From Repair__c Where Delivered_Product__c = '%@' order by Failure_Occurrence_Date__c desc limit 1", assetId]];
    infoRequest.networkOperation.operationTimeout = 20;
    
    [[SFRestAPI sharedInstance] sendRESTRequest:infoRequest failBlock:^(NSError *e) {
        NSLog(@"error:%@",e);
        _repairLabel.hidden = YES;
        _repairDate.hidden = YES;
        _repairDateLabel.hidden = YES;
        _repairTitleLabel.hidden = YES;
    } completeBlock:^(NSDictionary *dict) {
        NSArray* records = [dict objectForKey:@"records"];
        if ([records count] > 0) {
            NSDictionary* repair = [records objectAtIndex:0];
            NSString* name = [repair objectForKey:@"Name"];
            _repairNo = [repair objectForKey:@"Id"];
            id date = [repair objectForKey:@"Repair_Returned_To_HP_Date__c"];
            if (date == [NSNull null]) date = @"";
            NSString* dateStr = [date stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _repairLabel.text = name;
                _repairDate.text = dateStr;
                _baseRepairDate = dateStr;
                _repairLabel.hidden = NO;
                _repairDate.hidden = NO;
                _repairDateLabel.hidden = NO;
                _repairTitleLabel.hidden = NO;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                _repairLabel.hidden = YES;
                _repairDate.hidden = YES;
                _repairDateLabel.hidden = YES;
                _repairTitleLabel.hidden = YES;
            });
        }
    }];
}

-(void)clearImageCache
{
    _base64ForImg1 = nil;
    _base64ForImg2 = nil;
    _repairNo = nil;
    _baseRepairDate = nil;
}

//method to scale image accordcing to width
-(UIImage *) imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width {
    
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    if (fabs(newHeight - i_width) < 5) newHeight = i_width;
    if (fabs(newWidth - i_width) < 5) newWidth = i_width;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)setBtnEnable:(BOOL)enable
{
    [_cameraBtn setEnabled:enable];
    [_cameraBtn setAlpha:enable ? 1.0 : 0.8];
    [_photoBtn setEnabled:enable];
    [_photoBtn setAlpha:enable ? 1.0 : 0.8];
    [_uploadBtn setEnabled:enable];
    [_uploadBtn setAlpha:enable ? 1.0 : 0.8];
}

-(NSString*)generateRandomString:(int)num {
    NSMutableString* string = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [string appendFormat:@"%C", (unichar)('a' + arc4random_uniform(25))];
    }
    return string;
}

@end
