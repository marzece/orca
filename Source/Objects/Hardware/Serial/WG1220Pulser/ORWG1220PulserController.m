//--------------------------------------------------------
// ORWG1220PulserController
// Created by Mark  A. Howe on Fri Jul 22 2005 / Julius Hartmann, KIT, Mai 2017
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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
//for the use of this softwarePulser.
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORWG1220PulserController.h"
#import "ORWG1220PulserModel.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import <Carbon/Carbon.h>
#import "ORTimeRate.h"

@interface ORWG1220PulserController (private)
- (void) populatePortListPopup;
@end

@implementation ORWG1220PulserController

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"WG1220Pulser"];
	return self;
}

- (void) awakeFromNib
{
    [self populatePortListPopup];
    [super awakeFromNib];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORWG1220PulserLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORWG1220PulserModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(signalFormChanged:)
                         name : ORWG1220PulserModelSignalFormChanged
						object: model];

		[notifyCenter addObserver : self
                         selector : @selector(signalFormChangedArb:)
                             name : ORWG1220PulserModelSignalFormArbitrary
                            object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(amplitudeChanged:)
                         name : ORWG1220PulserModelAmplitudeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dutyCycleChanged:)
                         name : ORWG1220PulserModelDutyCycleChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(frequencyChanged:)
                         name : ORWG1220PulserModelFrequencyChanged
						object: model];

		[notifyCenter addObserver : self
				             selector : @selector(verboseChanged:)
				                 name : ORWG1220PulserModelVerboseChanged
					  object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self signalFormChanged:nil];
	[self amplitudeChanged:nil];
	[self dutyCycleChanged:nil];
	[self frequencyChanged:nil];
	[self verboseChanged:nil];
}

- (void) verboseChanged:(NSNotification*)aNote
{
	[verboseCB setIntValue:[model verbose]];
}

- (void) frequencyChanged:(NSNotification*)aNote
{
    [self updateStepper:frequencyStepper setting:[model frequency]];
	[frequencyField setFloatValue: [model frequency]];
}

- (void) dutyCycleChanged:(NSNotification*)aNote
{
    [self updateStepper:dutyCycleStepper setting:[model dutyCycle]];
	[dutyCycleField setIntValue: [model dutyCycle]];
}

- (void) amplitudeChanged:(NSNotification*)aNote
{
    [self updateStepper:amplitudeStepper setting:[model amplitude]];
	[amplitudeField setFloatValue: [model amplitude]];
}

- (void) signalFormChanged:(NSNotification*)aNote
{
	[signalFormPU selectItemAtIndex: [model signalForm]];
	[loadWaveButton setEnabled: NO];
}

- (void) signalFormChangedArb:(NSNotification*)aNote
{
 [signalFormPU selectItemAtIndex: [model signalForm]];
 [loadWaveButton setEnabled: YES];

}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORWG1220PulserLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    //BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORWG1220PulserLock];
    BOOL locked = [gSecurity isLocked:ORWG1220PulserLock];

    [lockButton setState: locked];

    [portListPopup setEnabled:	!locked];
    [openPortButton setEnabled:	!locked];
	[frequencyField setEnabled:!lockedOrRunningMaintenance];
	[dutyCycleField setEnabled:!lockedOrRunningMaintenance];
	[amplitudeField setEnabled:!lockedOrRunningMaintenance];
	[frequencyStepper setEnabled:!lockedOrRunningMaintenance];
	[dutyCycleStepper setEnabled:!lockedOrRunningMaintenance];
	[amplitudeStepper setEnabled:!lockedOrRunningMaintenance];
	[signalFormPU setEnabled:!lockedOrRunningMaintenance];
	[loadAmpButton setEnabled:!lockedOrRunningMaintenance];

}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];

            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];

	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;

    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}
    [self portStateChanged:nil];
}

#pragma mark ***Actions

- (IBAction) verboseAction:(id)sender;
{
	[model setVerbose:[sender intValue]];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORWG1220PulserLock to:[sender intValue] forWindow:[self window]];
}

- (void) frequencyAction:(id)sender
{
	[model setFrequency:[sender floatValue]];
}

- (void) dutyCycleAction:(id)sender
{
	[model setDutyCycle:[sender intValue]];
}

- (void) amplitudeAction:(id)sender
{
	[model setAmplitude:[sender floatValue]];
}

- (void) signalFormAction:(id)sender
{
	[model setSignalForm:[sender indexOfSelectedItem]];
}


- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) loadAmpAction:(id)sender
{
	[model commitAmplitude];
}

- (IBAction) signalFileAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt:@"Waveform File"];

    NSString* startingDir;
    NSString* defaultFile;

	NSString* fullPath = [model waveformFile];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"Waveform.ktf";
    }

    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel setNameFieldLabel:defaultFile];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
				if(result == NSModalResponseOK){
				[model setWaveformFile:[[openPanel URL] path]];
				NSLog(@"File path: %@ \n", [model waveformFile]);
				[self loadWaveAction];
			}
    }];

}

- (void) loadWaveAction
{
	if([model verbose]){
		NSLog(@"loadWaveAction.. \n");
	}
	[model loadValuesFromFile];
	[model commitWaveform];
}


@end

@implementation ORWG1220PulserController (private)

- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];

	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}
}
@end
