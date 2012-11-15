//--------------------------------------------------------
// ORVXMModel
// Created by Mark  A. Howe on Fri Jul 22 2005
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
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORVXMModel.h"
#import "ORVXMMotor.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"

#pragma mark ***External Strings
NSString* ORVXMModelUseCmdQueueChanged		= @"ORVXMModelUseCmdQueueChanged";
NSString* ORVXMModelWaitingChanged			= @"ORVXMModelWaitingChanged";
NSString* ORVXMModelCustomCmdChanged		= @"ORVXMModelCustomCmdChanged";
NSString* ORVXMModelCmdTypeExecutingChanged = @"ORVXMModelCmdTypeExecutingChanged";
NSString* ORVXMModelShipRecordsChanged		= @"ORVXMModelShipRecordsChanged";
NSString* ORVXMModelNumTimesToRepeatChanged = @"ORVXMModelNumTimesToRepeatChanged";
NSString* ORVXMModelCmdIndexChanged			= @"ORVXMModelCmdIndexChanged";
NSString* ORVXMModelStopRunWhenDoneChanged  = @"ORVXMModelStopRunWhenDoneChanged";
NSString* ORVXMModelRepeatCountChanged		= @"ORVXMModelRepeatCountChanged";
NSString* ORVXMModelRepeatCmdsChanged		= @"ORVXMModelRepeatCmdsChanged";
NSString* ORVXMModelSyncWithRunChanged		= @"ORVXMModelSyncWithRunChanged";
NSString* ORVXMModelDisplayRawChanged		= @"ORVXMModelDisplayRawChanged";
NSString* ORVXMModelSerialPortChanged		= @"ORVXMModelSerialPortChanged";
NSString* ORVXMModelPortNameChanged			= @"ORVXMModelPortNameChanged";
NSString* ORVXMModelPortStateChanged		= @"ORVXMModelPortStateChanged";
NSString* ORVXMModelCmdQueueChanged			= @"ORVXMModelCmdQueueChanged";
NSString* ORVXMModelListFileChanged			= @"ORVXMModelListFileChanged";
NSString* ORVXMModelListItemsAdded			= @"ORVXMModelListItemsAdded";
NSString* ORVXMModelListItemsRemoved		= @"ORVXMModelListItemsRemoved";

NSString* ORVXMLock							= @"ORVXMLock";


@interface ORVXMModel (private)
- (void) timeout;
- (void) process_response:(NSString*)theResponse;
- (void) startTimeOut;
- (int)  motorToQuery;
- (void) makeMotors;
- (void) addCmdToQueue:(NSString*)aCmdString description:(NSString*)aDescription waitToSend:(BOOL)waitToSendNextCmd;
- (void) processNextCommand;
- (void) incrementCmdIndex;
- (void) runStarting:(NSNotification*)aNote;
- (void) runStopping:(NSNotification*)aNote;
- (void) stopRun;
- (void) delayedRunStop;
- (void) queryPosition;
- (void) queryPositions;
- (int) nextMotorToQuery;
- (void) sendCommand:(NSString*)aCmd;
@end

@implementation ORVXMModel
- (id) init
{
	self = [super init];
    [self registerNotificationObservers];
	[[self undoManager] disableUndoRegistration];
    [self makeMotors];
    [[self undoManager] enableUndoRegistration];
	
	return self;
}

- (void) dealloc
{
	for(id aMotor in motors)[aMotor setDelegate:nil];
	[motors dealloc];
	[cmdQueue release];
    [listFile  release];
	[customCmd release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [portName release];
    if([serialPort isOpen]){
        [serialPort close];
    }
    [serialPort release];
	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"VXM"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORVXMController"];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStarting:)
                         name : ORRunAboutToStartNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runStopping:)
                         name : ORRunAboutToStopNotification
                       object : nil];
	
}


- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"] 
													  encoding:NSASCIIStringEncoding] autorelease] uppercaseString];        
        [self process_response:theString];
    }
}

