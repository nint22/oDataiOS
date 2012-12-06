/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
 This source file is developed and maintained by:
 + Jeremy Bridon jbridon@cores2.com
 
 File: oDataParser.h/m
 Desc: Parse any given string-result from a web service. Note
 that the oData standard has a ton of overhead meta-data, so
 in our case we are going to stic with retaining the properties
 of each entry.
 
***************************************************************/

#import <Foundation/Foundation.h>

// Helpful error macro for returning a new NSError
#ifndef NSErrorCreate
    #define NSErrorCreate(msg) [NSError errorWithDomain:@"world" code:200 userInfo:[NSDictionary dictionaryWithObject:(msg) forKey:NSLocalizedDescriptionKey]]
#endif

// Data parser
@interface oDataParser : NSObject <NSXMLParserDelegate>
{
    // Our internal entry list
    NSMutableArray* Entries;
    
    // The active entry we are filling
    NSMutableDictionary* Entry;
    
    // Current element name & type
    NSString* ElementName;
    NSString* ElementType;
    NSString* ElementString;
}

// Init with XML-string data (i.e. HTTP result)
-(id) initWithData:(NSData*)Data;

// Return the parsed data; on error, return nil, otherwise at minimum an empty dictionary is built
-(NSDictionary*)GetEntities;

@end
