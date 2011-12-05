//
//  FileInfoViewController.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BNSmbFile.h"

@interface FileInfoViewController : UIViewController {
    IBOutlet UILabel *fileNameLabel;
    IBOutlet UILabel *sizeLabel;
    IBOutlet UILabel *modeLabel;
    IBOutlet UILabel *createLabel;
    
    IBOutlet UIProgressView *progressView;
    IBOutlet UIButton *downloadButton;
    
    BNSmbFile *_info;
}
@property (nonatomic,retain) BNSmbFile *info;
- (IBAction)downloadButtonClicked:(id)sender;
@end
