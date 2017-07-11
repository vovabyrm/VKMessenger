//
//  DialogsTableViewController.h
//  VKMessenger
//
//  Created by Vladimir Burmistrov on 08.06.17.
//  Copyright © 2017 Vladimir Burmistrov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <VKSdk.h>
#import "VKDialogCellData.h"

@interface DialogsTableViewController : UITableViewController <VKSdkDelegate>

@property (strong, nonatomic) NSMutableArray* usersID;

@property (strong, nonatomic) VKUsersArray *VKusers;

@property (strong, nonatomic) NSMutableArray* groupsID;

@property (strong, nonatomic) VKGroups *VKGroups;

@property (strong, nonatomic) NSMutableArray* dialogCells;

@property (strong, nonatomic) NSMutableArray* allDialogs;

@property (strong, nonatomic) NSString* server;

@property (strong, nonatomic) NSString* key;

@property (strong, nonatomic) NSString* ts;

@end
