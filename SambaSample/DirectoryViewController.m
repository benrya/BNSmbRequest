//
//  SambaSampleTableViewController.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "DirectoryViewController.h"
#import "FileInfoViewController.h"
#import "SambaSampleAppDelegate.h"
#import "BNSmbRequest.h"
#import "BNSmbContext.h"
#import "BNSmbDirectory.h"
#import "BNSmbFile.h"

@implementation DirectoryViewController
@synthesize info=_info, list;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = _info.fileName;
    SambaSampleAppDelegate *delegate = [SambaSampleAppDelegate instance];
    NSLog(@"%@",_info.filePath);
    const char *test = [_info.filePath UTF8String];
    BNSmbRequest *request = [BNSmbRequest requestToGetContexts:_info.filePath];
    request.delegate = self;
    request.username = delegate.username;
    request.password = delegate.password;
    request.workgroup = delegate.workgroup;
    request.didFinishSelector = @selector(didFinishRequest:);
    request.didFailSelector  = @selector(didFailRequest:);
    [request startSynchronous];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_info dealloc];
    [list dealloc];
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    if (indexPath.row < list.count) {
        id<BNSmbContext> context = (id<BNSmbContext>)[list objectAtIndex:indexPath.row];
        cell.textLabel.text = context.fileName;
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    id<BNSmbContext> context = (id<BNSmbContext>)[list objectAtIndex:indexPath.row];
    if ([context isKindOfClass:[BNSmbDirectory class]]) {
        DirectoryViewController *directoryView = [[[DirectoryViewController alloc] init] autorelease];
        directoryView.info = (BNSmbDirectory*)context;
        [self.navigationController pushViewController:directoryView animated:YES];      
    } else if ([context isKindOfClass:[BNSmbFile class]]) {
        FileInfoViewController *fileInfoView = [[[FileInfoViewController alloc] init] autorelease];
        fileInfoView.info = (BNSmbFile*)context;
        [self.navigationController pushViewController:fileInfoView animated:YES];
    }
}


- (void)didFinishRequest:(BNSmbRequest*)request {
    list = [request.response retain];
    [self.tableView reloadData];
}

- (void)didFailRequest:(BNSmbRequest*)request {
    if (request.error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:request.error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

@end