- (void) shipMotorState:(int)motorIndex
{
	if( [[ORGlobal sharedGlobal] runInProgress] && (motorIndex < [motors count])){
		ORVXMMotor* aMotor = [motors objectAtIndex:motorIndex];
		//get the time(UT!)
		time_t	ut_time;
		time(&ut_time);
				
		unsigned long data[5];
		data[0] = dataId | 5;
		data[1] = ut_time;
		data[2] = (motorIndex<<16) | ([self uniqueIdNumber]&0x0000fffff);
		//encode the position 
		union {
			long asLong;
			float asFloat;
		}thePosition;
			
		thePosition.asFloat = [aMotor motorPosition]; //steps
		data[3] = thePosition.asLong;
			
		thePosition.asFloat = [aMotor conversion]; //steps/mm
		data[4] = thePosition.asLong;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*5]];
	}
}

#pragma mark ***Accessors

- (BOOL) useCmdQueue
{
    return useCmdQueue;
}

- (void) setUseCmdQueue:(BOOL)aUseCmdQueue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseCmdQueue:useCmdQueue];
    useCmdQueue = aUseCmdQueue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelUseCmdQueueChanged object:self];
}

- (BOOL) waiting
{
    return waiting;
}

- (void) setWaiting:(BOOL)aWaiting
{
    waiting = aWaiting;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelWaitingChanged object:self];
}

- (NSString*) customCmd
{
	if(customCmd) return customCmd;
	else return @"";
}

- (void) setCustomCmd:(NSString*)aCustomCmd
{
	if(!aCustomCmd)aCustomCmd = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomCmd:customCmd];
    
    [customCmd autorelease];
    customCmd = [aCustomCmd copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelCustomCmdChanged object:self];
}

- (int) cmdTypeExecuting
{
    return cmdTypeExecuting;
}

- (void) setCmdTypeExecuting:(int)aCmdTypeExecuting
{
    cmdTypeExecuting = aCmdTypeExecuting;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelCmdTypeExecutingChanged object:self];
}

- (void) loadListFrom:(NSString*)aPath
{
	[self setListFile:aPath];
	NSString* s = [NSString stringWithContentsOfFile:aPath encoding:NSASCIIStringEncoding error:nil];
	[self removeAllCmds];
	[self setCmdIndex:0];
	[self setRepeatCount:0];
	
	NSArray* lines = [s componentsSeparatedByString:@"\n"];
	BOOL saveUseCmdQueue = useCmdQueue;
	useCmdQueue = YES;
	for(id aLine in lines){
		NSArray* parts = [aLine componentsSeparatedByString:@"#"];
		if([parts count]>2){
			[self addCmdToQueue:[[parts objectAtIndex:0] trimSpacesFromEnds] 
					description:[[parts objectAtIndex:1] trimSpacesFromEnds] 
					 waitToSend:[[[parts objectAtIndex:2] trimSpacesFromEnds] intValue]];
			
		}
	}
	useCmdQueue = saveUseCmdQueue;
}

- (void) saveListTo:(NSString*)aPath
{
	[self setListFile:aPath];
    NSMutableString* list = [NSMutableString string];
    for(id aCmd in cmdQueue){
        [list appendFormat:@"%@ # %@ # %d\n",[aCmd cmd],[aCmd description],[aCmd waitToSendNextCmd]];
    }
    NSString* s = [list stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    [s writeToFile:listFile atomically:NO encoding:NSASCIIStringEncoding error:nil];
}

- (NSString*) listFile
{
    return listFile;
}

- (void) setListFile:(NSString*)aFileName
{
    
    [listFile autorelease];
    listFile = [aFileName copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelListFileChanged object:self];
    
}

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)aShipRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:shipRecords];
    shipRecords = aShipRecords;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelShipRecordsChanged object:self];
}

- (int) numTimesToRepeat
{
    return numTimesToRepeat;
}

- (void) setNumTimesToRepeat:(int)aNumTimesToRepeat
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumTimesToRepeat:numTimesToRepeat];
    numTimesToRepeat = aNumTimesToRepeat;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelNumTimesToRepeatChanged object:self];
}

- (int) cmdIndex
{
    return cmdIndex;
}

- (void) setCmdIndex:(int)aCmdIndex
{
    cmdIndex = aCmdIndex;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelCmdIndexChanged object:self];
}

