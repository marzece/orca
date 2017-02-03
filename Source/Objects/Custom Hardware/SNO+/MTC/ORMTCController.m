//
//  ORMTCController.m
//  Orca
//
//Created by Mark Howe on Fri, May 2, 2008
//Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#import "ORMTCController.h"
#import "ORMTCModel.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORMTC_Constants.h"
#import "ORSelectorSequence.h"

#pragma mark •••PrivateInterface
@interface ORMTCController (private)

- (void) setupNHitFormats;
- (void) setupESumFormats;
- (void) storeUserNHitValue:(float)value index:(int) thresholdIndex;
- (void) calcNHitValueForRow:(int) aRow;
- (void) storeUserESumValue:(float)userValue index:(int) thresholdIndex;
- (void) calcESumValueForRow:(int) aRow;

@end

@implementation ORMTCController

-(id)init
{
    self = [super initWithWindowNibName:@"MTC"];
    return self;
}

//This pulls any names from the Nib
- (NSMutableDictionary*) getMatriciesFromNib;
{
    NSMutableDictionary* returnDictionary= [NSMutableDictionary dictionaryWithCapacity:100];
    [returnDictionary setObject:globalTriggerMaskMatrix forKey:@"globalTriggerMaskMatrix"];
    [returnDictionary setObject:globalTriggerCrateMaskMatrix forKey:@"globalTriggerCrateMaskMatrix"];
    [returnDictionary setObject:pedCrateMaskMatrix forKey:@"pedCrateMaskMatrix"];
    return returnDictionary;
}

- (void) awakeFromNib
{
    basicOpsSize    = NSMakeSize(400,350);
    standardOpsSize	= NSMakeSize(560,530);
    settingsSize	= NSMakeSize(810,600);
    triggerSize		= NSMakeSize(800,640);
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[initProgressField setHidden:YES];
	
    [super awakeFromNib];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;

    [tabView selectTabViewItemAtIndex: index];
    [self populatePullDown];
    [self updateWindow];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORMTCBasicLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(selectedRegisterChanged:)
                         name : ORMTCModelSelectedRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(memoryOffsetChanged:)
                         name : ORMTCModelMemoryOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORMTCModelWriteValueChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatCountChanged:)
                         name : ORMTCModelRepeatCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatDelayChanged:)
                         name : ORMTCModelRepeatDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useMemoryChanged:)
                         name : ORMTCModelUseMemoryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(autoIncrementChanged:)
                         name : ORMTCModelAutoIncrementChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(basicOpsRunningChanged:)
                         name : ORMTCModelBasicOpsRunningChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCModelMtcDataBaseChanged
						object: model];

	[notifyCenter addObserver : self
			 selector : @selector(isPulserFixedRateChanged:)
			     name : ORMTCModelIsPulserFixedRateChanged
			    object: model];

	[notifyCenter addObserver : self
			 selector : @selector(fixedPulserRateCountChanged:)
			     name : ORMTCModelFixedPulserRateCountChanged
			    object: model];

	[notifyCenter addObserver : self
			 selector : @selector(fixedPulserRateDelayChanged:)
			     name : ORMTCModelFixedPulserRateDelayChanged
			    object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sequenceRunning:)
                         name : ORSequenceRunning
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector(sequenceStopped:)
                         name : ORSequenceStopped
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sequenceProgress:)
                         name : ORSequenceProgress
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerMTCAMaskChanged:)
                         name : ORMTCModelMTCAMaskChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(isPedestalEnabledInCSRChanged:)
                         name : ORMTCModelIsPedestalEnabledInCSR
                       object : nil];
}

- (void) updateWindow
{
    [super updateWindow];
    [self regBaseAddressChanged:nil];
    [self memBaseAddressChanged:nil];
    [self slotChanged:nil];
    [self basicLockChanged:nil];
	[self selectedRegisterChanged:nil];
	[self memoryOffsetChanged:nil];
	[self writeValueChanged:nil];
	[self repeatCountChanged:nil];
	[self repeatDelayChanged:nil];
	[self useMemoryChanged:nil];
	[self autoIncrementChanged:nil];
	[self basicOpsRunningChanged:nil];
	[self mtcDataBaseChanged:nil];
	[self isPulserFixedRateChanged:nil];
	[self fixedPulserRateCountChanged:nil];
	[self fixedPulserRateDelayChanged:nil];
    [self triggerMTCAMaskChanged:nil];
    [self isPedestalEnabledInCSRChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMTCBasicLock to:secure];
    [basicOpsLockButton setEnabled:secure];
}

