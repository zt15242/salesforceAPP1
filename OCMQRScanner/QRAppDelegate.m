//
//  QRAppDelegate.m
//  OCMQRScanner
//
//  Created by 王 文丰 on 2014/07/03.
//  Copyright (c) 2014年 sohobb. All rights reserved.
//

#import "QRAppDelegate.h"
#import "QRViewController.h"
#import <SalesforceSDKCore/SFUserAccountManager.h>
#import <SalesforceSDKCore/SFAuthenticationManager.h>
#import <SalesforceSDKCore/SFPushNotificationManager.h>
#import <SalesforceSDKCore/SFDefaultUserManagementViewController.h>
#import <SalesforceOAuth/SFOAuthInfo.h>
#import <SalesforceCommonUtils/SFLogger.h>

#ifdef BUILD_DEBUG
// Fill these in when creating a new Connected Application on Force.com
//阿里test
static NSString * const RemoteAccessConsumerKey = @"3MVG9nPIHG.zKGNanents6Jt6i_rOVKLZb4kJ6Rh.UjdhK4EFvPcgXDqyMEwdZQ4dM8r3awCDkgF8IIAcVRVH";
//正式
//static NSString * const RemoteAccessConsumerKey = @"3MVG9ViKlDlzW2Fd3nkmHi.py0kBnPKLXM9kfqUo_WXfCPhANDtc59Y6cdPlD2VwhGC8Z.UWieXkG.tl_H2hf";
static NSString * const OAuthRedirectURI        = @"http://localhost/callback";
#else
//test
static NSString * const RemoteAccessConsumerKey = @"3MVG9nPIHG.zKGNanents6Jt6i_rOVKLZb4kJ6Rh.UjdhK4EFvPcgXDqyMEwdZQ4dM8r3awCDkgF8IIAcVRVH";
//正式
//static NSString * const RemoteAccessConsumerKey = @"3MVG9ViKlDlzW2Fd3nkmHi.py0kBnPKLXM9kfqUo_WXfCPhANDtc59Y6cdPlD2VwhGC8Z.UWieXkG.tl_H2hf";
static NSString * const OAuthRedirectURI        = @"http://localhost/callback";
#endif


@interface QRAppDelegate () <SFAuthenticationManagerDelegate, SFUserAccountManagerDelegate>
@property (nonatomic, copy) SFOAuthFlowFailureCallbackBlock initialLoginFailureBlock;
@property (nonatomic) BOOL firstLaunch;
@end

@implementation QRAppDelegate

- (id)init
{
    self = [super init];
    if (self) {
        [SFLogger setLogLevel:SFLogLevelDebug];
        
        // These SFAccountManager settings are the minimum required to identify the Connected App.
        [SFUserAccountManager sharedInstance].oauthClientId = RemoteAccessConsumerKey;
        [SFUserAccountManager sharedInstance].oauthCompletionUrl = OAuthRedirectURI;
        [SFUserAccountManager sharedInstance].loginHost = Api_Server_URL;
        [SFUserAccountManager sharedInstance].scopes = [NSSet setWithObjects:@"full", nil];
        
        // Auth manager delegate, for receiving logout and login host change events.
        [[SFAuthenticationManager sharedManager] addDelegate:self];
        [[SFUserAccountManager sharedInstance] addDelegate:self];
        
        // Blocks to execute once authentication has completed.  You could define these at the different boundaries where
        // authentication is initiated, if you have specific logic for each case.
        self.initialLoginFailureBlock = ^(SFOAuthInfo *info, NSError *error) {
            [[SFAuthenticationManager sharedManager] logout];
        };
    }
    
    return self;
}

- (void)dealloc
{
    [[SFAuthenticationManager sharedManager] removeDelegate:self];
    [[SFUserAccountManager sharedInstance] removeDelegate:self];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
        QRViewController* mainVC;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            mainVC = ((UINavigationController*)self.window.rootViewController).viewControllers[0];
        } else {
            mainVC = ((UINavigationController*)self.window.rootViewController).viewControllers[0];
        }
        
        [mainVC loadUserName];
        [mainVC loadUrl];
        NSLog(@"token:%@",[SFUserAccountManager sharedInstance].currentUser.credentials.accessToken);
    } failure:self.initialLoginFailureBlock];
    
    self.autoLogin = YES;
    self.firstLaunch = YES;
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if (!self.firstLaunch) {
        QRViewController* mainVC = ((UINavigationController*)self.window.rootViewController).viewControllers[0];
        NSLog(@"checkLogin");
        NSLog(@"token:%@",[SFUserAccountManager sharedInstance].currentUser.credentials.accessToken);
        [mainVC checkLogin];
    } else {
        self.firstLaunch = NO;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - SFAuthenticationManagerDelegate

- (void)authManagerDidLogout:(SFAuthenticationManager *)manager
{
    [self log:SFLogLevelDebug msg:@"SFAuthenticationManager logged out.  Resetting app."];
    
    // Multi-user pattern:
    // - If there are two or more existing accounts after logout, let the user choose the account
    //   to switch to.
    // - If there is one existing account, automatically switch to that account.
    // - If there are no further authenticated accounts, present the login screen.
    //
    // Alternatively, you could just go straight to re-initializing your app state, if you know
    // your app does not support multiple accounts.  The logic below will work either way.
    NSArray *allAccounts = [SFUserAccountManager sharedInstance].allUserAccounts;
    if ([allAccounts count] > 1) {
        SFDefaultUserManagementViewController *userSwitchVc = [[SFDefaultUserManagementViewController alloc] initWithCompletionBlock:^(SFUserManagementAction action) {
            [self.window.rootViewController dismissViewControllerAnimated:YES completion:NULL];
        }];
        [self.window.rootViewController presentViewController:userSwitchVc animated:YES completion:NULL];
    } else if ([[SFUserAccountManager sharedInstance].allUserAccounts count] == 1) {
        [SFUserAccountManager sharedInstance].currentUser = [[SFUserAccountManager sharedInstance].allUserAccounts objectAtIndex:0];
        [[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
            QRViewController* mainVC = ((UINavigationController*)self.window.rootViewController).viewControllers[0];
            [mainVC loadUserName];
            [mainVC loadUrl];
        } failure:self.initialLoginFailureBlock];
    } else {
        if (self.autoLogin) {
            [[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
                QRViewController* mainVC = ((UINavigationController*)self.window.rootViewController).viewControllers[0];
                [mainVC loadUserName];
                [mainVC loadUrl];
            } failure:self.initialLoginFailureBlock];
        } else {
            self.autoLogin = YES;
        }
    }
}

#pragma mark - SFUserAccountManagerDelegate

- (void)userAccountManager:(SFUserAccountManager *)userAccountManager
         didSwitchFromUser:(SFUserAccount *)fromUser
                    toUser:(SFUserAccount *)toUser
{
    [self log:SFLogLevelDebug format:@"SFUserAccountManager changed from user %@ to %@.  Resetting app.",
     fromUser.userName, toUser.userName];
    [[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
        QRViewController* mainVC = ((UINavigationController*)self.window.rootViewController).viewControllers[0];
        [mainVC loadUserName];
        [mainVC loadUrl];
    } failure:self.initialLoginFailureBlock];
}

@end