- (BOOL) stopRunWhenDone
{
    return stopRunWhenDone;
}

- (void) setStopRunWhenDone:(BOOL)aStopRunWhenDone
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopRunWhenDone:stopRunWhenDone];
    stopRunWhenDone = aStopRunWhenDone;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelStopRunWhenDoneChanged object:self];
}

- (int) repeatCount
{
    return repeatCount;
}

- (void) setRepeatCount:(int)aRepeatCount
{
    repeatCount = aRepeatCount;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelRepeatCountChanged object:self];
}

- (BOOL) repeatCmds
{
    return repeatCmds;
}

- (void) setRepeatCmds:(BOOL)aRepeatCmds
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatCmds:repeatCmds];
    repeatCmds = aRepeatCmds;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelRepeatCmdsChanged object:self];
}

- (int) syncWithRun
{
    return syncWithRun;
}

- (void) setSyncWithRun:(int)aSyncWithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSyncWithRun:syncWithRun];
    syncWithRun = aSyncWithRun;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelSyncWithRunChanged object:self];
}

- (BOOL) displayRaw
{
    return displayRaw;
}

- (void) setDisplayRaw:(BOOL)aDisplayRaw
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayRaw:displayRaw];
    displayRaw = aDisplayRaw;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelDisplayRawChanged object:self];
}

- (NSArray*) motors
{
	return motors;
}

- (ORVXMMotor*) motor:(int)aMotor
{
	if(aMotor>=0 && aMotor<[motors count]) return [motors objectAtIndex:aMotor];
	else return nil;
}

- (BOOL) portWasOpen
{
    return portWasOpen;
}

- (void) setPortWasOpen:(BOOL)aPortWasOpen
{
    portWasOpen = aPortWasOpen;
}

- (NSString*) portName
{
    return portName;
}

- (void) removeAllCmds
{
	[self stopAllMotion];
	[cmdQueue removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelCmdQueueChanged object:self];
}

- (ORVXMMotorCmd*) motorCmd:(int)index
{
	if(index < [cmdQueue count]){
		return [cmdQueue objectAtIndex:index];
	}
	else return nil;
}

- (unsigned) cmdQueueCount
{
	return [cmdQueue count];
}

- (NSString*) cmdQueueCommand:(int)index
{
	if(index < [cmdQueue count]){
		return [[cmdQueue objectAtIndex:index] cmd];
	}
	else return @"";
}

- (NSString*) cmdQueueDescription:(int)index
{
	if(index < [cmdQueue count]){
		return [[cmdQueue objectAtIndex:index] description];
	}
	else return @"";
}

- (void) setPortName:(NSString*)aPortName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];
    
    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];    
		
        BOOL valid = NO;
        NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
        ORSerialPort *aPort;
        while (aPort = [enumerator nextObject]) {
            if([portName isEqualToString:[aPort name]]){
                [self setSerialPort:aPort];
                if(portWasOpen){
                    [self openPort:YES];
                }
                valid = YES;
                break;
            }
        } 
        if(!valid){
            [self setSerialPort:nil];
        }       
    }
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelPortNameChanged object:self];
}

- (ORSerialPort*) serialPort
{
    return serialPort;
}

