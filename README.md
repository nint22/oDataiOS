oDataiOS
========

A clean and simple [oData library](http://www.odata.org/) for the iOS platform. Version 1.0

**Please note that if you would like to use this library for comercial applications (i.e. a non-free & public app),
contact the developer (Jeremy Bridon) through his website, [Core S2](http://www.cores2.com/).**

About oData
-----------
oData is a simple, yet powerful, HTTP protocol for accessing data through web-services. oData, or Open Data Protocol,
comes from Microsoft, and is integrated in a variety of its products and solutions. [Learn more about oData here](http://www.odata.org/).

Library Design
--------------
This library is designed to be clean, minimal, and asynchronous-friendly. It avoids any sort of library-preparation
or packaged lib; it is simply 6 source code files that can be dragged-and-dropped into your project.

This library is designed to be used through classic Object Oriented Programming. The core class you want to
instantiate is the `oDataInterface`, which wraps a given service. With an instance of this class, you can set
the collection you want to manipulate, then either query the service, insert new data, update data, or delete it.
Note that this class internally acts as a state-machine: every member-function simply changes an internal state, and the work
is only executed" through the explicit `-(NSDictionary*)Execute:(NSError**)ErrorOut` function.

This class can be constructed in two way: first through the standard alloc/init, and the other through a static function that implements the alloc/init internally.
Construction requires the base URL (i.e. `http://services.odata.org/OData/`), the service directory (i.e. `OData.svc`), and associated database name (i.e. `ODataDemo`).

As an example, let's construct both of these interface types:

    oDataInterface* InterfaceA = [[oDataInterface alloc] initInterfaceForServer:[NSURL URLWithString:@"http://services.odata.org/OData/"] onService:@"OData.svc" andDatabase:@"ODataDemo"];
    oDataInterface* InterfaceB = [oDataInterface oDataInterfaceForServer:[NSURL URLWithString:@"http://services.odata.org/OData/"] onService:@"OData.svc" andDatabase:@"ODataDemo"];

Once constructed, you may set the collections you will be working on through `-(void)SetCollection:(NSString*)Collection` function, add query options through
the set of query functions (such as `-(void)AddOrderBy:(NSString*)Option`). If inserting a new entry to your service, simply create your object through an
`NSDictionary` (or derivative) instantiation and insert only the following supported types:

* NSString
* NSNumber (byte, char, short, int, float, double, long long, and all unsigned-forms of these types)
* DateTime
* **More to come...**

Insertion is executed through the `-(void)AddEntry:(NSString*)Entry withData:(NSDictionary*)NewEntry` function,
while updating is similar, but requires the object's key identifier: `-(void)UpdateEntry:(NSString*)Entry withID:(NSString*)EntryKey withData:(NSDictionary*)ExistingEntry`.
Deletion is not yet implemented.

Explicit execution of your current commands is still required to actually run your oData commands: simply call the blocking `-(NSDictionary*)Execute:(NSError**)ErrorOut` function
or the non-blocking callback method `-(void)ExecuteAsync:(void (^)(NSArray*, NSError*))CompletionHandler`. Note that this is an Objective-C anonymous block function, and **not** a C-style callback function.

Asynchronous execution is all based on pushing the current command state onto a queue, which can then be executed when you would like using the futures / promise functions.

Source-Code Comments
--------------------

The library has been heavily commented for easier use and manipulation by end-developers. If you need to change or modify any feature, all major concepts
are well documented in-line, with several references to the oData standards document.

Code Testing
------------

I wrote a very small and trivial application for the iPhone (iOS 6+, XCode 4.4+) to run through some simple tests. Load up the project file and look for the testing
code within the only view-controller, named `ConsoleViewController.m`.

License
-------
*TL;DR: Do whatever you want with this code, as long as 1. If you redistribute, please include my name. 2. You may not redistribute for any comercial benefits (i.e. inclusion with a paid product, asking for money, etc.)*

Simplified BSD (MODIFIED FOR NON-COMMERCIAL USE ONLY)

Copyright (c) 2012, Jeremy Bridon (Core S2 Software Solutions)

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Any redistribution, use, or modification is done solely for personal benefit and not for any commercial purpose or for monetary gain
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Change Log
==========

Version 1.0; Dec 11th 2012

+ Initial stable public build; still subject to heavy changes
+ Changed constructors to support the required database option
+ Known issue with deletion not implemented; differed to next version
+ Demo code now correctly implements GUI sync.
+ Set license to non-comercial
