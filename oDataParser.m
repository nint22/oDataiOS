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
        // Default to no error at first
        ErrorOut = nil;
        
        // Default parsing results
        Entries = [[NSMutableArray alloc] init];
        Entry = nil;
        
        // Completely skip if there is no data; it's all valid!
        if([Data length] > 0)
        {
            // Interpret the data as a string (for the sake of testing for errors)
            NSString* DataString = [[NSString alloc] initWithData:Data encoding:NSUTF8StringEncoding];
            
            // Error checking for any exceptions
            if([DataString rangeOfString:@"<type>Microsoft.Data.OData.ODataException</type>"].location != NSNotFound)
            {
                NSString* ErrorMessage = [NSString stringWithFormat:@"Exception recieved from server: %@", DataString];
                ErrorOut = NSErrorCreate(ErrorMessage);
            }
            
            // Continue parsing normally
            else
            {
                // Start XML parser
                NSXMLParser* Parser = [[NSXMLParser alloc] initWithData:Data];
                [Parser setDelegate:self];
                bool Success = [Parser parse];
                
                // On failure, return nil
                if(Success == false)
                    ErrorOut = NSErrorCreate([[Parser parserError] localizedDescription]);
            }
        }
    }
    return self;
}

-(NSError*)GetError
{
    return ErrorOut;
}

-(NSArray*)GetEntries
{
    return Entries;
}

