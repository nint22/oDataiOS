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
    oDataInterfaceExecType_None,    // Not yet set
    oDataInterfaceExecType_Get,     // Query
    oDataInterfaceExecType_Post,    // Insert
    oDataInterfaceExecType_Put,     // Update
    oDataInterfaceExecType_Delete,  // Delete
} oDataInterfaceExecType;

/*** Class Prototype ***/

@interface oDataInterface : NSObject < NSURLConnectionDelegate >
{
    /*** Service URL ***/
    
    // Server URL (such as http://services.odata.org/OData )
    NSURL* ServerURL;
    
    // Service path (such as OData.svc)
    NSString* ServiceURL;
    
    /*** Internal State Machine ***/
    
    // Current command type (query, insert, etc...)
    oDataInterfaceExecType ExecType;
    
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

/*** Single Executions ***/

// Execute the current string formed (not the one on the promise queue)
// Will block the calling thread's execution
-(NSDictionary*)Execute:(NSError**)ErrorOut;

// Execute with a callback block
// Will not
-(void)ExecuteAsync:(void (^)(NSDictionary*, NSError*))CompletionHandler;

/*** Futures & Promises Methods ***/

// Clear any queued promises
-(void)ClearPromises;

// Push the query string into the promise queue
-(void)PushPromise;

// Execute all queued promises and return their results in the
// order that the query strings were formed
-(NSArray*)ExecutePromises;

/*** Query Data (GET) ***/

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

@end