- (void) setSerialPort:(ORSerialPort*)aSerialPort
{
    [aSerialPort retain];
    [serialPort release];
    serialPort = aSerialPort;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
        [serialPort open];
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:1];
		[serialPort setDataBits:8];
 		[serialPort commitChanges];
    }
    else      [serialPort close];
    portWasOpen = [serialPort isOpen];
	if([serialPort isOpen]){
		[self queryPosition];
	}
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelPortStateChanged object:self];
}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setUseCmdQueue:	  [decoder decodeBoolForKey:@"useCmdQueue"]];
	[self setCustomCmd:		  [decoder decodeObjectForKey:@"customCmd"]];
	[self setShipRecords:	  [decoder decodeBoolForKey:@"shipRecords"]];
	[self setNumTimesToRepeat:[decoder decodeIntForKey:@"numTimesToRepeat"]];
	[self setStopRunWhenDone: [decoder decodeBoolForKey:@"stopRunWhenDone"]];
	[self setRepeatCmds:	  [decoder decodeBoolForKey:@"repeatCmds"]];
	[self setRepeatCount:	  [decoder decodeIntForKey:@"repeatCount"]];
	[self setSyncWithRun:	  [decoder decodeIntForKey:@"syncWithRun"]];
	[self setDisplayRaw:	  [decoder decodeBoolForKey:	@"displayRaw"]];
	[self setPortWasOpen:	  [decoder decodeBoolForKey:	@"portWasOpen"]];
    [self setPortName:		  [decoder decodeObjectForKey:@"portName"]];
    [self setListFile:		  [decoder decodeObjectForKey:@"listFile"]];
	
    cmdQueue = [[decoder decodeObjectForKey:@"cmdQueue"]retain];
	motors   = [[decoder decodeObjectForKey:@"motors"] retain];
	if(!motors)[self makeMotors];
	int i = 0;
	for(id aMotor in motors){
		[aMotor setOwner:self];
		[aMotor setMotorId:i];
		i++;
	}
	[[self undoManager] enableUndoRegistration];
	
    [self registerNotificationObservers];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:useCmdQueue		forKey:@"useCmdQueue"];
    [encoder encodeObject:customCmd		forKey:@"customCmd"];
    [encoder encodeBool:shipRecords		forKey:@"shipRecords"];
    [encoder encodeInt:repeatCount		forKey:@"repeatCount"];
    [encoder encodeInt:numTimesToRepeat forKey:@"numTimesToRepeat"];
    [encoder encodeBool:stopRunWhenDone forKey: @"stopRunWhenDone"];
    [encoder encodeBool:repeatCmds		forKey: @"repeatCmds"];
    [encoder encodeInt:syncWithRun		forKey: @"syncWithRun"];
    [encoder encodeBool:displayRaw		forKey: @"displayRaw"];
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
    [encoder encodeObject:motors		forKey: @"motors"];
    [encoder encodeObject:listFile		forKey: @"listFile"];
    [encoder encodeObject:cmdQueue		forKey: @"cmdQueue"];
}

#pragma mark ***Motor Commands
- (void) manualStart
{
	if(!syncWithRun){
		abortAllRepeats = NO;
        [self sendCommand:@"F,K,C\r"];
		[self setCmdIndex:0];
		[self setRepeatCount:0];
		[self processNextCommand];
	}	
}

