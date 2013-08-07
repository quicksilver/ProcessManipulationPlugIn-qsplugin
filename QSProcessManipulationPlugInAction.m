//
//  QSProcessManipulationPlugInAction.m
//  QSProcessManipulationPlugIn
//
//  Created by Nicholas Jitkoff on 9/23/05.
//  Copyright __MyCompanyName__ 2005. All rights reserved.
//

#import "QSProcessManipulationPlugInAction.h"
#import <signal.h>
#include <sys/time.h>
#include <sys/resource.h>

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

// Setting a higher "priority" corresponds to having a lower "nice" value.
const int MAX_NICE_MIN_PRIORITY = 20;
const int MIN_NICE_MAX_PRIORITY = -MAX_NICE_MIN_PRIORITY;

@implementation QSObject (Numeric)

+(QSObject *)numericObjectWithName:(NSString *)name intValue:(int)value {
    QSObject *newObject = [QSObject objectWithName:name];
    [newObject setObject:[NSNumber numberWithInt:value] forType:QSNumericType];
    [newObject setPrimaryType:QSNumericType];
    [newObject setIcon:[QSResourceManager imageNamed:@"ExecutableBinaryIcon"]];
    [newObject setIconLoaded:YES];
    return newObject;
}



@end

@implementation QSAdvancedProcessActionProvider

-(BOOL)loadChildrenForObject:(QSObject *)theObject {
    // theObject is (currently) only Activity Monitor.app
     [theObject setChildren:[[QSProcessMonitor sharedInstance] allProcesses]];
    return YES;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	if ([action isEqualToString:@"ProcessSignalAction"]){
		return [NSArray arrayWithObjects:
		[QSObject numericObjectWithName:@"SIGHUP" intValue:1],	/* hangup */
        [QSObject numericObjectWithName:@"SIGINT" intValue:2],	/* interrupt */
		[QSObject numericObjectWithName:@"SIGQUIT" intValue:3],	/* quit */
		[QSObject numericObjectWithName:@"SIGILL" intValue:4],	/* illegal instruction (not reset when caught) */
		[QSObject numericObjectWithName:@"SIGTRAP" intValue:5],	/* trace trap (not reset when caught) */
		[QSObject numericObjectWithName:@"SIGABRT" intValue:6],	/* abort() */
		[QSObject numericObjectWithName:@"SIGPOLL" intValue:7],	/* pollable event ([XSR] generated, not supported) */
		[QSObject numericObjectWithName:@"SIGIOT" intValue:SIGABRT],	/* compatibility */
		[QSObject numericObjectWithName:@"SIGEMT" intValue:7],	/* EMT instruction */
		[QSObject numericObjectWithName:@"SIGFPE" intValue:8],	/* floating point exception */
		[QSObject numericObjectWithName:@"SIGKILL" intValue:9],	/* kill (cannot be caught or ignored) */
		[QSObject numericObjectWithName:@"SIGBUS" intValue:10],	/* bus error */
		[QSObject numericObjectWithName:@"SIGSEGV" intValue:11],	/* segmentation violation */
        [QSObject numericObjectWithName:@"SIGSYS" intValue:12],	/* bad argument to system call */
		[QSObject numericObjectWithName:@"SIGPIPE" intValue:13],	/* write on a pipe with no one to read it */
		[QSObject numericObjectWithName:@"SIGALRM" intValue:14],	/* alarm clock */
		[QSObject numericObjectWithName:@"SIGTERM" intValue:15],	/* software termination signal from kill */
		[QSObject numericObjectWithName:@"SIGURG" intValue:16],	/* urgent condition on IO channel */
		[QSObject numericObjectWithName:@"SIGSTOP" intValue:17],	/* sendable stop signal not from tty */
		[QSObject numericObjectWithName:@"SIGTSTP" intValue:18],	/* stop signal from tty */
		[QSObject numericObjectWithName:@"SIGCONT" intValue:19],	/* continue a stopped process */
		[QSObject numericObjectWithName:@"SIGCHLD" intValue:20],	/* to parent on child stop or exit */
		[QSObject numericObjectWithName:@"SIGTTIN" intValue:21],	/* to readers pgrp upon background tty read */
		[QSObject numericObjectWithName:@"SIGTTOU" intValue:22],	/* like TTIN for output if (tp->t_local&LTOSTOP) */
		[QSObject numericObjectWithName:@"SIGIO" intValue:23],	/* input/output possible signal */
		[QSObject numericObjectWithName:@"SIGXCPU" intValue:24],	/* exceeded CPU time limit */
		[QSObject numericObjectWithName:@"SIGXFSZ" intValue:25],	/* exceeded file size limit */
		nil];
																													
	}else if ([action isEqualToString:@"ProcessSetPriorityAction"]){
		int pid=[self pidOfProcess:dObject];
		QSObject *proxy=[QSObject textProxyObjectWithDefaultValue:[NSString stringWithFormat:@"%d",getpriority(PRIO_PROCESS,pid)]];
		return [NSArray arrayWithObject:proxy];
	}
return nil;
}

