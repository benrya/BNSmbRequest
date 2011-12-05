//
//  SambaSampleViewController.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SambaSampleViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UITextField *urlField;
    IBOutlet UITextField *usrField;
    IBOutlet UITextField *pwdField;
    IBOutlet UITextField *wkgField;
    
    IBOutlet UIButton *getButton;
}

- (IBAction)getButtonClicked:(id)sender;
@end