- (void) addItem:(id)anItem atIndex:(int)anIndex
{
	if(!cmdQueue) cmdQueue= [[NSMutableArray array] retain];
	if([cmdQueue count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[cmdQueue count]);
	[[[self undoManager] prepareWithInvocationTarget:self] removeItemAtIndex:anIndex];
	[cmdQueue insertObject:anItem atIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelListItemsAdded object:self userInfo:userInfo];
}

- (void) removeItemAtIndex:(int) anIndex
{
	id anItem = [cmdQueue objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addItem:anItem atIndex:anIndex];
	[cmdQueue removeObjectAtIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelListItemsRemoved object:self userInfo:userInfo];
}

- (void) addCmdFromTableFor:(int)aMotorIndex
{	
	if(aMotorIndex>=0 && aMotorIndex<[motors count]){	
		id aMotor = [motors objectAtIndex:aMotorIndex];
		if([aMotor absoluteMotion]){
			[self move:aMotorIndex to:[aMotor targetPosition] speed:[aMotor motorSpeed]];
		}
		else {
			[self move:aMotorIndex dx:[aMotor targetPosition] speed:[aMotor motorSpeed]];
		}
	}
}
- (BOOL) isMoving
{
	return ([self cmdTypeExecuting]!=0) && !queryInProgress;
}

- (void) addCustomCmd
{	
	if([customCmd length]>0){
		[self addCmdToQueue:customCmd 
				description:@"Custom Cmd"
				 waitToSend:YES];
	}
}

- (void) addZeroCmd
{
	NSString* aCmd = [NSString stringWithFormat:@"N"];
	[self addCmdToQueue:aCmd 
			description:[NSString stringWithFormat:@"Zero Counter"]
			 waitToSend:NO];
    [self queryPositions];

}

- (void) goHome:(int)aMotorIndex plusDirection:(BOOL)yesOrNo
{
	if(yesOrNo == YES)	[self addHomePlusCmdFor:aMotorIndex];
	else				[self addHomeMinusCmdFor:aMotorIndex];
}

- (void) addHomePlusCmdFor:(int)aMotorIndex
{
	if(aMotorIndex>=0 && aMotorIndex<[motors count]){	
		id aMotor = [motors objectAtIndex:aMotorIndex];
		NSString* aCmd = [NSString stringWithFormat:@"F,K,C,S%dM%d,I%dM0,R",aMotorIndex+1,[aMotor motorSpeed],aMotorIndex+1];
		[self addCmdToQueue:aCmd
				description:[NSString stringWithFormat:@"Move Motor %d to Pos Limit",aMotorIndex]
				 waitToSend:YES];
	}
}

- (void) addHomeMinusCmdFor:(int)aMotorIndex
{
	if(aMotorIndex>=0 && aMotorIndex<[motors count]){	
		id aMotor = [motors objectAtIndex:aMotorIndex];
		NSString* aCmd = [NSString stringWithFormat:@"F,K,C,S%dM%d,I%dM-0,R",aMotorIndex+1,[aMotor motorSpeed],aMotorIndex+1];
		[self addCmdToQueue:aCmd 
				description:[NSString stringWithFormat:@"Move Motor %d to Neg Limit",aMotorIndex]
				 waitToSend:YES];
	}
}

- (void) stopAllMotion
{
    if([serialPort isOpen]){
		abortAllRepeats = YES;
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self sendCommand:@"F,K\r"];
        [self queryPositions];
    }
}

- (void) goToNexCommand
{
    if([serialPort isOpen]){
        [self sendCommand:@"F,K"]; //kill any existing program
	}
}

- (void) move:(int)motorIndex dx:(float)aPosition
{
    [self move: motorIndex dx: aPosition speed: [[self motor: motorIndex] motorSpeed]];
}

- (void) move:(int)motorIndex dx:(float)aPosition speed:(int)aSpeed
{
	if(motorIndex>=0 && motorIndex<[motors count]){	
		NSString* aCmd = [NSString stringWithFormat:@"F,C,S%dM%d,I%dM%.0f,R",motorIndex+1,aSpeed,motorIndex+1,aPosition];
		float conversion = [[motors objectAtIndex:motorIndex] conversion];
		NSString* units = displayRaw?@"stps":@"mm";
		
		[self addCmdToQueue:aCmd 
				description:[NSString stringWithFormat:@"Move %d by %.2f%@ at %.2f%@/s",motorIndex,aPosition/conversion,units,aSpeed/conversion,units]
				 waitToSend:YES];
	}
}

- (void) move:(int)motorIndex to:(float)aPosition speed:(int)aSpeed
{
	if(motorIndex>=0 && motorIndex<[motors count]){	
		NSString* aCmd = [NSString stringWithFormat:@"F,C,S%dM%d,IA%dM%.0f,R",motorIndex+1,aSpeed,motorIndex+1,aPosition];
		float conversion = [[motors objectAtIndex:motorIndex] conversion];
		NSString* units = displayRaw?@"stps":@"mm";
		[self addCmdToQueue:aCmd 
				description:[NSString stringWithFormat:@"Move %d to %.2f%@ at %.2f%@/s",motorIndex,aPosition/conversion,units,aSpeed/conversion,units]
				 waitToSend:YES];
	}
}

- (void) move:(int)motorIndex to:(float)aPosition
{
	if(motorIndex>=0 && motorIndex<[motors count]){	
		NSString* aCmd = [NSString stringWithFormat:@"F,C,IA%dM%.0f,R",motorIndex+1,aPosition];
		float conversion = [[motors objectAtIndex:motorIndex] conversion];
		NSString* units = displayRaw?@"stps":@"mm";
		[self addCmdToQueue:aCmd 
				description:[NSString stringWithFormat:@"Move %d to %.2f%@",motorIndex,aPosition/conversion,units]
				 waitToSend:YES];
	}
}

