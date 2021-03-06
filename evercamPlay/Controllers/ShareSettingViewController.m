//
//  ShareSettingViewController.m
//  evercamPlay
//
//  Created by Zulqarnain on 5/11/16.
//  Copyright © 2016 evercom. All rights reserved.
//

#import "ShareSettingViewController.h"
#import "EvercamUtility.h"
#import "AppDelegate.h"
#import "EvercamShare.h"
#import "ShareViewController.h"
#import "GlobalSettings.h"
#import "TPKeyboardAvoidingScrollView.h"
#import <QuartzCore/QuartzCore.h>
@interface ShareSettingViewController (){
    NSArray *optionsArray;
    NSIndexPath *checkedIndexPath;
}

@end

@implementation ShareSettingViewController
@synthesize userDictionary;
@synthesize isUserRights,isPendingUser;
@synthesize rightsString,cameraId;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (isUserRights) {
        optionsArray            = [NSArray arrayWithObjects:@"Full Rights",@"Read Only",@"No Access", nil];
        rightsString            = [AppUtility getCameraRights:userDictionary[@"rights"]];
        self.resendBtn.hidden   = isPendingUser?NO:YES;
        self.rights_View.hidden = NO;
        self.settingTableView.hidden    = YES;
        self.nameLabel.text     = isPendingUser?userDictionary[@"email"]:userDictionary[@"fullname"];
        self.emailLabel.text    = isPendingUser?@"...pending":userDictionary[@"email"];
        [GravatarServiceFactory requestUIImageByEmail:userDictionary[@"email"] defaultImage:gravatarServerImageMysteryMan size:96 delegate:self];
        if ([GlobalSettings sharedInstance].isPhone) {
            [self.iPhone_ScrollView contentSizeToFit];
        }
    }else{
        optionsArray = [NSArray arrayWithObjects:@"Public on the web",@"Anyone with the link",@"Only specific users", nil];
        self.resendBtn.hidden   = YES;
        self.rights_View.hidden = YES;
        if ([GlobalSettings sharedInstance].isPhone) {
            self.iPhone_ScrollView.hidden = YES;
        }
        self.navigationBar_Label.text = @"";
        self.settingTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        self.settingTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        self.settingTableView.layer.cornerRadius = 10.0;
        self.settingTableView.layer.borderWidth     = 1.0;
        self.settingTableView.layer.borderColor     = ((UIColor *)[AppUtility colorWithHexString:@"428bca"]).CGColor;
    }

    [optionsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == rightsString) {
            checkedIndexPath = [NSIndexPath indexPathForItem:idx inSection:0];
            [self.rights_Segment setSelectedSegmentIndex:checkedIndexPath.row];
            [self.settingTableView reloadData];
        }
    }];
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

- (IBAction)backAction:(id)sender {
    if ([GlobalSettings sharedInstance].isPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        if (!isUserRights) {
            [self.navigationController popViewControllerAnimated:YES];
        }else{
            [self dismissViewControllerAnimated:YES completion:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"K_ISIPAD_DEVICE" object:nil];
        }
    }
}

- (IBAction)save_Settings:(id)sender {
//     [self.loadingActivityIndicator startAnimating];
    if (isUserRights) {
        AppUser *user = [APP_DELEGATE defaultUser];
        if ([user.email isEqualToString:userDictionary[@"email"]]) {
            NSString *segment_String = [self.rights_Segment titleForSegmentAtIndex:self.rights_Segment.selectedSegmentIndex];

            if (self.rights_Segment.selectedSegmentIndex != 2 && ![segment_String isEqualToString:rightsString]) {
                [AppUtility displayAlertWithTitle:@"Sorry!" AndMessage:@"You can not change your own rights. You can remove yourself from this share."];
                return;
            }
        }
        NSString *newRights = nil;
        if (self.rights_Segment.selectedSegmentIndex == 0) {
            //Full Rights
            newRights = @"snapshot,view,edit,list";
            [self setCameraRightsForUser:newRights];
        }else if (self.rights_Segment.selectedSegmentIndex == 1){
            //Read Only
            newRights = @"snapshot,list";
            [self setCameraRightsForUser:newRights];
        }else{
            //No Access
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert!" message:@"Are you sure you want to remove this share?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove", nil];
            [alert show];
        }
        
    }else{
        NSString *choosenOption = optionsArray[checkedIndexPath.row];
        if ([choosenOption isEqualToString:@"Public on the web"]) {
            [self setCameraStatus_isDiscoverable:YES with_IsPublic:YES];
        }else if ([choosenOption isEqualToString:@"Anyone with the link"]){
            [self setCameraStatus_isDiscoverable:NO with_IsPublic:YES];
        }else{
            //Only specific users
            [self setCameraStatus_isDiscoverable:NO with_IsPublic:NO];
        }
    }
}

