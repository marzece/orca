//
//  ObjectFactory.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 30 2002.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


@interface ObjectFactory : NSButton {
    id object;
}
#pragma mark ���Factory methods
+ (id) makeObject:(NSString*)aClassName;
- (void) makeObject;
@end


//Objects that this factory makes should respond to the following
@interface NSObject (Factory)
- (void) setUpImage;					//required
- (void) makeConnectors;				//optional
- (void) setHighlighted:(BOOL)state;	//optional
@end