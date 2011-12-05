//
//  SambaSampleViewController.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "SambaSampleViewController.h"
#import "NSString+Encoding.h"
#import "SambaSampleAppDelegate.h"
#import "BNSmbRequest.h"
#import "BNSmbFile.h"
#import "BNSmbDirectory.h"
#import "DirectoryViewController.h"
#import "FileInfoViewController.h"

@implementation SambaSampleViewController

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.title = @"SambaSample";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)getButtonClicked:(id)sender {
    if (urlField.text != nil && ![urlField.text isEqualToString:@""]) {
        SambaSampleAppDelegate *delegate = [SambaSampleAppDelegate instance];
        delegate.username =  usrField.text;
        delegate.password = pwdField.text;
        delegate.workgroup = wkgField.text;
        
        BNSmbRequest *request = [BNSmbRequest requestToGetStatus:urlField.text];
        request.delegate = self;
        request.username = usrField.text;
        request.password = pwdField.text;
        request.workgroup = wkgField.text;
        request.didFinishSelector  = @selector(didFinishRequest:);
        request.didFailSelector  = @selector(didFailRequest:);
        [request startAsynchronous];
    }
}

- (void)didFinishRequest:(BNSmbRequest*)request {
    if ([request.response isKindOfClass:[BNSmbDirectory class]]) {
        DirectoryViewController *directoryView = [[[DirectoryViewController alloc] init] autorelease];
        directoryView.info = (BNSmbDirectory*)request.response;
        [self.navigationController pushViewController:directoryView animated:YES];        
    } else if ([request.response isKindOfClass:[BNSmbFile class]]) {
        FileInfoViewController *fileInfoView = [[[FileInfoViewController alloc] init] autorelease];
        fileInfoView.info = (BNSmbFile*)request.response;
        [self.navigationController pushViewController:fileInfoView animated:YES];
    }
}

- (void)didFailRequest:(BNSmbRequest*)request {
    if (request.error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:request.error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self getButtonClicked:nil];
    return YES;
}

@end
