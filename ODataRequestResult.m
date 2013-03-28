/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
***************************************************************/

#import "ODataRequestResult.h"

@implementation ODataRequestResult

-(id) initWithConnection:(NSURLRequest*)_Request
{
    if((self = [super init]) != nil)
    {
        // Save request
        Request = _Request;
    }
    return self;
}

/*** Public Functions ***/

-(NSData*) GetResult:(NSError**)ErrorOut
{
    // Reset error and results
    *ErrorOut = nil;
    __block NSData* Data = nil;
    __block NSURLResponse* Response = nil;
    
    // Old method (should be valid, but there is a server-side issue)
    // Fundamental issue with iOS 6: http://stackoverflow.com/questions/12582849/nsurlconnectiondownloaddelegate-expectedtotalbytes-zero-in-ios-6
    // And WinServer doesn't support: http://aspnetwebstack.codeplex.com/workitem/785
    //NSData* Data = [NSURLConnection sendSynchronousRequest:Request returningResponse:&Response error:ErrorOut];
    
    // Create a working queue that runs in the background
    NSOperationQueue* MyQueue = [[NSOperationQueue alloc] init];
    
    // Explicitly create a semaphore that we're going to wait on
    dispatch_semaphore_t MySemaphore = dispatch_semaphore_create(0);
    
    // Updated method; should work for iOS 6
    [NSURLConnection sendAsynchronousRequest:Request queue:MyQueue completionHandler:^(NSURLResponse* GivenResponse, NSData* GivenData, NSError* GivenError) {
        
        // Pass our data results...
        *ErrorOut = GivenError;
        Data = GivenData;
        Response = GivenResponse;
        
        // Done with semaphore
        dispatch_semaphore_signal(MySemaphore);
    }];
    
    // Wait for our function to be called; this is guaranteed, even if it fails
    dispatch_semaphore_wait(MySemaphore, DISPATCH_TIME_FOREVER);
    //dispatch_release(MySemaphore);
    
    // On connection failure
    if(*ErrorOut != nil)
        return nil;
    
    // On data failure
    else if(Data == nil)
        return nil;
    
    // Finally no problems
    return Data;
}

/*** NSURLConnectionDelegate ***/

// On failure of connection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed");
}

/*** NSURLConnectionDataDelegate ***/

// On completion
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Connection success!");
}

@end
