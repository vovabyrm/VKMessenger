//
//  VKDialogTableViewCell.h
//  VKMessenger
//
//  Created by Vladimir Burmistrov on 09.06.17.
//  Copyright © 2017 Vladimir Burmistrov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VKDialogTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView *photoImage;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UIView *coverView;

@end
