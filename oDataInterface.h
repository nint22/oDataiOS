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

    // General service info
    @property (atomic, readwrite, retain) NSURL* ServerURL;                 // Base URL (such as http://www.9104data.com/Services/
    @property (atomic, readwrite, retain) NSString* ServiceName;            // Service name (such as CarData.scv)
    @property (atomic, readwrite, retain) NSString* DatabaseName;           // The database name associated with the service (such as RaceMotionData_01)
    
    // Current state / feature to execute
    @property (atomic, readwrite) oDataInterfaceExecType ExecType;          // The type of command we want to execute (query, insert, update, delete)
    @property (atomic, readwrite, retain) NSString* CollectionName;         // The collection name we want to *query* through (such as Cars)
    @property (atomic, readwrite, retain) NSString* QueryString;            // The query string
    @property (atomic, readwrite, retain) NSString* QueryEntryName;         // The entry name type (such as Car in the collection named Cars)
    @property (atomic, readwrite, retain) NSDictionary* QueryEntry;         // The data-structure we will be inserting, updating, or deleting
    @property (atomic, readwrite, retain) NSString* EntryKeyID;             // The data-structures key; only used during entry-update
    
@end

/*** Main Class Prototype ***/

@interface oDataInterface : NSObject < NSURLConnectionDelegate >
{
    // Main / active state
    __oDataQuery* ActiveQuery;
    
    // Queue of all promisies we will fulfill when the end-user tells us to
    // Is an array of "__oDataQuery" objects
    NSMutableArray* FuturesQueue;
}

/*** Creation & Settings ***/

// Constructor
-(id)initInterfaceForServer:(NSURL*)ServerURL onService:(NSString*)Service andDatabase:(NSString*)_Database;

// Static constructor
+(id)oDataInterfaceForServer:(NSURL*)ServerURL onService:(NSString*)Service andDatabase:(NSString*)_Database;

// Clear / reset the internal state (i.e. any query we currently have setup)
-(void)Clear;

/*** Single Executions ***/

// Execute the current string formed (not the one on the promise queue)
// Will block the calling thread's execution
-(NSArray*)Execute:(NSError**)ErrorOut;

// Execute with a callback block
// Will not block, since the CompletionHandler function block is executed upon completion
-(void)ExecuteAsync:(void (^)(NSArray*, NSError*))CompletionHandler;

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

// Apply a "$filter" filter option
-(void)AddFilter:(NSString*)Option;

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
-(void)AddEntry:(NSString*)Entry withData:(NSDictionary*)NewEntry;

/*** Update Data (PUT) ***/

// Update the given object
// Note that the key must be appropriatly typed by the user (i.e. if the key is a GUID, then the string must be in the form of "guid'000-00..00-000'")
-(void)UpdateEntry:(NSString*)Entry withID:(NSString*)EntryKey withData:(NSDictionary*)ExistingEntry;

/*** Deletion (DELETE) ***/

// Delete a given entry
-(void)DeleteEntry:(NSString*)Entry withData:(NSDictionary*)ExistingEntry;

/*** Special Execution (Functions that return OData info) ***/

// Execute the given string against the set server and service
// This is a blocking call; use the async version for non-block
-(NSArray*)ExecuteFuncString:(NSString*)FuncString WithError:(NSError**)ErrorOut;

// Non-blocking async. version of the string execution function
-(void)ExecuteFuncStringAsync:(NSString*)FuncString WithCompletionBlock:(void (^)(NSArray*, NSError*))CompletionHandler;

@end