- (QSObject *) launchACopyOfApplication:(QSObject *)dObject{
	NSArray *array=[dObject arrayForType:QSProcessType];
	[[NSWorkspace sharedWorkspace] performSelector:@selector(launchACopyOfApplication:) onObjectsInArray:array returnValues:NO];
	return nil;
}

- (QSObject *) killProcess:(QSObject *)dObject{
	[self sendSignal:SIGQUIT toProcess:dObject];
	return nil;
}
- (QSObject *) suspendProcess:(QSObject *)dObject{
	[[NSWorkspace sharedWorkspace] hideApplication:[dObject objectForType:QSProcessType]];
	usleep(300000);
	[self sendSignal:SIGSTOP toProcess:dObject];
	return nil;
}
- (QSObject *) resumeProcess:(QSObject *)dObject{
	[self sendSignal:SIGCONT toProcess:dObject];
	
	[[NSWorkspace sharedWorkspace] showApplication:[dObject objectForType:QSProcessType]];
	return nil;
}
- (void)sendSignal:(int)signal toProcess:(QSObject *)dObject{
	NSEnumerator *e=[[dObject arrayForType:QSProcessType]objectEnumerator];
	NSDictionary *dict;
	while(dict=[e nextObject]){
		int pid=[[[dObject objectForType:QSProcessType]objectForKey:@"NSApplicationProcessIdentifier"]intValue];
		kill(pid, signal);   
	}
}

- (QSObject *) signalProcess:(QSObject *)dObject withValue:(QSObject *)iObject{
	int value=[[iObject objectForType:QSNumericType]intValue];
	[self sendSignal:value toProcess:dObject];
    return nil;
}

- (QSObject *) showFilesOfProcess:(QSObject *)dObject{
	int pid=[self pidOfProcess:dObject];
	NSString *str=[NSString stringWithFormat:@"/usr/sbin/lsof -p %d",pid];
	FILE *file = popen( [str UTF8String], "r" );
	NSString *output=nil;
	NSMutableData *data=[NSMutableData data];
	if( file )
	{
		char buffer[1024];
		size_t length;
		while (length = fread( buffer, 1, sizeof( buffer ), file ))[data appendBytes:buffer length:length];
		output=[[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]autorelease];
		pclose( file );
	} 
	
	NSLog(@"output%@",output);
	NSMutableArray *files=[NSMutableArray array];
	NSArray *lines=[output lines];
	if ([lines count]){
		NSInteger offset=[[lines objectAtIndex:0]rangeOfString:@"NAME"].location;
		lines=[lines subarrayWithRange:NSMakeRange(1,[lines count]-1)];
		for(NSString * line in lines){
			//NSLog([line substringFromIndex:63]);	
			if ((NSInteger)[line length] > offset+1){
				QSObject *object=[QSObject objectWithString:[line substringFromIndex:offset]];
				if (object)[files addObject:object];
			}
		}
		
		id controller=[[NSApp delegate] interfaceController];
		[controller showArray:files];
	}
	//	NSTask *task=[NSTask taskWithLaunchPath:@"/usr/sbin/lsof" arguments:[NSArray arrayWithObjects:@"-p",[NSString stringWithFormat:@"%d",pid],nil]];
	//	NSData *data=[task launchAndReturnOutput];
	//	NSString *string=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
	
	//	NSLog(@"output%@",string);
	return nil;
}
- (QSObject *) sampleProcess:(QSObject *)dObject{
	int pid=[self pidOfProcess:dObject];
	NSString *str=[NSString stringWithFormat:@"/usr/bin/sample %d 5 5 2>&1",pid];
	FILE *file = popen( [str UTF8String], "r" );
	NSString *output=nil;
	NSMutableData *data=[NSMutableData data];
	if( file )
	{
		char buffer[1024];
		size_t length;
		while (length = fread( buffer, 1, sizeof( buffer ), file ))[data appendBytes:buffer length:length];
		output=[[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]autorelease];
		pclose( file );
        
        return [QSObject objectWithString:output];
	} 
	return nil;
	//	NSTask *sampleTask=[NSTask taskWithLaunchPath:@"/usr/bin/sample" arguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",pid],@"5",@"5",nil];
	//	sampleTask
}

- (QSObject *) minimizePriority:(QSObject *)dObject{
  int pid=[self pidOfProcess:dObject];
  
  [self setPriority:MAX_NICE_MIN_PRIORITY ofPID:pid];
  return nil;
}

- (QSObject *) maximizePriority:(QSObject *)dObject{
  int pid=[self pidOfProcess:dObject];
  
  [self setPriority:MIN_NICE_MAX_PRIORITY ofPID:pid];
  return nil;
}

- (QSObject *) lowerPriority:(QSObject *)dObject{
  int pid=[self pidOfProcess:dObject];
  
  [self setPriority:getpriority(PRIO_PROCESS,pid)+5 ofPID:pid];
  return nil;
}

