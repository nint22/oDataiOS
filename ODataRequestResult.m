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
    // Reset error
    *ErrorOut = nil;
    
    // Exec. request
    NSURLResponse* Response = nil;
    NSData* Data = [NSURLConnection sendSynchronousRequest:Request returningResponse:&Response error:ErrorOut];
    
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
