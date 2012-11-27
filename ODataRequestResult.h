/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
 This source file is developed and maintained by:
 + Jeremy Bridon jbridon@cores2.com
 
 File: oDataRequestResult.h/m
 Desc: Handle all connection events associated with a given
 NSURLConnection attempt.
 
***************************************************************/

#import <Foundation/Foundation.h>

@interface ODataRequestResult : NSObject < NSURLConnectionDelegate, NSURLConnectionDataDelegate >
{
    // The request in question
    NSURLRequest* Request;
    
    // The connection in question we are the delegate of
    NSURLConnection* Connection;
}

// Required initialization
-(id) initWithConnection:(NSURLRequest*)_Request;

// Execute the request synchronously
-(NSData*) GetResult:(NSError**)ErrorOut;

@end
