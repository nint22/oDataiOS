/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
***************************************************************/

#import "oDataInterface.h"

/*** Internal Constants ***/

static const NSTimeInterval __oDataInterface_TimeOut = 3; // 3 seconds

@implementation oDataInterface

/*** Public ***/

-(id)initInterfaceForServer:(NSURL*)_ServerURL
{
    return [self initInterfaceForServer:_ServerURL onService:nil];
}

-(id)initInterfaceForServer:(NSURL*)_ServerURL onService:(NSString*)_Service
{
    // The true constructor for this entire class
    if((self = [super init]) != nil)
    {
        // Save URLs
        ServerURL = _ServerURL;
        ServiceURL = _Service;
        
        // Clean state machine
        [self ClearStates];
    }
    return self;
}

+(id)oDataInterfaceForServer:(NSURL*)_ServerURL
{
    return [[oDataInterface alloc] initInterfaceForServer:_ServerURL];
}

+(id)oDataInterfaceForServer:(NSURL*)_ServerURL onService:(NSString*)_Service
{
    return [[oDataInterface alloc] initInterfaceForServer:_ServerURL onService:_Service];
}

-(void)SetService:(NSString*)_Service
{
    ServiceURL = _Service;
}

-(NSDictionary*)Execute:(NSError**)ErrorOut
{
    // Reset error
    *ErrorOut = nil;
    
    // Ignore if no query set
    if(ExecType == oDataInterfaceExecType_None)
    {
        *ErrorOut = NSErrorCreate(@"No query formed to execute");
        return nil;
    }
    
    // Form the appropriate URL get / post / etc...
    NSMutableURLRequest* Request = [[NSMutableURLRequest alloc] init];
    
    // Set the query / exec string
    switch(ExecType) {
        case oDataInterfaceExecType_Get: [Request setHTTPMethod:@"GET"];
        case oDataInterfaceExecType_Post: [Request setHTTPMethod:@"POST"];
        case oDataInterfaceExecType_Put: [Request setHTTPMethod:@"PUT"];
        case oDataInterfaceExecType_Delete: [Request setHTTPMethod:@"DELETE"];
        
        // Error out:
        default:
        case oDataInterfaceExecType_None:
        {
            *ErrorOut = NSErrorCreate(@"No known HTTP header type to use");
            return nil;
        }
    };
    
    // Set the default timeout
    [Request setTimeoutInterval:__oDataInterface_TimeOut];
    
    // Set headers
    [Request setValue:@"2.0" forHTTPHeaderField:@"DataServiceVersion"];
    [Request setValue:@"2.0" forHTTPHeaderField:@"MaxDataServiceVersion"];
    
    // Prep for result
    ODataRequestResult* Result = nil;
    
    // Insert our query (or data)
    if(ExecType == oDataInterfaceExecType_Get)
    {
        // Check if there is anything to actually execute
        if(QueryString == nil || [QueryString length] <= 0)
        {
            *ErrorOut = NSErrorCreate(@"No query string formed");
            return nil;
        }
        
        // Form query URL
        [Request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/?%@", [ServerURL absoluteString], ServiceURL, QueryString]]];
        
        // Execute
        ODataRequestResult* Result = [[ODataRequestResult alloc] initWithConnection:Request];
    }
    
    // On no result generated, error out
    if(Result == nil)
    {
        *ErrorOut = NSErrorCreate(@"No known oData action to use");
        return nil;
    }
    
    // Explicitly stall until success or failure
    NSData* Data = [Result GetResult:ErrorOut];
    
    // On failure, just stop
    if(Data == nil || *ErrorOut != nil)
        return nil;
    
    // On success, parse!
    oDataParser* Parser = [[oDataParser alloc] initWithData:Data];
    
    // On failure, report last possible error
    if(Parser == nil)
    {
        *ErrorOut = NSErrorCreate(@"Unable to parse the returned data");
        return nil;
    }
    
    // All done!
    return [Parser GetEntities];
}

-(void)ExecuteAsync:(void (^)(NSDictionary*, NSError*))CompletionHandler
{
    // Parallel execution (async)
}

-(void)ClearPromises
{
    
}

-(void)PushPromise
{
    
}

-(NSArray*)ExecutePromises
{
    
}

-(void)AddOrderBy:(NSString*)Option
{
    
}

-(void)AddTop:(NSString*)Option
{
    
}

-(void)AddSkip:(NSString*)Option
{
    
}

-(void)AddExpand:(NSString*)Option
{
    
}

-(void)AddFormat:(NSString*)Option
{
    
}

-(void)AddSelect:(NSString*)Option
{
    
}

-(void)AddInLineCount:(NSString*)Option
{
    
}

-(void)AddEntry:(NSDictionary*)NewEntry
{
    
}

-(void)UpdateEntry:(NSDictionary*)ExistingEntry
{
    
}

-(void)DeleteEntry:(NSDictionary*)ExistingEntry
{
    
}

/*** Private ***/

-(void)ClearStates
{
    // Reset query / exec type
    ExecType = oDataInterfaceExecType_None;
    
    // Reset strings
    QueryString = nil;
}

@end