+(NSString*)oDataDateFormat:(NSDate*)GivenDate
{
    NSDateFormatter* DateFormatter = [[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SS'Z'"];
    return [DateFormatter stringFromDate:GivenDate];
}

/*** NSXMLParserDelegate Implementation ***/

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    // All we care about is the start of a properties list
    if([elementName compare:@"m:properties" options:NSCaseInsensitiveSearch] == 0)
    {
        // Start new property...
        Entry = [[NSMutableDictionary alloc] init];
    }
    
    // For any elements within an entry..
    else if(Entry != nil && [elementName hasPrefix:@"d:"])
    {
        // Format is "d:OrderDate m:type="Edm.DateTime"" where m:type is optional
        ElementName = ElementType = ElementString = nil;
        
        // If it's the name, save
        if([elementName hasPrefix:@"d:"])
            ElementName = [elementName substringFromIndex:2];
        
        // Do we have a type?
        ElementType = [attributeDict objectForKey:@"m:type"];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Push entry into array
    if([elementName compare:@"m:properties" options:NSCaseInsensitiveSearch] == 0)
    {
        // Push
        [Entries addObject:Entry];
        Entry = nil;
    }
    
    // For any elements we have finished parsing...
    else if(Entry != nil && [elementName hasPrefix:@"d:"])
    {
        // In some cases we will either have nul data or just an empty string;
        // These are considered seperate cases, so we will actually not include null key-value pairs,
        // but will include empty strings
        
        // Only continue if the element string is existant
        if(ElementString != nil)
        {
            // Is there a type? (Default to string)
            oDataParser_EdmType Type = oDataParser_EdmType_String;
            if(ElementType != nil)
                Type = [oDataParser GetEDMType:ElementType];
            
            // Parse as needed
            id ElementObject = ElementString;
            
            // Switch and format as needed
            switch(Type)
            {
                // Trival true/false check
                case oDataParser_EdmType_Boolean:
                {
                    ElementObject = [NSNumber numberWithBool:[ElementString caseInsensitiveCompare:@"true"] == NSOrderedSame];
                    break;
                }
                
                // Attempt to parse
                case oDataParser_EdmType_DateTime:
                {
                    // First, we have to remove the wrapper "datetime'DATE'"
                    NSString* CleanDate = [[ElementString stringByReplacingOccurrencesOfString:@"datetime" withString:@""] stringByReplacingOccurrencesOfString:@"'" withString:@""];
                    ElementObject = [oDataParser GetEDMDateTime:CleanDate];
                    break;
                }
                
                // Todo: test these more extensively
                case oDataParser_EdmType_Time:
                case oDataParser_EdmType_DateTimeOffset:
                {
                    NSDateFormatter *rfc3339TimestampFormatterWithTimeZone = [[NSDateFormatter alloc] init];
                    [rfc3339TimestampFormatterWithTimeZone setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
                    [rfc3339TimestampFormatterWithTimeZone setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                    
                    NSDate *theDate = nil;
                    NSError *error = nil;
                    if (![rfc3339TimestampFormatterWithTimeZone getObjectValue:&theDate forString:ElementString range:nil error:&error]) {
                        NSLog(@"Date '%@' could not be parsed: %@", ElementString, error);
                    }
                    
                    NSDateFormatter* DateParser = [[NSDateFormatter alloc] init];
                    [DateParser setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"]; // ISO 8601 support
                    ElementObject = [DateParser dateFromString:ElementString];
                    break;
                }
                
                // Trivial float/double/sci-notation syntax
                case oDataParser_EdmType_Double:
                case oDataParser_EdmType_Single:
                case oDataParser_EdmType_Decimal:
                {
                    // Note: will this fail with a 1.0f? (the c-style float declaration)
                    NSScanner* Scanner = [[NSScanner alloc] initWithString:ElementString];
                    double ScannedNumber;
                    [Scanner scanDouble:&ScannedNumber];
                    ElementObject = [NSNumber numberWithDouble:ScannedNumber];
                    break;
                }
                
                // Hex string
                case oDataParser_EdmType_Binary:
                case oDataParser_EdmType_Byte:
                {
                    // Critical issue: the oData docs tell us that edm.byte is a hex value,
                    // yet when we query the server, we are getting a decimal value
                    // WORK-AROUND: Just parse as integer (todo: fix either server or whatever)
                    NSScanner* Scanner = [[NSScanner alloc] initWithString:ElementString];
                    int ScannedNumber; // Guaranteed to be 64-bit length
                    [Scanner scanInt:&ScannedNumber];
                    ElementObject = [NSNumber numberWithInt:ScannedNumber];
                    break;
                }
                
                // Signed variable-width integer
                case oDataParser_EdmType_SByte:
                case oDataParser_EdmType_Int16:
                case oDataParser_EdmType_Int32:
                case oDataParser_EdmType_Int64:
                {
                    NSScanner* Scanner = [[NSScanner alloc] initWithString:ElementString];
                    long long ScannedNumber; // Guaranteed to be 64-bit length
                    [Scanner scanLongLong:&ScannedNumber];
                    ElementObject = [NSNumber numberWithLongLong:ScannedNumber];
                    break;
                }
                
                // Pull out and lower-case the format
                case oDataParser_EdmType_Guid:
                {
                    ElementObject = [[ElementString stringByReplacingOccurrencesOfString:@"guid'" withString:@""] stringByReplacingOccurrencesOfString:@"'" withString:@""];
                    break;
                }
                
                // Fall-through cases
                case oDataParser_EdmType_String:
                case oDataParser_EdmType_Undefined:
                default: break;
            }
            
            // Error check
            if(ElementObject == nil)
            {
                NSString* ErrorMessage = [NSString stringWithFormat:@"Unable to parse element: [%@] \"%@\"", ElementType, ElementString];
                ErrorOut = NSErrorCreate(ErrorMessage);
            }
            
            // Save into dict. structure
            else
            {
                [Entry setObject:ElementObject forKey:ElementName];
            }
        }
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

/*** Internal Helper Functions ***/

// Return the type of the given EDM-type string
+(oDataParser_EdmType)GetEDMType:(NSString*)EDMStringType
{
    // Ignore if not long enough
    if([EDMStringType length] <= 4)
        return oDataParser_EdmType_Undefined;
    
    // Remove "Edm." for speedup
    // Note: I could speed this up by doing a hash-dictionary
    NSString* Type = [EDMStringType substringFromIndex:4];
    
    // Simple if/else-if checking
    if([Type caseInsensitiveCompare:@"Binary"] == NSOrderedSame)
        return oDataParser_EdmType_Binary;
    else if([Type caseInsensitiveCompare:@"Boolean"] == NSOrderedSame)
        return oDataParser_EdmType_Boolean;
    else if([Type caseInsensitiveCompare:@"Byte"] == NSOrderedSame)
        return oDataParser_EdmType_Byte;
    else if([Type caseInsensitiveCompare:@"DateTime"] == NSOrderedSame)
        return oDataParser_EdmType_DateTime;
    else if([Type caseInsensitiveCompare:@"Decimal"] == NSOrderedSame)
        return oDataParser_EdmType_Decimal;
    else if([Type caseInsensitiveCompare:@"Double"] == NSOrderedSame)
        return oDataParser_EdmType_Double;
    else if([Type caseInsensitiveCompare:@"Single"] == NSOrderedSame)
        return oDataParser_EdmType_Single;
    else if([Type caseInsensitiveCompare:@"Guid"] == NSOrderedSame)
        return oDataParser_EdmType_Guid;
    else if([Type caseInsensitiveCompare:@"Int16"] == NSOrderedSame)
        return oDataParser_EdmType_Int16;
    else if([Type caseInsensitiveCompare:@"Int32"] == NSOrderedSame)
        return oDataParser_EdmType_Int32;
    else if([Type caseInsensitiveCompare:@"Int64"] == NSOrderedSame)
        return oDataParser_EdmType_Int64;
    else if([Type caseInsensitiveCompare:@"SByte"] == NSOrderedSame)
        return oDataParser_EdmType_SByte;
    else if([Type caseInsensitiveCompare:@"String"] == NSOrderedSame)
        return oDataParser_EdmType_String;
    else if([Type caseInsensitiveCompare:@"Time"] == NSOrderedSame)
        return oDataParser_EdmType_Time;
    else if([Type caseInsensitiveCompare:@"DateTimeOffset"] == NSOrderedSame)
        return oDataParser_EdmType_DateTimeOffset;
    
    // Else, all has failed
    else
        return oDataParser_EdmType_Undefined;
}

// Given a date string, attempt to return the mapped NSDate object
// This function is for the "Edm.DateTime" element only; returns nil on failure
+(NSDate*)GetEDMDateTime:(NSString*)DateString
{
    // The internal static three trusted formals
    static const int DateFormatsCount = 3;
    static const char DateFormatsCString[DateFormatsCount][32] = {"yyyy-MM-dd'T'HH:mm:ss.SS'Z'", "yyyy-MM-dd'T'HH:mm'Z'", "yyyy-MM-dd'T'HH:mm:ss'Z'"};
    
    // Date we parse
    NSDate* ParsedDate = nil;
    
    // Try three different versions
    for(int i = 0; i < DateFormatsCount && ParsedDate == nil; i++)
    {
        NSDateFormatter* DateFormatter = [[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:[NSString stringWithCString:DateFormatsCString[i] encoding:NSASCIIStringEncoding]];
        ParsedDate = [DateFormatter dateFromString:DateString];
    }
    
    // Done!
    return ParsedDate;
}

@end
