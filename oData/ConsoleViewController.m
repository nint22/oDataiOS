//
//  ConsoleViewController.m
//  oData
//
//  Created by Jeremy Bridon on 12/5/12.
//  Copyright (c) 2012 Jeremy Bridon. All rights reserved.
//

#import "ConsoleViewController.h"
#import "oDataInterface.h"

@implementation ConsoleViewController

@synthesize Console;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start testing
    NSOperationQueue* Queue = [[NSOperationQueue alloc] init];
    [Queue addOperationWithBlock:^{
        [self StartTests];
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*** Testing ***/

-(void)StartTests
{
    // Since we're running in the background, everytime we want to update the form,
    // we'll have to use a main-threaded function. Thus, I use "ConsolePrint" to add to console
    
    [self ConsolePrint:@"Executing tests..."];
    
    // Overhead structures
    NSError* ErrorOut = nil;
    NSArray* Result = nil;
    
    // TODO: Update this to the latest interface standard
    #ifdef __SKIP__
    
    /*** Test A ***/
    
    [self ConsolePrint:@"Testing reading from Northwind service..."];
    
    // Connect to example service
    oDataInterface* InterfaceA = [oDataInterface oDataInterfaceForServer:[NSURL URLWithString:@"http://services.odata.org/Northwind/"] onService:@"Northwind.svc"];
    [InterfaceA SetCollection:@"Invoices"];
    
    // Query all (by giving no filter)
    ErrorOut = nil;
    Result = [InterfaceA Execute:&ErrorOut];
    
    // Any errors?
    if(ErrorOut != nil)
    {
        [self ConsolePrint:@"FAILED: Got an error"];
        [self ConsolePrint:[ErrorOut description]];
    }
    // No results?
    else if(Result == nil)
    {
        [self ConsolePrint:@"FAILED: Unable to parse"];
    }
    // No content?
    else if([Result count] <= 0)
    {
        [self ConsolePrint:@"FAILED: Missing results"];
    }
    // No error
    else
    {
        [self ConsolePrint:[NSString stringWithFormat:@"PASSED: Printing off first element...\n%@", [Result objectAtIndex:0]]];
    }
    
    /*** Test B ***/
    
    // Connect to example service
    oDataInterface* InterfaceB = [oDataInterface oDataInterfaceForServer:[NSURL URLWithString:@"http://services.odata.org/Northwind/"] onService:@"Northwind.svc"];
    [InterfaceB SetCollection:@"Products_by_Categories"];
    
    // Query all (by giving no filter)
    ErrorOut = nil;
    [InterfaceB AddTop:@"5"];
    Result = [InterfaceB Execute:&ErrorOut];
    
    // Any errors?
    if(ErrorOut != nil)
    {
        [self ConsolePrint:@"FAILED: Got an error"];
        [self ConsolePrint:[ErrorOut description]];
    }
    // No results?
    else if(Result == nil)
    {
        [self ConsolePrint:@"FAILED: Unable to parse"];
    }
    // No content?
    else if([Result count] <= 0)
    {
        [self ConsolePrint:@"FAILED: Missing results"];
    }
    // No error
    else
    {
        [self ConsolePrint:[NSString stringWithFormat:@"PASSED: Printing off first element...\n%@", [Result objectAtIndex:0]]];
    }
    
    #endif
}

-(void)ConsolePrint:(NSString*)String
{
    NSOperationQueue* MainQueue = [NSOperationQueue mainQueue];
    [MainQueue addOperationWithBlock:^{
        [Console setText:[NSString stringWithFormat:@"%@\n%@", [Console text], String]];
    }];
}

@end
