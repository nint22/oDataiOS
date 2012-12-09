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

// Entity Data Model (EDM) types
typedef enum __oDataParser_EdmType
{
    // Null isn't a type - it's just ObjC's nil
    oDataParser_EdmType_Binary,         // Represented as UTF8 hex '[A-Fa-f0-9][A-Fa-f0-9]*' OR X '[A-Fa-f0-9][A-Fa-f0-9]*'; length always even number
    oDataParser_EdmType_Boolean,        // String of "true" or "false"
    oDataParser_EdmType_Byte,           // Unsigned 8-bit ineger in hex form (same as binary format)
    oDataParser_EdmType_DateTime,       // UTF8 string in form of 'yyyy-mm-ddThh:mm[:ss[.fffffff]]'
    oDataParser_EdmType_Decimal,        // Decimal-literal [0-9]+.[0-9]+M|m
    oDataParser_EdmType_Double,         // IEEE / Mantisa-based notation; [0-9]+ ((.[0-9]+) | [E[+ | -][0-9]+])
    oDataParser_EdmType_Single,         // Same as double, just less range; [0-9]+.[0-9]+f
    oDataParser_EdmType_Guid,           // guid'dddddddd-dddd-dddd-dddd-dddddddddddd' where each d represents [A-Fa-f0-9]
    oDataParser_EdmType_Int16,          // signed 16-bits for [-][0-9]+ data
    oDataParser_EdmType_Int32,          // signed 32-bits for [-][0-9]+ data
    oDataParser_EdmType_Int64,          // signed 64-bits for [-][0-9]+L data
    oDataParser_EdmType_SByte,          // signed 8-bits for [-] [0-9]+ data
    oDataParser_EdmType_String,         // UTF-8 String
    oDataParser_EdmType_Time,           // ISO 8601 Time Format
    oDataParser_EdmType_DateTimeOffset, // ISO 8601 Date Format
    oDataParser_EdmType_Undefined,      // Undefined / unknown
} oDataParser_EdmType;

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
-(NSArray*)GetEntries;

/*** Public-Static Helper Functions ***/

// Return the given data in form of "2010-02-27T21:36:47Z" (oData expected data-format)
+(NSString*)oDataDateFormat:(NSDate*)GivenDate;

@end