- (void) sendGo
{
	if([serialPort isOpen]){
        [self sendCommand:@"G\r"];
		[self setWaiting:NO];
		NSLog(@"sent 'Go' to VXM %d\n",[self uniqueIdNumber]);
	}
}

#pragma mark ***Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherVXM
{
    [self setDataId:[anotherVXM dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"VXMModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORVXMDecoderForPosition",   @"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:5],        @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Position"];
    
    return dataDictionary;
}
@end

@implementation ORVXMModel (private)

- (int) motorToQuery
{
	int i;
	for(i=0;i<kNumVXMMotors;i++){
		if(motorToQueryMask & (1<<i)) return i;
	}
	return -1;
}

#pragma mark ***Command Handling
- (void) timeout
{
	NSLogError(@"command timeout",@"VXM",nil);
}

- (void) startTimeOut
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:3];
}

- (void) process_response:(NSString*)aCmd
{
    
	if([aCmd hasPrefix:@"W"]){
		NSLog(@"VXM (%d) paused and waiting on a 'Go' cmd\n",[self uniqueIdNumber]);
		[self setWaiting:YES];
	}
	else {
		if([aCmd rangeOfString:@"^"].location != NSNotFound){
			//the '^' means a command is complete
			aCmd = [aCmd substringFromIndex:1]; //might be more on this response, strip off the '^'
			[self queryPositions];
		}
		else {
			//query reponse
			if([aCmd hasPrefix:@"X"] || 
			   [aCmd hasPrefix:@"Y"] || 
			   [aCmd hasPrefix:@"Z"] || 
			   [aCmd hasPrefix:@"T"] ){			
				aCmd = [aCmd substringFromIndex:1];
			}
			
			if([aCmd length]>0 && [aCmd rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"+-.0123456789"]].location==0) {			
				ORVXMMotor* aMotor = [motors objectAtIndex:[self motorToQuery]];
				[aMotor setMotorPosition:[aCmd floatValue]];
				if([aMotor hasMoved] && shipRecords)[self shipMotorState:[self motorToQuery]];
				
				int nextMotor = [self nextMotorToQuery];
				if(nextMotor>=0){
					[self queryPosition];
				}
				else {
					//all motors queried. 
					queryInProgress = NO;
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
                    if(useCmdQueue){
                        [self incrementCmdIndex];
                        [self processNextCommand];
                    }
					else [self setCmdTypeExecuting:kVXMCmdIdle];
				}
			}
		}
	}
}

- (void) makeMotors
{
    if(!motors){
		motors = [[NSMutableArray arrayWithCapacity:kNumVXMMotors] retain];
		int i;
		for(i=0;i<kNumVXMMotors;i++){
			ORVXMMotor* aMotor = [[ORVXMMotor alloc] initWithOwner:self motorNumber:i];
			[motors addObject:aMotor];
			[aMotor release];
		}
	}
}

- (void) addCmdToQueue:(NSString*)aCmdString description:(NSString*)aDescription waitToSend:(BOOL)waitToSendNextCmd
{
	if(useCmdQueue){
		if(!cmdQueue)cmdQueue	= [[NSMutableArray array] retain];
		ORVXMMotorCmd* aCmd		= [[ORVXMMotorCmd alloc] init];
		aCmd.cmd				= aCmdString;
		aCmd.description		= aDescription;
		aCmd.waitToSendNextCmd	= waitToSendNextCmd;
	 
		[self  addItem:aCmd atIndex:[cmdQueue count]];

		[aCmd release];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelCmdQueueChanged object:self];
	}
	else {
		if([serialPort isOpen] && cmdTypeExecuting == kVXMCmdIdle && ([aCmdString length]>0)){
			[self setCmdTypeExecuting:kVXMImmediateCmdExecuting];
			abortAllRepeats = YES;
			[self setCmdIndex:0];
			[self setRepeatCount:0];
            [self sendCommand:aCmdString];
		}
	}
}

- (void) sendCommand:(NSString*)aCmd
{
	if([serialPort isOpen]){
		[serialPort writeString:aCmd];
	}
}

