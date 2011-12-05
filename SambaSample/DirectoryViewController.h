//
//  SambaSampleTableViewController.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BNSmbDirectory.h"

@interface DirectoryViewController : UITableViewController {
    BNSmbDirectory *_info;
    NSArray *list;
}
@property (nonatomic, copy) BNSmbDirectory *info;
@property (nonatomic, retain) NSArray *list;
@end
