/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
***************************************************************/

#import "oDataInterface.h"

/*** Internal Constants ***/

static const NSTimeInterval __oDataInterface_TimeOut = 5; // In seconds (Magic number)

/*** Internal Structures ***/

@implementation __oDataQuery
    @synthesize ExecType, FullURL, QueryData;
@end

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
        ServiceName = _Service;
        
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
    ServiceName = _Service;
}

-(NSURL*)GetFullURL
{
    // Form the appropriate URL
    NSURL* FullURL = nil;
    
    // Switch based on current state
    switch(ExecType)
    {
        // TODO: implement the rest...
        case oDataInterfaceExecType_Get: FullURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", ServiceName, QueryString] relativeToURL:ServerURL];
        case oDataInterfaceExecType_Post:
        case oDataInterfaceExecType_Put:
        case oDataInterfaceExecType_Delete:
        default:
            break;
    }
    
    return FullURL;
}

-(NSDictionary*)Execute:(NSError**)ErrorOut
{
    // Form the appropriate URL
    NSURL* FullURL = [self GetFullURL];
    NSDictionary* Result = nil;
    
    // If not correctly formed, error out
    if(FullURL == nil)
        *ErrorOut = NSErrorCreate(@"Unable to form the appropriate URL for this command");
    
    // Else, all good!
    else
        Result = [oDataInterface ExecuteWithState:ExecType OnURL:FullURL WithData:nil OnError:ErrorOut];
    
    // Done
    return Result;
}

-(void)ExecuteAsync:(void (^)(NSDictionary*, NSError*))CompletionHandler
{
    // Copy our current state
    __oDataQuery* Query = [[__oDataQuery alloc] init];
    [Query setExecType:ExecType];
    
    // Todo: copy over any data for the commanb
    [Query setQueryData:nil];
    
    // Save full URL
    [Query setFullURL:[self GetFullURL]];
    
    // Parallel execution (async)
    NSOperationQueue* Queue = [[NSOperationQueue alloc] init];
    [Queue addOperationWithBlock:^{
        
        // Execute and have the result posted to the completion handler
        NSError* Error = nil;
        NSDictionary* Results = [oDataInterface ExecuteWithState:[Query ExecType] OnURL:[Query FullURL] WithData:[Query QueryData] OnError:&Error];
        
        // Post results
        CompletionHandler(Results, Error);
        
    }];
}

-(void)ClearPromises
{
    [FuturesQueue removeAllObjects];
}

-(void)PushPromise
{
    // Copy over our state
    __oDataQuery* Promise = [[__oDataQuery alloc] init];
    [Promise setExecType:ExecType];
    [Promise setFullURL:[self GetFullURL]];
    [Promise setQueryData:nil]; // TODO: get data struct pasted...
    
    // Save promise as a structure and clear the current state
    [FuturesQueue addObject:Promise];
    [self ClearStates];
}

-(NSArray*)ExecutePromises:(NSError**)ErrorOut
{
    // Result array
    NSMutableArray* ResultsArray = [[NSMutableArray alloc] init];
    
    // Create our worker queue; only when all events are complete do we return...
    NSOperationQueue* WorkerQueue = [[NSOperationQueue alloc] init];
    
    // Todo: deal with errors...
    
    // For each query in the queued promises
    for(__oDataQuery* Query in FuturesQueue)
    {
        // Add work in the background process
        [WorkerQueue addOperationWithBlock:^{
            
            // Execute and have the result posted to the completion handler
            NSError* Error = nil;
            NSDictionary* Results = [oDataInterface ExecuteWithState:[Query ExecType] OnURL:[Query FullURL] WithData:[Query QueryData] OnError:&Error];
            
            // Push back into results array (not sure if we need some sort of lock?)
            [ResultsArray addObject:Results];
        }];
    }
    
    // Block until completion
    [WorkerQueue waitUntilAllOperationsAreFinished];
    
    // All done, return an immutable array
    return [NSArray arrayWithArray:ResultsArray];
}