- (void) processNextCommand
{
	if([serialPort isOpen]){ 
		if(!abortAllRepeats){
			if(cmdIndex<[cmdQueue count]){
				ORVXMMotorCmd* aCmd = [cmdQueue objectAtIndex:cmdIndex];
				[self setCmdTypeExecuting:kVXMCmdListExecuting];
				NSString* theCmd = aCmd.cmd;
                [self sendCommand:theCmd];
				if(!aCmd.waitToSendNextCmd){
					[self incrementCmdIndex];
					[self processNextCommand];
				}
			}
			else {
				//ok finished
				if(repeatCmds && !abortAllRepeats){
					[self setCmdIndex:0];
					[self setRepeatCount:repeatCount+1];
					if(repeatCount < numTimesToRepeat){
						[self processNextCommand];
					}
					else {
						if(stopRunWhenDone){
							[self stopRun];
						}
						[self setCmdTypeExecuting:kVXMCmdIdle];
					}
				}
				else {
					if(stopRunWhenDone)[self stopRun];
					[self setCmdTypeExecuting:kVXMCmdIdle];
				}
			}
		}
        else {
            [self setCmdTypeExecuting:kVXMCmdIdle];
        }
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORVXMModelCmdQueueChanged object:self];
}

- (void) incrementCmdIndex
{
	[self setCmdIndex:cmdIndex+1];
}

- (void) runStarting:(NSNotification*)aNote
{
	if(syncWithRun){
		abortAllRepeats = NO;
		[self setCmdIndex:0];
		[self setRepeatCount:0];
		[self processNextCommand];
	}	
}

- (void) runStopping:(NSNotification*)aNote
{
	if(syncWithRun){
		[self stopAllMotion];
	}	
}
- (void) stopRun
{
	if(stopRunWhenDone && [[ORGlobal sharedGlobal] runInProgress]){
		[self performSelector:@selector(delayedRunStop) withObject:nil afterDelay:1.5];
	}
}
- (void) delayedRunStop
{
	id s = [NSString stringWithFormat:@"VXM %lu Finished Pattern",[self uniqueIdNumber]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRequestRunStop object:self userInfo:s];
}

- (void) queryPositions
{
	if(!queryInProgress){
		queryInProgress = YES;
		int i;
		motorToQueryMask = 0;
		for(i=0;i<kNumVXMMotors;i++) {
			if([[self motor:i] motorEnabled]){
				motorToQueryMask |= (1<<i);
			}
		}
        [self queryPosition];
	}
}

- (int) nextMotorToQuery
{
	if(motorToQueryMask == 0)return -1;
	int i;
	for(i=0;i<kNumVXMMotors;i++) {
		if(motorToQueryMask & (1<<i)){
			motorToQueryMask &= ~(1<<i);
            break;
		}
	}
	if(motorToQueryMask == 0)return -1;

	for(i=0;i<kNumVXMMotors;i++) {
		if(motorToQueryMask & (1<<i)){
			return i;
		}
	}
	return -1;
}

- (void) queryPosition
{
    if([serialPort isOpen]){
		NSString* cmd = nil;
		switch([self motorToQuery]){
			case 0: cmd = @"E,X"; break;
			case 1: cmd = @"E,Y"; break;
			case 2: cmd = @"E,Z"; break;
			case 3: cmd = @"E,T"; break;
		}
		if(cmd){
			[self sendCommand:cmd];
			[self startTimeOut];
		}
    }
}

@end

@implementation ORVXMMotorCmd
@synthesize cmd, description,waitToSendNextCmd;
- (void) dealloc
{
	self.description = nil;
	self.cmd		 = nil;
	[super dealloc];
}
#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super init];
	self.description		= [decoder decodeObjectForKey:	@"description"];	
	self.cmd				= [decoder decodeObjectForKey:	@"cmd"];	
	self.waitToSendNextCmd	= [decoder decodeIntForKey:		@"waitToSendNextCmd"];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:	description			forKey:@"description"];	
    [encoder encodeObject:	cmd					forKey:@"cmd"];	
    [encoder encodeInt:		waitToSendNextCmd	forKey:@"waitToSendNextCmd"];
}

@end
