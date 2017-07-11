//
//  DialogsTableViewController.m
//  VKMessenger
//
//  Created by Vladimir Burmistrov on 08.06.17.
//  Copyright © 2017 Vladimir Burmistrov. All rights reserved.
//

#import "DialogsTableViewController.h"
#import "UIImageView+AFNetworking.h"
#import "VKDialogTableViewCell.h"

static NSArray *SCOPE = nil;
static int NumberOfDialogs = 40;

@interface DialogsTableViewController () <UIAlertViewDelegate, VKSdkUIDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *logInButton;

@property (strong, nonatomic) UIRefreshControl* refreshControlDialog;

@end

@implementation DialogsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.allDialogs = [[NSMutableArray alloc] init];
    self.usersID = [[NSMutableArray alloc] init];
    self.groupsID = [[NSMutableArray alloc] init];
    self.dialogCells = [[NSMutableArray alloc] init];
    
    self.refreshControlDialog = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControlDialog];
    [self.refreshControlDialog addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    SCOPE = @[VK_PER_FRIENDS, VK_PER_AUDIO, VK_PER_PHOTOS, VK_PER_NOHTTPS, VK_PER_EMAIL, VK_PER_MESSAGES];
    [super viewDidLoad];
    [[VKSdk initializeWithAppId:@"6065865"] registerDelegate:self];
    [[VKSdk instance] setUiDelegate:self];
    [VKSdk wakeUpSession:SCOPE completeBlock:^(VKAuthorizationState state, NSError *error) {
        if (state == VKAuthorizationAuthorized) {
            self.logInButton.title = @"Log Out";
            [self startWorking];
        } else if (error) {
            [[[UIAlertView alloc] initWithTitle:nil message:[error description] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startWorking {
    [self getDialogsAndUsers:NumberOfDialogs withOffset:@"0"];
    [self.allDialogs addObjectsFromArray:self.dialogCells];
    [self newPathsForTable];
    [self startPoll];
}

- (void) refreshArrays {
    [self.dialogCells removeAllObjects];
    [self.usersID removeAllObjects];
    [self.VKusers.items removeAllObjects];
    [self.groupsID removeAllObjects];
    [self.VKGroups.items removeAllObjects];
}

- (void)refreshTable {
    [self refreshArrays];
    [self performSelectorInBackground:@selector(getMoreDialogsDataRefresh) withObject:nil];

}

- (void) getDialogsAndUsers: (int)count withOffset:(NSString*) offset {
    [self getDialogsFromServer: [NSString stringWithFormat:@"%i", count] withOffset:offset];
    [self getUsersFromDialogs];
    [self getGroupsFromDialogs];
    [self titleForDialogs];
}

- (IBAction)authorize:(id)sender {
    if([self.logInButton.title isEqualToString:@"Log In"]){
        [VKSdk authorize:SCOPE];
        self.logInButton.title = @"Log Out";
    }else{
        [VKSdk forceLogout];
        self.logInButton.title = @"Log In";
        [self refreshArrays];
        [self.allDialogs removeAllObjects];
        
        [self.tableView reloadData];
    }
}

- (void)getMoreDialogsData {
    [self getDialogsAndUsers:NumberOfDialogs withOffset:[NSString stringWithFormat:@"%i", (int)[self.allDialogs count]]];
    [self.allDialogs addObjectsFromArray:self.dialogCells];
    [self performSelectorOnMainThread:@selector(newPathsForTable) withObject:nil waitUntilDone:YES];
}

- (void)getMoreDialogsDataRefresh {
    [self getDialogsAndUsers:NumberOfDialogs withOffset:@"0"];
    [self.allDialogs removeAllObjects];
    [self.allDialogs addObjectsFromArray:self.dialogCells];
    [self performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:YES];
}

- (void) endRefreshing {
    [self.refreshControlDialog endRefreshing];
    [self.tableView reloadData];
}

- (void) loadMore {
    [self refreshArrays];
    [self performSelectorInBackground:@selector(getMoreDialogsData) withObject:nil];
}

#pragma mark - API

- (void) getDialogsFromServer:(NSString*)numberOfDialogs withOffset: (NSString*)offset {
    if ([numberOfDialogs integerValue] > 200) {
        numberOfDialogs = @"200";
    }
    VKRequest* req = [VKRequest requestWithMethod:@"messages.getDialogs" parameters:@{@"preview_length" : @"50",
                                                                                      @"count" : numberOfDialogs,
                                                                                      @"offset" : offset} ];
    req.waitUntilDone = YES;
    
    __weak __typeof(self) welf = self;
    
    [req executeWithResultBlock:^(VKResponse *response) {
        NSArray* dialogsArray = [response.json objectForKey:@"items"];
        for(NSMutableDictionary* dialog in dialogsArray)
        {
            NSMutableDictionary* mes = [dialog objectForKey:@"message"];
            VKDialogCellData* cell = [[VKDialogCellData alloc] initWithServerResponse:mes];
            [welf.dialogCells addObject:cell];
            if(cell.dialogType == kTetAtet){
                NSString* userID = [NSString stringWithFormat:@"%@", [mes objectForKey:@"user_id"]];
                if ([userID integerValue] >= 0) {
                    [welf.usersID addObject:[mes objectForKey:@"user_id"]];
                } else {
                    [welf.groupsID addObject:[userID substringFromIndex:1]];
                }
            }
        }
        //NSLog(@"%@", response.request.requestTiming);
        //NSLog(@"%@", dialogsArray);
    }                                errorBlock:^(NSError *error) {
        NSLog(@"smth went horribly wrong");
    }];
}

- (void) getGroupsFromDialogs {
    if(self.groupsID.count) {
        
        __weak __typeof(self) welf = self;
        NSString* stringWithIDs = @"";
        for (NSString* ids in self.groupsID) {
            stringWithIDs = [stringWithIDs stringByAppendingString:ids];
            stringWithIDs = [stringWithIDs stringByAppendingString:@","];
        }
        stringWithIDs = [stringWithIDs substringToIndex:(stringWithIDs.length - 1)];
        NSDictionary* params = [[NSDictionary alloc] initWithObjectsAndKeys:stringWithIDs, @"group_ids" , nil];
        VKRequest* req = [[VKApi groups] getById: params];
        req.waitUntilDone = YES;
        [req executeWithResultBlock:^(VKResponse *response) {
            welf.VKGroups = response.parsedModel;
        } errorBlock:^(NSError *error) {
            NSLog(@"smth went horribly wrong - String = %@", stringWithIDs);
        }];
        
    }
}

- (void) getUsersFromDialogs {
    
    if(self.usersID.count) {
    
    __weak __typeof(self) welf = self;
    VKRequest* req = [[VKApi users] get:@{VK_API_FIELDS : @"first_name, last_name, photo_100, online, last_seen", VK_API_USER_IDS : self.usersID}];
    req.waitUntilDone = YES;
    [req executeWithResultBlock:^(VKResponse *response) {
        welf.VKusers = response.parsedModel;
    } errorBlock:^(NSError *error) {
        NSLog(@"smth went horribly wrong");
    }];
        
    }
}

- (void) newPathsForTable {
    NSMutableArray* newPaths = [NSMutableArray array];
    
    for (int i = (int)[self.allDialogs count] - (int)[self.dialogCells count]; i < [self.allDialogs count]; i++) {
        [newPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:newPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];

}

- (void) titleForDialogs {
    for (VKDialogCellData* cell in self.dialogCells) {
        if(cell.dialogType == kTetAtet){
            NSString* userID = [NSString stringWithFormat:@"%@", cell.userID];
            if ([userID integerValue] >= 0) {
                NSArray* array = [NSArray arrayWithArray:self.VKusers.items];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id==%@", cell.userID];
                NSArray *results = [array filteredArrayUsingPredicate:predicate];
                VKUser* user = [results firstObject];
                NSString* name = [[NSString alloc] init];
                if(user.last_name){
                    name = [NSString stringWithFormat:@"%@ %@",
                                  user.first_name,
                                  user.last_name];
                }else {
                    name = [NSString stringWithFormat:@"%@", user.first_name];
                }
                cell.title = name;
                if(user.online == [NSNumber numberWithInteger:1]) {
                    cell.isOnline = true;
                }
                NSURL* photoURL = [NSURL URLWithString:user.photo_100];
                cell.imageURL = photoURL;
            } else {
                NSArray* array = [NSArray arrayWithArray:self.VKGroups.items];
                NSString* predicateString = [NSString stringWithFormat:@"id==%@", [userID substringFromIndex:1]];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
                NSArray *results = [array filteredArrayUsingPredicate:predicate];
                VKGroup* group = [results firstObject];
                cell.title = group.name;
                NSURL* photoURL = [NSURL URLWithString:group.photo_100];
                cell.imageURL = photoURL;
            }
        }
    }
}

#pragma mark - long pool

- (void) getLPinfo {
    __weak __typeof(self) welf = self;
    VKRequest* req = [VKRequest requestWithMethod:@"messages.getLongPollServer" parameters:@{@"need_pts" : @"0"} ];
    [req executeWithResultBlock:^(VKResponse *response) {
        welf.server = [response.json objectForKey:@"server"];
        //NSLog(@"%@",self.server);
        welf.key = [response.json objectForKey:@"key"];
        //NSLog(@"%@",self.key);
        welf.ts = [response.json objectForKey:@"ts"];
        //NSLog(@"%@",self.ts);
        [welf performSelectorInBackground:@selector(longPoll) withObject: nil];
    } errorBlock:^(NSError *error) {
        NSLog(@"smth went horribly wrong");
    }];
}

- (void) longPoll {
    
    NSError* error = nil;
    NSURLResponse* response = nil;
    NSString* urlString = [NSString stringWithFormat
                           :@"https://%@?act=a_check&key=%@&ts=%@&wait=25&mode=2&version=2",
                           self.server, self.key, self.ts];
    //NSLog(@"%@",urlString);
    NSURL* requestUrl = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:requestUrl];
    
    //send the request (will block until a response comes back)
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response error:&error];
    
    //pass the response on to the handler (can also check for errors here, if you want)
    [self performSelectorOnMainThread:@selector(dataReceived:)
                           withObject:responseData waitUntilDone:YES];
}

- (void) startPoll {
    //not covered:  stopping the poll or ensuring that only 1 poll is active at any given time
    [self getLPinfo];
}

- (void) dataReceived: (NSData*) theData {

    if(theData){
    id json = [NSJSONSerialization JSONObjectWithData:theData options:0 error:nil];
    BOOL shouldUpdate = NO;
    NSLog(@"JSON - %@",[json objectForKey:@"updates"]);
    NSArray* updates = [json objectForKey:@"updates"];
    for(NSArray* upadte in updates){
        NSString* typeOfUpdate = [NSString stringWithFormat:@"%@",[upadte firstObject]];
        if([typeOfUpdate isEqualToString:@"4"] || [typeOfUpdate isEqualToString:@"6"]
           || [typeOfUpdate isEqualToString:@"7"]){
            shouldUpdate = YES;
        }
            
    }
    
    NSLog(@"TS - %@",[json objectForKey:@"ts"]);
    self.ts = [json objectForKey:@"ts"];
    
    if(shouldUpdate)
        [self updateDialogs];
    }
    
    [self performSelectorInBackground:@selector(longPoll) withObject: nil];
    
}

- (void) updateDialogs {
    [self refreshArrays];
    int count = (int)[self.allDialogs count];
    if (count > 100) { //if there is more than 100 dialogs loaded, only first 100 will be updated
        count = 100;
        NSRange range = NSMakeRange(0, 100);
        [self.allDialogs removeObjectsInRange:range];
        [self getDialogsAndUsers:count withOffset:@"0"];
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                               NSMakeRange(0,[self.dialogCells count])];
        [self.allDialogs insertObjects:self.dialogCells atIndexes:indexes];
    } else {
        [self.allDialogs removeAllObjects];
        [self getDialogsAndUsers:count withOffset:@"0"];
        [self.allDialogs addObjectsFromArray:self.dialogCells];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allDialogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VKDialogTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VKDialogCell" forIndexPath:indexPath];
    VKDialogCellData* data = [self.allDialogs objectAtIndex:indexPath.row];
    if(self.allDialogs){
        if(data.isOnline){
            NSString* text = [NSString stringWithFormat:@"%@  ",data.title];
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
            
            NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
            textAttachment.image = [UIImage imageNamed:@"dot.png"];
            
            //CGFloat imageOffsetY = -5.0;
            textAttachment.bounds = CGRectMake(0, 2, 6, 6);
            
            NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
            
            [attributedString replaceCharactersInRange:NSMakeRange([text length] - 1, 1)
                                  withAttributedString:attrStringWithImage];
            
            cell.titleLabel.attributedText = attributedString;
        }
        cell.titleLabel.text = [data title];
        
        cell.messageLabel.text = [data messege];
        
        NSString* string =[data time];
        NSTimeInterval interval = [string intValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSDateFormatter *day = [[NSDateFormatter alloc] init];
        NSDateFormatter *week = [[NSDateFormatter alloc] init];
        NSDate* currentTime = [NSDate date];
        NSDate* yesterday = [currentTime dateByAddingTimeInterval:-86400];
        [day setDateFormat:@"dd MM YY"];
        [week setDateFormat:@"ww YY"];
        NSString *dayDate = [day stringFromDate:date];
        NSString *dayCT = [day stringFromDate:currentTime];
        if([dayDate isEqualToString:dayCT]) {
            [dateFormatter setDateFormat:@"HH:mm"];
        }else if ([[day stringFromDate:date] isEqualToString:[day stringFromDate:yesterday]]) {
            [dateFormatter setDateFormat:@"вчера"];
        }else if ([[week stringFromDate:date] isEqualToString:[week stringFromDate:currentTime]]) {
            [dateFormatter setDateFormat:@"cccc"];
        }else {
            [dateFormatter setDateFormat:@"dd.MM.yy"];
        }
        NSString *formattedDateString = [dateFormatter stringFromDate:date];
        cell.timeLabel.text = formattedDateString;
        
        cell.photoImage.image = nil;
        if (data.imageURL) {
            __weak VKDialogTableViewCell* weakCell = cell;
            NSURL* url = [[NSURL alloc] init];
            url = [[self.allDialogs objectAtIndex:indexPath.row] imageURL];
            NSURLRequest* request = [NSURLRequest requestWithURL:url];
            [cell.photoImage
             setImageWithURLRequest:request
             placeholderImage:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                 weakCell.photoImage.image = image;
                 weakCell.photoImage.layer.cornerRadius = weakCell.photoImage.frame.size.height /2;
                 weakCell.photoImage.layer.masksToBounds = YES;
                 weakCell.photoImage.layer.borderWidth = 0;
                 [weakCell layoutSubviews];
             }
             failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
             }];
        } else {
            cell.photoImage.image = [UIImage imageNamed:@"chat.png"];
        }
        if(![data readState]){
            if(![data out]) {
                [cell setBackgroundColor:
                 [UIColor colorWithRed:235.0f/255.0f green:237.0f/255.0f blue:250.0f/255.0f alpha:1.0f]];
            }
                [cell.coverView setBackgroundColor: [UIColor colorWithRed:235.0f/255.0f green:237.0f/255.0f blue:250.0f/255.0f alpha:1.0f]];
                cell.coverView.layer.cornerRadius = 8;
                cell.coverView.layer.masksToBounds = YES;
        }else{
            [UIView animateWithDuration:0.3 animations:^{
                [cell setBackgroundColor:
                 [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f]];
                [cell.coverView setBackgroundColor: [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f]];
            }];
            
        }

    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.dialogCells){
        if(indexPath.row == ([self.allDialogs count] - 20)) {
            [self loadMore];
        }
    }
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

#pragma mark - VKSDK Delegate

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {
    VKCaptchaViewController *vc = [VKCaptchaViewController captchaControllerWithError:captchaError];
    [vc presentIn:self.navigationController.topViewController];
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {
    //[self authorize:nil];
    [VKSdk authorize:SCOPE];
}

- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result {
    if (result.token) {
        [self startWorking];
    } else if (result.error) {
        [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Access denied\n%@", result.error] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (void)vkSdkUserAuthorizationFailed {
    [[[UIAlertView alloc] initWithTitle:nil message:@"Access denied" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
    [self.navigationController.topViewController presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end

