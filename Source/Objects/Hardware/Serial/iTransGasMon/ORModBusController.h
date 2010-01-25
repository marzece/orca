//--------------------------------------------------------
// ORModBusController
// Created by Mark  A. Howe on Tues Sept 8, 2009
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2009 University of North Carolina. All rights reserved.
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
#pragma mark ***Imported Files

@class ORPlotter1D;
@class ORFlippedView;

@interface ORModBusController : OrcaObjectController
{
    IBOutlet NSButton*			lockButton;
    IBOutlet NSTextField*		portStateField;
    IBOutlet NSPopUpButton*		portListPopup;
    IBOutlet NSPopUpButton*		pollTimePopup;
    IBOutlet NSButton*			openPortButton;
    IBOutlet NSMatrix*			timeMatrix;
	IBOutlet ORPlotter1D*		plotter0;
    IBOutlet NSButton*			addSensorButton;
	IBOutlet ORFlippedView*		sensorsView;
	IBOutlet NSButton*			shipValuesCB;
	NSMutableArray*				sensorControllers;
}

#pragma mark ***Initialization
- (id)	 init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) updateTimePlot:(NSNotification*)aNotification;
- (void) portNameChanged:(NSNotification*)aNote;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) sensorsChanged:(NSNotification*)aNote;
- (void) sensorAdded:(NSNotification*)aNote;
- (void) sensorRemoved:(NSNotification*)aNote;
- (void) tileSensors;
- (void) shipValuesChanged:(NSNotification*)aNote;

#pragma mark ***Actions
- (IBAction) addSensorAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) readNowAction:(id)sender;
- (IBAction) shipValuesAction:(id)sender;

@end

