//
//  FileInfoViewController.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "FileInfoViewController.h"
#import "BNSmbRequest.h"

@implementation FileInfoViewController
@synthesize info=_info;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [_info dealloc];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = _info.fileName;
    fileNameLabel.text = _info.fileName;
    sizeLabel.text = [NSString stringWithFormat:@"%d", _info.size];
    modeLabel.text = [NSString stringWithFormat:@"%d", _info.mode];
    createLabel.text = [NSString stringWithFormat:@"%d", _info.lastModified];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)downloadButtonClicked:(id)sender {

    downloadButton.enabled = NO;
    progressView.progress = 0;
    progressView.hidden = NO;
    NSString *downloadPath = [NSHomeDirectory() stringByAppendingPathComponent:_info.fileName];
    
    BNSmbRequest *request = [BNSmbRequest requestWithURL:_info.filePath toDownloadFile:downloadPath];
    request.delegate = self;
    request.progressView = progressView;
    request.didFinishSelector = @selector(didFinishRequest:);
    request.didFailSelector = @selector(didFailRequest:);
    [request startAsynchronous];
}

- (void)didFinishRequest:(BNSmbRequest*)request {
    downloadButton.enabled = YES;
}

- (void)didFailRequest:(BNSmbRequest*)request {
    if (request.error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:request.error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    downloadButton.enabled = YES;
}

@end