- (IBAction)resendShareRequest:(id)sender {
    [self.loadingActivityIndicator startAnimating];
    NSDictionary *param_Dictionary = [NSDictionary dictionaryWithObjectsAndKeys:userDictionary[@"camera_id"],@"camId",[APP_DELEGATE defaultUser].apiId,@"api_id",[APP_DELEGATE defaultUser].apiKey,@"api_Key",[NSNumber numberWithBool:isPendingUser],@"isPending",[NSDictionary dictionaryWithObjectsAndKeys:userDictionary[@"email"],@"email", nil],@"Post_Param", nil];
    EvercamShare *api_share_Obj = [EvercamShare new];
    [api_share_Obj New_Resend_CameraShare:param_Dictionary withBlock:^(id details, NSError *error) {
        if (!error) {
            [self.loadingActivityIndicator stopAnimating];
            UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:@"Success!" message:details[@"message"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            alert.tag           = 5606;
            [alert show];
        }else{
            [self.loadingActivityIndicator stopAnimating];
            [AppUtility displayAlertWithTitle:@"Error!" AndMessage:error.localizedDescription];
        }
    }];
}

-(void)setCameraStatus_isDiscoverable:(BOOL)isDiscoverable with_IsPublic:(BOOL)isPublic{
    [self.loadingActivityIndicator startAnimating];
    NSDictionary *param_Dictionary = [NSDictionary dictionaryWithObjectsAndKeys:cameraId,@"camId",[APP_DELEGATE defaultUser].apiId,@"api_id",[APP_DELEGATE defaultUser].apiKey,@"api_Key",[NSDictionary dictionaryWithObjectsAndKeys:isPublic?@"true":@"false",@"is_public",isDiscoverable?@"true":@"false",@"discoverable", nil],@"Post_Param", nil];
    EvercamShare *api_status_Obj = [EvercamShare new];
    [api_status_Obj changeCameraStatus:param_Dictionary withBlock:^(id details, NSError *error) {
        if (!error) {
            [self.loadingActivityIndicator stopAnimating];
            [self.navigationController popViewControllerAnimated:YES];
        }else{
            [self.loadingActivityIndicator stopAnimating];
            [AppUtility displayAlertWithTitle:@"Error!" AndMessage:error.localizedDescription];
        }
    }];
}

-(void)setCameraRightsForUser:(NSString *)newRights{
    [self.loadingActivityIndicator startAnimating];
    NSDictionary *param_Dictionary = [NSDictionary dictionaryWithObjectsAndKeys:userDictionary[@"camera_id"],@"camId",[APP_DELEGATE defaultUser].apiId,@"api_id",[APP_DELEGATE defaultUser].apiKey,@"api_Key",[NSNumber numberWithBool:isPendingUser],@"isPending",[NSDictionary dictionaryWithObjectsAndKeys:userDictionary[@"email"],@"email",newRights,@"rights", nil],@"Post_Param", nil];
    EvercamShare *api_share_Obj = [EvercamShare new];
    [api_share_Obj updateUserRights:param_Dictionary withBlock:^(id details, NSError *error) {
        if (!error) {
            [self.loadingActivityIndicator stopAnimating];
            if ([GlobalSettings sharedInstance].isPhone) {
                [self.navigationController popViewControllerAnimated:YES];
            }else{
                [self dismissViewControllerAnimated:YES completion:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"K_ISIPAD_DEVICE" object:nil];
            }
        }else{
            [self.loadingActivityIndicator stopAnimating];
            [AppUtility displayAlertWithTitle:@"Error!" AndMessage:error.localizedDescription];
        }
    }];
}

-(void)blockAccessOfUser{
    [self.loadingActivityIndicator startAnimating];
    NSDictionary *param_Dictionary = [NSDictionary dictionaryWithObjectsAndKeys:userDictionary[@"camera_id"],@"camId",[APP_DELEGATE defaultUser].apiId,@"api_id",[APP_DELEGATE defaultUser].apiKey,@"api_Key",userDictionary[@"email"],@"user_Email",[NSNumber numberWithBool:isPendingUser],@"isPending", nil];
    EvercamShare *api_share_Obj = [EvercamShare new];
    [api_share_Obj deleteCameraShare:param_Dictionary withBlock:^(id details, NSError *error) {
        if (!error) {
            [self.loadingActivityIndicator stopAnimating];
            AppUser *user = [APP_DELEGATE defaultUser];
            if ([user.email isEqualToString:userDictionary[@"email"]]) {
                //back to live view
                AppUtility.isFullyDismiss  = YES;
            }
            if ([GlobalSettings sharedInstance].isPhone) {
                [self.navigationController popViewControllerAnimated:YES];
            }else{
                [self dismissViewControllerAnimated:YES completion:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"K_ISIPAD_DEVICE" object:nil];
            }
        }else{
            [self.loadingActivityIndicator stopAnimating];
            [AppUtility displayAlertWithTitle:@"Error!" AndMessage:error.localizedDescription];
        }
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 5606) {
        [self.navigationController popViewControllerAnimated:YES];
    }else if (buttonIndex == 1) {
        [self blockAccessOfUser];
    }
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return optionsArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.textLabel.textColor = [AppUtility colorWithHexString:@"4B4B4B"];
        cell.textLabel.font     = [UIFont fontWithName:@"Arial" size:16.0];
        if (indexPath.row != 2) {
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0, cell.frame.size.height-1, cell.frame.size.width, 1)];
            lineView.backgroundColor = [AppUtility colorWithHexString:@"428bca"];
            lineView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
            UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleWidth;
            [cell addSubview:lineView];
        }
    }
    cell.textLabel.text = optionsArray[indexPath.row];
    if (checkedIndexPath.row == indexPath.row) {
        cell.accessoryType  = UITableViewCellAccessoryCheckmark;
        checkedIndexPath    = indexPath;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    AppUser *user = [APP_DELEGATE defaultUser];
    if ([user.email isEqualToString:userDictionary[@"email"]] && isUserRights) {
        UITableViewCell* cellCheck = [tableView
                                      cellForRowAtIndexPath:indexPath];
        if (indexPath.row != 2 && ![cellCheck.textLabel.text isEqualToString:rightsString]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [AppUtility displayAlertWithTitle:@"Sorry!" AndMessage:@"You can not change your own rights."];
            return;
        }
    }
    
    if (indexPath != checkedIndexPath) {
        UITableViewCell* uncheckCell = [tableView
                                        cellForRowAtIndexPath:checkedIndexPath];
        uncheckCell.accessoryType = UITableViewCellAccessoryNone;
        UITableViewCell* cellCheck = [tableView
                                      cellForRowAtIndexPath:indexPath];
        cellCheck.accessoryType = UITableViewCellAccessoryCheckmark;
        checkedIndexPath = indexPath;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)gravatarServiceDone:(id<GravatarService>)gravatarService
                 withImage:(UIImage *)image{
    self.gravator_ImageView.image = image;
}

-(void)gravatarService:(id<GravatarService>)gravatarService
      didFailWithError:(NSError *)error{
    
}

@end
