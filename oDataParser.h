/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
 This source file is developed and maintained by:
 + Jeremy Bridon jbridon@cores2.com
 
 File: oDataParser.h/m
 Desc: Parse any given string-result from a web service
 
***************************************************************/

#import <Foundation/Foundation.h>

// Helpful error macro for returning a new NSError
#ifndef NSErrorCreate
    #define NSErrorCreate(msg) [NSError errorWithDomain:@"world" code:200 userInfo:[NSDictionary dictionaryWithObject:(msg) forKey:NSLocalizedDescriptionKey]];
#endif


@interface oDataParser : NSObject <NSXMLParserDelegate>

// Init with XML-string data (i.e. HTTP result)
-(id) initWithData:(NSData*)Data;

@end