#pragma mark •••Interface Management
- (void) sequenceRunning:(NSNotification*)aNote
{
	sequenceRunning = YES;
	[initProgressBar startAnimation:self];
	[initProgressBar setDoubleValue:0];
	[initProgressField setHidden:NO];
	[initProgressField setDoubleValue:0];
    [self basicLockChanged:nil];
    //hack to unlock UI if the sequence couldn't finish and didn't raise an exception (MTCD feature)
    [self performSelector:@selector(sequenceStopped:) withObject:nil afterDelay:5];
}

- (void) sequenceStopped:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[initProgressField setHidden:YES];
	[initProgressBar setDoubleValue:0];
	[initProgressBar stopAnimation:self];
	sequenceRunning = NO;
    [self basicLockChanged:nil];
}

- (void) sequenceProgress:(NSNotification*)aNote
{
	double progress = [[[aNote userInfo] objectForKey:@"progress"] floatValue];
	[initProgressBar setDoubleValue:progress];
	[initProgressField setFloatValue:progress/100.];
}

- (void) mtcDataBaseChanged:(NSNotification*)aNote
{
	[lockOutWidthField		setFloatValue:	[model dbFloatByIndex: kLockOutWidth]];
	[pedestalWidthField		setFloatValue:	[model dbFloatByIndex: kPedestalWidth]];
	[nhit100LoPrescaleField setFloatValue:	[model dbFloatByIndex: kNhit100LoPrescale]];
	[pulserPeriodField		setFloatValue:	[model dbFloatByIndex: kPulserPeriod]];
    [extraPulserPeriodField	setFloatValue:	[model dbFloatByIndex: kPulserPeriod]];
    [fineSlopeField			setFloatValue:	[model dbFloatByIndex: kFineSlope]];
	[minDelayOffsetField	setFloatValue:	[model dbFloatByIndex: kMinDelayOffset]];
	[coarseDelayField		setFloatValue:	[model dbFloatByIndex: kCoarseDelay]];
	[fineDelayField			setFloatValue:	[model dbFloatByIndex: kFineDelay]];
	
	[self displayMasks];

	//load the nhit values
	/*
    int col,row;
	float displayValue=0;
	for(col=0;col<4;col++){
		for(row=0;row<6;row++){
			int index = kNHit100HiThreshold + row + (col * 6);
			if(col == 0){
				int type = [model nHitViewType];
				if(type == kNHitsViewRaw) {
					displayValue = [model dbFloatByIndex: index];
				}	
				else if(type == kNHitsViewmVolts) { 
					float rawValue = [model dbFloatByIndex: index];
					displayValue = [model rawTomVolts:rawValue];
				}
				else if(type == kNHitsViewNHits) {
					int rawValue    = [model dbFloatByIndex: index];
					float mVolts    = [model rawTomVolts:rawValue];
					float dcOffset  = [model dbFloatByIndex:index + kNHitDcOffset_Offset];
					float mVperNHit = [model dbFloatByIndex:index + kmVoltPerNHit_Offset];
					displayValue    = [model mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];			
				}
			}
			else displayValue = [model dbFloatByIndex: index];
			[[nhitMatrix cellAtRow:row column:col] setFloatValue:displayValue];
		}
	}
	
	//now the esum values
	for(col=0;col<4;col++){
		for(row=0;row<4;row++){
			int index = kESumLowThreshold + row + (col * 4);
			if(col == 0){
				int type = [model eSumViewType];
				if(type == kESumViewRaw) {
					displayValue = [model dbFloatByIndex: index];
				}	
				else if(type == kESumViewmVolts) { 
					float rawValue = [model dbFloatByIndex: index];
					displayValue = [model rawTomVolts:rawValue];
				}
				else if(type == kESumVieweSumRel) {					
					float dcOffset = [model dbFloatByIndex:index + kESumDcOffset_Offset];
					displayValue = dcOffset - [model dbFloatByIndex: index];
				}
				else if(type == kESumViewpC) {
					int rawValue   = [model dbFloatByIndex: index];
					float mVolts   = [model rawTomVolts:rawValue];
					float dcOffset = [model dbFloatByIndex:index + kESumDcOffset_Offset];
					float mVperpC  = [model dbFloatByIndex:index + kmVoltPerpC_Offset];
					displayValue   = [model mVoltsTopC:mVolts dcOffset:dcOffset mVperpC:mVperpC];			
				}
			}
			else displayValue = [model dbFloatByIndex: index];
			[[esumMatrix cellAtRow:row column:col] setFloatValue:displayValue];
		}
	}
	*/
	NSString* ss = [model dbObjectByIndex: kDBComments];
	if(!ss) ss = @"---";
	[commentsField setStringValue: ss];
}

