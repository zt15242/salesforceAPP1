//
//  QRAssetTableViewController.m
//  OCMQRScanner
//
//  Created by 王 文丰 on 2015/01/15.
//  Copyright (c) 2015年 sohobb. All rights reserved.
//

#import "QRAssetTableViewController.h"
#import "QRUploadViewController.h"

@interface QRAssetTableViewController ()
@property (strong, nonatomic) QRUploadViewController* qrUpVC;
@property (strong, nonatomic) NSDateFormatter* sdf_sql;
@property (strong, nonatomic) NSDateFormatter* sdf;
@end

@implementation QRAssetTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _sdf_sql = [[NSDateFormatter alloc] init];
    [_sdf_sql setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSZ"];
    _sdf = [[NSDateFormatter alloc] init];
    [_sdf setDateFormat:@"yyyy/MM/dd HH:mm"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [_infoList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"assetCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary* record = [_infoList objectAtIndex:indexPath.row];
    
    // Name
    UILabel* label1 = (UILabel*) [cell viewWithTag:1];
    // SerialNumber
    UILabel* label2 = (UILabel*) [cell viewWithTag:2];
    // Location
    UILabel* label3 = (UILabel*) [cell viewWithTag:3];
    // UpdateTime
    UILabel* label4 = (UILabel*) [cell viewWithTag:4];
    
    label1.text = [record objectForKey:@"Name"];
    label2.text = [record objectForKey:@"SerialNumber"];
    if ([record objectForKey:@"Internal_asset_location__c"] != [NSNull null]) {
        label3.text = [record objectForKey:@"Internal_asset_location__c"];
    }
    
    NSString* iautStr = @"9999/99/99 99:99";
    NSString* isutStr = @"9999/99/99 99:99";
    label4.backgroundColor = label2.backgroundColor;
    label4.textColor = label2.textColor;
    
    if ([record objectForKey:@"ImageAssetUploadedTime__c"] != [NSNull null]) {
        NSDate* iaut = [_sdf_sql dateFromString:[record objectForKey:@"ImageAssetUploadedTime__c"]];
        iautStr = [_sdf stringFromDate:iaut];
    } else {
        label4.backgroundColor = [UIColor redColor];
        label4.textColor = [UIColor whiteColor];
    }
    
    if ([record objectForKey:@"ImageSerialUploadedTime__c"] != [NSNull null]) {
        NSDate* isut = [_sdf_sql dateFromString:[record objectForKey:@"ImageSerialUploadedTime__c"]];
        isutStr = [_sdf stringFromDate:isut];
    } else {
        label4.backgroundColor = [UIColor redColor];
        label4.textColor = [UIColor whiteColor];
    }

    if ([iautStr compare:isutStr] == NSOrderedAscending) {
        label4.text = [iautStr hasPrefix:@"9999"] ? @"" : iautStr;
    } else {
        label4.text = [isutStr hasPrefix:@"9999"] ? @"" : isutStr;
    }
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* record = [_infoList objectAtIndex:indexPath.row];
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    [info setObject:[record objectForKey:@"SerialNumber"] forKey:@"sNo"];
    [info setObject:[record objectForKey:@"Name"] forKey:@"astName"];
    [info setObject:[record objectForKey:@"Product_Serial_No__c"] forKey:@"psNo"];
    [info setObject:[record objectForKey:@"ImageAsset__c"] forKey:@"imga"];
    [info setObject:[record objectForKey:@"ImageSerial__c"] forKey:@"imgs"];
    [info setObject:[record objectForKey:@"Id"] forKey:@"Id"];
    [info setObject:[record objectForKey:@"ImageAssetUploadedTime__c"] forKey:@"iaut"];
    [info setObject:[record objectForKey:@"ImageSerialUploadedTime__c"] forKey:@"isut"];
    [info setObject:[record objectForKey:@"Remark__c"] forKey:@"remark"];
    
    if (_qrUpVC == nil) {
        _qrUpVC = [self.storyboard instantiateViewControllerWithIdentifier:@"uploadVC"];
    }
    _qrUpVC.info = info;
    [_qrUpVC clearImageCache];
    [_qrUpVC requestForRepair];
    
    [self.navigationController pushViewController:_qrUpVC animated:YES];

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
