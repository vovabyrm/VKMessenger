//
//  VKDialogCellData.m
//  VKMessenger
//
//  Created by Vladimir Burmistrov on 09.06.17.
//  Copyright © 2017 Vladimir Burmistrov. All rights reserved.
//

#import "VKDialogCellData.h"

@implementation VKDialogCellData

- (id) initWithServerResponse:(NSDictionary*) responseObject
{
    self = [super init];
    if (self) {
        
        self.messege = [responseObject objectForKey:@"body"];
        if([responseObject objectForKey:@"attachments"]) {
            NSArray* array = [responseObject objectForKey:@"attachments"];
            NSString* type = [[array firstObject] objectForKey:@"type"];
            if([type isEqualToString:@"photo"]) {
                //[self.messege substringToIndex:[self.messege length] - ]
                self.messege = [self.messege stringByAppendingString:@"[Фото]"];
            }else if ([type isEqualToString:@"video"]) {
                self.messege = [self.messege stringByAppendingString:@"[Видео]"];
            }else if ([type isEqualToString:@"audio"]) {
                self.messege = [self.messege stringByAppendingString:@"[Аудио]"];
            }else if ([type isEqualToString:@"doc"]) {
                self.messege = [self.messege stringByAppendingString:@"[Документ]"];
            }else if ([type isEqualToString:@"link"]) {
                self.messege = [self.messege stringByAppendingString:@"[Ссылка]"];
            }else if ([type isEqualToString:@"market"]) {
                self.messege = [self.messege stringByAppendingString:@"[Товар]"];
            }else if ([type isEqualToString:@"market_album"]) {
                self.messege = [self.messege stringByAppendingString:@"[Альбом товаров]"];
            }else if ([type isEqualToString:@"wall"]) {
                self.messege = [self.messege stringByAppendingString:@"[Запись]"];
            }else if ([type isEqualToString:@"wall_reply"]) {
                self.messege = [self.messege stringByAppendingString:@"[Репост]"];
            }else if ([type isEqualToString:@"sticker"]) {
                self.messege = [self.messege stringByAppendingString:@"[Стикер]"];
            }else if ([type isEqualToString:@"gift"]) {
                self.messege = [self.messege stringByAppendingString:@"[Подарок]"];
            }
        } else if ([responseObject objectForKey:@"fwd_messages"]) {
            self.messege = [self.messege stringByAppendingString:@"[Сообщение]"];
        } else if ([responseObject objectForKey:@"action"]) {
            self.messege = [self.messege stringByAppendingString:@"[Обновление беседы]"];
        }
        
        self.time = [responseObject objectForKey:@"date"];
        
        NSString* str1 = [NSString stringWithFormat:@"%@", [responseObject objectForKey:@"out"]];
        if([str1 isEqualToString:@"1"])
            self.out = true;
        
        NSString* str2 = [NSString stringWithFormat:@"%@", [responseObject objectForKey:@"read_state"]];
        if([str2 isEqualToString:@"1"])
        self.readState = true;
        
        NSString* urlString = [responseObject objectForKey:@"photo_100"];
        
        if (urlString) {
            self.imageURL = [NSURL URLWithString:urlString];
        }
        
        if([responseObject objectForKey:@"chat_id"]){
            self.dialogType = kChat;
            self.chatID = [responseObject objectForKey:@"chat_id"];
            self.title = [responseObject objectForKey:@"title"];
        }else{
            self.dialogType = kTetAtet;
            self.userID = [responseObject objectForKey:@"user_id"];
        }
    }
    return self;
}

@end