- (void) displayMasks
{
	int i;
	int maskValue = [model dbIntByIndex: kGtMask];
	for(i=0;i<26;i++){
		[[globalTriggerMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model dbIntByIndex: kGtCrateMask];
	for(i=0;i<25;i++){
		[[globalTriggerCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model dbIntByIndex: kPEDCrateMask];
	for(i=0;i<25;i++){
		[[pedCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
}

- (void) basicOpsRunningChanged:(NSNotification*)aNote
{
	if([model basicOpsRunning])[basicOpsRunningIndicator startAnimation:model];
	else [basicOpsRunningIndicator stopAnimation:model];
}

- (void) autoIncrementChanged:(NSNotification*)aNote
{
	[autoIncrementCB setIntValue: [model autoIncrement]];
}

- (void) useMemoryChanged:(NSNotification*)aNote
{
	[useMemoryMatrix selectCellWithTag: [model useMemory]];
}

- (void) repeatDelayChanged:(NSNotification*)aNote
{
	[repeatDelayField setIntValue: [model repeatDelay]];
	[repeatDelayStepper setIntValue:   [model repeatDelay]];
}

- (void) repeatCountChanged:(NSNotification*)aNote
{
	[repeatCountField setIntValue:	 [model repeatOpCount]];
	[repeatCountStepper setIntValue: [model repeatOpCount]];
}

- (void) writeValueChanged:(NSNotification*)aNote
{
	[writeValueField setIntValue: [model writeValue]];
}

- (void) memoryOffsetChanged:(NSNotification*)aNote
{
	[memoryOffsetField setIntValue: [model memoryOffset]];
}

- (void) selectedRegisterChanged:(NSNotification*)aNote
{
	[selectedRegisterPU selectItemAtIndex: [model selectedRegister]];
}

- (void) isPulserFixedRateChanged:(NSNotification*)aNote
{
	[[isPulserFixedRateMatrix cellWithTag:1] setIntValue:[model isPulserFixedRate]];
	[[isPulserFixedRateMatrix cellWithTag:0] setIntValue:![model isPulserFixedRate]];
    [self basicLockChanged:nil];
}

- (void) fixedPulserRateCountChanged:(NSNotification*)aNote
{
	[fixedTimePedestalsCountField setIntValue:[model fixedPulserRateCount]];
}

- (void) fixedPulserRateDelayChanged:(NSNotification*)aNote
{
	[fixedTimePedestalsDelayField setFloatValue:[model fixedPulserRateDelay]];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{

    BOOL locked						= [gSecurity isLocked:ORMTCBasicLock];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCBasicLock];

    //Basic ops
    [basicOpsLockButton setState: locked];
    [autoIncrementCB setEnabled: !lockedOrNotRunningMaintenance];
    [useMemoryMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayStepper setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountStepper setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueField setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueStepper setEnabled: !lockedOrNotRunningMaintenance];
    [memoryOffsetField setEnabled: !lockedOrNotRunningMaintenance];
    [memoryOffsetStepper setEnabled: !lockedOrNotRunningMaintenance];
    [selectedRegisterPU setEnabled: !lockedOrNotRunningMaintenance];
    [memBaseAddressStepper setEnabled: !lockedOrNotRunningMaintenance];
    [readButton setEnabled: !lockedOrNotRunningMaintenance];
    [writteButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopButton setEnabled: !lockedOrNotRunningMaintenance];
    [statusButton setEnabled: !lockedOrNotRunningMaintenance];
    
    //Standards ops
    lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCBasicLock] | sequenceRunning;
    
    [initMtcButton				setEnabled: !lockedOrNotRunningMaintenance];
    [initNoXilinxButton			setEnabled: !lockedOrNotRunningMaintenance];
    [initNo10MHzButton			setEnabled: !lockedOrNotRunningMaintenance];
    [initNoXilinxNo100MHzButton setEnabled: !lockedOrNotRunningMaintenance];
    [pulserFeedsMatrix          setEnabled: !lockedOrNotRunningMaintenance];
    
    [firePedestalsButton		setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [stopPedestalsButton		setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [continuePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [fireFixedTimePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance  && ![model isPulserFixedRate]];
    [stopFixedTimePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    [fixedTimePedestalsCountField	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    [fixedTimePedestalsDelayField	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    
    [triggerZeroMatrix			setEnabled: !lockedOrNotRunningMaintenance];
    [findTriggerZerosButton		setEnabled: !lockedOrNotRunningMaintenance];
    [continuousButton			setEnabled: !lockedOrNotRunningMaintenance];
    [stopTriggerZeroButton		setEnabled: !lockedOrNotRunningMaintenance];

    //Settings
    [load10MhzCounterButton		    setEnabled: !lockedOrNotRunningMaintenance];
    [setCoarseDelayButton           setEnabled: !lockedOrNotRunningMaintenance];
    [setFineDelayButton				setEnabled: !lockedOrNotRunningMaintenance];
    [loadMTCADacsButton				setEnabled: !lockedOrNotRunningMaintenance];
    [nhitMatrix                     setEnabled: !lockedOrNotRunningMaintenance];
    [esumMatrix                     setEnabled: !lockedOrNotRunningMaintenance];
    [lockOutWidthField              setEnabled: !lockedOrNotRunningMaintenance];
    [pedestalWidthField             setEnabled: !lockedOrNotRunningMaintenance];
    [low10MhzClockField             setEnabled: !lockedOrNotRunningMaintenance];
    [high10MhzClockField            setEnabled: !lockedOrNotRunningMaintenance];
    [nhit100LoPrescaleField         setEnabled: !lockedOrNotRunningMaintenance];
    [pulserPeriodField              setEnabled: !lockedOrNotRunningMaintenance];
    [extraPulserPeriodField         setEnabled: !lockedOrNotRunningMaintenance];
    [fineSlopeField                 setEnabled: !lockedOrNotRunningMaintenance];
    [minDelayOffsetField            setEnabled: !lockedOrNotRunningMaintenance];
    [fineDelayField                 setEnabled: !lockedOrNotRunningMaintenance];
    [coarseDelayField               setEnabled: !lockedOrNotRunningMaintenance];

    //Triggers
    [globalTriggerCrateMaskMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [globalTriggerMaskMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [pedCrateMaskMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaEHIMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaELOMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaN100Matrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaN20Matrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaOEHIMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaOELOMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [mtcaOWLNMatrix setEnabled: !lockedOrNotRunningMaintenance];
    
    [loadGTCrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadMTCACrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadPEDCrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadTriggerMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [clearGTCratesButton setEnabled: !lockedOrNotRunningMaintenance];
    [clearMTCAMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [clearPEDCratesButton setEnabled: !lockedOrNotRunningMaintenance];
    [clearTriggersButton setEnabled: !lockedOrNotRunningMaintenance];
    
}

- (void) isPedestalEnabledInCSRChanged:(NSNotification*)aNotification
{
    if ([model isPedestalEnabledInCSR]) {
        [[pulserFeedsMatrix cellWithTag:0] setIntegerValue:0];
        [[pulserFeedsMatrix cellWithTag:1] setIntegerValue:1];
    }
    else {
        [[pulserFeedsMatrix cellWithTag:0] setIntegerValue:1];
        [[pulserFeedsMatrix cellWithTag:1] setIntegerValue:0];
    }
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    if([tabView indexOfTabViewItem:item] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicOpsSize];
		[[self window] setContentView:mtcView];
    }
    else if([tabView indexOfTabViewItem:item] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:standardOpsSize];
		[[self window] setContentView:mtcView];
    }
    else if([tabView indexOfTabViewItem:item] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingsSize];
		[[self window] setContentView:mtcView];
    }
    else if([tabView indexOfTabViewItem:item] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:triggerSize];
		[[self window] setContentView:mtcView];
    }


    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) regBaseAddressChanged:(NSNotification*)aNotification
{
	[regBaseAddressText setIntValue: [model baseAddress]];
}

- (void) memBaseAddressChanged:(NSNotification*)aNotification
{
	[memBaseAddressText setIntValue: [model memBaseAddress]];
}

- (void) triggerMTCAMaskChanged:(NSNotification*)aNotification
{
    unsigned long maskValue = [model mtcaN100Mask];
    unsigned short i;
	for(i=0;i<20;i++) [[mtcaN100Matrix cellWithTag:i] setIntValue: maskValue & (1<<i)];

    maskValue = [model mtcaN20Mask];
	for(i=0;i<20;i++) [[mtcaN20Matrix cellWithTag:i] setIntValue: maskValue & (1<<i)];

    maskValue = [model mtcaEHIMask];
	for(i=0;i<20;i++) [[mtcaEHIMatrix cellWithTag:i] setIntValue: maskValue & (1<<i)];

    maskValue = [model mtcaELOMask];
	for(i=0;i<20;i++) [[mtcaELOMatrix cellWithTag:i] setIntValue: maskValue & (1<<i)];
    
    maskValue = [model mtcaOELOMask];
	for(i=0;i<20;i++) {
        if ([mtcaOELOMatrix cellWithTag:i]) {
            [[mtcaOELOMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
        }
    }

    maskValue = [model mtcaOEHIMask];
	for(i=0;i<20;i++) {
        if ([mtcaOEHIMatrix cellWithTag:i]) {
            [[mtcaOEHIMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
        }
    }

    maskValue = [model mtcaOWLNMask];
	for(i=0;i<20;i++) {
        if ([mtcaOWLNMatrix cellWithTag:i]) {
            [[mtcaOWLNMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
        }
    }
}

#pragma mark •••Actions

- (IBAction) basicAutoIncrementAction:(id)sender
{
	[model setAutoIncrement:[sender intValue]];	
}

//basic ops
- (IBAction) basicUseMemoryAction:(id)sender
{
	[model setUseMemory:[[sender selectedCell] tag]];	
}

- (IBAction) basicRepeatDelayAction:(id)sender
{
	[model setRepeatDelay:[sender intValue]];	
}

- (IBAction) basicRepeatCountAction:(id)sender
{
	[model setRepeatOpCount:[sender intValue]];	
}

- (IBAction) basicWriteValueAction:(id)sender
{
	[model setWriteValue:[sender intValue]];	
}

- (IBAction) basicMemoryOffsetAction:(id)sender
{
	[model setMemoryOffset:[sender intValue]];	
}

- (void) basicSelectedRegisterAction:(id)sender
{
	[model setSelectedRegister:[sender indexOfSelectedItem]];	
}

- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORMTCBasicLock to:[sender intValue] forWindow:[self window]];
}

- (void) populatePullDown
{
    short	i;
        
    [selectedRegisterPU removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [selectedRegisterPU insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
     
    [self selectedRegisterChanged:nil];

}

- (void) buttonPushed:(id) sender 
{
	NSLog(@"Input received from %@\n", [sender title] );	//This is the only real method.  The other button push methods just call this one.
	NSLogColor([NSColor redColor], @"implementation needed\n");
}

//basic ops Actions
- (IBAction) basicReadAction:(id) sender
{
	[model readBasicOps];
}

- (IBAction) basicWriteAction:(id) sender
{
	[model writeBasicOps];
}

- (IBAction) basicStatusAction:(id) sender
{
	[model reportStatus];
}

- (IBAction) basicStopAction:(id) sender
{
	[model stopBasicOps];
}

//MTC Init Ops buttons.
- (IBAction) standardInitMTC:(id) sender 
{
	[model initializeMtc:YES load10MHzClock:YES]; 
}

- (IBAction) standardInitMTCnoXilinx:(id) sender 
{
	[model initializeMtc:NO load10MHzClock:YES]; 
}

- (IBAction) standardInitMTCno10MHz:(id) sender 
{
	[model initializeMtc:YES load10MHzClock:NO]; 
}

- (IBAction) standardInitMTCnoXilinxno10MHz:(id) sender 
{
	[model initializeMtc:NO load10MHzClock:NO]; 
}

- (IBAction) standardLoad10MHzCounter:(id) sender 
{
	[model load10MHzClock];
}

- (IBAction) standardLoadOnlineGTMasks:(id) sender 
{
	[model setGlobalTriggerWordMask];
}
	
- (IBAction) standardLoadMTCADacs:(id) sender 
{
	[model loadTheMTCADacs];
}

- (IBAction) standardSetCoarseDelay:(id) sender 
{
	[model setupGTCorseDelay];
}

- (IBAction) standardSetFineDelay:(id) sender
{
    [model setupGTFineDelay];
}

- (IBAction) standardIsPulserFixedRate:(id) sender
{
	[self endEditing];
	[model setIsPulserFixedRate:[[sender selectedCell] tag]];
}

- (IBAction) standardFirePedestals:(id) sender 
{
	[model fireMTCPedestalsFixedRate];
}

- (IBAction) standardStopPedestals:(id) sender 
{
	[model stopMTCPedestalsFixedRate];
}

- (IBAction) standardContinuePedestals:(id) sender 
{
	[model continueMTCPedestalsFixedRate];
}

- (IBAction) standardFirePedestalsFixedTime:(id) sender
{
	[model fireMTCPedestalsFixedTime];
}

- (IBAction) standardStopPedestalsFixedTime:(id) sender
{
	[model stopMTCPedestalsFixedTime];
}

- (IBAction) standardSetPedestalsCount:(id) sender
{
	unsigned long aValue = [sender intValue];
	if (aValue < 1) aValue = 1;
	if (aValue > 10000) aValue = 10000;
	[model setFixedPulserRateCount:aValue];
}

- (IBAction) standardSetPedestalsDelay:(id) sender
{
	float aValue = [sender floatValue];
	if (aValue < 0.1) aValue = 0.1;
	if (aValue > 2000000) aValue = 2000000;
	[model setFixedPulserRateDelay:aValue];
}

- (IBAction) standardFindTriggerZeroes:(id) sender 
{
	[self buttonPushed:sender];
}

- (IBAction) standardStopFindTriggerZeroes:(id) sender 
{
	[self buttonPushed:sender];
}

- (IBAction) standardPulserFeeds:(id)sender
{
    [model setIsPedestalEnabledInCSR:[[sender selectedCell] tag]];
}

//Settings buttons.
- (IBAction) eSumViewTypeAction:(id)sender
{
	[self endEditing];
    [self changeNhitThresholdsDisplay:[sender tag]];
}

- (IBAction) nHitViewTypeAction:(id)sender
{
	[self endEditing];
    [self changeNhitThresholdsDisplay: [sender tag]];
}

- (void) changeNhitThresholdsDisplay: (int) type
{
    for(int i=0;i<7;i++)
    {
        [[nhitMatrix cellWithTag:i] setFloatValue:
         [model getThresholdOfType:[self convert_view_thresold_index_to_model_index:i]
                           inUnits:type]];
    }
}
- (void) changeESUMThresholdDisplay: (int) type
{
    for(int i=0;i<7;i++)
    {
        [[nhitMatrix cellWithTag:i] setFloatValue:
         [model getThresholdOfType:[self convert_view_thresold_index_to_model_index:i]
                           inUnits:type]];
    }
}
- (int) convert_view_thresold_index_to_model_index: (int) view_index {
    return view_index;
}
- (int) convert_model_threshold_index_to_view_index: (int) model_index{
    return model_index;
}
- (int) convert_view_unit_index_to_model_index: (int) view_index {
    return view_index;
}
- (int) convert_model_unit_index_to_view_index: (int) model_index{
    return model_index;
}

- (IBAction) settingsMTCDAction:(id) sender
{
	[model setDbObject:[sender stringValue] forIndex:[sender tag]];
}

- (IBAction) settingsNHitAction:(id) sender 
{
    NSLog(@"SettingsNHItAction needs implementation\n");
}


- (IBAction) settingsESumAction:(id) sender 
{
    NSLog(@"SettingsESUMAction needs implementation\n");

}

- (IBAction) settingsGTMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<26;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kGtMask];
}

- (IBAction) settingsGTCrateMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<25;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kGtCrateMask];
}

- (IBAction) settingsPEDCrateMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<25;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setDbLong:mask forIndex:kPEDCrateMask];
}


- (IBAction) triggerMTCAN100:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaN100Mask:mask];
}

- (IBAction) triggerMTCAN20:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaN20Mask:mask];
}

- (IBAction) triggerMTCAEHI:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaEHIMask:mask];
}

- (IBAction) triggerMTCAELO:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaELOMask:mask];
}

- (IBAction) triggerMTCAOELO:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([sender cellWithTag:i] && [[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaOELOMask:mask];
}

- (IBAction) triggerMTCAOEHI:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([sender cellWithTag:i] && [[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaOEHIMask:mask];
}

- (IBAction) triggerMTCAOWLN:(id) sender
{
    unsigned long mask = 0;
	int i;
	for(i=0;i<20;i++){
		if([sender cellWithTag:i] && [[sender cellWithTag:i] intValue]){
			mask |= (1L << i);
		}
	}
    [model setMtcaOWLNMask:mask];
}

- (IBAction) triggersLoadTriggerMask:(id) sender
{
    [model setGlobalTriggerWordMask];
}

- (IBAction) triggersLoadGTCrateMask:(id) sender
{
    [model setGTCrateMask];
}

- (IBAction) triggersLoadPEDCrateMask:(id) sender
{
    [model setPedestalCrateMask];
}

- (IBAction) triggersLoadMTCACrateMask:(id) sender
{
    [model mtcatLoadCrateMasks];
}

- (IBAction) triggersClearTriggerMask:(id) sender
{
    [model clearGlobalTriggerWordMask];
}

- (IBAction) triggersClearGTCrateMask:(id) sender
{
    [model clearGTCrateMask];
}

- (IBAction) triggersClearPEDCrateMask:(id) sender
{
    [model clearPedestalCrateMask];
}

- (IBAction) triggersClearMTCACrateMask:(id) sender
{
    [model mtcatClearCrateMasks];
}

@end

#pragma mark •••PrivateInterface
@implementation ORMTCController (private)

- (void) setupNHitFormats
{
    NSLog(@"setupNHitFormats -> Needs implemenation\n");
}

- (void) setupESumFormats
{
    NSLog(@"setupESumFormats -> Needs implemenation\n");
}

- (void) storeUserNHitValue:(float)userValue index:(int) thresholdIndex
{
	//user changed the NHit threshold -- convert from the displayed value to the raw value and store
    NSLog(@"storeUserNHitValue -> Needs implemenation\n");

}

- (void) calcNHitValueForRow:(int) aRow
{
    NSLog(@"calcNHitValueForRow -> Needs implemenation\n");

}

- (void) storeUserESumValue:(float)userValue index:(int) thresholdIndex
{
	//user changed the ESum threshold -- convert from the displayed value to the raw value and store
    NSLog(@"storeUserEsumValue -> Needs implemenation\n");
}

- (void) calcESumValueForRow:(int) aRow
{
    NSLog(@"calcESUMValueForRow -> Needs implemenation\n");
}

@end