- (QSObject *) raisePriority:(QSObject *)dObject{
    int pid=[self pidOfProcess:dObject];
    [self setPriority:getpriority(PRIO_PROCESS,pid)-5 ofPID:pid];
    return nil;
}

- (QSObject *) setPriorityOf:(QSObject *)dObject to:(QSObject *)iObject{
	int pid=[self pidOfProcess:dObject];
	int value=[[iObject objectForType:QSNumericType]intValue];
	if (!value)value=[[iObject stringValue]intValue];
	if (value>MAX_NICE_MIN_PRIORITY)value=MAX_NICE_MIN_PRIORITY;
	else if (value<MIN_NICE_MAX_PRIORITY)value=MIN_NICE_MAX_PRIORITY;
    [self setPriority:value ofPID:pid];
    return nil;
}


- (int)pidOfProcess:(QSObject *)dObject{
    return [[[dObject objectForType:QSProcessType]objectForKey:@"NSApplicationProcessIdentifier"]intValue];
}

// A wrapper for a QS action.
- (QSObject *)getPidAction:(QSObject *)dObject{
  int pid = [self pidOfProcess:dObject];
  NSString *pidString = [NSString stringWithFormat:@"%d", pid];
  return [QSObject objectWithString:pidString];
}

// A wrapper for a QS action.
- (QSObject *)getPriorityAction:(QSObject *)dObject{
    int pid=[self pidOfProcess:dObject];
    int prio = getpriority(PRIO_PROCESS,pid);
    NSString *priorityString = [NSString stringWithFormat:@"%d", prio];
    return [QSObject objectWithString:priorityString];
}

- (BOOL)setPriority:(int)priority ofPID:(int)pid{
    
    BOOL error=setpriority(PRIO_PROCESS, pid, priority);
    
    if (error){
        OSStatus myStatus;
        
        AuthorizationRef myAuthorizationRef;             //2
        AuthorizationFlags myFlags = kAuthorizationFlagDefaults; 
        
        myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,myFlags,
                                       &myAuthorizationRef);
        if (myStatus != errAuthorizationSuccess) return NO;        
        
        AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
        AuthorizationRights myRights = {1, &myItems};            //7
        
        myFlags = kAuthorizationFlagDefaults |           //8
            kAuthorizationFlagInteractionAllowed |           //9
            kAuthorizationFlagPreAuthorize |         //10
            kAuthorizationFlagExtendRights;         //11
        myStatus = AuthorizationCopyRights (myAuthorizationRef,&myRights, NULL, myFlags, NULL );
        
        if (myStatus != errAuthorizationSuccess) return NO;
        
        char myToolPath[] = "/usr/bin/renice";
        char *myArguments[] = {(char *)[[[NSNumber numberWithInt:priority]stringValue]cStringUsingEncoding:NSUTF8StringEncoding],"-p",(char *)[[[NSNumber numberWithInt:pid]stringValue]cStringUsingEncoding:NSUTF8StringEncoding], NULL };
		//  FILE *myCommunicationsPipe = NULL;
		//  char myReadBuffer[128];
        
        myFlags = kAuthorizationFlagDefaults;             //13
        myStatus = AuthorizationExecuteWithPrivileges           //14
            (myAuthorizationRef, myToolPath, myFlags, myArguments,          //15
             NULL);         //16
        
        AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDefaults);                //17
    }
    
#ifdef DEBUG
        NSLog(@"Priority of %D set to %d", pid, getpriority(PRIO_PROCESS, pid));
#endif
    return YES;
}

- (QSObject *)launchAsRoot:(QSBasicObject *)dObject{
	NSString *path=[dObject validSingleFilePath];
	path=[[NSBundle bundleWithPath:path]executablePath];
	
	OSStatus myStatus;
	
	AuthorizationRef myAuthorizationRef;             //2
	AuthorizationFlags myFlags = kAuthorizationFlagDefaults; 
	
	myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,myFlags,
								   &myAuthorizationRef);
	if (myStatus != errAuthorizationSuccess) return NO;        
	
	AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights myRights = {1, &myItems};            //7
	
	myFlags = kAuthorizationFlagDefaults |           //8
		kAuthorizationFlagInteractionAllowed |           //9
		kAuthorizationFlagPreAuthorize |         //10
		kAuthorizationFlagExtendRights;         //11
	myStatus = AuthorizationCopyRights (myAuthorizationRef,&myRights, NULL, myFlags, NULL );
	
	if (myStatus != errAuthorizationSuccess) return NO;
	
	//	char myToolPath[] = [path UTF8String];
	//	char *myArguments[] = {NULL};
	//  FILE *myCommunicationsPipe = NULL;
	//  char myReadBuffer[128];
	
	myFlags = kAuthorizationFlagDefaults;             //13
	myStatus = AuthorizationExecuteWithPrivileges           //14
		(myAuthorizationRef, [path UTF8String], myFlags, NULL,          //15
		 NULL);         //16
	
	AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDefaults);                //17
	
	
	return nil;
	
	
}

@end
