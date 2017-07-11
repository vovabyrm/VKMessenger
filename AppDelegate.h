//
//  AppDelegate.h
//  VKMessenger
//
//  Created by Vladimir Burmistrov on 07.06.17.
//  Copyright © 2017 Vladimir Burmistrov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <VKSdk.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

