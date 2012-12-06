/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
 This source file is developed and maintained by:
 + Jeremy Bridon jbridon@cores2.com
 
 File: oDataInterface.h/m
 Desc: The main interface that wraps a given oData service.
 http://www.odata.org/documentation/uri-conventions#OrderBySystemQueryOption
 http://en.wikipedia.org/wiki/Futures_and_promises
 
***************************************************************/

#import "oDataParser.h"
#import "ODataRequestResult.h"

/*** Internal Types ***/

// All possible URL actions
typedef enum __oDataInterfaceExecType {
    oDataInterfaceExecType_Get,     // Query (default)
    oDataInterfaceExecType_Post,    // Insert
    oDataInterfaceExecType_Put,     // Update
    oDataInterfaceExecType_Delete,  // Delete
} oDataInterfaceExecType;

/*** Special Structure for all Queries ***/

// Internal private class
@interface __oDataQuery : NSObject
    @property (atomic, readwrite) oDataInterfaceExecType ExecType;
    @property (atomic, readwrite) NSURL* FullURL;
    @property (atomic, readwrite) NSDictionary* QueryData;
@end

/*** Main Class Prototype ***/

@interface oDataInterface : NSObject < NSURLConnectionDelegate >
{
    /*** Service URL ***/
    
    // Server URL (such as http://services.odata.org/OData )
    NSURL* ServerURL;
    
    // Service path (such as OData.svc)
    NSString* ServiceName;
    
    /*** Promises & Futures ***/
    
    // Queue of all promisies we will fulfill when the end-user tells us to
    // Is an array of "__oDataQuery" objects
    NSMutableArray* FuturesQueue;
    
    /*** Internal State Machine ***/
    
    // Current command type (query, insert, etc...)
    oDataInterfaceExecType ExecType;
    
    // Current table (collection)
    NSString* CollectionString;
    
    // Current query strings
    NSString* QueryString;
}

/*** Creation & Settings ***/

// Constructor
-(id)initInterfaceForServer:(NSURL*)ServerURL;
-(id)initInterfaceForServer:(NSURL*)ServerURL onService:(NSString*)Service;

// Static constructor
+(id)oDataInterfaceForServer:(NSURL*)ServerURL;
+(id)oDataInterfaceForServer:(NSURL*)ServerURL onService:(NSString*)Service;

// Set the service (.svc) we will be executing upon (can be changed at any point)
-(void)SetService:(NSString*)Service;

// Get the full URL formed by the current state of this interface
-(NSURL*)GetFullURL;

/*** Single Executions ***/

// Execute the current string formed (not the one on the promise queue)
// Will block the calling thread's execution
-(NSDictionary*)Execute:(NSError**)ErrorOut;

// Execute with a callback block
// Will not block, since the CompletionHandler function block is executed upon completion
-(void)ExecuteAsync:(void (^)(NSDictionary*, NSError*))CompletionHandler;

/*** Futures & Promises Methods ***/

// Clear any queued promises
-(void)ClearPromises;

// Push the query string into the promise queue
-(void)PushPromise;

// Execute all queued promises and return their results in the
// order that the query strings were formed (blocking call)
-(NSArray*)ExecutePromises:(NSError**)ErrorOut;

// Execute all queued promises and return their results in the
// order that the query strings were formed (non-blocking)
-(void)ExecutePromisesAsync:(void (^)(NSArray*, NSError*))CompletionHandler;

/*** Query Data (GET) ***/

// Set the table (collection) we are working with
-(void)SetCollection:(NSString*)Collection;

// Apply a "$orderBy" filter option
-(void)AddOrderBy:(NSString*)Option;

// Apply a "$top" filter option
-(void)AddTop:(NSString*)Option;

// Apply a "$skip" filter option
-(void)AddSkip:(NSString*)Option;

// Apply a "$expand" option
-(void)AddExpand:(NSString*)Option;

// Apply a "$format" option
-(void)AddFormat:(NSString*)Option;

// Apply a "$select" option
-(void)AddSelect:(NSString*)Option;

// Apply a "$inlinecount" option
-(void)AddInLineCount:(NSString*)Option;

/*** Insert Data (POST) ***/

// Insert data to the server
-(void)AddEntry:(NSDictionary*)NewEntry;

/*** Update Data (PUT) ***/

// Update the given object
-(void)UpdateEntry:(NSDictionary*)ExistingEntry;

/*** Deletion (DELETE) ***/

// Delete a given entry
-(void)DeleteEntry:(NSDictionary*)ExistingEntry;

/*** Special Execution (Functions that return OData info) ***/

// Execute the given string against the set server and service
// This is a blocking call; use the async version for non-block
-(NSDictionary*)ExecuteFuncString:(NSString*)FuncString WithError:(NSError**)ErrorOut;

// Non-blocking async. version of the string execution function
-(void)ExecuteFuncStringAsync:(NSString*)FuncString WithCompletionBlock:(void (^)(NSDictionary*, NSError*))CompletionHandler;

@end