-(void)ExecutePromisesAsync:(void (^)(NSArray*, NSError*))CompletionHandler
{
    // Todo: what about the user manipulating the promises array during execution?
    
    // Put all in the background
    NSOperationQueue* Queue = [[NSOperationQueue alloc] init];
    [Queue addOperationWithBlock:^{
        
        // Execute it all
        NSError* Error = nil;
        NSArray* Results = [self ExecutePromises:&Error];
        
        // Update the completion handler
        CompletionHandler(Results, Error);
    }];
}

-(void)AddOrderBy:(NSString*)Option
{
    [self QueryStringAppend:[NSString stringWithFormat:@"$orderBy=%@", Option]];
}

-(void)AddTop:(NSString*)Option
{
    [self QueryStringAppend:[NSString stringWithFormat:@"$top=%@", Option]];
}

-(void)AddSkip:(NSString*)Option
{
    [self QueryStringAppend:[NSString stringWithFormat:@"$skip=%@", Option]];
}

-(void)AddExpand:(NSString*)Option
{
    [self QueryStringAppend:[NSString stringWithFormat:@"$expand=%@", Option]];
}

-(void)AddFormat:(NSString*)Option
{
    [self QueryStringAppend:[NSString stringWithFormat:@"$format=%@", Option]];
}

-(void)AddSelect:(NSString*)Option
{
    [self QueryStringAppend:[NSString stringWithFormat:@"$select=%@", Option]];
}

-(void)AddInLineCount:(NSString*)Option
{
    [self QueryStringAppend:[NSString stringWithFormat:@"$inlinecount=%@", Option]];
}

-(void)AddEntry:(NSDictionary*)NewEntry
{
    // TODO...
}

-(void)UpdateEntry:(NSDictionary*)ExistingEntry
{
    // TODO...
}

-(void)DeleteEntry:(NSDictionary*)ExistingEntry
{
    // TODO...
}

-(NSDictionary*)ExecuteFuncString:(NSString*)FuncString WithError:(NSError**)ErrorOut
{
    // Just form the service URL with the function
    return [oDataInterface ExecuteWithState:oDataInterfaceExecType_Get OnURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", ServiceName, FuncString] relativeToURL:ServerURL] WithData:nil OnError:ErrorOut];
}

// Non-blocking async. version of the string execution function
-(void)ExecuteFuncStringAsync:(NSString*)FuncString WithCompletionBlock:(void (^)(NSDictionary*, NSError*))CompletionHandler
{
    // Start a background thread and execute the regular function
    NSOperationQueue* BackgroundQueue = [[NSOperationQueue alloc] init];
    [BackgroundQueue addOperationWithBlock:^{
        
        // Error handler
        NSError* Error = nil;
        
        // Simply execute the same work as the blocking method (but this runs in the background)
        NSDictionary* Result = [self ExecuteFuncString:FuncString WithError:&Error];
        
        // Pass result to block
        CompletionHandler(Result, Error);
    }];
}

/*** Private ***/

-(void)ClearStates
{
    // Reset query / exec type
    ExecType = oDataInterfaceExecType_None;
    
    // Reset strings
    QueryString = nil;
}

-(void)QueryStringAppend:(NSString*)ToAppend
{
    // Explicit alloc & copy
    if(QueryString == nil)
        QueryString = [NSString stringWithString:ToAppend];
    
    // ... or just alloc & append
    else
        QueryString = [NSString stringWithFormat:@"%@%@", QueryString, ToAppend];
}

// Generalized execution function; executes with the state and with a given string or data
+(NSDictionary*)ExecuteWithState:(oDataInterfaceExecType)StateType OnURL:(NSURL*)FullURL WithData:(NSDictionary*)DataIn OnError:(NSError**)ErrorOut
{
    // Reset error
    *ErrorOut = nil;
    
    // Ignore if no query set
    if(StateType == oDataInterfaceExecType_None)
    {
        *ErrorOut = NSErrorCreate(@"No query formed to execute");
        return nil;
    }
    
    // Form the appropriate URL get / post / etc...
    NSMutableURLRequest* Request = [[NSMutableURLRequest alloc] init];
    
    // Set the query / exec string
    switch(StateType) {
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
    if(StateType == oDataInterfaceExecType_Get)
    {
        // Form query URL
        [Request setURL:FullURL];
        
        // Execute
        Result = [[ODataRequestResult alloc] initWithConnection:Request];
    }
    
    // TODO: other exec types
    
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

@end
