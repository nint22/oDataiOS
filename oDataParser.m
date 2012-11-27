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

@end
