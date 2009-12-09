/*
 *  ORCaen965Controller.h
 *  Orca
 *
 *  Created by Mark Howe on Friday June 19 2009.
 *  Copyright (c) 2009 UNC. All rights reserved.
 *
 */
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
#pragma mark •••Imported Files

#import "ORCaenCardController.h"

// Definition of class.
@interface ORCaen965Controller : ORCaenCardController {
	IBOutlet NSPopUpButton* cardTypePU;
    IBOutlet NSMatrix*		onlineMaskMatrix;
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) cardTypeChanged:(NSNotification*)aNote;
- (void) onlineMaskChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) cardTypePUAction:(id)sender;
- (IBAction) onlineAction:(id)sender;


@end
