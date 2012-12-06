/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
***************************************************************/

#import "oDataParser.h"

@implementation oDataParser

-(id) initWithData:(NSData*)Data
{
    if((self = [super init]) != nil)
    {
        // Print in string format for debugging
        //NSLog(@"%@", [[NSString alloc] initWithData:Data encoding:NSUTF8StringEncoding]);
        
        // Default parsing results
        Entries = [[NSMutableArray alloc] init];
        Entry = nil;
        
        // Start XML parser
        NSXMLParser* Parser = [[NSXMLParser alloc] initWithData:Data];
        [Parser setDelegate:self];
        bool Success = [Parser parse];
        
        // On failure, return nil
        if(Success == false)
            return nil;
    }
    return self;
}

-(NSDictionary*)GetEntities
{
    return nil;
}

/*** NSXMLParserDelegate Implementation ***/

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    // All we care about is the start of a properties list
    if([elementName compare:@"m:properties" options:NSCaseInsensitiveSearch])
    {
        // Start new property...
        Entry = [[NSMutableDictionary alloc] init];
    }
    
    // For any elements within an entry..
    else if(Entry != nil && [elementName hasPrefix:@"d:"])
    {
        // Format is "d:OrderDate m:type="Edm.DateTime"" where m:type is optional
        NSArray* Split = [elementName componentsSeparatedByString:@" "];
        ElementName = ElementType = ElementString = nil;
        
        // For each..
        for(NSString* Element in Split)
        {
            // If it's the name, save
            if([Element hasPrefix:@"d:"])
                ElementName = [Element substringFromIndex:2];
            
            // Else, it's the type, save
            else if([Element hasPrefix:@"m:"])
            {
                // Pull out contents of quote
                // Note: index will always be 1 since the type will be split by quote-chars
                ElementType = [[Element componentsSeparatedByString:@"\""] objectAtIndex:1];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Push entry into array
    if([elementName compare:@"m:properties" options:NSCaseInsensitiveSearch])
    {
        // Push
        [Entries addObject:Entry];
        Entry = nil;
    }
    
    // For any elements we have finished parsing...
    else if(Entry != nil && [elementName hasPrefix:@"d:"])
    {
        // TODO: Type conversion here!
        [Entry setObject:ElementName forKey:ElementString];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // If we ever hit strings and we're filling out an entry..
    if(Entry != nil)
        ElementString = string;
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    // Todo...
}

@end
