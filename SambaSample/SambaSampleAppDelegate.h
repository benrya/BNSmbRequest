//
//  SambaSampleAppDelegate.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SambaSampleViewController;

@interface SambaSampleAppDelegate : NSObject <UIApplicationDelegate> {
    NSString *_username;
    NSString *_password;
    NSString *_workgroup;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *workgroup;
@property (nonatomic, retain) IBOutlet UINavigationController *viewController;

+(SambaSampleAppDelegate*)instance;
@end
