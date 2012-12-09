/***************************************************************
 
 oData iOS - A clean and simple oData interface for iOS
 Copyright (c) 2012 'Core S2'. All rights reserved.
 
 This source file is developed and maintained by:
 + Jeremy Bridon jbridon@cores2.com
 
 File: XMLCleaner.c
 Desc: A simple mini-application that correctly indents XML / ATOM
 text from standard-in. This code is written in the C99 dialect,
 and is simply a tool to help reading XML data. To build, either
 run it through GCC/LLVM/whatever-you-use or just use the makefile.
 Note that some simple cases (like closing brackets being "/ >" or
 where there is many white-spaces or when there is a windows-end-of-line
 format (which is "\r\n"), then this code will not behave correctly.
 
***************************************************************/

#include <stdio.h>
#include <string.h>

#define bool char
#define true (1);
#define false (0);

int main()
{
	// Echo standard control stuff
	printf("Press Ctrl+C to quit");
	
	// While we have characters on stdin
	char c = '\0';
	int TabCount = 0;
    
    // Only close at "/>" or after a ">" once a "</" is detected
    bool NeedsNewline = false;
    
    // Keep reading until input is done
	while((c = getc(stdin)) != EOF)
	{
        // Look ahead since there are many paired-characters
        char nextc = getc(stdin);
        
        // Closing the tag, regular method
		if(c == '<')
		{
			// Confirm this is a closing slash
			if(nextc == '/')
            {
				TabCount--;
                NeedsNewline = true;
            }
            
            // Else, we are opening
            else
                TabCount++;
		}
        
        // Closing the tag, in-line
        else if(c == '/' && nextc == '>')
        {
            TabCount--;
            NeedsNewline = true;
        }
        
        // Put back the char in case we need to parse a new tag-group
        ungetc(nextc, stdin);
        
		// Print off the character no matter what
		putc(c, stdout);
        
        // Print off new line if required
        if(c == '>' && NeedsNewline)
        {
            // Put newline
            if(nextc != '\n')
                putc('\n', stdout);
            
            // Place tabs
            for(int i = 0; i < TabCount; i++)
                putc('\t', stdout);
            
            // Done placing the new line
            NeedsNewline = false;
        }
	}
	
	// All done!
	return 0;
}


