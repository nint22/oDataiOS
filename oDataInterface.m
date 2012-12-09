/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
***************************************************************/

#import "oDataInterface.h"

/*** Internal Constants ***/

static const NSTimeInterval __oDataInterface_TimeOut = 5; // In seconds (Magic number)

/*** Internal Structures ***/

@implementation __oDataQuery
    @synthesize ServerURL, ServiceName, DatabaseName, ExecType, CollectionName, QueryString, QueryEntryName, QueryEntry;
@end

@implementation oDataInterface

/*** Public ***/

-(id)initInterfaceForServer:(NSURL*)_ServerURL andDatabase:(NSString*)_Database
{
    return [self initInterfaceForServer:_ServerURL onService:nil andDatabase:_Database];
}

-(id)initInterfaceForServer:(NSURL*)_ServerURL onService:(NSString*)_Service andDatabase:(NSString*)_Database
{
    // The true constructor for this entire class
    if((self = [super init]) != nil)
    {
        // Init and save base data
        ActiveQuery = [[__oDataQuery alloc] init];
        [ActiveQuery setServerURL:_ServerURL];
        [ActiveQuery setServiceName:_Service];
        [ActiveQuery setDatabaseName:_Database];
        
        // Clean state machine
        [self ClearStates];
    }
    return self;
}

+(id)oDataInterfaceForServer:(NSURL*)_ServerURL andDatabase:(NSString*)_Database
{
    return [[oDataInterface alloc] initInterfaceForServer:_ServerURL andDatabase:_Database];
}

+(id)oDataInterfaceForServer:(NSURL*)_ServerURL onService:(NSString*)_Service andDatabase:(NSString*)_Database
{
    return [[oDataInterface alloc] initInterfaceForServer:_ServerURL onService:_Service andDatabase:_Database];
}

-(NSURL*)GetFullURL
{
    // Form the appropriate URL
    NSURL* FullURL = nil;
    
    // Switch based on current state
    switch([ActiveQuery ExecType])
    {
        case oDataInterfaceExecType_Get:
            FullURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@%@", [[ActiveQuery ServerURL] absoluteString], [ActiveQuery ServiceName], [ActiveQuery CollectionName], [ActiveQuery QueryString] ? [NSString stringWithFormat:@"?%@", [ActiveQuery QueryString]] : @""]];
            break;
        case oDataInterfaceExecType_Post:
        case oDataInterfaceExecType_Put:
            FullURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@", [[ActiveQuery ServerURL] absoluteString], [ActiveQuery ServiceName], [ActiveQuery CollectionName]]];
            break;
        case oDataInterfaceExecType_Delete:
            // todo.. implement the delete overhead structures
            break;
        default:
            break;
    }
    
    return FullURL;
}

-(NSArray*)Execute:(NSError**)ErrorOut
{
    // Form the appropriate URL
    NSURL* FullURL = [self GetFullURL];
    NSArray* Result = nil;
    
    // If not correctly formed, error out
    if(FullURL == nil)
        *ErrorOut = NSErrorCreate(@"Unable to form the appropriate URL for this command");
    
    // Else, all good!
    else
        Result = [oDataInterface ExecuteQuery:ActiveQuery OnError:ErrorOut];
    
    // Done
    return Result;
}

