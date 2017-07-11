//
//  VKDialogCellData.h
//  VKMessenger
//
//  Created by Vladimir Burmistrov on 09.06.17.
//  Copyright © 2017 Vladimir Burmistrov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VKDialogCellData : NSObject

typedef enum {
    kChat,
    kTetAtet,
} DialogType;

@property (assign, nonatomic) DialogType dialogType;

@property (strong, nonatomic) NSString* messege;

@property (strong, nonatomic) NSString* userID;

@property (strong, nonatomic) NSString* chatID;

@property (strong, nonatomic) NSString* title;

@property (assign, nonatomic) BOOL readState;

@property (assign, nonatomic) BOOL out;

@property (assign, nonatomic) BOOL isOnline;

@property (assign, nonatomic) NSString* time;

@property (strong, nonatomic) NSURL* imageURL;

- (id) initWithServerResponse:(NSDictionary*) responseObject;

@end
