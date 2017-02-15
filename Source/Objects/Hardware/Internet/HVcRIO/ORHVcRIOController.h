//--------------------------------------------------------
// ORHVcRIOController
// Created by Mark  A. Howe on Mon Jun 16, 2014
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2014, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
@class ORCompositeTimeLineView;
@class ORValueBarGroupView;

@interface ORHVcRIOController : OrcaObjectController
{
    
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*   channelSelectionField;
	IBOutlet NSTextField*   preAmpSelectionField;
	IBOutlet NSTextField*   setGainsResultTextField;
	IBOutlet NSTextField*   workingOnGainTextField;
    IBOutlet NSMatrix*		gainDisplayTypeMatrix;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;

	IBOutlet NSTabView*		tabView;
	IBOutlet NSTextField*   lastGainReadField;
	IBOutlet NSTextField*	cmdQueCountField;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      readAdcsButton;
    IBOutlet NSButton*      readAllAdcsButton;
    IBOutlet NSMatrix*      channelMatrix;
    IBOutlet NSMatrix*      adcNameMatrix;
    IBOutlet NSMatrix*      adcMatrix;
    IBOutlet NSMatrix*      timeMatrix;
    IBOutlet NSMatrix*      lcmEnabledMatrix;
    IBOutlet NSBox*         adc0Line0;
    IBOutlet NSBox*         adc0Line1;
    IBOutlet NSBox*         adc0Line2;
    IBOutlet NSTextField*	lcmRunVetoWarning;

    IBOutlet NSButton*      readAllGainsButton;
    IBOutlet NSButton*      writeAllGainsButton;

	IBOutlet NSPopUpButton* pollingButton;
	IBOutlet NSTextField*	logFileTextField;
	IBOutlet NSButton*		logToFileButton;
	
	IBOutlet ORCompositeTimeLineView*   plotter0;
	IBOutlet ORCompositeTimeLineView*   plotter1;
	
	IBOutlet NSButton*		readGainFileButton;
	IBOutlet NSButton*		writeGainFileButton;

	IBOutlet NSTableView*	gainTableView;
	IBOutlet NSTableView*	gainReadBackTableView;
    IBOutlet NSTableView*   processLimitsTableView;

    IBOutlet ORValueBarGroupView*  queueValueBar;
    IBOutlet NSProgressIndicator*  progress;
    IBOutlet NSTextField*          progressField;
    
    NSSize					normalSize;
    NSSize					setUpSize;
    NSSize					gainSize;
    NSSize					processLimitsSize;
    NSSize					trendSize;
    NSView*					blankView;
    IBOutlet NSView*        totalView;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management
- (void) channelSelectionChanged:(NSNotification*)aNote;
- (void) preAmpSelectionChanged:(NSNotification*)aNote;
- (void) setGainsResultChanged:(NSNotification*)aNote;
- (void) workingOnGainChanged:(NSNotification*)aNote;
- (void) processLimitsChanged:(NSNotification*)aNote;
- (void) gainDisplayTypeChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNotification;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) pollingStateChanged:(NSNotification*)aNote;
- (void) gainsChanged:(NSNotification*)aNote;
- (void) gainsReadBackChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) adcChanged:(NSNotification*)aNote;
- (void) logToFileChanged:(NSNotification*)aNote;
- (void) loadAdcTimeValuesForIndex:(int)index;
- (void) logFileChanged:(NSNotification*)aNote;
- (void) queCountChanged:(NSNotification*)aNote;
- (void) lcmChanged:(NSNotification*)aNote;
- (void) loadLcmTimeValues;
- (void) vetoConditionChanged:(NSNotification*)aNote;

- (void) lcmEnabledChanged:(NSNotification*)aNote;

- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) isConnectedChanged:(NSNotification*)aNote;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions
- (IBAction) readAdcsAction:(id)sender;
- (IBAction) readAllAdcsAction:(id)sender;
- (IBAction) lcmEnabledAction:(id)sender;
- (IBAction) gainDisplayTypeAction:(id)sender;
- (IBAction) sendPreAmpAndChannelAction:(id)sender;
- (IBAction) channelSelectionAction:(id)sender;
- (IBAction) preAmpSelectionAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) getGainsAction:(id)sender;
- (IBAction) setGainsAction:(id)sender;

- (IBAction) selectFileAction:(id)sender;
- (IBAction) setPollingAction:(id)sender;
- (IBAction) logToFileAction:(id)sender;
- (IBAction) readGainFileAction:(id)sender;
- (IBAction) saveGainFileAction:(id)sender;

- (IBAction) ipAddressFieldAction:(id)sender;
- (IBAction) connectAction: (id) aSender;
- (IBAction) flushQueueAction: (id) aSender;

- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
@end