-(void)ExecuteAsync:(void (^)(NSArray*, NSError*))CompletionHandler
{
    // Copy our current state
    __oDataQuery* Query = [ActiveQuery copy];
    
    // Parallel execution (async)
    NSOperationQueue* Queue = [[NSOperationQueue alloc] init];
    [Queue addOperationWithBlock:^{
        
        // Execute and have the result posted to the completion handler
        NSError* Error = nil;
        NSArray* Results = [oDataInterface ExecuteQuery:Query OnError:&Error];
        
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
    __oDataQuery* Promise = [ActiveQuery copy];
    
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
            NSArray* Results = [oDataInterface ExecuteQuery:Query OnError:&Error];
            
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

-(void)SetCollection:(NSString*)Collection
{
    [ActiveQuery setCollectionName: Collection];
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

-(void)AddEntry:(NSString*)Entry withData:(NSDictionary*)NewEntry
{
    // Register this as an execution operation
    [ActiveQuery setExecType: oDataInterfaceExecType_Post];
    [ActiveQuery setQueryString:[NSString stringWithFormat:@"%@/%@", [ActiveQuery ServiceName], [ActiveQuery CollectionName]]];
    [ActiveQuery setQueryEntryName: Entry];
    [ActiveQuery setQueryEntry: NewEntry];
}

-(void)UpdateEntry:(NSString*)Entry withData:(NSDictionary*)ExistingEntry
{
    // TODO...
}

-(void)DeleteEntry:(NSString*)Entry withData:(NSDictionary*)ExistingEntry
{
    // TODO...
}

-(NSArray*)ExecuteFuncString:(NSString*)FuncString WithError:(NSError**)ErrorOut
{
    // Just form the service URL with the function
    // Todo..
    [ActiveQuery setQueryString:[NSString stringWithFormat:@"%@/%@", [ActiveQuery ServiceName], FuncString]];
    return [oDataInterface ExecuteQuery:ActiveQuery OnError:ErrorOut];
}

// Non-blocking async. version of the string execution function
-(void)ExecuteFuncStringAsync:(NSString*)FuncString WithCompletionBlock:(void (^)(NSArray*, NSError*))CompletionHandler
{
    // Start a background thread and execute the regular function
    NSOperationQueue* BackgroundQueue = [[NSOperationQueue alloc] init];
    [BackgroundQueue addOperationWithBlock:^{
        
        // Error handler
        NSError* Error = nil;
        
        // Simply execute the same work as the blocking method (but this runs in the background)
        NSArray* Result = [self ExecuteFuncString:FuncString WithError:&Error];
        
        // Pass result to block
        CompletionHandler(Result, Error);
    }];
}

/*** Private ***/

-(void)ClearStates
{
    [ActiveQuery setExecType:oDataInterfaceExecType_Get];
    [ActiveQuery setCollectionName:nil];
    [ActiveQuery setQueryString:nil];
    [ActiveQuery setQueryEntryName:nil];
    [ActiveQuery setQueryEntry:nil];
}

-(void)QueryStringAppend:(NSString*)ToAppend
{
    // Explicit alloc & copy
    if([ActiveQuery QueryString] == nil)
        [ActiveQuery setQueryString:[NSString stringWithString:ToAppend]];
    
    // ... or just alloc & append
    else
        [ActiveQuery setQueryString:[NSString stringWithFormat:@"%@%@", [ActiveQuery QueryString], ToAppend]];
}

// Generalized execution function; executes with the state and with a given string or data
+(NSArray*)ExecuteQuery:(__oDataQuery*)Query OnError:(NSError**)ErrorOut
{
    // Reset error
    *ErrorOut = nil;
    
    // Form the appropriate URL get / post / etc...
    NSMutableURLRequest* Request = [[NSMutableURLRequest alloc] init];
    
    // Set the query / exec string
    switch([Query ExecType]) {
        case oDataInterfaceExecType_Get: [Request setHTTPMethod:@"GET"]; break;
        case oDataInterfaceExecType_Post: [Request setHTTPMethod:@"POST"]; break;
        case oDataInterfaceExecType_Put: [Request setHTTPMethod:@"PUT"]; break;
        case oDataInterfaceExecType_Delete: [Request setHTTPMethod:@"DELETE"]; break;
        
        // Error out:
        default:
        {
            *ErrorOut = NSErrorCreate(@"No known HTTP header type to use");
            return nil;
        }
    };
    
    // Set the default timeout
    [Request setTimeoutInterval:__oDataInterface_TimeOut];
    
    // Set headers
    [Request setValue:@"1.0" forHTTPHeaderField:@"DataServiceVersion"];
    [Request setValue:@"2.0" forHTTPHeaderField:@"MaxDataServiceVersion"];
    [Request setValue:@"application/atom+xml" forHTTPHeaderField:@"accept"];
    
    // Form query URL
    [Request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[Query ServerURL] absoluteString], [Query QueryString]]]];
    
    // Prep for result
    ODataRequestResult* Result = nil;
    
    // Insert our query (or data)
    if([Query ExecType] == oDataInterfaceExecType_Get)
    {
        // Execute
        Result = [[ODataRequestResult alloc] initWithConnection:Request];
    }
    // Insert or update (warning: update does not merge, but instead overwrites conflicts & defaults/nulls-out empty fields)
    else if([Query ExecType] == oDataInterfaceExecType_Post || [Query ExecType] == oDataInterfaceExecType_Put)
    {
        // Inform the server the XML+Atom format we will be posting
        [Request setValue:@"application/atom+xml" forHTTPHeaderField:@"content-type"];
        
        // The body of our message
        NSMutableString* MessageBody = [[NSMutableString alloc] init];
        [MessageBody appendFormat:
            @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"\
            @"<entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\""\
            @"  xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\""\
            @"  xmlns=\"http://www.w3.org/2005/Atom\">"\
            @"<title type=\"text\"></title>"\
            @"<updated>%@</updated>"\
            @"<author><name /></author>", [oDataParser oDataDateFormat:[NSDate date]]];
        
        // Define where we want to insert
        [MessageBody appendFormat:@"<category term=\"%@.%@\" scheme=\"http://schemas.microsoft.com/ado/2007/08/dataservices/scheme\" />", [Query DatabaseName], [Query QueryEntryName]];
        [MessageBody appendString:@"<content type=\"application/xml\">"];
        [MessageBody appendString:@"<m:properties>"];
        
        // For each key-value pair...
        for(id Key in [[Query QueryEntry] allKeys])
        {
            // Pull out value
            id Value = [[Query QueryEntry] objectForKey:Key];
            
            // Print off properties as "<d:ID>10</d:ID>", but if we know a type...
            
            // Check for expected types...
            if([Value isKindOfClass:[NSNumber class]])
            {
                // Get the type in question
                CFNumberType NumberType = CFNumberGetType((__bridge CFNumberRef)((NSNumber*)Value));
                switch(NumberType)
                {
                    case kCFNumberCharType:
                    case kCFNumberSInt8Type:
                        [MessageBody appendFormat:@"<d:%@ m:type=\"Edm.SByte\">%d</d:%@>", Key, [Value charValue], Key];
                        break;
                    case kCFNumberShortType:
                    case kCFNumberSInt16Type:
                        [MessageBody appendFormat:@"<d:%@ m:type=\"Edm.Int16\">%d</d:%@>", Key, [Value shortValue], Key];
                        break;
                    case kCFNumberIntType:
                    case kCFNumberSInt32Type:
                        [MessageBody appendFormat:@"<d:%@ m:type=\"Edm.Int32\">%d</d:%@>", Key, [Value intValue], Key];
                        break;
                    case kCFNumberLongType:
                    case kCFNumberSInt64Type:
                        [MessageBody appendFormat:@"<d:%@ m:type=\"Edm.Int64\">%lld</d:%@>", Key, [Value longLongValue], Key];
                        break;
                    case kCFNumberFloatType:
                    case kCFNumberFloat32Type:
                        [MessageBody appendFormat:@"<d:%@ m:type=\"Edm.Single\">%.7ff</d:%@>", Key, [Value floatValue], Key];
                        break;
                    case kCFNumberDoubleType:
                    case kCFNumberFloat64Type:
                        [MessageBody appendFormat:@"<d:%@ m:type=\"Edm.Double\">%.15lf</d:%@>", Key, [Value floatValue], Key];
                        break;
                    case kCFNumberLongLongType:
                        break;
                    default:
                        NSLog(@"Warning: Unknown NSNumber type, unable to handle!");
                        break;
                }
            }
            else if([Value isKindOfClass:[NSDate class]])
            {
                [MessageBody appendFormat:@"<d:%@ m:type=\"Edm.DateTime\">%@</d:%@>", Key, [oDataParser oDataDateFormat:Value], Key];
            }
            // Else, we will just print off as a string litereal
            else
            {
                [MessageBody appendFormat:@"<d:%@>%@</d:%@>", Key, Value, Key];
            }
        }
        
        // End of body
        [MessageBody appendString:@"</m:properties>"];
        [MessageBody appendString:@"</content></entry>"];
        
        // Execute with content
        [Request setHTTPBody:[MessageBody dataUsingEncoding:NSUTF8StringEncoding]];
        Result = [[ODataRequestResult alloc] initWithConnection:Request];
    }
    
    // TODO: other exec types
    
    // On no result generated, error out
    if(Result == nil)
    {
        *ErrorOut = NSErrorCreate(@"Unable to form connection");
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
    NSArray* ParsedData = [Parser GetEntries];
    if(ParsedData == nil)
        *ErrorOut = NSErrorCreate(@"Unable to form the returned data");
    
    return ParsedData;
}

@end
